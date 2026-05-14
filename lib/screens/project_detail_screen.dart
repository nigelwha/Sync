import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/stage.dart';
import '../models/team_member.dart';
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'stage_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<Stage> _stages = [];
  List<TeamMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<ProjectService>(context, listen: false);
    final stages = await service.getStagesForProject(widget.project.id);
    final members = await service.getTeamForProject(widget.project.id);
    setState(() {
      _stages = stages;
      _members = members;
      _loading = false;
    });
  }

  void _addStage() async {
    // ... (без изменений)
  }

  void _addTeamMember() async {
    // ... (без изменений)
  }

  void _setMentor(String memberId) async {
    await Provider.of<ProjectService>(context, listen: false).setMentor(widget.project.id, memberId);
    _loadData(); // перезагружаем
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<ProjectService>(context);
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    final mentor = _members.firstWhere(
      (m) => m.role == MemberRole.mentor,
      orElse: () => TeamMember(id: '', name: 'Не назначен', role: MemberRole.participant),
    );
    final participants = _members.where((m) => m.role == MemberRole.participant).toList();
    final bool isMentor = currentUser != null && currentUser.fullName == mentor.name;

    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text(widget.project.title)), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addStage,
            tooltip: 'Добавить этап',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Экран проекта', style: AppTheme.headline2),
            const SizedBox(height: 8),
            if (_stages.isEmpty)
              const Text('Нет этапов')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final stage = _stages[index];
                  return Card(
                    child: ListTile(
                      title: Text(stage.title),
                      subtitle: stage.dueDate != null ? Text('Срок: ${stage.dueDate!.toLocal().toString().split(' ')[0]}') : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await service.removeStage(stage.id);
                          _loadData();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StageScreen(
                              projectId: widget.project.id,
                              stageId: stage.id,
                              stageTitle: stage.title,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            Text('Участник команды', style: AppTheme.headline2),
            const SizedBox(height: 8),
            ...participants.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 8),
                  Text(p.name),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Text('Наставник команды: ${mentor.name}'),
                if (isMentor && participants.isNotEmpty)
                  DropdownButton<String>(
                    value: mentor.id,
                    hint: const Text('Назначить'),
                    onChanged: (newId) {
                      if (newId != null) _setMentor(newId);
                    },
                    items: participants.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text('Статус: ${widget.project.status}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_border),
                const SizedBox(width: 8),
                Text('Оценка: '),
                if (isMentor)
                  DropdownButton<String>(
                    value: widget.project.grade,
                    items: const [
                      DropdownMenuItem(value: 'не оценено', child: Text('не оценено')),
                      DropdownMenuItem(value: 'плохо', child: Text('плохо')),
                      DropdownMenuItem(value: 'удовлетворительно', child: Text('удовлетворительно')),
                      DropdownMenuItem(value: 'хорошо', child: Text('хорошо')),
                      DropdownMenuItem(value: 'отлично', child: Text('отлично')),
                    ],
                    onChanged: (newGrade) async {
                      if (newGrade != null) {
                        await service.updateGrade(widget.project.id, newGrade);
                        setState(() {});
                      }
                    },
                  )
                else
                  Text(widget.project.grade),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.project.description != null) ...[
              Text('Описание проекта', style: AppTheme.headline2),
              const SizedBox(height: 4),
              Text(widget.project.description!),
              const SizedBox(height: 16),
            ],
            Text('Сроки проекта', style: AppTheme.headline2),
            const SizedBox(height: 4),
            Text('${widget.project.startDate?.toLocal().toString().split(' ')[0] ?? 'не указано'} — ${widget.project.endDate?.toLocal().toString().split(' ')[0] ?? 'не указано'}'),
          ],
        ),
      ),
    );
  }
}