import 'package:flutter/foundation.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/services/api_client.dart';

/// Concentra todo o acesso às entidades reais do backend usadas pelo fluxo
/// central do app (Projetos, Missões, Entregas, Revisões, Arquivos,
/// Documentos, Auditoria, Usuários).
class WorkspaceProvider extends ChangeNotifier {
  ApiClientBase _api = ApiClient();

  /// Troca o cliente HTTP real pelo backend fake em memória — ver
  /// [AuthProvider.habilitarModoDemo]. Também limpa os caches de
  /// workspace/área padrão, que pertenciam à sessão real anterior.
  void habilitarModoDemo(ApiClientBase clienteDemo) {
    _api = clienteDemo;
    _areaIdPadrao = null;
    _workspaceIdPadrao = null;
  }

  bool isLoadingProjetos = false;
  String? erro;
  List<Projeto> projetos = [];

  List<LogAuditoria> auditoria = [];
  bool isLoadingAuditoria = false;

  List<User> usuarios = [];

  String? _areaIdPadrao;
  String? _workspaceIdPadrao;
  List<AreaApi> areas = [];

  Future<String> garantirWorkspacePadrao() async {
    if (_workspaceIdPadrao != null) return _workspaceIdPadrao!;

    final workspaces = await _api.get('/workspaces') as List<dynamic>;
    Map<String, dynamic> workspace;
    if (workspaces.isEmpty) {
      workspace = await _api.post('/workspaces', {'nome': 'Workspace Principal'}) as Map<String, dynamic>;
    } else {
      workspace = workspaces.first as Map<String, dynamic>;
    }
    _workspaceIdPadrao = workspace['id'] as String;
    return _workspaceIdPadrao!;
  }

  /// A criação de projeto precisa de um `area_id` real. Na primeira vez,
  /// provisiona sozinho uma Área padrão dentro do Workspace padrão via API.
  Future<String> garantirAreaPadrao() async {
    if (_areaIdPadrao != null) return _areaIdPadrao!;

    final workspaceId = await garantirWorkspacePadrao();
    final areasList = await _api.get('/workspaces/$workspaceId/areas') as List<dynamic>;
    Map<String, dynamic> area;
    if (areasList.isEmpty) {
      area = await _api.post('/workspaces/$workspaceId/areas', {'nome': 'Geral', 'tipo': 'PERICIA'})
          as Map<String, dynamic>;
    } else {
      area = areasList.first as Map<String, dynamic>;
    }
    _areaIdPadrao = area['id'] as String;
    return _areaIdPadrao!;
  }

