import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';

class LocalFile {
  final String id;
  final String name;
  final String size;
  final Uint8List bytes;
  final String mimeType;
  final String uploadedBy;
  final DateTime uploadedAt;
  String grade;
  String authorComment;
  String mentorComment;

  LocalFile({
    required this.id,
    required this.name,
    required this.size,
    required this.bytes,
    required this.mimeType,
    required this.uploadedBy,
    required this.uploadedAt,
    this.grade = 'не оценено',
    this.authorComment = '',
    this.mentorComment = '',
  });
}

class StageScreen extends StatefulWidget {
  final String projectId;
  final String stageId;
  final String stageTitle;
  const StageScreen({Key? key, required this.projectId, required this.stageId, required this.stageTitle}) : super(key: key);

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  List<LocalFile> files = [];
  LocalFile? selectedFile;
  bool _isMentor = false;

  @override
  void initState() {
    super.initState();
    _checkMentor();
  }

  Future<void> _checkMentor() async {
    final service = Provider.of<ProjectService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;
    final members = await service.getTeamForProject(widget.projectId);
    final mentor = members.firstWhere(
      (m) => m.role == MemberRole.mentor,
      orElse: () => TeamMember(id: '', name: '', role: MemberRole.participant),
    );
    setState(() {
      _isMentor = mentor.name == currentUser.fullName;
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

    final newFile = LocalFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: file.name,
      size: (file.size / 1024).toStringAsFixed(2) + ' KB',
      bytes: bytes,
      mimeType: file.extension?.toLowerCase() ?? '',
      uploadedBy: currentUser.fullName,
      uploadedAt: DateTime.now(),
    );
    setState(() {
      files.add(newFile);
      if (selectedFile == null) selectedFile = newFile;
    });
    _showSnackbar('Файл "${file.name}" добавлен');
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.success));
  }

  void _downloadFile(LocalFile file) {
    final blob = html.Blob([file.bytes], file.mimeType == 'pdf' ? 'application/pdf' : 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', file.name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _previewFile(LocalFile file) {
    if (file.mimeType == 'jpg' || file.mimeType == 'jpeg' || file.mimeType == 'png' || file.mimeType == 'gif') {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: Text(file.name), automaticallyImplyLeading: false),
              Expanded(child: Image.memory(file.bytes)),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Закрыть')),
            ],
          ),
        ),
      );
    } else if (file.mimeType == 'pdf') {
      final blob = html.Blob([file.bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      Future.delayed(Duration(seconds: 10), () => html.Url.revokeObjectUrl(url));
    } else {
      _showSnackbar('Предпросмотр не поддерживается');
    }
  }

  void _updateGrade(String newGrade) {
    if (selectedFile != null) {
      setState(() {
        selectedFile!.grade = newGrade;
        final index = files.indexWhere((f) => f.id == selectedFile!.id);
        if (index != -1) files[index] = selectedFile!;
      });
    }
  }

  void _updateAuthorComment(String comment) {
    if (selectedFile != null) {
      setState(() {
        selectedFile!.authorComment = comment;
        final index = files.indexWhere((f) => f.id == selectedFile!.id);
        if (index != -1) files[index] = selectedFile!;
      });
    }
  }

  void _updateMentorComment(String comment) {
    if (selectedFile != null) {
      setState(() {
        selectedFile!.mentorComment = comment;
        final index = files.indexWhere((f) => f.id == selectedFile!.id);
        if (index != -1) files[index] = selectedFile!;
      });
    }
  }

  void _deleteFile() {
    if (selectedFile != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить файл'),
          content: Text('Вы уверены, что хотите удалить "${selectedFile!.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                setState(() {
                  files.removeWhere((f) => f.id == selectedFile!.id);
                  selectedFile = files.isNotEmpty ? files.first : null;
                });
                Navigator.pop(ctx);
                _showSnackbar('Файл удалён');
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;

    if (selectedFile != null && !files.any((f) => f.id == selectedFile!.id)) {
      selectedFile = files.isNotEmpty ? files.first : null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.stageTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Левая колонка
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
                              return Card(
                                child: ListTile(
                                  leading: Icon(_getIconForMime(file.mimeType), color: AppTheme.primary),
                                  title: Text(file.name),
                                  subtitle: Text('${file.size} • ${file.uploadedBy}'),
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
                                  selected: selectedFile?.id == file.id,
                                  selectedTileColor: AppTheme.primary.withOpacity(0.1),
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
            // Правая колонка
            Expanded(
              flex: 1,
              child: selectedFile == null
                  ? const Center(child: Text('Выберите файл для просмотра деталей'))
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selectedFile!.name, style: AppTheme.headline2),
                            const SizedBox(height: 8),
                            Text('Добавлен: ${_formatDate(selectedFile!.uploadedAt)} • ${selectedFile!.uploadedBy}', style: AppTheme.label),
                            const SizedBox(height: 16),
                            // Оценка
                            Row(
                              children: [
                                const Icon(Icons.star_border),
                                const SizedBox(width: 8),
                                Text('Оценка: ', style: AppTheme.bodyText),
                                if (_isMentor)
                                  DropdownButton<String>(
                                    value: selectedFile!.grade,
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
                                  Text(selectedFile!.grade, style: AppTheme.bodyText),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Комментарий автора
                            Text('Комментарий автора', style: AppTheme.headline2),
                            const SizedBox(height: 4),
                            if (selectedFile!.uploadedBy == currentUser?.fullName)
                              TextFormField(
                                initialValue: selectedFile!.authorComment,
                                decoration: const InputDecoration(hintText: 'Напишите комментарий...'),
                                maxLines: 3,
                                onChanged: _updateAuthorComment,
                              )
                            else
                              Text(selectedFile!.authorComment.isEmpty ? '—' : selectedFile!.authorComment),
                            const SizedBox(height: 16),
                            // Комментарий наставника
                            Text('Комментарий наставника', style: AppTheme.headline2),
                            const SizedBox(height: 4),
                            if (_isMentor)
                              TextFormField(
                                initialValue: selectedFile!.mentorComment,
                                decoration: const InputDecoration(hintText: 'Напишите комментарий...'),
                                maxLines: 3,
                                onChanged: _updateMentorComment,
                              )
                            else
                              Text(selectedFile!.mentorComment.isEmpty ? '—' : selectedFile!.mentorComment),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: _deleteFile,
                              icon: const Icon(Icons.delete),
                              label: const Text('Удалить файл'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute}';
  IconData _getIconForMime(String mime) {
    if (mime == 'jpg' || mime == 'jpeg' || mime == 'png' || mime == 'gif') return Icons.image;
    if (mime == 'pdf') return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }
}