import 'package:flutter/material.dart';

class Submission {
  final String id;
  final String missionId;
  final String authorName;
  final DateTime submittedAt;
  final String content; // Texto da submissão ou link do arquivo
  String status; // 'Pendente', 'Aprovada', 'Ajustes'

  Submission({
    required this.id,
    required this.missionId,
    required this.authorName,
    required this.submittedAt,
    required this.content,
    this.status = 'Pendente',
  });
}

class Mission {
  final String id;
  final String title;
  final String description;
  final String assignee; // Nome de quem vai fazer
  final DateTime deadline;
  String status; // 'A Fazer', 'Em Andamento', 'Em Revisão', 'Concluída'
  final List<Submission> submissions;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.deadline,
    this.status = 'A Fazer',
    this.submissions = const [],
  });
}

class ProjectFile {
  final String id;
  final String name;
  final String type; // 'folder', 'md', 'image', 'pdf', etc
  final DateTime createdAt;
  String content; // for .md files

  ProjectFile({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.content = '',
  });
}

class ProjectType {
  final String id;
  final String name;
  final String area;
  final int customFieldsCount;

  ProjectType({
    required this.id,
    required this.name,
    required this.area,
    required this.customFieldsCount,
  });
}

class Project {
  final String id;
  final String name;
  final String type;
  final String area;
  String status;
  final DateTime deadline;
  final List<ProjectFile> files;
  final List<Mission> missions;

  Project({
    required this.id,
    required this.name,
    required this.type,
    required this.area,
    required this.status,
    required this.deadline,
    this.files = const [],
    this.missions = const [],
  });
}

class Area {
  final String id;
  final String name;
  final String manager;
  final int activeProjects;

  Area({
    required this.id,
    required this.name,
    required this.manager,
    required this.activeProjects,
  });
}

class UserResource {
  final String id;
  final String name;
  final String role;
  final String email;

  UserResource({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
  });
}

class AuditLog {
  final String id;
  final String action;
  final String user;
  final String entity;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.action,
    required this.user,
    required this.entity,
    required this.timestamp,
  });
}

class AppState extends ChangeNotifier {
  final List<Project> _projects = [
    Project(
      id: 'p1',
      name: 'Operação Ransomware ABC',
      type: 'Perícia Digital',
      area: 'Cibernética',
      status: 'Em Andamento',
      deadline: DateTime.now().add(const Duration(days: 30)),
      files: [
        ProjectFile(id: 'f1', name: 'Evidencias', type: 'folder', createdAt: DateTime.now()),
        ProjectFile(id: 'f2', name: 'Laudo_Preliminar.md', type: 'md', createdAt: DateTime.now(), content: '# Laudo Preliminar\n\nNenhuma evidência encontrada até o momento.'),
      ],
      missions: [
        Mission(
          id: 'm1',
          title: 'Extração de Logs do Servidor',
          description: 'Obter os logs do Windows Event Viewer da máquina afetada.',
          assignee: 'João Silva',
          deadline: DateTime.now().add(const Duration(days: 2)),
          status: 'Em Andamento',
        ),
        Mission(
          id: 'm2',
          title: 'Análise de Malware (Ransomware)',
          description: 'Rodar o payload em sandbox isolada e documentar o comportamento.',
          assignee: 'Maria Souza',
          deadline: DateTime.now().add(const Duration(days: 5)),
          status: 'Em Revisão',
          submissions: [
            Submission(
              id: 's1',
              missionId: 'm2',
              authorName: 'Maria Souza',
              submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
              content: 'Anexo: Relatorio_Sandbox_v1.pdf. O malware utiliza encriptação AES-256 e tenta deletar os shadow copies.',
              status: 'Pendente'
            )
          ]
        ),
      ]
    ),
    Project(
      id: 'p2',
      name: 'Campanha de Conscientização',
      type: 'Marketing',
      area: 'Comunicação',
      status: 'Concluído',
      deadline: DateTime.now().subtract(const Duration(days: 5)),
      files: [],
      missions: [],
    ),
  ];

