import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';

class StageScreen extends StatefulWidget {
  final String projectId;
  final String stageId;
  final String stageTitle;
  const StageScreen({Key? key, required this.projectId, required this.stageId, required this.stageTitle}) : super(key: key);

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  List<Map<String, dynamic>> files = [];
  Map<String, dynamic>? selectedFile;
  bool _isMentor = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<ProjectService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    // Загружаем файлы
    final loadedFiles = await service.getFilesForStage(widget.stageId);
    setState(() {
      files = loadedFiles;
      if (files.isNotEmpty && selectedFile == null) selectedFile = files.first;
    });

    // Проверяем, наставник ли пользователь
    final members = await service.getTeamForProject(widget.projectId);
    final mentor = members.firstWhere(
      (m) => m.role == MemberRole.mentor,
      orElse: () => TeamMember(id: '', name: '', role: MemberRole.participant),
    );
    setState(() {
      _isMentor = mentor.name == currentUser.fullName;
      _isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _showSnackbar('Не удалось прочитать файл');
      return;
    }

    final service = Provider.of<ProjectService>(context, listen: false);
    try {
      final newFile = await service.uploadFile(
        widget.stageId,
        currentUser.id,
        file.name,
        bytes,
        file.extension?.toLowerCase() ?? '',
      );
      // Добавляем имя автора (можно подгрузить из профиля)
      newFile['profiles'] = {'full_name': currentUser.fullName};
      setState(() {
        files.insert(0, newFile);
        if (selectedFile == null) selectedFile = newFile;
      });
      _showSnackbar('Файл "${file.name}" загружен');
    } catch (e) {
      _showSnackbar('Ошибка загрузки: $e');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.success));
  }

  void _previewFile(Map<String, dynamic> file) async {
    final storagePath = file['storage_path'];
    final mimeType = file['mime_type'];
    try {
      final service = Provider.of<ProjectService>(context, listen: false);
      final bytes = await service.downloadFile(storagePath);
      if (mimeType == 'jpg' || mimeType == 'jpeg' || mimeType == 'png' || mimeType == 'gif') {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(title: Text(file['original_name']), automaticallyImplyLeading: false),
                Expanded(child: Image.memory(bytes)),
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Закрыть')),
              ],
            ),
          ),
        );
      } else if (mimeType == 'pdf') {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        Future.delayed(Duration(seconds: 10), () => html.Url.revokeObjectUrl(url));
      } else {
        _showSnackbar('Предпросмотр не поддерживается');
      }
    } catch (e) {
      _showSnackbar('Ошибка загрузки файла для предпросмотра');
    }
  }

  void _downloadFile(Map<String, dynamic> file) async {
    final storagePath = file['storage_path'];
    try {
      final service = Provider.of<ProjectService>(context, listen: false);
      final bytes = await service.downloadFile(storagePath);
      final blob = html.Blob([bytes], 'application/octet-stream');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', file['original_name'])
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      _showSnackbar('Ошибка скачивания');
    }
  }

  void _deleteFile(Map<String, dynamic> file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить файл'),
        content: Text('Вы уверены, что хотите удалить "${file['original_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final service = Provider.of<ProjectService>(context, listen: false);
      await service.deleteFile(file['id'], file['storage_path']);
      setState(() {
        files.removeWhere((f) => f['id'] == file['id']);
        if (selectedFile?['id'] == file['id']) selectedFile = files.isNotEmpty ? files.first : null;
      });
      _showSnackbar('Файл удалён');
    }
  }

  void _updateGrade(String newGrade) async {
    if (selectedFile != null) {
      await Provider.of<ProjectService>(context, listen: false).updateFileMeta(selectedFile!['id'], grade: newGrade);
      setState(() {
        selectedFile!['grade'] = newGrade;
        final index = files.indexWhere((f) => f['id'] == selectedFile!['id']);
        if (index != -1) files[index]['grade'] = newGrade;
      });
    }
  }

  void _updateAuthorComment(String comment) async {
    if (selectedFile != null) {
      await Provider.of<ProjectService>(context, listen: false).updateFileMeta(selectedFile!['id'], authorComment: comment);
      setState(() {
        selectedFile!['author_comment'] = comment;
        final index = files.indexWhere((f) => f['id'] == selectedFile!['id']);
        if (index != -1) files[index]['author_comment'] = comment;
      });
    }
  }

  void _updateMentorComment(String comment) async {
    if (selectedFile != null) {
      await Provider.of<ProjectService>(context, listen: false).updateFileMeta(selectedFile!['id'], mentorComment: comment);
      setState(() {
        selectedFile!['mentor_comment'] = comment;
        final index = files.indexWhere((f) => f['id'] == selectedFile!['id']);
        if (index != -1) files[index]['mentor_comment'] = comment;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: Text(widget.stageTitle)), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.stageTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Левая колонка: список файлов
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Загруженные файлы', style: AppTheme.headline2),
                  const SizedBox(height: 8),
                  Expanded(
                    child: files.isEmpty
                        ? const Center(child: Text('Нет файлов. Загрузите первый.'))
                        : ListView.separated(
                            itemCount: files.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final file = files[index];
                              final isSelected = selectedFile?['id'] == file['id'];
                              return Card(
                                color: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
                                child: ListTile(
                                  leading: Icon(_getIconForMime(file['mime_type']), color: AppTheme.primary),
                                  title: Text(file['original_name']),
                                  subtitle: Text('${(file['size_bytes'] / 1024).toStringAsFixed(2)} KB • ${file['profiles']?['full_name'] ?? ''}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () => _previewFile(file),
                                        tooltip: 'Предпросмотр',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => _downloadFile(file),
                                        tooltip: 'Скачать',
                                      ),
                                    ],
                                  ),
                                  onTap: () => setState(() => selectedFile = file),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Загрузить новый файл'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Правая колонка: детали выбранного файла
            Expanded(
              flex: 1,
              child: selectedFile == null
                  ? const Center(child: Text('Выберите файл для просмотра деталей'))
                  : SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedFile!['original_name'], style: AppTheme.headline2),
                              const SizedBox(height: 8),
                              Text('Добавлен: ${_formatDate(DateTime.parse(selectedFile!['uploaded_at']))} • ${selectedFile!['profiles']?['full_name'] ?? ''}', style: AppTheme.label),
                              const SizedBox(height: 16),
                              // Оценка
                              Row(
                                children: [
                                  const Icon(Icons.star_border),
                                  const SizedBox(width: 8),
                                  Text('Оценка: ', style: AppTheme.bodyText),
                                  if (_isMentor)
                                    DropdownButton<String>(
                                      value: selectedFile!['grade'],
                                      items: const [
                                        DropdownMenuItem(value: 'не оценено', child: Text('не оценено')),
                                        DropdownMenuItem(value: 'плохо', child: Text('плохо')),
                                        DropdownMenuItem(value: 'удовлетворительно', child: Text('удовлетворительно')),
                                        DropdownMenuItem(value: 'хорошо', child: Text('хорошо')),
                                        DropdownMenuItem(value: 'отлично', child: Text('отлично')),
                                      ],
                                      onChanged: (newGrade) {
                                        if (newGrade != null) _updateGrade(newGrade);
                                      },
                                    )
                                  else
                                    Text(selectedFile!['grade'], style: AppTheme.bodyText),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Комментарий автора
                              Text('Комментарий автора', style: AppTheme.headline2),
                              const SizedBox(height: 4),
                              if (selectedFile!['uploaded_by'] == currentUser?.id)
                                TextFormField(
                                  initialValue: selectedFile!['author_comment'] ?? '',
                                  decoration: const InputDecoration(hintText: 'Напишите комментарий...'),
                                  maxLines: 3,
                                  onChanged: _updateAuthorComment,
                                )
                              else
                                Text(selectedFile!['author_comment']?.isNotEmpty == true ? selectedFile!['author_comment'] : '—'),
                              const SizedBox(height: 16),
                              // Комментарий наставника
                              Text('Комментарий наставника', style: AppTheme.headline2),
                              const SizedBox(height: 4),
                              if (_isMentor)
                                TextFormField(
                                  initialValue: selectedFile!['mentor_comment'] ?? '',
                                  decoration: const InputDecoration(hintText: 'Напишите комментарий...'),
                                  maxLines: 3,
                                  onChanged: _updateMentorComment,
                                )
                              else
                                Text(selectedFile!['mentor_comment']?.isNotEmpty == true ? selectedFile!['mentor_comment'] : '—'),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () => _deleteFile(selectedFile!),
                                icon: const Icon(Icons.delete),
                                label: const Text('Удалить файл'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute}';
  IconData _getIconForMime(String mime) {
    if (mime == 'jpg' || mime == 'jpeg' || mime == 'png' || mime == 'gif') return Icons.image;
    if (mime == 'pdf') return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }
}