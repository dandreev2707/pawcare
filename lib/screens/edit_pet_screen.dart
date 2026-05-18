import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class EditPetScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  String? _selectedSex;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.pet['name'] ?? '');
    _breedController = TextEditingController(text: widget.pet['breed'] ?? '');
    _selectedSex = widget.pet['sex'];
    if (widget.pet['birth_date'] != null) {
      try { _selectedDate = DateTime.parse(widget.pet['birth_date']); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите кличку питомца')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.updatePet(
      petId: widget.pet['id'],
      name: _nameController.text.trim(),
      breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
      birthDate: _selectedDate != null ? _selectedDate!.toIso8601String().split('T').first : null,
      sex: _selectedSex,
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result['success']) {
      context.pop(result['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Ошибка сохранения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text('Редактировать питомца',
            style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('Сохранить',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textField(controller: _nameController, hint: 'Кличка *', icon: Icons.pets),
            const SizedBox(height: 16),
            _textField(controller: _breedController, hint: 'Порода', icon: Icons.category_outlined),
            const SizedBox(height: 16),
            _label('Пол'),
            const SizedBox(height: 8),
            Row(children: [
              _sexButton('male', '♂ Мальчик'),
              const SizedBox(width: 12),
              _sexButton('female', '♀ Девочка'),
            ]),
            const SizedBox(height: 16),
            _label('Дата рождения'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputFill(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day.toString().padLeft(2,'0')}'
                          '.${_selectedDate!.month.toString().padLeft(2,'0')}'
                          '.${_selectedDate!.year}'
                        : 'Выбрать дату',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? AppColors.textPrimary(context)
                          : AppColors.textSecondary(context),
                      fontSize: 15,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить изменения',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({required TextEditingController controller,
      required String hint, required IconData icon}) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.inputFill(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(context)),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );

  Widget _sexButton(String value, String label) {
    final selected = _selectedSex == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSex = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.inputFill(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border(context)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary(context),
                fontWeight: FontWeight.w500,
              )),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary(context)));
}