  final List<Area> _areas = [
    Area(id: 'a1', name: 'Cibernética', manager: 'Admin', activeProjects: 1),
    Area(id: 'a2', name: 'Comunicação', manager: 'Maria Souza', activeProjects: 0),
    Area(id: 'a3', name: 'Inteligência', manager: 'João Silva', activeProjects: 0),
  ];

  final List<UserResource> _resources = [
    UserResource(id: 'u1', name: 'Admin', role: 'Administrador', email: 'admin@csis.gov'),
    UserResource(id: 'u2', name: 'Maria Souza', role: 'Revisor Sênior', email: 'maria@csis.gov'),
    UserResource(id: 'u3', name: 'João Silva', role: 'Analista Pleno', email: 'joao@csis.gov'),
  ];

  final List<ProjectType> _projectTypes = [
    ProjectType(id: 'pt1', name: 'Perícia Digital', area: 'Cibernética', customFieldsCount: 5),
    ProjectType(id: 'pt2', name: 'Campanha de Conteúdo', area: 'Comunicação', customFieldsCount: 2),
    ProjectType(id: 'pt3', name: 'Investigação', area: 'Inteligência', customFieldsCount: 8),
  ];

  final List<AuditLog> _auditLogs = [
    AuditLog(id: 'al1', action: 'Login no Sistema', user: 'Admin', entity: 'Sistema', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    AuditLog(id: 'al2', action: 'Criação de Projeto', user: 'Admin', entity: 'Operação Ransomware ABC', timestamp: DateTime.now().subtract(const Duration(hours: 4))),
  ];

  List<Project> get projects => _projects;
  List<Area> get areas => _areas;
  List<UserResource> get resources => _resources;
  List<ProjectType> get projectTypes => _projectTypes;
  List<AuditLog> get auditLogs => _auditLogs;

  void addAuditLog(String action, String user, String entity) {
    _auditLogs.insert(0, AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      user: user,
      entity: entity,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void addProject(Project project) {
    _projects.add(project);
    addAuditLog('Criou Projeto', 'Admin', project.name);
    notifyListeners();
  }

  void archiveProject(String projectId) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    project.status = 'Arquivado';
    addAuditLog('Arquivou Projeto', 'Admin', project.name);
    notifyListeners();
  }

  void addFileToProject(String projectId, ProjectFile file) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    project.files.add(file);
    addAuditLog('Upload de Arquivo', 'Admin', '${project.name} -> ${file.name}');
    notifyListeners();
  }

  void updateFileContent(String projectId, String fileId, String newContent) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final file = project.files.firstWhere((f) => f.id == fileId);
    file.content = newContent;
    notifyListeners();
  }

  void addArea(Area area) {
    _areas.add(area);
    notifyListeners();
  }

  void addResource(UserResource resource) {
    _resources.add(resource);
    addAuditLog('Convidou Usuário', 'Admin', resource.email);
    notifyListeners();
  }

  void addProjectType(ProjectType type) {
    _projectTypes.add(type);
    addAuditLog('Criou Tipo de Projeto', 'Admin', type.name);
    notifyListeners();
  }

  void addMission(String projectId, Mission mission) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    project.missions.add(mission);
    notifyListeners();
  }

  void updateMissionStatus(String projectId, String missionId, String newStatus) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final mission = project.missions.firstWhere((m) => m.id == missionId);
    mission.status = newStatus;
    notifyListeners();
  }

  void addSubmission(String projectId, String missionId, Submission submission) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final mission = project.missions.firstWhere((m) => m.id == missionId);
    mission.submissions.add(submission);
    mission.status = 'Em Revisão';
    addAuditLog('Enviou Entrega', submission.authorName, mission.title);
    notifyListeners();
  }

  void reviewSubmission(String projectId, String missionId, String submissionId, String newStatus) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final mission = project.missions.firstWhere((m) => m.id == missionId);
    final submission = mission.submissions.firstWhere((s) => s.id == submissionId);
    
    submission.status = newStatus;
    
    if (newStatus == 'Aprovada') {
      mission.status = 'Concluída';
    } else if (newStatus == 'Ajustes') {
      mission.status = 'Em Andamento';
    }
    addAuditLog('Revisou Entrega ($newStatus)', 'Admin', mission.title);
    notifyListeners();
  }
}
