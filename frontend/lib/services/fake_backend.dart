import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'package:frontend/services/api_client.dart';

/// "Backend" inteiro do modo demonstração, vivendo só na memória da aba.
///
/// Implementa, com dados fictícios, o mesmo contrato de rotas que o NestJS
/// real expõe (mesmos paths, mesmas chaves de JSON) — assim nenhuma tela ou
/// provider precisa saber que está falando com isto em vez do `ApiClient`
/// real. Cada aba nova recomeça do zero (sem `localStorage`/IndexedDB) por
/// design: é só uma vitrine para navegar antes de existir um backend público.
class FakeBackend {
  FakeBackend._();
  static final FakeBackend instance = FakeBackend._();

  final List<Map<String, dynamic>> _usuarios = [];
  final Map<String, String> _senhas = {};
  final List<Map<String, dynamic>> _workspaces = [];
  final List<Map<String, dynamic>> _areas = [];
  final List<Map<String, dynamic>> _projetos = [];
  final List<Map<String, dynamic>> _missoes = [];
  final List<Map<String, dynamic>> _comentarios = [];
  final List<Map<String, dynamic>> _checklist = [];
  final List<Map<String, dynamic>> _entregas = [];
  final List<Map<String, dynamic>> _revisoes = [];
  final List<Map<String, dynamic>> _arquivos = [];
  final Map<String, List<int>> _arquivoBytes = {};
  final List<Map<String, dynamic>> _documentos = [];
  final List<Map<String, dynamic>> _pastas = [];
  final List<Map<String, dynamic>> _auditoria = [];

  String? _sessaoUserId;
  bool _seeded = false;
  int _seq = 0;

  String _novoId(String prefixo) => '$prefixo-${(_seq++).toString().padLeft(4, '0')}';

