import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_cubit.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  bool _nameTouched     = false;
  bool _emailTouched    = false;
  bool _passwordTouched = false;
  bool _confirmTouched  = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) setState(() => _nameTouched = true);
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _emailTouched = true);
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) setState(() => _passwordTouched = true);
    });
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus) setState(() => _confirmTouched = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? get _nameError {
    final v = _nameController.text.trim();
    if (v.isEmpty) return 'Введите имя';
    if (v.length < 2) return 'Минимум 2 символа';
    if (v.length > 50) return 'Максимум 50 символов';
    if (!RegExp(r'^[а-яёА-ЯЁa-zA-Z\s\-]+$').hasMatch(v)) {
      return 'Только буквы и дефис';
    }
    return null;
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
    final v = _passwordController.text;
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < 8) return 'Минимум 8 символов';
    if (!RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(v)) return 'Должна быть хотя бы одна буква';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Должна быть хотя бы одна цифра';
    return null;
  }

  String? get _confirmError {
    final v = _confirmController.text;
    if (v.isEmpty) return 'Повторите пароль';
    if (v != _passwordController.text) return 'Пароли не совпадают';
    return null;
  }

  bool get _formValid =>
      _nameError == null &&
      _emailError == null &&
      _passwordError == null &&
      _confirmError == null;

  int get _passwordStrength {
    final v = _passwordController.text;
    if (v.isEmpty) return 0;
    int score = 0;
    if (v.length >= 8) score++;
    if (v.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score++;
    return score.clamp(0, 4);
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return const Color(0xFF2C6E49);
      default: return Colors.transparent;
    }
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 1: return 'Слабый';
      case 2: return 'Средний';
      case 3: return 'Хороший';
      case 4: return 'Надёжный';
      default: return '';
    }
  }

  void _register() {
    setState(() {
      _nameTouched     = true;
      _emailTouched    = true;
      _passwordTouched = true;
      _confirmTouched  = true;
    });
    if (!_formValid) return;
    context.read<AuthCubit>().register(
      name:     _nameController.text.trim(),
      email:    _emailController.text.trim(),
      password: _passwordController.text,
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
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context)),
              onPressed: () => context.go('/login'),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Создать аккаунт',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context))),
                  const SizedBox(height: 8),
                  Text('Зарегистрируйтесь, чтобы начать',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary(context))),
                  const SizedBox(height: 32),

                  _buildField(
                    label: 'Имя',
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hint: 'Иван Иванов',
                    icon: Icons.person_outlined,
                    error: _nameTouched ? _nameError : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Email',
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'example@mail.ru',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    error: _emailTouched ? _emailError : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Пароль'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: '••••••••',
                    obscure: _obscurePassword,
                    error: _passwordTouched ? _passwordError : null,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildStrengthIndicator(),
                  ],
                  const SizedBox(height: 20),

                  _buildLabel('Повторите пароль'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hint: '••••••••',
                    obscure: _obscureConfirm,
                    error: _confirmTouched ? _confirmError : null,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C6E49),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF2C6E49).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Зарегистрироваться',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Уже есть аккаунт? ',
                          style: TextStyle(color: AppColors.textSecondary(context))),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('Войти',
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

  Widget _buildStrengthIndicator() {
    final s = _passwordStrength;
    final color = _strengthColor(s);
    final label = _strengthLabel(s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s / 4,
                backgroundColor: AppColors.border(context),
                color: color,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(
          'Используйте буквы, цифры и символы (!@# и др.)',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            error: error,
            isValid: error == null && controller.text.isNotEmpty,
          ),
        ),
        if (error != null) _errorText(error),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool obscure,
    String? error,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: _inputDecoration(
            hint: hint,
            icon: Icons.lock_outlined,
            error: error,
            isValid: error == null && controller.text.isNotEmpty,
            suffix: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary(context),
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
        if (error != null) _errorText(error),
      ],
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
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _errorText(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 14),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ]),
      );

  Widget _buildLabel(String text) => Text(text,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context)));
}