  Future<void> carregarAreas() async {
    final workspaceId = await garantirWorkspacePadrao();
    final list = await _api.get('/workspaces/$workspaceId/areas') as List<dynamic>;
    areas = list.map((a) => AreaApi.fromJson(a as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> criarArea(String nome, String tipo) async {
    final workspaceId = await garantirWorkspacePadrao();
    await _api.post('/workspaces/$workspaceId/areas', {'nome': nome, 'tipo': tipo});
    await carregarAreas();
  }

  Future<void> atualizarArea(String id, {String? nome, String? tipo}) async {
    await _api.patch('/areas/$id', {
      if (nome != null) 'nome': nome,
      if (tipo != null) 'tipo': tipo,
    });
    await carregarAreas();
  }

  Future<void> removerArea(String id) async {
    await _api.delete('/areas/$id');
    await carregarAreas();
  }

  Future<List<Missao>> listarMinhasMissoes() async {
    final list = await _api.get('/missoes/minhas') as List<dynamic>;
    return list.map((m) => Missao.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> carregarProjetos() async {
    isLoadingProjetos = true;
    erro = null;
    notifyListeners();
    try {
      final workspaces = await _api.get('/workspaces') as List<dynamic>;
      final List<Projeto> todos = [];
      for (final w in workspaces) {
        final workspaceId = (w as Map<String, dynamic>)['id'] as String;
        final areas = await _api.get('/workspaces/$workspaceId/areas') as List<dynamic>;
        for (final a in areas) {
          final areaId = (a as Map<String, dynamic>)['id'] as String;
          final projs = await _api.get('/areas/$areaId/projetos') as List<dynamic>;
          todos.addAll(projs.map((p) => Projeto.fromJson(p as Map<String, dynamic>)));
        }
      }
      projetos = todos;
    } on ApiException catch (e) {
      erro = e.message;
    } finally {
      isLoadingProjetos = false;
      notifyListeners();
    }
  }

  Future<Projeto> criarProjeto(String nome, {String? descricao}) async {
    final areaId = await garantirAreaPadrao();
    final json = await _api.post('/areas/$areaId/projetos', {
      'nome': nome,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
    }) as Map<String, dynamic>;
    final projeto = Projeto.fromJson(json);
    projetos = [...projetos, projeto];
    notifyListeners();
    return projeto;
  }

  Future<Projeto> buscarProjeto(String id) async {
    final json = await _api.get('/projetos/$id') as Map<String, dynamic>;
    return Projeto.fromJson(json);
  }

  Future<void> arquivarProjeto(String id) async {
    await _api.patch('/projetos/$id', {'status': 'ARQUIVADO'});
    projetos = projetos.map((p) => p.id == id ? Projeto.fromJson({..._paraJson(p), 'status': 'ARQUIVADO'}) : p).toList();
    notifyListeners();
  }

  Map<String, dynamic> _paraJson(Projeto p) => {
        'id': p.id,
        'area_id': p.areaId,
        'nome': p.nome,
        'descricao': p.descricao,
        'status': p.status,
        'prazo': p.prazo?.toIso8601String(),
      };

  Future<Missao> criarMissao(String projetoId, {required String titulo, String? descricao, String? criterioAceite}) async {
    final json = await _api.post('/projetos/$projetoId/missoes', {
      'titulo': titulo,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      if (criterioAceite != null && criterioAceite.isNotEmpty) 'criterio_aceite': criterioAceite,
    }) as Map<String, dynamic>;
    return Missao.fromJson(json);
  }

  Future<Missao> buscarMissao(String missaoId) async {
    final json = await _api.get('/missoes/$missaoId') as Map<String, dynamic>;
    return Missao.fromJson(json);
  }

  Future<Missao> atribuirMissao(String missaoId, String responsavelId) async {
    final json = await _api.patch('/missoes/$missaoId/atribuir', {'responsavelId': responsavelId}) as Map<String, dynamic>;
    return Missao.fromJson(json);
  }

  Future<Missao> iniciarMissao(String missaoId) async {
    final json = await _api.patch('/missoes/$missaoId/iniciar') as Map<String, dynamic>;
    return Missao.fromJson(json);
  }

  /// Tags são livres para qualquer usuário editar — dá espaço pro colaborador
  /// organizar/detalhar a missão mesmo sem poder mudar o status dela.
  Future<Missao> atualizarTagsMissao(String missaoId, List<String> tags) async {
    final json = await _api.patch('/missoes/$missaoId/tags', {'tags': tags}) as Map<String, dynamic>;
    return Missao.fromJson(json);
  }

  Future<List<ComentarioMissao>> listarComentarios(String missaoId) async {
    final list = await _api.get('/missoes/$missaoId/comentarios') as List<dynamic>;
    return list.map((c) => ComentarioMissao.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<ComentarioMissao> criarComentario(String missaoId, String texto) async {
    final json = await _api.post('/missoes/$missaoId/comentarios', {'texto': texto}) as Map<String, dynamic>;
    return ComentarioMissao.fromJson(json);
  }

  Future<void> removerComentario(String comentarioId) async {
    await _api.delete('/comentarios/$comentarioId');
  }

  Future<List<ChecklistItem>> listarChecklist(String missaoId) async {
    final list = await _api.get('/missoes/$missaoId/checklist') as List<dynamic>;
    return list.map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<ChecklistItem> criarItemChecklist(String missaoId, String texto) async {
    final json = await _api.post('/missoes/$missaoId/checklist', {'texto': texto}) as Map<String, dynamic>;
    return ChecklistItem.fromJson(json);
  }

  Future<void> alternarItemChecklist(String itemId, bool concluido) async {
    await _api.patch('/checklist/$itemId', {'concluido': concluido});
  }

  Future<void> removerItemChecklist(String itemId) async {
    await _api.delete('/checklist/$itemId');
  }

  Future<Entrega> criarEntrega(String missaoId, {String? conteudo}) async {
    final json = await _api.post('/missoes/$missaoId/entregas', {
      if (conteudo != null) 'conteudo': conteudo,
    }) as Map<String, dynamic>;
    return Entrega.fromJson(json);
  }

  Future<List<Entrega>> listarEntregasDaMissao(String missaoId) async {
    final list = await _api.get('/missoes/$missaoId/entregas') as List<dynamic>;
    return list.map((e) => Entrega.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Revisao>> listarRevisoesDaEntrega(String entregaId) async {
    final list = await _api.get('/entregas/$entregaId/revisoes') as List<dynamic>;
    return list.map((r) => Revisao.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Revisao> criarRevisao(String entregaId, {required String status, String? comentario}) async {
    final json = await _api.post('/entregas/$entregaId/revisoes', {
      'status': status,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    }) as Map<String, dynamic>;
    return Revisao.fromJson(json);
  }

  Future<Arquivo> uploadArquivo(
    String projetoId, {
    required List<int> bytes,
    required String nomeArquivo,
    String? entregaId,
    String? missaoId,
    String? pastaId,
  }) async {
    final query = <String, String>{
      if (entregaId != null) 'entregaId': entregaId,
      if (missaoId != null) 'missaoId': missaoId,
      if (pastaId != null) 'pastaId': pastaId,
    };
    final queryString = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final json = await _api.uploadMultipart('/projetos/$projetoId/arquivos$queryString', bytes: bytes, nomeArquivo: nomeArquivo) as Map<String, dynamic>;
    return Arquivo.fromJson(json);
  }

  /// [pastaId] usa `'raiz'` para listar a raiz do projeto; `null` (omitido)
  /// não filtra por pasta nenhuma (usado pelos anexos de uma missão).
  Future<List<Arquivo>> listarArquivosDoProjeto(String projetoId, {String? missaoId, String? pastaId}) async {
    final query = <String, String>{
      if (missaoId != null) 'missaoId': missaoId,
      if (pastaId != null) 'pastaId': pastaId,
    };
    final queryString = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final list = await _api.get('/projetos/$projetoId/arquivos$queryString') as List<dynamic>;
    return list.map((a) => Arquivo.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> verificarIntegridade(String arquivoId) async {
    return await _api.get('/arquivos/$arquivoId/verificar') as Map<String, dynamic>;
  }

  Future<Documento> criarDocumento(String projetoId, String conteudo, {String? missaoId, String? pastaId, List<String>? tags}) async {
    final json = await _api.post('/projetos/$projetoId/documentos', {
      'conteudo': conteudo,
      if (missaoId != null) 'missaoId': missaoId,
      if (pastaId != null) 'pastaId': pastaId,
      if (tags != null) 'tags': tags,
    }) as Map<String, dynamic>;
    return Documento.fromJson(json);
  }

  Future<Documento> atualizarDocumento(String documentoId, String conteudo, {List<String>? tags, String? pastaId}) async {
    final json = await _api.patch('/documentos/$documentoId', {
      'conteudo': conteudo,
      if (tags != null) 'tags': tags,
      if (pastaId != null) 'pastaId': pastaId,
    }) as Map<String, dynamic>;
    return Documento.fromJson(json);
  }

  Future<Documento> buscarDocumento(String documentoId) async {
    final json = await _api.get('/documentos/$documentoId') as Map<String, dynamic>;
    return Documento.fromJson(json);
  }

  Future<List<Documento>> listarDocumentosDoProjeto(String projetoId, {String? missaoId, String? pastaId}) async {
    final query = <String, String>{
      if (missaoId != null) 'missaoId': missaoId,
      if (pastaId != null) 'pastaId': pastaId,
    };
    final queryString = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final list = await _api.get('/projetos/$projetoId/documentos$queryString') as List<dynamic>;
    return list.map((d) => Documento.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// [pastaPaiId] nulo/omitido lista as subpastas da raiz do projeto.
  Future<List<Pasta>> listarPastas(String projetoId, {String? pastaPaiId}) async {
    final queryString = pastaPaiId != null ? '?pastaPaiId=$pastaPaiId' : '';
    final list = await _api.get('/projetos/$projetoId/pastas$queryString') as List<dynamic>;
    return list.map((p) => Pasta.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<Pasta> criarPasta(String projetoId, String nome, {String? pastaPaiId, String? missaoId}) async {
    final json = await _api.post('/projetos/$projetoId/pastas', {
      'nome': nome,
      if (pastaPaiId != null) 'pastaPaiId': pastaPaiId,
      if (missaoId != null) 'missaoId': missaoId,
    }) as Map<String, dynamic>;
    return Pasta.fromJson(json);
  }

  Future<void> renomearPasta(String pastaId, String nome) async {
    await _api.patch('/pastas/$pastaId', {'nome': nome});
  }

  Future<void> removerPasta(String pastaId) async {
    await _api.delete('/pastas/$pastaId');
  }

  /// Pacote completo do projeto (manifesto.json + relatorio.md + arquivos
  /// originais com hash) para custódia/análise externa (inclusive por IA).
  Future<List<int>> exportarProjeto(String projetoId) async {
    return _api.getBytes('/projetos/$projetoId/exportar');
  }

  Future<void> carregarUsuarios() async {
    final list = await _api.get('/auth/usuarios') as List<dynamic>;
    usuarios = list.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  /// Cadastro é fechado — só ADMIN/LIDER autenticado pode convidar alguém.
  Future<void> criarUsuario(String nome, String email, String senha, String papelGlobal) async {
    await _api.post('/auth/register', {'nome': nome, 'email': email, 'senha': senha, 'papelGlobal': papelGlobal});
    await carregarUsuarios();
  }

  Future<void> atualizarPapelUsuario(String userId, String papelGlobal) async {
    await _api.patch('/auth/usuarios/$userId/papel', {'papelGlobal': papelGlobal});
    await carregarUsuarios();
  }

  Future<void> carregarAuditoria() async {
    isLoadingAuditoria = true;
    notifyListeners();
    try {
      final json = await _api.get('/auditoria?pageSize=100') as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>;
      auditoria = items.map((i) => LogAuditoria.fromJson(i as Map<String, dynamic>)).toList();
    } finally {
      isLoadingAuditoria = false;
      notifyListeners();
    }
  }

  /// Agrega, sobre os projetos já carregados, todas as entregas com status
  /// EM_REVISAO — equivalente ao antigo loop triplo do mock, só que sobre a
  /// API real (sem precisar de um endpoint global novo).
  Future<List<Map<String, dynamic>>> entregasPendentes() async {
    final List<Map<String, dynamic>> pendentes = [];
    for (final projetoResumo in projetos) {
      final projeto = await buscarProjeto(projetoResumo.id);
      for (final missao in projeto.missoes) {
        if (missao.status != MissaoStatus.emRevisao) continue;
        final entregas = await listarEntregasDaMissao(missao.id);
        for (final entrega in entregas) {
          if (entrega.status == 'EM_REVISAO') {
            pendentes.add({'projeto': projeto, 'missao': missao, 'entrega': entrega});
          }
        }
      }
    }
    return pendentes;
  }
}
