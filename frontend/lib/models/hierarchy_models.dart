enum MissaoStatus { pendente, emAndamento, emRevisao, aprovada, rejeitada }

MissaoStatus missaoStatusFromString(String value) {
  switch (value) {
    case 'EM_ANDAMENTO':
      return MissaoStatus.emAndamento;
    case 'EM_REVISAO':
      return MissaoStatus.emRevisao;
    case 'APROVADA':
      return MissaoStatus.aprovada;
    case 'REJEITADA':
      return MissaoStatus.rejeitada;
    case 'PENDENTE':
    default:
      return MissaoStatus.pendente;
  }
}

String missaoStatusToApi(MissaoStatus status) {
  switch (status) {
    case MissaoStatus.pendente:
      return 'PENDENTE';
    case MissaoStatus.emAndamento:
      return 'EM_ANDAMENTO';
    case MissaoStatus.emRevisao:
      return 'EM_REVISAO';
    case MissaoStatus.aprovada:
      return 'APROVADA';
    case MissaoStatus.rejeitada:
      return 'REJEITADA';
  }
}

String missaoStatusLabel(MissaoStatus status) {
  switch (status) {
    case MissaoStatus.pendente:
      return 'Pendente';
    case MissaoStatus.emAndamento:
      return 'Em Andamento';
    case MissaoStatus.emRevisao:
      return 'Em Revisão';
    case MissaoStatus.aprovada:
      return 'Aprovada';
    case MissaoStatus.rejeitada:
      return 'Rejeitada';
  }
}

class Workspace {
  final String id;
  final String nome;
  final String? descricao;

  Workspace({required this.id, required this.nome, this.descricao});

  factory Workspace.fromJson(Map<String, dynamic> json) => Workspace(
        id: json['id'] as String,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
      );
}

class AreaApi {
  final String id;
  final String nome;
  final String tipo;
  final String workspaceId;

  AreaApi({required this.id, required this.nome, required this.tipo, required this.workspaceId});

  factory AreaApi.fromJson(Map<String, dynamic> json) => AreaApi(
        id: json['id'] as String,
        nome: json['nome'] as String,
        tipo: json['tipo'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
      );
}

class Missao {
  final String id;
  final String projetoId;
  final String? projetoNome;
  final String titulo;
  final String? descricao;
  final String? responsavelId;
  final String? responsavelNome;
  final MissaoStatus status;
  final DateTime? prazo;
  final String? criterioAceite;
  final double? valorBounty;
  final List<String> tags;

  Missao({
    required this.id,
    required this.projetoId,
    this.projetoNome,
    required this.titulo,
    this.descricao,
    this.responsavelId,
    this.responsavelNome,
    required this.status,
    this.prazo,
    this.criterioAceite,
    this.valorBounty,
    this.tags = const [],
  });

  factory Missao.fromJson(Map<String, dynamic> json) => Missao(
        id: json['id'] as String,
        projetoId: json['projeto_id'] as String,
        projetoNome: json['projeto'] is Map ? (json['projeto']['nome'] as String?) : null,
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String?,
        responsavelId: json['responsavel_id'] as String?,
        responsavelNome: json['responsavel'] is Map ? (json['responsavel']['nome'] as String?) : null,
        status: missaoStatusFromString(json['status'] as String),
        prazo: json['prazo'] != null ? DateTime.tryParse(json['prazo'] as String) : null,
        criterioAceite: json['criterio_aceite'] as String?,
        valorBounty: (json['valor_bounty'] as num?)?.toDouble(),
        tags: json['tags'] is List ? List<String>.from(json['tags'] as List) : const [],
      );
}

class Projeto {
  final String id;
  final String areaId;
  final String nome;
  final String? descricao;
  final String status;
  final DateTime? prazo;
  final List<Missao> missoes;

  Projeto({
    required this.id,
    required this.areaId,
    required this.nome,
    this.descricao,
    required this.status,
    this.prazo,
    this.missoes = const [],
  });

  factory Projeto.fromJson(Map<String, dynamic> json) => Projeto(
        id: json['id'] as String,
        areaId: json['area_id'] as String,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
        status: json['status'] as String? ?? 'ATIVO',
        prazo: json['prazo'] != null ? DateTime.tryParse(json['prazo'] as String) : null,
        missoes: json['missoes'] is List
            ? (json['missoes'] as List).map((m) => Missao.fromJson(m as Map<String, dynamic>)).toList()
            : const [],
      );
}
