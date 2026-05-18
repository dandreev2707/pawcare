import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';


class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late Map<String, dynamic> _pet;
  bool _uploadingPhoto = false;
  int _photoVersion = 0;

  @override
  void initState() {
    super.initState();
    _pet = Map<String, dynamic>.from(widget.pet);
  }

  String _calcAge() {
    if (_pet['birth_date'] == null) return 'Возраст не указан';
    try {
      final birth = DateTime.parse(_pet['birth_date']);
      final now = DateTime.now();
      int years = now.year - birth.year;
      int months = now.month - birth.month;
      if (months < 0) { years--; months += 12; }
      if (years == 0) return '$months мес.';
      return '$years л. $months мес.';
    } catch (_) {
      return 'Возраст не указан';
    }
  }

  Future<void> _changePhoto() async {
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
            Text('Изменить фото',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(ctx))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(ctx, Icons.camera_alt, 'Камера',
                    ImageSource.camera, picker),
                _photoOption(ctx, Icons.photo_library, 'Галерея',
                    ImageSource.gallery, picker),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(BuildContext ctx, IconData icon, String label,
      ImageSource source, ImagePicker picker) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        final img = await picker.pickImage(
            source: source, imageQuality: 80);
        if (img == null) return;

        setState(() => _uploadingPhoto = true);
        final result = await ApiService.uploadPetPhoto(
          petId: _pet['id'],
          filePath: img.path,
        );
          if (result['success']) {
          final newUrl = result['data']['photo_url'] as String;
          imageCache.clear();
          imageCache.clearLiveImages();
          setState(() {
            _pet['photo_url'] = newUrl;
            _photoVersion++;
            _uploadingPhoto = false;
          });
        } else {
          setState(() => _uploadingPhoto = false);
        }
      },
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                color: const Color(0xFF2C6E49), size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary(ctx))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sex = _pet['sex'] == 'male' ? '♂ Мальчик' :
                _pet['sex'] == 'female' ? '♀ Девочка' : 'Пол не указан';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2C6E49),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () async {
                  final updated = await context.push<Map<String, dynamic>>(
                    '/edit-pet',
                    extra: _pet,
                  );
                  if (updated != null) {
                    setState(() => _pet = Map<String, dynamic>.from(updated));
                  }
                },
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: _uploadingPhoto
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt,
                        color: Colors.white),
                onPressed: _uploadingPhoto ? null : _changePhoto,
                tooltip: 'Изменить фото',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _pet['photo_url'] != null
                  ? Image.network(
                      _buildPhotoUrl(_pet['photo_url'] as String),
                      key: ValueKey('${_pet['photo_url']}_$_photoVersion'),
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _defaultAvatar(),
                      errorBuilder: (_, error, __) {
                        debugPrint('Фото не загружено: $error');
                        return _defaultAvatar();
                      },
                    )
                  : _defaultAvatar(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pet['name'] ?? '',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pet['breed'] ?? 'Порода не указана',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    _infoCard(
                        Icons.cake_outlined, 'Возраст', _calcAge()),
                    const SizedBox(width: 12),
                    _infoCard(Icons.pets, 'Пол', sex),
                  ]),
                  const SizedBox(height: 32),
                  _actionButton(
                    icon: Icons.medical_services_outlined,
                    label: 'Медицинский журнал',
                    onTap: () => context.push(
                      '/health/${_pet['id']}/${Uri.encodeComponent(_pet['name'])}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Трекинг веса',
                    onTap: () => context.push(
                      '/weight/${_pet['id']}/${Uri.encodeComponent(_pet['name'])}',
                    ),
                  ),
                  if (_pet['sex'] == 'female') ...[
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.favorite_outline,
                      label: 'Календарь течек',
                      iconColor: const Color(0xFFE91E8C),
                      onTap: () => context.push(
                        '/heat-cycles/${_pet['id']}/${Uri.encodeComponent(_pet['name'])}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildPhotoUrl(String? url) {
    if (url == null) return '';
    return url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
  }

  Widget _defaultAvatar() => Container(
    color: const Color(0xFF2C6E49),
    child: const Center(
      child: Icon(Icons.pets, size: 100, color: Colors.white54),
    ),
  );

  Widget _infoCard(IconData icon, String label, String value) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary(context))),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context))),
            ],
          ),
        ),
      );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context))),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ]),
        ),
      );
}