class User {
  final String id;
  final String nome;
  final String email;
  final String papelGlobal;
  final DateTime? criadoEm;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.papelGlobal,
    this.criadoEm,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        papelGlobal: json['papel_global'] as String,
        criadoEm: json['criado_em'] != null ? DateTime.tryParse(json['criado_em'] as String) : null,
      );

  bool get isAdmin => papelGlobal == 'ADMIN';
  bool get isLider => papelGlobal == 'LIDER';
  bool get isRevisor => papelGlobal == 'REVISOR';
  bool get isColaborador => papelGlobal == 'COLABORADOR';

  /// Iniciais para avatar (ex: "Ana Coordenadora" -> "AC")
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}
