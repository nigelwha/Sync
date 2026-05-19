import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/stage.dart';
import '../models/team_member.dart';
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newTagController = TextEditingController();
  final _participantEmailController = TextEditingController();
  final _mentorEmailController = TextEditingController();
  List<String> _tags = [];
  List<Stage> _stages = [];
  List<String> _participantEmails = [];
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _suggestedTags = ['#наука', '#AI', '#программирование', '#творчество', '#дизайн'];

  @override
  void initState() {
    super.initState();
    _addStage();
    _addStage();
  }

  void _addStage() {
    setState(() {
      _stages.add(Stage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + _stages.length.toString(),
        title: '',
        dueDate: null,
        orderIndex: _stages.length,
      ));
    });
  }

  void _removeStage(int index) {
    setState(() {
      _stages.removeAt(index);
      for (int i = 0; i < _stages.length; i++) {
        final old = _stages[i];
        _stages[i] = Stage(
          id: old.id,
          title: old.title,
          dueDate: old.dueDate,
          orderIndex: i,
        );
      }
    });
  }

  void _updateStageTitle(int index, String title) {
    setState(() {
      final old = _stages[index];
      _stages[index] = Stage(
        id: old.id,
        title: title,
        dueDate: old.dueDate,
        orderIndex: old.orderIndex,
      );
    });
  }

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    setState(() {
      if (!_tags.contains(tag)) _tags.add(tag);
      _newTagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _addParticipantEmail() {
    final email = _participantEmailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      if (!_participantEmails.contains(email)) _participantEmails.add(email);
      _participantEmailController.clear();
    });
  }

  void _removeParticipantEmail(String email) {
    setState(() => _participantEmails.remove(email));
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _createProject() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackbar('Введите название проекта');
      return;
    }
    final validStages = _stages.where((s) => s.title.trim().isNotEmpty).toList();
    if (validStages.isEmpty) {
      _showSnackbar('Добавьте хотя бы один этап с названием');
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      _showSnackbar('Пользователь не авторизован');
      return;
    }

    final service = Provider.of<ProjectService>(context, listen: false);

    Set<String> emailsToFind = {};
    if (_mentorEmailController.text.trim().isNotEmpty) {
      emailsToFind.add(_mentorEmailController.text.trim());
    }
    emailsToFind.addAll(_participantEmails);

    Map<String, String> emailToId = {};
    if (emailsToFind.isNotEmpty) {
      final foundUsers = await service.findUsersByEmails(emailsToFind.toList());
      for (var user in foundUsers) {
        emailToId[user['email'] as String] = user['id'] as String;
      }
      for (var email in emailsToFind) {
        if (!emailToId.containsKey(email)) {
          _showSnackbar('Пользователь с email $email не найден в системе');
          return;
        }
      }
    }

    final newProject = Project(
      id: '',
      title: _titleController.text,
      tags: _tags.join(' '),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text,
      startDate: _startDate,
      endDate: _endDate,
      status: 'в работе',
      grade: 'не оценено',
    );

    final createdProject = await service.addProject(newProject, currentUser.id);
    final projectId = createdProject.id;

    for (var stage in validStages) {
      await service.addStage(projectId, Stage(
        id: stage.id,
        title: stage.title,
        dueDate: stage.dueDate,
        orderIndex: stage.orderIndex,
      ));
    }

    if (_mentorEmailController.text.trim().isNotEmpty) {
      final mentorId = emailToId[_mentorEmailController.text.trim()];
      if (mentorId != null) {
        await service.addTeamMember(projectId, TeamMember(
          id: mentorId,
          name: '',
          role: MemberRole.mentor,
        ));
      }
    }

    for (var email in _participantEmails) {
      final userId = emailToId[email];
      if (userId != null) {
        await service.addTeamMember(projectId, TeamMember(
          id: userId,
          name: '',
          role: MemberRole.participant,
        ));
      }
    }

    _showSnackbar('Проект "${createdProject.title}" создан', success: true);
    Navigator.pop(context);
  }

  void _showSnackbar(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.success : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Создание проекта', style: AppTheme.headline2)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Название проекта', style: AppTheme.headline2),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Введите название проекта'),
                  ),
                  const SizedBox(height: 24),
                  Text('Этапы', style: AppTheme.headline2),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stages.length,
                    itemBuilder: (ctx, index) {
                      final stage = _stages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: stage.title,
                                decoration: const InputDecoration(hintText: 'Название этапа'),
                                onChanged: (value) => _updateStageTitle(index, value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeStage(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addStage,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить этап'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Теги', style: AppTheme.headline2),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._suggestedTags.map((tag) => FilterChip(
                        label: Text(tag),
                        selected: _tags.contains(tag),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) _tags.add(tag);
                            else _tags.remove(tag);
                          });
                        },
                      )),
                      ..._tags.where((t) => !_suggestedTags.contains(t)).map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newTagController,
                          decoration: const InputDecoration(hintText: 'Свой тег'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addTag(_newTagController.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Участники команды', style: AppTheme.headline2),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _participantEmailController,
                                  decoration: const InputDecoration(hintText: 'Email участника'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.person_add),
                                onPressed: _addParticipantEmail,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _participantEmails.map((email) => Chip(
                              label: Text(email),
                              onDeleted: () => _removeParticipantEmail(email),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('Наставник команды', style: AppTheme.headline2),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _mentorEmailController,
                            decoration: const InputDecoration(hintText: 'Email наставника'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Написать описание проекта', style: AppTheme.headline2),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(hintText: 'Описание'),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          Text('Указать сроки', style: AppTheme.headline2),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_startDate == null ? 'Дата начала' : _startDate!.toLocal().toString().split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectStartDate(context),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_endDate == null ? 'Дата окончания' : _endDate!.toLocal().toString().split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectEndDate(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createProject,
                    child: const Text('Создать проект'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}