import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/project_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/projects_list_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yozrxtjeddqvnyemlapl.supabase.co',
    anonKey: 'sb_publishable_2YF-1mzMU5HeDmveL66xEg_QbZNKWuC',
  );
  final authService = AuthService();
  await authService.init();
  runApp(SyncApp(authService: authService));
}

class SyncApp extends StatelessWidget {
  final AuthService authService;
  const SyncApp({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ProjectService()),
      ],
      child: MaterialApp(
        title: 'Sync',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/projects': (context) => const ProjectsListScreen(),
        },
      ),
    );
  }
}