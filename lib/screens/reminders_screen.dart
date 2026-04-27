import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<dynamic> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getReminders();
    if (result['success']) {
      setState(() {
        _reminders = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReminder(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить напоминание?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteReminder(id);
      _loadReminders();
    }
  }

  void _showAddReminderDialog() async {
    // Сначала получим питомцев
    final petsResult = await ApiService.getPets();
    if (!petsResult['success'] || petsResult['data'].isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Сначала добавьте питомца')),
        );
      }
      return;
    }
    final pets = List<Map<String, dynamic>>.from(petsResult['data']);

    if (!mounted) return;

    String? selectedPetId = pets.first['id'];
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Новое напоминание',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Выбор питомца
                const Text('Питомец',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedPetId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: pets.map((pet) => DropdownMenuItem<String>(
                      value: pet['id'] as String,
                      child: Text(pet['name'] as String),
                    )).toList(),
                    onChanged: (v) => setModalState(() => selectedPetId = v),
                  ),
                ),
                const SizedBox(height: 16),

                // Название
                const Text('Название',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Например: Прививка от бешенства',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    filled: true,
                    fillColor: const Color(0xFFF4FAF6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2C6E49), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Дата
                const Text('Дата',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF2C6E49)),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = DateTime(
                        date.year, date.month, date.day,
                        selectedTime.hour, selectedTime.minute,
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF2C6E49), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Время
                const Text('Время',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF2C6E49)),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setModalState(() {
                        selectedTime = time;
                        selectedDate = DateTime(
                          selectedDate.year, selectedDate.month,
                          selectedDate.day, time.hour, time.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          color: Color(0xFF2C6E49), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty) return;
                      Navigator.pop(ctx);
                      await ApiService.createReminder(
                        petId: selectedPetId!,
                        title: titleController.text.trim(),
                        remindAt: selectedDate.toIso8601String(),
                      );
                      _loadReminders();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C6E49),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Сохранить',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(String? date) {
    if (date == null) return const Color(0xFF888888);
    try {
      final d = DateTime.parse(date);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0) return Colors.red;
      if (days <= 7) return const Color(0xFFE65100);
      if (days <= 30) return const Color(0xFFF9A825);
      return const Color(0xFF2C6E49);
    } catch (_) {
      return const Color(0xFF888888);
    }
  }

  String _getDaysText(String? date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      final days = d.difference(DateTime.now()).inDays;
      if (days < 0) return 'Просрочено на ${days.abs()} дн.';
      if (days == 0) return 'Сегодня!';
      if (days == 1) return 'Завтра';
      return 'Через $days дн.';
    } catch (_) {
      return '';
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'vaccination':
        return {'icon': Icons.vaccines, 'color': const Color(0xFF2C6E49), 'bg': const Color(0xFFE8F5EE)};
      case 'deworming':
        return {'icon': Icons.medication, 'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD)};
      case 'antiparasitic':
        return {'icon': Icons.bug_report, 'color': const Color(0xFF6A1B9A), 'bg': const Color(0xFFF3E5F5)};
      case 'vet_visit':
        return {'icon': Icons.local_hospital, 'color': const Color(0xFFC62828), 'bg': const Color(0xFFFFEBEE)};
      case 'custom':
        return {'icon': Icons.alarm, 'color': const Color(0xFFE65100), 'bg': const Color(0xFFFFF3E0)};
      default:
        return {'icon': Icons.note, 'color': const Color(0xFF555555), 'bg': const Color(0xFFF5F5F5)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Напоминания',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1B1B))),
                      Text('Предстоящие процедуры',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF666666))),
                    ],
                  ),
                  // Кнопка добавить
                  GestureDetector(
                    onTap: _showAddReminderDialog,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C6E49),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2C6E49)))
                    : _reminders.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadReminders,
                            color: const Color(0xFF2C6E49),
                            child: ListView.builder(
                              itemCount: _reminders.length,
                              itemBuilder: (ctx, i) =>
                                  _buildCard(_reminders[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.notifications_none,
                size: 50, color: Color(0xFF2C6E49)),
          ),
          const SizedBox(height: 20),
          const Text('Напоминаний нет',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B1B))),
          const SizedBox(height: 8),
          const Text(
            'Нажмите + чтобы добавить напоминание\nили добавьте медицинские записи с датой',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Color(0xFF666666), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> reminder) {
    final info = _getTypeInfo(reminder['record_type'] ?? 'custom');
    final urgencyColor = _getUrgencyColor(reminder['remind_at']);
    final daysText = _getDaysText(reminder['remind_at']);
    final isCustom = reminder['source'] == 'custom';
    final id = reminder['id'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: info['bg'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(info['icon'], color: info['color'], size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1B1B1B))),
                const SizedBox(height: 2),
                Text('🐾 ${reminder['pet_name'] ?? ''}',
                    style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 13)),
                const SizedBox(height: 2),
                Text(_formatDateTime(reminder['remind_at']),
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(daysText,
                    style: TextStyle(
                        color: urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              if (isCustom && id != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _deleteReminder(id),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }
}