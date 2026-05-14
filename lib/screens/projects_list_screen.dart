import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final projectService = Provider.of<ProjectService>(context, listen: false);
    if (auth.currentUser != null) {
      await projectService.loadProjects(auth.currentUser!.id);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Sync', style: AppTheme.headline2.copyWith(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Уведомления будут позже')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ЛЕВАЯ ЧАСТЬ: список проектов
            Expanded(
              flex: 2,
              child: Consumer<ProjectService>(
                builder: (context, projectService, child) {
                  final projects = projectService.projects;
                  if (projects.isEmpty) {
                    return const Center(child: Text('Нет проектов. Создайте первый!'));
                  }
                  return ListView.separated(
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final project = projects[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailScreen(project: project),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.title, style: AppTheme.headline2.copyWith(fontSize: 18)),
                                const SizedBox(height: 8),
                                if (project.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    children: project.tags.split(' ').map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                                      labelStyle: AppTheme.label.copyWith(color: AppTheme.primary),
                                    )).toList(),
                                  ),
                                if (project.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(project.description!, style: AppTheme.bodyText, maxLines: 2),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            // ПРАВАЯ ЧАСТЬ: профиль пользователя
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(
                          currentUser?.firstName[0].toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 40, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(currentUser?.fullName ?? '', style: AppTheme.headline2),
                      const SizedBox(height: 4),
                      Text('ID: ${currentUser?.id ?? ''}', style: AppTheme.label),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Уровень 1', style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold)),
                          Text('0%', style: AppTheme.label),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: 0,
                        backgroundColor: AppTheme.divider,
                        color: AppTheme.secondary,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),
                      // Количество проектов
                      Consumer<ProjectService>(
                        builder: (context, projectService, child) {
                          return Text('${projectService.projects.length}', style: AppTheme.headline1.copyWith(fontSize: 32));
                        },
                      ),
                      const SizedBox(height: 4),
                      Text('Всего проектов', style: AppTheme.label),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text('0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('В работе', style: AppTheme.label),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text('0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Завершено', style: AppTheme.label),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Создать новый проект'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await auth.signOut();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Выйти'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}