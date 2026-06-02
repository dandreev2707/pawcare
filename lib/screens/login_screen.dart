import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_cubit.dart';
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

  void _submit() {
    setState(() {
      _emailTouched    = true;
      _passwordTouched = true;
    });
    if (_emailError != null || _passwordError != null) return;
    context.read<AuthCubit>().login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _showGoogleLogin() async {
    final codeController = TextEditingController();
    final googleUrl = '${ApiService.baseUrl}/api/v1/auth/google/initiate';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text('G',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4))),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Google авторизация'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Скопируйте ссылку и откройте её в браузере на компьютере\n'
              '2. Войдите в аккаунт Google\n'
              '3. Введите 8-символьный код со страницы',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary(ctx), height: 1.6),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.inputFill(ctx),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(ctx)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    googleUrl,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary(ctx),
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: googleUrl));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Ссылка скопирована'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Icon(Icons.copy, size: 16,
                      color: Color(0xFF4285F4)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'Код авторизации (8 символов)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              context.read<AuthCubit>().loginWithGoogleCode(code);
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTelegramLogin() async {
    final codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2AABEE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.send, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('Вход через Telegram'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Откройте бота @PawCareBot в Telegram\n'
              '2. Введите команду /login\n'
              '3. Введите полученный 6-значный код',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary(ctx), height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2AABEE),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final code = codeController.text.trim();
              if (code.length != 6) return;
              Navigator.pop(ctx);
              context.read<AuthCubit>().loginWithTelegramCode(code);
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          context.read<AuthCubit>().resetState();
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<AuthCubit>().resetState();
        }
      },
      builder: (ctx, state) {
        final isLoading = state is AuthLoading;

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
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary(context)),
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
                      isValid: _passwordError == null &&
                          _passwordController.text.isNotEmpty,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary(context),
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (_passwordTouched && _passwordError != null)
                    _errorText(_passwordError!),
                  const SizedBox(height: 32),

                  // Основная кнопка входа
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C6E49),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Войти',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Разделитель
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.border(context))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('или',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(context))),
                    ),
                    Expanded(child: Divider(color: AppColors.border(context))),
                  ]),
                  const SizedBox(height: 16),

                  // Войти через Google
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _showGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Text('G',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4285F4))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Войти через Google',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Войти через Telegram
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _showTelegramLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2AABEE)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2AABEE),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.send,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text('Войти через Telegram',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2AABEE))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Нет аккаунта? ',
                          style: TextStyle(
                              color: AppColors.textSecondary(context))),
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
      },
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
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
