import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AddHealthScreen extends StatefulWidget {
  final String petId;

  const AddHealthScreen({super.key, required this.petId});

  @override
  State<AddHealthScreen> createState() => _AddHealthScreenState();
}

class _AddHealthScreenState extends State<AddHealthScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'vaccination';
  DateTime? _recordDate;
  DateTime? _nextDate;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _types = [
    {
      'value': 'vaccination',
      'label': 'Вакцинация',
      'icon': Icons.vaccines
    },
    {
      'value': 'deworming',
      'label': 'Дегельминтизация',
      'icon': Icons.medication
    },
    {
      'value': 'antiparasitic',
      'label': 'От паразитов',
      'icon': Icons.bug_report
    },
    {
      'value': 'vet_visit',
      'label': 'Визит к ветеринару',
      'icon': Icons.local_hospital
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isNext) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2C6E49),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        if (isNext) {
          _nextDate = date;
        } else {
          _recordDate = date;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Выбрать дату';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _toIso(DateTime date) =>
      date.toIso8601String().split('T')[0];

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название')),
      );
      return;
    }
    if (_recordDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату записи')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.addHealthRecord(
      petId: widget.petId,
      recordType: _selectedType,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      recordDate: _toIso(_recordDate!),
      nextDate: _nextDate != null ? _toIso(_nextDate!) : null,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) context.pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FAF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1B1B1B)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Новая запись',
            style: TextStyle(
                color: Color(0xFF1B1B1B),
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Тип записи'),
            const SizedBox(height: 12),
            // Выбор типа
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: _types.map((t) {
                final selected = _selectedType == t['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedType = t['value']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2C6E49)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2C6E49)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t['icon'],
                            size: 18,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF666666)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF666666),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _label('Название *'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Например: Комплексная вакцина',
                Icons.title,
              ),
            ),
            const SizedBox(height: 20),
            _label('Описание'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputDecoration(
                'Препарат, доза, врач...',
                Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 20),
            _label('Дата процедуры *'),
            const SizedBox(height: 8),
            _datePicker(_recordDate, false),
            const SizedBox(height: 20),
            _label('Следующий раз (необязательно)'),
            const SizedBox(height: 8),
            _datePicker(_nextDate, true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C6E49),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Сохранить',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1B1B)));

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        prefixIcon: Icon(icon, color: const Color(0xFF2C6E49)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF2C6E49), width: 2),
        ),
      );

  Widget _datePicker(DateTime? date, bool isNext) =>
      GestureDetector(
        onTap: () => _pickDate(isNext),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF2C6E49)),
              const SizedBox(width: 12),
              Text(
                _formatDate(date),
                style: TextStyle(
                  color: date == null
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF1B1B1B),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
}