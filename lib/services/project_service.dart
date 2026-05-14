import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import '../models/stage.dart';
import '../models/team_member.dart';

class ProjectService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Project> _projects = [];

  List<Project> get projects => _projects;

  // Загружаем проекты, где пользователь – участник
  Future<void> loadProjects(String userId) async {
    final response = await _supabase
        .from('project_members')
        .select('project_id, projects(*)')
        .eq('user_id', userId);

    _projects = response.map<Project>((json) {
      final proj = json['projects'];
      return Project(
        id: proj['id'].toString(),
        title: proj['title'],
        tags: proj['tags'] ?? '',
        description: proj['description'],
        startDate: proj['start_date'] != null ? DateTime.parse(proj['start_date']) : null,
        endDate: proj['end_date'] != null ? DateTime.parse(proj['end_date']) : null,
        status: proj['status'] ?? 'в работе',
        grade: proj['grade'] ?? 'не оценено',
      );
    }).toList();
    notifyListeners();
  }

  // Создание проекта
  Future<void> addProject(Project project, String ownerId) async {
    final response = await _supabase.from('projects').insert({
      'title': project.title,
      'description': project.description,
      'tags': project.tags,
      'start_date': project.startDate?.toIso8601String(),
      'end_date': project.endDate?.toIso8601String(),
      'status': project.status,
      'grade': project.grade,
      'owner_id': ownerId,
    }).select();
    if (response.isNotEmpty) {
      final newProject = Project(
        id: response[0]['id'].toString(),
        title: response[0]['title'],
        tags: response[0]['tags'] ?? '',
        description: response[0]['description'],
        startDate: response[0]['start_date'] != null ? DateTime.parse(response[0]['start_date']) : null,
        endDate: response[0]['end_date'] != null ? DateTime.parse(response[0]['end_date']) : null,
        status: response[0]['status'],
        grade: response[0]['grade'],
      );
      _projects.add(newProject);
      // Добавляем владельца как участника
      await _supabase.from('project_members').insert({
        'project_id': newProject.id,
        'user_id': ownerId,
        'role': 'участник',
      });
      notifyListeners();
    }
  }

  // Получение этапов проекта
  Future<List<Stage>> getStagesForProject(String projectId) async {
    final response = await _supabase
        .from('stages')
        .select('*')
        .eq('project_id', projectId)
        .order('order_index', ascending: true);
    return response.map<Stage>((json) => Stage(
      id: json['id'].toString(),
      title: json['title'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      orderIndex: json['order_index'],
    )).toList();
  }

  // Добавление этапа
  Future<void> addStage(String projectId, Stage stage) async {
    await _supabase.from('stages').insert({
      'project_id': projectId,
      'title': stage.title,
      'due_date': stage.dueDate?.toIso8601String(),
      'order_index': stage.orderIndex,
    });
    notifyListeners();
  }

  // Удаление этапа
  Future<void> removeStage(String stageId) async {
    await _supabase.from('stages').delete().eq('id', stageId);
    notifyListeners();
  }

  // Получение участников проекта
  Future<List<TeamMember>> getTeamForProject(String projectId) async {
    final response = await _supabase
        .from('project_members')
        .select('user_id, role, profiles(full_name)')
        .eq('project_id', projectId);
    return response.map<TeamMember>((json) => TeamMember(
      id: json['user_id'].toString(),
      name: json['profiles']['full_name'] ?? 'Без имени',
      role: json['role'] == 'наставник' ? MemberRole.mentor : MemberRole.participant,
    )).toList();
  }

  // Добавление участника
  Future<void> addTeamMember(String projectId, TeamMember member) async {
    await _supabase.from('project_members').insert({
      'project_id': projectId,
      'user_id': member.id,
      'role': member.role == MemberRole.mentor ? 'наставник' : 'участник',
    });
    notifyListeners();
  }

  // Удаление участника
  Future<void> removeTeamMember(String projectId, String userId) async {
    await _supabase
        .from('project_members')
        .delete()
        .match({'project_id': projectId, 'user_id': userId});
    notifyListeners();
  }

  // Назначение наставника
  Future<void> setMentor(String projectId, String userId) async {
    // Снять наставника со всех
    await _supabase
        .from('project_members')
        .update({'role': 'участник'})
        .match({'project_id': projectId, 'role': 'наставник'});
    // Назначить нового
    await _supabase
        .from('project_members')
        .update({'role': 'наставник'})
        .match({'project_id': projectId, 'user_id': userId});
    notifyListeners();
  }

  // Обновление оценки проекта
  Future<void> updateGrade(String projectId, String newGrade) async {
    final newStatus = (newGrade == 'хорошо' || newGrade == 'отлично') ? 'завершён' : 'в работе';
    await _supabase
        .from('projects')
        .update({'grade': newGrade, 'status': newStatus})
        .eq('id', projectId);
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index].grade = newGrade;
      _projects[index].status = newStatus;
      notifyListeners();
    }
  }
}