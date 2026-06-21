import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  TextEditingController? _breedFieldController;
  String? _selectedSex;
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isLoading = false;

  static const _dogBreeds = [
    'Австралийская овчарка', 'Акита-ину', 'Аляскинский маламут',
    'Американский стаффордширский терьер', 'Бассет-хаунд', 'Бигль',
    'Бордер-колли', 'Боксёр', 'Бультерьер', 'Бордоский дог',
    'Веймаранер', 'Вельш-корги', 'Далматинец', 'Джек-рассел-терьер',
    'Доберман', 'Дворняга', 'Золотистый ретривер', 'Ирландский сеттер',
    'Кане-корсо', 'Кавказская овчарка', 'Китайская хохлатая',
    'Кокер-спаниель', 'Лабрадор ретривер', 'Левретка',
    'Мальтийская болонка', 'Мопс', 'Немецкая овчарка',
    'Немецкий шпиц', 'Немецкий дог', 'Ньюфаундленд',
    'Пекинес', 'Пудель', 'Померанский шпиц', 'Ротвейлер',
    'Русская борзая', 'Самоед', 'Сенбернар', 'Сиба-ину',
    'Скотч-терьер', 'Спрингер-спаниель', 'Такса', 'Терьер',
    'Той-терьер', 'Хаски', 'Чихуахуа', 'Шарпей',
    'Шотландская овчарка', 'Шнауцер', 'Йоркширский терьер',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выбрать фото',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(ctx))),
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
                        source: ImageSource.camera, imageQuality: 80);
                    if (img != null) {
                      setState(() => _selectedImage = File(img.path));
                    }
                  },
                ),
                _photoOption(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (img != null) {
                      setState(() => _selectedImage = File(img.path));
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
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context))),
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
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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

    final breedText = _breedFieldController?.text.trim() ?? '';
    final result = await ApiService.createPet(
      name: _nameController.text.trim(),
      breed: breedText.isEmpty ? null : breedText,
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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text('Новый питомец',
            style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
                            SizedBox(height: 4),
                            Text('Фото',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _label('Кличка *'),
            const SizedBox(height: 8),
            _textField(controller: _nameController, hint: 'Например: Бублик', icon: Icons.pets),
            const SizedBox(height: 20),
            _label('Порода'),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text.trim().isEmpty) return _dogBreeds;
                final q = value.text.toLowerCase();
                return _dogBreeds.where((b) => b.toLowerCase().contains(q));
              },
              onSelected: (_) {},
              fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
                _breedFieldController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Например: Лабрадор',
                    hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                    prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.card(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.border(context),
                        ),
                        itemBuilder: (_, i) {
                          final breed = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(breed),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              child: Row(
                                children: [
                                  const Icon(Icons.pets,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text(breed,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary(context))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Выбрать дату'
                        : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? AppColors.textSecondary(context)
                          : AppColors.textPrimary(context),
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Сохранить',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context)));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) =>
      TextField(
        controller: controller,
        style: TextStyle(color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary(context)),
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.inputFill(context),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      );

  Widget _sexButton(String value, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedSex = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _selectedSex == value
                  ? AppColors.primary
                  : AppColors.inputFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedSex == value
                    ? AppColors.primary
                    : AppColors.border(context),
              ),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _selectedSex == value
                        ? Colors.white
                        : AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}
