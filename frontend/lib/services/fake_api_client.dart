import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/fake_backend.dart';

/// Implementação de [ApiClientBase] que não faz nenhuma chamada de rede —
/// delega tudo para [FakeBackend], o "servidor" em memória do modo
/// demonstração. Usada no lugar do [ApiClient] real quando não há backend
/// público disponível (ver `AuthProvider.habilitarModoDemo`).
class FakeApiClient implements ApiClientBase {
  final FakeBackend _backend = FakeBackend.instance;

  @override
  Future<dynamic> get(String path) => _backend.handle('GET', path);

  @override
  Future<List<int>> getBytes(String path) => _backend.handleBytes(path);

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _backend.handle('POST', path, body: body);

  @override
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) => _backend.handle('PATCH', path, body: body);

  @override
  Future<void> delete(String path) => _backend.handle('DELETE', path);

  @override
  Future<dynamic> uploadMultipart(String path, {required List<int> bytes, required String nomeArquivo, String campoArquivo = 'arquivo'}) {
    return _backend.handleUpload(path, bytes: bytes, nomeArquivo: nomeArquivo);
  }
}
