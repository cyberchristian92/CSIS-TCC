import 'package:flutter/foundation.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  ApiClientBase _api = ApiClient();

  User? currentUser;
  bool isLoading = true; // true durante a checagem inicial de sessão
  String? errorMessage;
  bool modoDemo = false;

  /// Troca o cliente HTTP real pelo backend fake em memória — usado pelo
  /// botão "Entrar em modo demonstração" do login, quando não há backend
  /// público disponível ainda.
  void habilitarModoDemo(ApiClientBase clienteDemo) {
    _api = clienteDemo;
    modoDemo = true;
  }

  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isLider => currentUser?.isLider ?? false;
  bool get isRevisor => currentUser?.isRevisor ?? false;
  bool get isColaborador => currentUser?.isColaborador ?? false;
  bool get isAutenticado => currentUser != null;

  /// Chamado uma vez ao abrir o app: se o cookie HttpOnly ainda for válido,
  /// restaura a sessão sem precisar logar de novo.
  Future<void> tentarRestaurarSessao() async {
    isLoading = true;
    notifyListeners();
    try {
      final json = await _api.get('/auth/me') as Map<String, dynamic>;
      currentUser = User.fromJson(json);
    } catch (_) {
      currentUser = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String senha) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      final json = await _api.post('/auth/login', {'email': email, 'senha': senha}) as Map<String, dynamic>;
      currentUser = User.fromJson(json);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Lança [ApiException] em erro real (ex: rede) — a tela trata a exceção
  /// localmente. O backend sempre responde 200 aqui, exista ou não o email,
  /// pra não permitir descobrir contas cadastradas por esta rota.
  Future<void> esqueciSenha(String email) {
    return _api.post('/auth/esqueci-senha', {'email': email});
  }

  /// Lança [ApiException] se o token for inválido/expirado/já usado.
  Future<void> redefinirSenha(String token, String novaSenha) {
    return _api.post('/auth/redefinir-senha', {'token': token, 'novaSenha': novaSenha});
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // mesmo se a chamada falhar, limpamos o estado local
    }
    currentUser = null;
    notifyListeners();
  }
}