  Map<String, dynamic>? _porId(List<Map<String, dynamic>> lista, String id) {
    for (final item in lista) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  Map<String, dynamic> _exigir(List<Map<String, dynamic>> lista, String id, String rotulo) {
    final item = _porId(lista, id);
    if (item == null) throw ApiException(404, '$rotulo não encontrado(a).');
    return item;
  }

  void _log(String? atorId, String acao, String entidade, String entidadeId, {DateTime? quando}) {
    _auditoria.add({
      'id': _novoId('log'),
      'user_id': atorId,
      'acao': acao,
      'entidade': entidade,
      'entidade_id': entidadeId,
      'timestamp': (quando ?? DateTime.now()).toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------
  // Serialização (anexa os objetos aninhados que os `fromJson` esperam)
  // ---------------------------------------------------------------------

  Map<String, dynamic> _serializarUsuario(Map<String, dynamic> u) => {...u};

  Map<String, dynamic> _serializarMissao(Map<String, dynamic> m) {
    final projeto = _porId(_projetos, m['projeto_id'] as String);
    final responsavel = m['responsavel_id'] != null ? _porId(_usuarios, m['responsavel_id'] as String) : null;
    return {
      ...m,
      if (projeto != null) 'projeto': {'nome': projeto['nome']},
      if (responsavel != null) 'responsavel': {'nome': responsavel['nome']},
    };
  }

  Map<String, dynamic> _serializarProjeto(Map<String, dynamic> p) {
    final missoesDoProjeto = _missoes.where((m) => m['projeto_id'] == p['id']).map(_serializarMissao).toList();
    return {...p, 'missoes': missoesDoProjeto};
  }

  Map<String, dynamic> _serializarComentario(Map<String, dynamic> c) {
    final autor = _porId(_usuarios, c['autor_id'] as String);
    return {...c, if (autor != null) 'autor': {'nome': autor['nome']}};
  }

  Map<String, dynamic> _serializarEntrega(Map<String, dynamic> e) {
    final autor = _porId(_usuarios, e['autor_id'] as String);
    return {...e, if (autor != null) 'autor': {'nome': autor['nome']}};
  }

  Map<String, dynamic> _serializarLog(Map<String, dynamic> l) {
    final user = l['user_id'] != null ? _porId(_usuarios, l['user_id'] as String) : null;
    return {...l, if (user != null) 'user': {'nome': user['nome']}};
  }

  // ---------------------------------------------------------------------
  // Roteador
  // ---------------------------------------------------------------------

  Future<dynamic> handle(String method, String pathComQuery, {Map<String, dynamic>? body}) async {
    _seedSeNecessario();
    await Future.delayed(const Duration(milliseconds: 180));

    final uri = Uri.parse(pathComQuery);
    final segs = uri.pathSegments;
    final q = uri.queryParameters;
    final b = body ?? const {};

    Map<String, String>? m(List<String> padrao) {
      if (segs.length != padrao.length) return null;
      final params = <String, String>{};
      for (var i = 0; i < padrao.length; i++) {
        if (padrao[i].startsWith(':')) {
          params[padrao[i].substring(1)] = segs[i];
        } else if (padrao[i] != segs[i]) {
          return null;
        }
      }
      return params;
    }

    // `id` guarda o parâmetro de rota capturado pela última chamada de
    // `matches()` que bateu — usar uma variável de fechamento fixa em vez de
    // reatribuir `p` evita que o analisador perca a promoção non-null
    // dentro das closures (`.where(...)`) mais abaixo.
    String? id;
    bool matches(List<String> padrao) {
      final p = m(padrao);
      if (p == null) return false;
      id = p['id'];
      return true;
    }

    if (method == 'GET') {
      if (matches(['auth', 'me'])) return _authMe();
      if (matches(['auth', 'usuarios'])) return _usuarios.map(_serializarUsuario).toList();
      if (matches(['workspaces'])) return _workspaces.map((w) => {...w}).toList();
      if (matches(['workspaces', ':id', 'areas'])) return _areas.where((a) => a['workspace_id'] == id).map((a) => {...a}).toList();
      if (matches(['areas', ':id', 'projetos'])) return _projetos.where((pr) => pr['area_id'] == id).map(_serializarProjeto).toList();
      if (matches(['missoes', 'minhas'])) {
        return _missoes.where((mi) => mi['responsavel_id'] == _sessaoUserId).map(_serializarMissao).toList();
      }
      if (matches(['projetos', ':id'])) return _serializarProjeto(_exigir(_projetos, id!, 'Projeto'));
      if (matches(['missoes', ':id'])) return _serializarMissao(_exigir(_missoes, id!, 'Missão'));
      if (matches(['missoes', ':id', 'comentarios'])) return _comentarios.where((c) => c['missao_id'] == id).map(_serializarComentario).toList();
      if (matches(['missoes', ':id', 'checklist'])) {
        final itens = _checklist.where((c) => c['missao_id'] == id).toList()..sort((a, b) => (a['ordem'] as int).compareTo(b['ordem'] as int));
        return itens.map((c) => {...c}).toList();
      }
      if (matches(['missoes', ':id', 'entregas'])) return _entregas.where((e) => e['missao_id'] == id).map(_serializarEntrega).toList();
      if (matches(['entregas', ':id', 'revisoes'])) return _revisoes.where((r) => r['entrega_id'] == id).map((r) => {...r}).toList();
      if (matches(['projetos', ':id', 'arquivos'])) {
        var lista = _arquivos.where((a) => a['projeto_id'] == id);
        if (q['missaoId'] != null) lista = lista.where((a) => a['missao_id'] == q['missaoId']);
        if (q['pastaId'] != null) {
          final alvo = q['pastaId'] == 'raiz' ? null : q['pastaId'];
          lista = lista.where((a) => a['pasta_id'] == alvo);
        }
        return lista.map((a) => {...a}).toList();
      }
      if (matches(['arquivos', ':id', 'verificar'])) {
        _exigir(_arquivos, id!, 'Arquivo');
        return {'integro': true};
      }
      if (matches(['projetos', ':id', 'documentos'])) {
        var lista = _documentos.where((d) => d['projeto_id'] == id);
        if (q['missaoId'] != null) lista = lista.where((d) => d['missao_id'] == q['missaoId']);
        if (q['pastaId'] != null) {
          final alvo = q['pastaId'] == 'raiz' ? null : q['pastaId'];
          lista = lista.where((d) => d['pasta_id'] == alvo);
        }
        return lista.map((d) => {...d}).toList();
      }
      if (matches(['documentos', ':id'])) return {..._exigir(_documentos, id!, 'Documento')};
      if (matches(['projetos', ':id', 'pastas'])) {
        final pai = q['pastaPaiId'];
        return _pastas.where((f) => f['projeto_id'] == id && f['pasta_pai_id'] == pai).map((f) => {...f}).toList();
      }
      if (matches(['auditoria'])) {
        final itens = List.of(_auditoria)..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
        return {'items': itens.map(_serializarLog).toList()};
      }
    }

    if (method == 'POST') {
      if (matches(['auth', 'login'])) return _login(b['email'] as String, b['senha'] as String);
      if (matches(['auth', 'logout'])) {
        _sessaoUserId = null;
        return null;
      }
      if (matches(['auth', 'esqueci-senha'])) return null;
      if (matches(['auth', 'redefinir-senha'])) return null;
      if (matches(['auth', 'register'])) return _criarUsuario(b['nome'] as String, b['email'] as String, b['senha'] as String, b['papelGlobal'] as String);
      if (matches(['workspaces'])) return _criarWorkspace(b['nome'] as String);
      if (matches(['workspaces', ':id', 'areas'])) return _criarArea(id!, b['nome'] as String, b['tipo'] as String);
      if (matches(['areas', ':id', 'projetos'])) return _criarProjeto(id!, b['nome'] as String, b['descricao'] as String?);
      if (matches(['projetos', ':id', 'missoes'])) return _criarMissao(id!, b['titulo'] as String, b['descricao'] as String?, b['criterio_aceite'] as String?);
      if (matches(['missoes', ':id', 'comentarios'])) return _criarComentario(id!, b['texto'] as String);
      if (matches(['missoes', ':id', 'checklist'])) return _criarItemChecklist(id!, b['texto'] as String);
      if (matches(['missoes', ':id', 'entregas'])) return _criarEntrega(id!, b['conteudo'] as String?);
      if (matches(['entregas', ':id', 'revisoes'])) return _criarRevisao(id!, b['status'] as String, b['comentario'] as String?);
      if (matches(['projetos', ':id', 'documentos'])) return _criarDocumento(id!, b['conteudo'] as String, b['missaoId'] as String?, b['pastaId'] as String?, b['tags'] as List<dynamic>?);
      if (matches(['projetos', ':id', 'pastas'])) return _criarPasta(id!, b['nome'] as String, b['pastaPaiId'] as String?, b['missaoId'] as String?);
    }

    if (method == 'PATCH') {
      if (matches(['areas', ':id'])) return _atualizarArea(id!, b['nome'] as String?, b['tipo'] as String?);
      if (matches(['projetos', ':id'])) return _atualizarProjeto(id!, b['status'] as String?);
      if (matches(['missoes', ':id', 'atribuir'])) return _atribuirMissao(id!, b['responsavelId'] as String);
      if (matches(['missoes', ':id', 'iniciar'])) return _iniciarMissao(id!);
      if (matches(['missoes', ':id', 'tags'])) return _atualizarTagsMissao(id!, List<String>.from(b['tags'] as List));
      if (matches(['checklist', ':id'])) return _alternarChecklist(id!, b['concluido'] as bool);
      if (matches(['documentos', ':id'])) return _atualizarDocumento(id!, b['conteudo'] as String, b['tags'] as List<dynamic>?, b['pastaId'] as String?);
      if (matches(['pastas', ':id'])) return _renomearPasta(id!, b['nome'] as String);
      if (matches(['arquivos', ':id'])) return _renomearArquivo(id!, b['nome'] as String);
      if (matches(['auth', 'usuarios', ':id', 'papel'])) return _atualizarPapelUsuario(id!, b['papelGlobal'] as String);
    }

    if (method == 'DELETE') {
      if (matches(['areas', ':id'])) {
        _areas.removeWhere((a) => a['id'] == id);
        return null;
      }
      if (matches(['comentarios', ':id'])) {
        _comentarios.removeWhere((c) => c['id'] == id);
        return null;
      }
      if (matches(['checklist', ':id'])) {
        _checklist.removeWhere((c) => c['id'] == id);
        return null;
      }
      if (matches(['pastas', ':id'])) return _removerPasta(id!);
    }

    throw ApiException(404, 'Rota demo não implementada: $method $pathComQuery');
  }

  Future<List<int>> handleBytes(String pathComQuery) async {
    _seedSeNecessario();
    await Future.delayed(const Duration(milliseconds: 250));
    final uri = Uri.parse(pathComQuery);
    final projetoId = uri.pathSegments[1];
    return _exportarProjeto(projetoId);
  }

  Future<Map<String, dynamic>> handleUpload(String pathComQuery, {required List<int> bytes, required String nomeArquivo}) async {
    _seedSeNecessario();
    await Future.delayed(const Duration(milliseconds: 300));
    final uri = Uri.parse(pathComQuery);
    final projetoId = uri.pathSegments[1];
    return _uploadArquivo(projetoId, bytes, nomeArquivo, uri.queryParameters['entregaId'], uri.queryParameters['missaoId'], uri.queryParameters['pastaId']);
  }

  // ---------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------

  Map<String, dynamic> _authMe() {
    if (_sessaoUserId == null) throw ApiException(401, 'Não autenticado.');
    return _serializarUsuario(_exigir(_usuarios, _sessaoUserId!, 'Usuário'));
  }

  Map<String, dynamic> _login(String email, String senha) {
    final usuario = _usuarios.where((u) => u['email'] == email).toList();
    if (usuario.isEmpty || _senhas[email] != senha) {
      throw ApiException(401, 'Credenciais inválidas.');
    }
    _sessaoUserId = usuario.first['id'] as String;
    return _serializarUsuario(usuario.first);
  }

  Map<String, dynamic> _criarUsuario(String nome, String email, String senha, String papelGlobal) {
    final id = _novoId('user');
    final row = {'id': id, 'nome': nome, 'email': email, 'papel_global': papelGlobal, 'criado_em': DateTime.now().toIso8601String()};
    _usuarios.add(row);
    _senhas[email] = senha;
    _log(_sessaoUserId, 'CRIOU', 'USUARIO', id);
    return _serializarUsuario(row);
  }

  Map<String, dynamic> _atualizarPapelUsuario(String userId, String papelGlobal) {
    final usuario = _exigir(_usuarios, userId, 'Usuário');
    usuario['papel_global'] = papelGlobal;
    _log(_sessaoUserId, 'ATUALIZOU_PAPEL', 'USUARIO', userId);
    return _serializarUsuario(usuario);
  }

  Map<String, dynamic> _criarWorkspace(String nome) {
    final id = _novoId('ws');
    final row = {'id': id, 'nome': nome, 'descricao': null};
    _workspaces.add(row);
    return {...row};
  }

  Map<String, dynamic> _criarArea(String workspaceId, String nome, String tipo, {DateTime? quando, String? atorId}) {
    final id = _novoId('area');
    final row = {'id': id, 'nome': nome, 'tipo': tipo, 'workspace_id': workspaceId};
    _areas.add(row);
    _log(atorId ?? _sessaoUserId, 'CRIOU', 'AREA', id, quando: quando);
    return {...row};
  }

  Map<String, dynamic> _atualizarArea(String id, String? nome, String? tipo) {
    final area = _exigir(_areas, id, 'Área');
    if (nome != null) area['nome'] = nome;
    if (tipo != null) area['tipo'] = tipo;
    _log(_sessaoUserId, 'ATUALIZOU', 'AREA', id);
    return {...area};
  }

  Map<String, dynamic> _criarProjeto(String areaId, String nome, String? descricao, {String status = 'ATIVO', DateTime? quando, String? atorId}) {
    final id = _novoId('projeto');
    final row = {'id': id, 'area_id': areaId, 'nome': nome, 'descricao': descricao, 'status': status, 'prazo': null};
    _projetos.add(row);
    _log(atorId ?? _sessaoUserId, 'CRIOU', 'PROJETO', id, quando: quando);
    return _serializarProjeto(row);
  }

  Map<String, dynamic> _atualizarProjeto(String id, String? status) {
    final projeto = _exigir(_projetos, id, 'Projeto');
    if (status != null) projeto['status'] = status;
    _log(_sessaoUserId, 'ATUALIZOU_STATUS', 'PROJETO', id);
    return _serializarProjeto(projeto);
  }

  Map<String, dynamic> _criarMissao(
    String projetoId,
    String titulo,
    String? descricao,
    String? criterioAceite, {
    String status = 'PENDENTE',
    String? responsavelId,
    double? valorBounty,
    List<String> tags = const [],
    DateTime? quando,
    String? atorId,
  }) {
    final id = _novoId('missao');
    final row = {
      'id': id,
      'projeto_id': projetoId,
      'titulo': titulo,
      'descricao': descricao,
      'responsavel_id': responsavelId,
      'status': status,
      'prazo': null,
      'criterio_aceite': criterioAceite,
      'valor_bounty': valorBounty,
      'tags': tags,
    };
    _missoes.add(row);
    _log(atorId ?? _sessaoUserId, 'CRIOU', 'MISSAO', id, quando: quando);
    return _serializarMissao(row);
  }

  Map<String, dynamic> _atribuirMissao(String missaoId, String responsavelId) {
    final missao = _exigir(_missoes, missaoId, 'Missão');
    missao['responsavel_id'] = responsavelId;
    _log(_sessaoUserId, 'ATRIBUIU', 'MISSAO', missaoId);
    return _serializarMissao(missao);
  }

  Map<String, dynamic> _iniciarMissao(String missaoId) {
    final missao = _exigir(_missoes, missaoId, 'Missão');
    missao['status'] = 'EM_ANDAMENTO';
    _log(_sessaoUserId, 'INICIOU', 'MISSAO', missaoId);
    return _serializarMissao(missao);
  }

  Map<String, dynamic> _atualizarTagsMissao(String missaoId, List<String> tags) {
    final missao = _exigir(_missoes, missaoId, 'Missão');
    missao['tags'] = tags;
    return _serializarMissao(missao);
  }

  Map<String, dynamic> _criarComentario(String missaoId, String texto, {String? autorId, DateTime? quando}) {
    _exigir(_missoes, missaoId, 'Missão');
    final id = _novoId('coment');
    final row = {'id': id, 'missao_id': missaoId, 'autor_id': autorId ?? _sessaoUserId, 'texto': texto, 'criado_em': (quando ?? DateTime.now()).toIso8601String()};
    _comentarios.add(row);
    _log(autorId ?? _sessaoUserId, 'COMENTOU', 'MISSAO', missaoId, quando: quando);
    return _serializarComentario(row);
  }

  Map<String, dynamic> _criarItemChecklist(String missaoId, String texto, {bool concluido = false}) {
    final ordem = _checklist.where((c) => c['missao_id'] == missaoId).length;
    final id = _novoId('check');
    final row = {'id': id, 'missao_id': missaoId, 'texto': texto, 'concluido': concluido, 'ordem': ordem};
    _checklist.add(row);
    return {...row};
  }

  Map<String, dynamic> _alternarChecklist(String itemId, bool concluido) {
    final item = _exigir(_checklist, itemId, 'Item de checklist');
    item['concluido'] = concluido;
    return {...item};
  }

  Map<String, dynamic> _criarEntrega(String missaoId, String? conteudo, {String? autorId, DateTime? quando, String status = 'EM_REVISAO'}) {
    final missao = _exigir(_missoes, missaoId, 'Missão');
    final id = _novoId('entrega');
    final row = {'id': id, 'missao_id': missaoId, 'autor_id': autorId ?? _sessaoUserId, 'conteudo': conteudo, 'status': status, 'criado_em': (quando ?? DateTime.now()).toIso8601String()};
    _entregas.add(row);
    if (status == 'EM_REVISAO') missao['status'] = 'EM_REVISAO';
    _log(autorId ?? _sessaoUserId, 'ENTREGOU', 'MISSAO', missaoId, quando: quando);
    return _serializarEntrega(row);
  }

  Map<String, dynamic> _criarRevisao(String entregaId, String status, String? comentario, {String? revisorId, DateTime? quando}) {
    final entrega = _exigir(_entregas, entregaId, 'Entrega');
    final revisor = revisorId ?? _sessaoUserId;
    if (revisor != null && revisor == entrega['autor_id']) {
      throw ApiException(403, 'Você não pode revisar a própria entrega — regra de segregação de funções.');
    }
    final id = _novoId('revisao');
    final row = {'id': id, 'entrega_id': entregaId, 'revisor_id': revisor, 'status': status, 'comentario': comentario, 'criado_em': (quando ?? DateTime.now()).toIso8601String()};
    _revisoes.add(row);
    final statusEntrega = status == 'APROVADO' ? 'APROVADA' : 'REJEITADA';
    entrega['status'] = statusEntrega;
    final missao = _porId(_missoes, entrega['missao_id'] as String);
    if (missao != null) missao['status'] = statusEntrega;
    _log(revisor, status == 'APROVADO' ? 'APROVOU' : 'REJEITOU', 'ENTREGA', entregaId, quando: quando);
    return {...row};
  }

  String _adivinharMime(String nome) {
    final ext = nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
    const mapa = {
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'json': 'application/json',
      'zip': 'application/zip',
      'e01': 'application/x-ewf',
      'csv': 'text/csv',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return mapa[ext] ?? 'application/octet-stream';
  }

  Map<String, dynamic> _uploadArquivo(
    String projetoId,
    List<int> bytes,
    String nomeArquivo,
    String? entregaId,
    String? missaoId,
    String? pastaIdRaw, {
    String? enviadoPor,
    DateTime? quando,
  }) {
    _exigir(_projetos, projetoId, 'Projeto');
    final pastaId = (pastaIdRaw == null || pastaIdRaw == 'raiz') ? null : pastaIdRaw;
    final id = _novoId('arquivo');
    final hash = sha256.convert(bytes).toString();
    final row = {
      'id': id,
      'projeto_id': projetoId,
      'missao_id': missaoId,
      'pasta_id': pastaId,
      'nome': nomeArquivo,
      'hash_sha256': hash,
      'tamanho': bytes.length,
      'tipo_mime': _adivinharMime(nomeArquivo),
      'enviado_por': enviadoPor ?? _sessaoUserId,
      'enviado_em': (quando ?? DateTime.now()).toIso8601String(),
      'entrega_id': entregaId,
    };
    _arquivos.add(row);
    _arquivoBytes[id] = bytes;
    _log(enviadoPor ?? _sessaoUserId, 'ENVIOU_ARQUIVO', 'ARQUIVO', id, quando: quando);
    return {...row};
  }

  Map<String, dynamic> _renomearArquivo(String id, String nome) {
    final arquivo = _exigir(_arquivos, id, 'Arquivo');
    arquivo['nome'] = nome;
    _log(_sessaoUserId, 'RENOMEAR', 'ARQUIVO', id);
    return {...arquivo};
  }

  Map<String, dynamic> _criarDocumento(
    String projetoId,
    String conteudo,
    String? missaoId,
    String? pastaIdRaw,
    List<dynamic>? tags, {
    String? autorId,
    DateTime? quando,
  }) {
    _exigir(_projetos, projetoId, 'Projeto');
    final pastaId = (pastaIdRaw == null || pastaIdRaw == 'raiz') ? null : pastaIdRaw;
    final id = _novoId('doc');
    final agora = (quando ?? DateTime.now()).toIso8601String();
    final row = {
      'id': id,
      'projeto_id': projetoId,
      'missao_id': missaoId,
      'pasta_id': pastaId,
      'autor_id': autorId ?? _sessaoUserId,
      'conteudo': conteudo,
      'tags': tags?.map((t) => t.toString()).toList() ?? <String>[],
      'criado_em': agora,
      'atualizado_em': agora,
    };
    _documentos.add(row);
    _log(autorId ?? _sessaoUserId, 'CRIOU', 'DOCUMENTO', id, quando: quando);
    return {...row};
  }

  Map<String, dynamic> _atualizarDocumento(String id, String conteudo, List<dynamic>? tags, String? pastaIdRaw) {
    final documento = _exigir(_documentos, id, 'Documento');
    documento['conteudo'] = conteudo;
    if (tags != null) documento['tags'] = tags.map((t) => t.toString()).toList();
    if (pastaIdRaw != null) documento['pasta_id'] = pastaIdRaw == 'raiz' ? null : pastaIdRaw;
    documento['atualizado_em'] = DateTime.now().toIso8601String();
    _log(_sessaoUserId, 'ATUALIZOU', 'DOCUMENTO', id);
    return {...documento};
  }

  Map<String, dynamic> _criarPasta(String projetoId, String nome, String? pastaPaiId, String? missaoId, {DateTime? quando}) {
    _exigir(_projetos, projetoId, 'Projeto');
    final id = _novoId('pasta');
    final row = {'id': id, 'projeto_id': projetoId, 'missao_id': missaoId, 'pasta_pai_id': pastaPaiId, 'nome': nome, 'criado_em': (quando ?? DateTime.now()).toIso8601String()};
    _pastas.add(row);
    return {...row};
  }

  Map<String, dynamic> _renomearPasta(String id, String nome) {
    final pasta = _exigir(_pastas, id, 'Pasta');
    pasta['nome'] = nome;
    return {...pasta};
  }

  Object? _removerPasta(String id) {
    final pasta = _exigir(_pastas, id, 'Pasta');
    final paiId = pasta['pasta_pai_id'];
    // Filhos (subpastas, arquivos e documentos) sobem um nível — nada é apagado.
    for (final sub in _pastas.where((p) => p['pasta_pai_id'] == id)) {
      sub['pasta_pai_id'] = paiId;
    }
    for (final a in _arquivos.where((a) => a['pasta_id'] == id)) {
      a['pasta_id'] = paiId;
    }
    for (final d in _documentos.where((d) => d['pasta_id'] == id)) {
      d['pasta_id'] = paiId;
    }
    _pastas.removeWhere((p) => p['id'] == id);
    return null;
  }

  List<int> _exportarProjeto(String projetoId) {
    final projeto = _exigir(_projetos, projetoId, 'Projeto');
    final missoesDoProjeto = _missoes.where((m) => m['projeto_id'] == projetoId).toList();
    final arquivosDoProjeto = _arquivos.where((a) => a['projeto_id'] == projetoId).toList();
    final usuarioAtual = _sessaoUserId != null ? _porId(_usuarios, _sessaoUserId!) : null;
    final exportadoPor = usuarioAtual == null ? null : usuarioAtual['nome'];

    final manifesto = {
      'projeto': {...projeto},
      'missoes': missoesDoProjeto,
      'arquivos': arquivosDoProjeto.map((a) => {...a}).toList(),
      'exportado_em': DateTime.now().toIso8601String(),
      'exportado_por': exportadoPor,
      'observacao': 'Pacote gerado pelo modo demonstração da Plataforma CSIS — dados fictícios, sem persistência.',
    };

    final relatorio = StringBuffer()
      ..writeln('# Relatório de Custódia — ${projeto['nome']}')
      ..writeln()
      ..writeln('Exportado em ${DateTime.now().toString().split('.').first} por ${exportadoPor ?? 'usuário demo'}.')
      ..writeln()
      ..writeln('## Missões (${missoesDoProjeto.length})')
      ..writeln();
    for (final missao in missoesDoProjeto) {
      relatorio.writeln('- **${missao['titulo']}** — ${missao['status']}');
    }
    relatorio
      ..writeln()
      ..writeln('## Arquivos (${arquivosDoProjeto.length})')
      ..writeln();
    for (final arquivo in arquivosDoProjeto) {
      relatorio.writeln('- ${arquivo['nome']} — SHA-256 `${arquivo['hash_sha256']}` (${arquivo['tamanho']} bytes)');
    }

    final archive = Archive()
      ..addFile(ArchiveFile.string('manifesto.json', const JsonEncoder.withIndent('  ').convert(manifesto)))
      ..addFile(ArchiveFile.string('relatorio.md', relatorio.toString()));
    for (final arquivo in arquivosDoProjeto) {
      final bytes = _arquivoBytes[arquivo['id']] ?? utf8.encode('(conteúdo simulado — modo demonstração)');
      archive.addFile(ArchiveFile.bytes('arquivos/${arquivo['nome']}', Uint8List.fromList(bytes)));
    }

    return ZipEncoder().encode(archive);
  }

  // ---------------------------------------------------------------------
  // Dados de exemplo
  // ---------------------------------------------------------------------

  /// Credenciais fixas do botão "Entrar em modo demonstração" no login.
  static const emailDemo = 'demo@csis.com';
  static const senhaDemo = 'demo123';

  void _seedSeNecessario() {
    if (_seeded) return;
    _seeded = true;

    final agora = DateTime.now();
    DateTime diasAtras(int dias, [int horas = 9]) => agora.subtract(Duration(days: dias, hours: agora.hour - horas));

    final admin = {'id': _novoId('user'), 'nome': 'Ana Coordenadora', 'email': emailDemo, 'papel_global': 'ADMIN', 'criado_em': diasAtras(30).toIso8601String()};
    final lider = {'id': _novoId('user'), 'nome': 'Bruno Líder', 'email': 'bruno.lider@csis.com', 'papel_global': 'LIDER', 'criado_em': diasAtras(28).toIso8601String()};
    final revisora = {'id': _novoId('user'), 'nome': 'Carla Revisora', 'email': 'carla.revisora@csis.com', 'papel_global': 'REVISOR', 'criado_em': diasAtras(28).toIso8601String()};
    final diego = {'id': _novoId('user'), 'nome': 'Diego Colaborador', 'email': 'diego@csis.com', 'papel_global': 'COLABORADOR', 'criado_em': diasAtras(25).toIso8601String()};
    final elisa = {'id': _novoId('user'), 'nome': 'Elisa Colaboradora', 'email': 'elisa@csis.com', 'papel_global': 'COLABORADOR', 'criado_em': diasAtras(20).toIso8601String()};
    _usuarios.addAll([admin, lider, revisora, diego, elisa]);
    _senhas[emailDemo] = senhaDemo;
    _senhas['bruno.lider@csis.com'] = 'demo123';
    _senhas['carla.revisora@csis.com'] = 'demo123';
    _senhas['diego@csis.com'] = 'demo123';
    _senhas['elisa@csis.com'] = 'demo123';

    final adminId = admin['id'] as String;
    final diegoId = diego['id'] as String;
    final elisaId = elisa['id'] as String;
    final carlaId = revisora['id'] as String;

    final workspace = {'id': _novoId('ws'), 'nome': 'Workspace CSIS', 'descricao': 'Ambiente de demonstração'};
    _workspaces.add(workspace);
    final workspaceId = workspace['id'] as String;

    final areaPericia = _criarArea(workspaceId, 'Perícia Digital', 'PERICIA', quando: diasAtras(27), atorId: adminId);
    final areaMarketing = _criarArea(workspaceId, 'Marketing & Growth', 'MARKETING', quando: diasAtras(26), atorId: adminId);
    final areaCursos = _criarArea(workspaceId, 'Cursos & Conteúdo', 'CURSOS', quando: diasAtras(24), atorId: adminId);

    // --- Perícia Digital ---------------------------------------------
    final projMeridian = _criarProjeto(areaPericia['id'] as String, 'Laudo Forense — Caso Meridian', 'Perícia em dispositivos apreendidos no caso Meridian.', quando: diasAtras(21), atorId: adminId);
    final projMeridianId = projMeridian['id'] as String;

    final missaoColeta = _criarMissao(projMeridianId, 'Coletar imagem forense do disco', 'Gerar imagem bit-a-bit do HD apreendido, preservando a cadeia de custódia.', 'Imagem E01 gerada com hash conferido.', status: 'APROVADA', responsavelId: diegoId, quando: diasAtras(20), atorId: adminId);
    final missaoColetaId = missaoColeta['id'] as String;
    _criarItemChecklist(missaoColetaId, 'Lacrar mídia original', concluido: true);
    _criarItemChecklist(missaoColetaId, 'Gerar hash SHA-256 da imagem', concluido: true);
    _criarItemChecklist(missaoColetaId, 'Preencher termo de cadeia de custódia', concluido: true);
    _criarComentario(missaoColetaId, 'Imagem gerada com write-blocker, sem alterações no disco original.', autorId: diegoId, quando: diasAtras(19));
    _criarComentario(missaoColetaId, 'Confirmado — hash bate com o termo. Aprovando.', autorId: adminId, quando: diasAtras(18));
    final entregaColeta = _criarEntrega(missaoColetaId, 'Imagem forense em imagem-disco.E01, hash SHA-256 conferido e anexado.', autorId: diegoId, quando: diasAtras(18, 10), status: 'EM_REVISAO');
    _criarRevisao(entregaColeta['id'] as String, 'APROVADO', 'Cadeia de custódia íntegra. Aprovado.', revisorId: adminId, quando: diasAtras(18, 15));
    final pastaEvidencias = _criarPasta(projMeridianId, 'Evidências', null, null, quando: diasAtras(19));
    _uploadArquivo(projMeridianId, utf8.encode('Imagem forense simulada — modo demonstração.'), 'imagem-disco.E01', null, missaoColetaId, pastaEvidencias['id'] as String, enviadoPor: diegoId, quando: diasAtras(18, 9));

    final missaoAnalise = _criarMissao(projMeridianId, 'Analisar artefatos de rede', 'Investigar tráfego de rede e conexões suspeitas nos logs coletados.', 'Relatório de IOCs identificados.', status: 'EM_REVISAO', responsavelId: elisaId, quando: diasAtras(15), atorId: adminId);
    final missaoAnaliseId = missaoAnalise['id'] as String;
    _criarItemChecklist(missaoAnaliseId, 'Extrair logs de firewall', concluido: true);
    _criarItemChecklist(missaoAnaliseId, 'Cruzar IPs com feeds de threat intel', concluido: true);
    _criarItemChecklist(missaoAnaliseId, 'Documentar IOCs no laudo', concluido: false);
    _criarComentario(missaoAnaliseId, 'Encontrei 3 IPs batendo com infraestrutura conhecida de C2.', autorId: elisaId, quando: diasAtras(2));
    _criarEntrega(missaoAnaliseId, 'Relatório preliminar de IOCs anexado — aguardando revisão.', autorId: elisaId, quando: diasAtras(1), status: 'EM_REVISAO');

    _criarMissao(projMeridianId, 'Redigir laudo pericial', 'Consolidar achados técnicos em laudo formal, no padrão CSIS.', null, status: 'EM_ANDAMENTO', responsavelId: diegoId, quando: diasAtras(10), atorId: adminId);
    _criarMissao(projMeridianId, 'Validar cadeia de custódia', 'Conferência final de todos os termos e assinaturas antes da entrega ao cliente.', null, status: 'PENDENTE', quando: diasAtras(9), atorId: adminId);

    final docRelatorio = _criarDocumento(projMeridianId, '# Relatório Técnico Preliminar\n\nAnálise em andamento sobre o Caso Meridian.\n\nOs artefatos coletados indicam movimentação lateral na rede interna. Detalhes da cadeia de custódia estão descritos em [[Cadeia de Custódia]].\n\n## Próximos passos\n\n- Finalizar análise de IOCs\n- Consolidar laudo formal', null, null, ['laudo', 'preliminar'], autorId: diegoId, quando: diasAtras(17));
    _criarDocumento(projMeridianId, '# Cadeia de Custódia\n\n| Item | Responsável | Data |\n| --- | --- | --- |\n| Coleta da imagem | Diego Colaborador | ${diasAtras(18).toString().split(' ').first} |\n| Lacre da mídia | Diego Colaborador | ${diasAtras(18).toString().split(' ').first} |\n\nVeja também [[${_tituloDoc(docRelatorio)}]].', null, null, ['custodia'], autorId: diegoId, quando: diasAtras(17));

    final projIncidente = _criarProjeto(areaPericia['id'] as String, 'Resposta a Incidente — Ransomware XYZ', 'Contenção e investigação de incidente de ransomware em ambiente corporativo.', quando: diasAtras(14), atorId: adminId);
    final projIncidenteId = projIncidente['id'] as String;
    _criarMissao(projIncidenteId, 'Conter propagação lateral', 'Isolar hosts comprometidos e bloquear comunicação C2.', 'Rede segmentada, C2 bloqueado no firewall.', status: 'APROVADA', responsavelId: elisaId, quando: diasAtras(13), atorId: adminId);
    final missaoVetor = _criarMissao(projIncidenteId, 'Identificar vetor inicial', 'Determinar como o ransomware entrou no ambiente.', null, status: 'REJEITADA', responsavelId: diegoId, quando: diasAtras(12), atorId: adminId);
    final entregaVetor = _criarEntrega(missaoVetor['id'] as String, 'Vetor identificado como phishing por e-mail.', autorId: diegoId, quando: diasAtras(6), status: 'EM_REVISAO');
    _criarRevisao(entregaVetor['id'] as String, 'REJEITADO', 'Faltam evidências do e-mail original (cabeçalhos, anexo). Refazer com anexos completos.', revisorId: carlaId, quando: diasAtras(5));
    _criarMissao(projIncidenteId, 'Elaborar relatório executivo', 'Resumo não-técnico do incidente para a diretoria do cliente.', null, status: 'PENDENTE', quando: diasAtras(4), atorId: adminId);

    // --- Marketing & Growth --------------------------------------------
    final projCampanha = _criarProjeto(areaMarketing['id'] as String, 'Campanha de Lançamento CSIS', 'Campanha multicanal de lançamento da plataforma.', quando: diasAtras(11), atorId: adminId);
    _criarMissao(projCampanha['id'] as String, 'Criar carrossel Instagram', 'Peças para o carrossel de lançamento.', null, status: 'EM_ANDAMENTO', responsavelId: elisaId, quando: diasAtras(8), atorId: adminId, tags: ['design', 'social']);
    _criarMissao(projCampanha['id'] as String, 'Escrever roteiro vídeo demo', 'Roteiro do vídeo demonstrativo do produto.', 'Roteiro aprovado pelo time de produto.', status: 'APROVADA', responsavelId: adminId, quando: diasAtras(16), atorId: adminId);

    final projRebranding = _criarProjeto(areaMarketing['id'] as String, 'Rebranding institucional', 'Atualização da identidade visual da CSIS.', status: 'CONCLUIDO', quando: diasAtras(23), atorId: adminId);
    _criarMissao(projRebranding['id'] as String, 'Definir paleta de cores', 'Nova paleta institucional.', 'Paleta aprovada e documentada no brand book.', status: 'APROVADA', responsavelId: elisaId, quando: diasAtras(22), atorId: adminId);

    // --- Cursos & Conteúdo (arquivado) ----------------------------------
    final projCurso = _criarProjeto(areaCursos['id'] as String, 'Curso Introdução à Perícia Digital', 'Curso introdutório gravado para a base de alunos.', status: 'ARQUIVADO', quando: diasAtras(25), atorId: adminId);
    _criarMissao(projCurso['id'] as String, 'Gravar módulo 1', 'Módulo introdutório sobre fundamentos de perícia digital.', null, status: 'APROVADA', responsavelId: adminId, quando: diasAtras(24), atorId: adminId);

    // Alguns eventos de login recentes, pra Auditoria não parecer "morta".
    _log(adminId, 'LOGIN', 'USUARIO', adminId, quando: diasAtras(1, 8));
    _log(lider['id'] as String, 'LOGIN', 'USUARIO', lider['id'] as String, quando: diasAtras(0, 8));
  }

  String _tituloDoc(Map<String, dynamic> doc) {
    final primeiraLinha = (doc['conteudo'] as String).split('\n').first.replaceAll('#', '').trim();
    return primeiraLinha.isEmpty ? 'Documento sem título' : primeiraLinha;
  }
}
