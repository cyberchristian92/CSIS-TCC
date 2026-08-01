class ComentarioMissao {
  final String id;
  final String missaoId;
  final String autorId;
  final String? autorNome;
  final String texto;
  final DateTime criadoEm;

  ComentarioMissao({
    required this.id,
    required this.missaoId,
    required this.autorId,
    this.autorNome,
    required this.texto,
    required this.criadoEm,
  });

  factory ComentarioMissao.fromJson(Map<String, dynamic> json) => ComentarioMissao(
        id: json['id'] as String,
        missaoId: json['missao_id'] as String,
        autorId: json['autor_id'] as String,
        autorNome: json['autor'] is Map ? (json['autor']['nome'] as String?) : null,
        texto: json['texto'] as String,
        criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ?? DateTime.now(),
      );
}

class ChecklistItem {
  final String id;
  final String missaoId;
  final String texto;
  final bool concluido;
  final int ordem;

  ChecklistItem({
    required this.id,
    required this.missaoId,
    required this.texto,
    required this.concluido,
    required this.ordem,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        missaoId: json['missao_id'] as String,
        texto: json['texto'] as String,
        concluido: json['concluido'] as bool? ?? false,
        ordem: json['ordem'] as int? ?? 0,
      );
}

class Pasta {
  final String id;
  final String projetoId;
  final String? missaoId;
  final String? pastaPaiId;
  final String nome;
  final DateTime criadoEm;

  Pasta({
    required this.id,
    required this.projetoId,
    this.missaoId,
    this.pastaPaiId,
    required this.nome,
    required this.criadoEm,
  });

  factory Pasta.fromJson(Map<String, dynamic> json) => Pasta(
        id: json['id'] as String,
        projetoId: json['projeto_id'] as String,
        missaoId: json['missao_id'] as String?,
        pastaPaiId: json['pasta_pai_id'] as String?,
        nome: json['nome'] as String,
        criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ?? DateTime.now(),
      );
}

class Entrega {
  final String id;
  final String missaoId;
  final String autorId;
  final String? autorNome;
  final String? conteudo;
  final String status; // EM_REVISAO, APROVADA, REJEITADA
  final DateTime criadoEm;

  Entrega({
    required this.id,
    required this.missaoId,
    required this.autorId,
    this.autorNome,
    this.conteudo,
    required this.status,
    required this.criadoEm,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) => Entrega(
        id: json['id'] as String,
        missaoId: json['missao_id'] as String,
        autorId: json['autor_id'] as String,
        autorNome: json['autor'] is Map ? (json['autor']['nome'] as String?) : null,
        conteudo: json['conteudo'] as String?,
        status: json['status'] as String,
        criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ?? DateTime.now(),
      );
}

class Revisao {
  final String id;
  final String entregaId;
  final String revisorId;
  final String status; // APROVADO, REJEITADO
  final String? comentario;
  final DateTime criadoEm;

  Revisao({
    required this.id,
    required this.entregaId,
    required this.revisorId,
    required this.status,
    this.comentario,
    required this.criadoEm,
  });

  factory Revisao.fromJson(Map<String, dynamic> json) => Revisao(
        id: json['id'] as String,
        entregaId: json['entrega_id'] as String,
        revisorId: json['revisor_id'] as String,
        status: json['status'] as String,
        comentario: json['comentario'] as String?,
        criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ?? DateTime.now(),
      );
}

class Arquivo {
  final String id;
  final String projetoId;
  final String? missaoId;
  final String nome;
  final String hashSha256;
  final int tamanho;
  final String tipoMime;
  final String enviadoPor;
  final DateTime enviadoEm;
  final String? entregaId;

  Arquivo({
    required this.id,
    required this.projetoId,
    this.missaoId,
    required this.nome,
    required this.hashSha256,
    required this.tamanho,
    required this.tipoMime,
    required this.enviadoPor,
    required this.enviadoEm,
    this.entregaId,
  });

  factory Arquivo.fromJson(Map<String, dynamic> json) => Arquivo(
        id: json['id'] as String,
        projetoId: json['projeto_id'] as String,
        missaoId: json['missao_id'] as String?,
        nome: json['nome'] as String,
        hashSha256: json['hash_sha256'] as String,
        tamanho: json['tamanho'] as int,
        tipoMime: json['tipo_mime'] as String,
        enviadoPor: json['enviado_por'] as String,
        enviadoEm: DateTime.tryParse(json['enviado_em'] as String? ?? '') ?? DateTime.now(),
        entregaId: json['entrega_id'] as String?,
      );
}

class Documento {
  final String id;
  final String projetoId;
  final String? missaoId;
  final String autorId;
  final String conteudo;
  final List<String> tags;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  Documento({
    required this.id,
    required this.projetoId,
    this.missaoId,
    required this.autorId,
    required this.conteudo,
    this.tags = const [],
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory Documento.fromJson(Map<String, dynamic> json) => Documento(
        id: json['id'] as String,
        projetoId: json['projeto_id'] as String,
        missaoId: json['missao_id'] as String?,
        autorId: json['autor_id'] as String,
        conteudo: json['conteudo'] as String? ?? '',
        tags: json['tags'] is List ? List<String>.from(json['tags'] as List) : const [],
        criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ?? DateTime.now(),
        atualizadoEm: DateTime.tryParse(json['atualizado_em'] as String? ?? '') ?? DateTime.now(),
      );
}

class LogAuditoria {
  final String id;
  final String? userId;
  final String? userNome;
  final String acao;
  final String entidade;
  final String entidadeId;
  final DateTime timestamp;

  LogAuditoria({
    required this.id,
    this.userId,
    this.userNome,
    required this.acao,
    required this.entidade,
    required this.entidadeId,
    required this.timestamp,
  });

  factory LogAuditoria.fromJson(Map<String, dynamic> json) => LogAuditoria(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        userNome: json['user'] is Map ? (json['user']['nome'] as String?) : null,
        acao: json['acao'] as String,
        entidade: json['entidade'] as String,
        entidadeId: json['entidade_id'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}
