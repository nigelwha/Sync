import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app;

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  app.User? _currentUser;

  app.User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Инициализация: проверяем сессию и загружаем профиль
  Future<void> init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchOrCreateProfile(session.user.id, session.user.email!);
    }
  }

  // Получить или создать профиль
  Future<void> _fetchOrCreateProfile(String userId, String email) async {
    // Пытаемся найти профиль
    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      // Профиль существует
      _currentUser = app.User(
        id: existing['id'],
        firstName: existing['full_name']?.split(' ')[0] ?? '',
        lastName: existing['full_name']?.split(' ').skip(1).join(' ') ?? '',
        email: existing['email'],
        level: 'Уровень ${existing['level'] ?? 1}',
        activeProjectsCount: 0,
        completedProjectsCount: 0,
      );
    } else {
      // Создаём профиль автоматически
      final fullName = email.split('@')[0]; // временное имя
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'level': 1,
      });
      _currentUser = app.User(
        id: userId,
        firstName: fullName,
        lastName: '',
        email: email,
        level: 'Уровень 1',
        activeProjectsCount: 0,
        completedProjectsCount: 0,
      );
    }
    notifyListeners();
  }

  // Регистрация
  Future<void> signUp(String email, String password, String fullName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'level': 1,
        });
        await _fetchOrCreateProfile(user.id, email);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Вход (автоматически создаёт профиль, если нет)
  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        await _fetchOrCreateProfile(user.id, user.email!);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Выход
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}