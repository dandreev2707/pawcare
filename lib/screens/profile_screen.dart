import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _tgLinked = false;
  String? _tgUsername;
  bool _loadingTg = true;
  String? _generatedCode;
  bool _generatingCode = false;

  @override
  void initState() {
    super.initState();
    _loadTelegramStatus();
  }

  Future<void> _loadTelegramStatus() async {
    setState(() => _loadingTg = true);
    final result = await ApiService.getTelegramStatus();
    if (result['success']) {
      setState(() {
        _tgLinked = result['data']['linked'];
        _tgUsername = result['data']['username'];
        _loadingTg = false;
      });
    } else {
      setState(() => _loadingTg = false);
    }
  }

  Future<void> _generateCode() async {
    setState(() => _generatingCode = true);
    final result = await ApiService.generateTelegramCode();
    if (result['success']) {
      setState(() {
        _generatedCode = result['data']['code'];
        _generatingCode = false;
      });
    } else {
      setState(() => _generatingCode = false);
    }
  }

  Future<void> _unlink() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отвязать Telegram?'),
        content: const Text('Уведомления перестанут приходить в Telegram.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Отвязать',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.unlinkTelegram();
      setState(() {
        _tgLinked = false;
        _tgUsername = null;
        _generatedCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Профиль',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B1B))),
              const SizedBox(height: 24),

              // Аватар
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C6E49),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 32),

              // Telegram секция
              const Text('Telegram',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B1B))),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: _loadingTg
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2C6E49)))
                    : _tgLinked
                        ? _buildLinkedState()
                        : _buildUnlinkedState(),
              ),
              const SizedBox(height: 32),

              // Выход
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ApiService.deleteToken();
                    if (context.mounted) context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти из аккаунта',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2AABEE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.telegram,
                color: Color(0xFF2AABEE), size: 24),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Telegram привязан',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1B1B1B))),
            if (_tgUsername != null)
              Text('@$_tgUsername',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF666666))),
          ]),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('✓ Активен',
                style: TextStyle(
                    color: Color(0xFF2C6E49),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        const Text(
          'Вы будете получать уведомления о предстоящих процедурах в Telegram.',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _unlink,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Отвязать Telegram'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinkedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.telegram,
                color: Color(0xFF888888), size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Telegram не привязан',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1B1B1B))),
                Text('Привяжите для получения уведомлений',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
              ]),
        ]),
        const SizedBox(height: 16),

        if (_generatedCode == null) ...[
          const Text(
            'Привяжите Telegram чтобы получать напоминания о процедурах прямо в мессенджер.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _generatingCode ? null : _generateCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2AABEE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: _generatingCode
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.telegram),
              label: const Text('Получить код привязки',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ] else ...[
          const Text('Ваш код привязки:',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF666666))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2AABEE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _generatedCode!,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _generatedCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Код скопирован')),
                    );
                  },
                  icon: const Icon(Icons.copy,
                      color: Color(0xFF2AABEE)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Отправьте боту команду:\n/code XXXXXX',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline,
                  color: Color(0xFF2AABEE), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Найдите бота в Telegram по имени @pawcare_notify_bot',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF444444)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _generatedCode = null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF888888),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loadTelegramStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C6E49),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Проверить'),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}