import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  String? _selectedSex;
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выбрать фото',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(
                  icon: Icons.camera_alt,
                  label: 'Камера',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80);
                    if (img != null) {
                      setState(() =>
                          _selectedImage = File(img.path));
                    }
                  },
                ),
                _photoOption(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80);
                    if (img != null) {
                      setState(() =>
                          _selectedImage = File(img.path));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                color: const Color(0xFF2C6E49), size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF444444))),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C6E49)),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите кличку питомца')),
      );
      return;
    }
    setState(() => _isLoading = true);

    final result = await ApiService.createPet(
      name: _nameController.text.trim(),
      breed: _breedController.text.trim().isEmpty
          ? null
          : _breedController.text.trim(),
      birthDate: _selectedDate != null
          ? _selectedDate!.toIso8601String().split('T')[0]
          : null,
      sex: _selectedSex,
    );

    if (!result['success']) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
      return;
    }

    // Загружаем фото если выбрано
    if (_selectedImage != null) {
      final petId = result['data']['id'];
      await ApiService.uploadPetPhoto(
        petId: petId,
        filePath: _selectedImage!.path,
      );
    }

    setState(() => _isLoading = false);
    if (mounted) context.pop();
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
        title: const Text('Новый питомец',
            style: TextStyle(
                color: Color(0xFF1B1B1B),
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: const Color(0xFF2C6E49), width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: Color(0xFF2C6E49), size: 32),
                            SizedBox(height: 4),
                            Text('Фото',
                                style: TextStyle(
                                    color: Color(0xFF2C6E49),
                                    fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _label('Кличка *'),
            const SizedBox(height: 8),
            _textField(
                controller: _nameController,
                hint: 'Например: Бублик',
                icon: Icons.pets),
            const SizedBox(height: 20),
            _label('Порода'),
            const SizedBox(height: 8),
            _textField(
                controller: _breedController,
                hint: 'Например: Лабрадор',
                icon: Icons.category_outlined),
            const SizedBox(height: 20),
            _label('Пол'),
            const SizedBox(height: 8),
            Row(children: [
              _sexButton('male', '♂ Мальчик'),
              const SizedBox(width: 12),
              _sexButton('female', '♀ Девочка'),
            ]),
            const SizedBox(height: 20),
            _label('Дата рождения'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE0E0E0)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF2C6E49)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Выбрать дату'
                        : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF1B1B1B),
                      fontSize: 15,
                    ),
                  ),
                ]),
              ),
            ),
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
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
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

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFAAAAAA)),
          prefixIcon:
              Icon(icon, color: const Color(0xFF2C6E49)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF2C6E49), width: 2)),
        ),
      );

  Widget _sexButton(String value, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedSex = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _selectedSex == value
                  ? const Color(0xFF2C6E49)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedSex == value
                    ? const Color(0xFF2C6E49)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _selectedSex == value
                        ? Colors.white
                        : const Color(0xFF666666),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}