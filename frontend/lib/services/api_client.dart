import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as browser;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Contrato usado por [AuthProvider]/[WorkspaceProvider] para falar com "o
/// backend" — implementado tanto pelo [ApiClient] real (HTTP) quanto pelo
/// `FakeApiClient` do modo demonstração, para que nenhuma tela/provider
/// precise saber qual dos dois está em uso.
abstract class ApiClientBase {
  Future<dynamic> get(String path);
  Future<List<int>> getBytes(String path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]);
  Future<void> delete(String path);
  @override
  Future<dynamic> uploadMultipart(String path, {required List<int> bytes, required String nomeArquivo, String campoArquivo = 'arquivo'});
}

/// Cliente HTTP único do app, alvo Flutter Web.
///
/// Usa [browser.BrowserClient] com `withCredentials = true` para que o cookie
/// HttpOnly do backend (`access_token`) seja enviado/aceito nas chamadas —
/// necessário porque o front (porta 5000, ver FRONTEND_ORIGIN) e o backend
/// (porta 3000) são origens diferentes, ainda que "same-site" (localhost).
class ApiClient implements ApiClientBase {
  // Deriva do host que serviu a página (localhost no desktop, IP da rede
  // local quando acessado por outro dispositivo) em vez de fixar localhost —
  // assim o mesmo build funciona tanto no navegador da máquina quanto no
  // celular, sem precisar recompilar pra cada endereço.
  static String get baseUrl => 'http://${Uri.base.host}:3000';

  final http.Client _client = browser.BrowserClient()..withCredentials = true;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, dynamic>? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  dynamic _decodeRaw(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  void _checarErro(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _decodeBody(response);
    final mensagem = body?['message'];
    final texto = mensagem is List ? mensagem.join(', ') : (mensagem?.toString() ?? 'Erro inesperado (${response.statusCode}).');
    throw ApiException(response.statusCode, texto);
  }

  @override
  Future<dynamic> get(String path) async {
    final response = await _client.get(_uri(path));
    _checarErro(response);
    return _decodeRaw(response);
  }

  /// Para respostas binárias (ex: zip de exportação) — não tenta decodificar como JSON.
  @override
  Future<List<int>> getBytes(String path) async {
    final response = await _client.get(_uri(path));
    _checarErro(response);
    return response.bodyBytes;
  }

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final response = await _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _checarErro(response);
    return _decodeRaw(response);
  }

  @override
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final response = await _client.patch(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _checarErro(response);
    return _decodeRaw(response);
  }

  @override
  Future<void> delete(String path) async {
    final response = await _client.delete(_uri(path));
    _checarErro(response);
  }

  /// Upload multipart. [campoArquivo] é o nome do campo esperado pelo backend ('arquivo').
  @override
  Future<dynamic> uploadMultipart(
    String path, {
    required List<int> bytes,
    required String nomeArquivo,
    String campoArquivo = 'arquivo',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..files.add(http.MultipartFile.fromBytes(campoArquivo, bytes, filename: nomeArquivo));
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    _checarErro(response);
    return _decodeRaw(response);
  }
}
