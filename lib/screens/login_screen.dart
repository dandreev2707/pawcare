import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus         = FocusNode();
  final _passwordFocus      = FocusNode();

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _emailTouched    = false;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _emailTouched = true);
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) setState(() => _passwordTouched = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? get _emailError {
    final v = _emailController.text.trim();
    if (v.isEmpty) return 'Введите email';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
      return 'Некорректный email';
    }
    return null;
  }

  String? get _passwordError {
    if (_passwordController.text.isEmpty) return 'Введите пароль';
    return null;
  }

  Future<void> _login() async {
    setState(() {
      _emailTouched    = true;
      _passwordTouched = true;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    final result = await ApiService.login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (result['success']) {
      await ApiService.saveToken(result['data']['access_token']);
      if (mounted) context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Ошибка входа')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C6E49),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.pets, size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Добро пожаловать\nв PawCare!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Войдите чтобы продолжить',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 40),

              // Email
              _label('Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: _inputDecoration(
                  hint: 'example@mail.ru',
                  icon: Icons.email_outlined,
                  error: _emailTouched ? _emailError : null,
                  isValid: _emailError == null && _emailController.text.isNotEmpty,
                ),
              ),
              if (_emailTouched && _emailError != null) _errorText(_emailError!),
              const SizedBox(height: 20),

              // Пароль
              _label('Пароль'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_outlined,
                  error: _passwordTouched ? _passwordError : null,
                  isValid: _passwordError == null && _passwordController.text.isNotEmpty,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary(context),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (_passwordTouched && _passwordError != null)
                _errorText(_passwordError!),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C6E49),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Войти',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Нет аккаунта? ',
                      style: TextStyle(color: AppColors.textSecondary(context))),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('Зарегистрироваться',
                        style: TextStyle(
                            color: Color(0xFF2C6E49),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? error,
    bool isValid = false,
    Widget? suffix,
  }) {
    final borderColor = error != null
        ? Colors.red
        : isValid
            ? const Color(0xFF2C6E49)
            : AppColors.border(context);
    final borderWidth = (error != null || isValid) ? 1.5 : 1.0;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary(context)),
      prefixIcon: Icon(icon,
          color: error != null
              ? Colors.red
              : isValid
                  ? const Color(0xFF2C6E49)
                  : AppColors.textSecondary(context),
          size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.inputFill(context),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: borderWidth)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: error != null ? Colors.red : const Color(0xFF2C6E49),
              width: 2)),
    );
  }

  Widget _errorText(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ]),
      );

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context)));
}
