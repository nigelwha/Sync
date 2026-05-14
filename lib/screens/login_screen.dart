import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      if (_isLoginMode) {
        await auth.signIn(_emailController.text.trim(), _passwordController.text);
      } else {
        await auth.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/projects');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Логотип
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.folder, size: 44, color: AppTheme.primary),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isLoginMode ? 'Вход в систему' : 'Регистрация',
                        style: AppTheme.headline2,
                      ),
                      const SizedBox(height: 24),
                      if (!_isLoginMode)
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Имя и фамилия',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
                              return 'Введите имя';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите email';
                          }
                          if (!value.contains('@')) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          if (!_isLoginMode && value.length < 6) {
                            return 'Пароль должен быть не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLoginMode ? 'Войти' : 'Зарегистрироваться'),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            // Очищаем поля при переключении
                            _emailController.clear();
                            _passwordController.clear();
                            _nameController.clear();
                          });
                        },
                        child: Text(
                          _isLoginMode ? 'Создать аккаунт' : 'Уже есть аккаунт? Войти',
                          style: AppTheme.bodyText.copyWith(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}