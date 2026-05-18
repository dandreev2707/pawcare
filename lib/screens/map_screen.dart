import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class _PlaceCategory {
  final String type;
  final String label;
  final IconData icon;
  final Color color;

  const _PlaceCategory({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  bool _isLoading = false;
  bool _mapReady = false;
  List<Map<String, dynamic>> _places = [];
  Point? _userLocation;
  int _selectedCategoryIndex = 0;

  static const _defaultPoint = Point(latitude: 47.2085, longitude: 38.9371);

  static const _categories = [
    _PlaceCategory(
      type: 'vets',
      label: 'Ветклиники',
      icon: Icons.local_hospital,
      color: Color(0xFF2C6E49),
    ),
    _PlaceCategory(
      type: 'pet_store',
      label: 'Зоомагазины',
      icon: Icons.storefront,
      color: Color(0xFF1565C0),
    ),
    _PlaceCategory(
      type: 'grooming',
      label: 'Груминг',
      icon: Icons.content_cut,
      color: Color(0xFF7B1FA2),
    ),
    _PlaceCategory(
      type: 'pet_pharmacy',
      label: 'Зооаптеки',
      icon: Icons.local_pharmacy,
      color: Color(0xFFE65100),
    ),
    _PlaceCategory(
      type: 'dog_park',
      label: 'Площадки',
      icon: Icons.park,
      color: Color(0xFF558B2F),
    ),
  ];

  _PlaceCategory get _category => _categories[_selectedCategoryIndex];

  // Кеш мест по типу категории
  static final Map<String, List<Map<String, dynamic>>> _cachedPlaces = {};
  static final Map<String, DateTime> _cachedAtMap = {};

  // Кеш пин-иконок по цвету
  final Map<int, Uint8List> _pinCache = {};

  /// Цветной пин с хвостиком для мест на карте
  Future<Uint8List> _buildPin(Color color) async {
    final key = color.toARGB32();
    if (_pinCache.containsKey(key)) return _pinCache[key]!;

    const double size = 60;
    const double r = 19;
    const double cx = size / 2;
    const double cy = r + 4;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Тень
    canvas.drawCircle(
      Offset(cx + 1, cy + 2),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Хвостик
    final tail = Path()
      ..moveTo(cx - 7, cy + r - 3)
      ..lineTo(cx, cy + r + 12)
      ..lineTo(cx + 7, cy + r - 3)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
    canvas.drawPath(tail, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Заливка круга
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

    // Белая обводка
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Белый значок внутри (маленький)
    canvas.drawCircle(Offset(cx, cy), r * 0.38, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    _pinCache[key] = bytes;
    return bytes;
  }

  Future<bool> _ensurePermission() async {
    // Сначала разрешение — потом проверка GPS
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Разрешите геолокацию в настройках приложения'),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: Geolocator.openAppSettings,
          ),
        ));
      }
      return false;
    }
    if (perm == LocationPermission.denied) return false;

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Включите геолокацию на устройстве'),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: Geolocator.openLocationSettings,
          ),
        ));
      }
      return false;
    }

    return true;
  }

  Future<Point> _getUserLocation() async {
    try {
      if (!await _ensurePermission()) return _defaultPoint;

      // Сначала последнее известное положение — отвечает мгновенно
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return Point(latitude: last.latitude, longitude: last.longitude);
      }

      // Нет кеша — ждём GPS до 20 секунд, точность medium (быстрее high)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Point(latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      return _defaultPoint;
    }
  }

  Future<void> _initMap() async {
    setState(() => _isLoading = true);
    final userPoint = await _getUserLocation();
    setState(() => _userLocation = userPoint);

    if (_mapController != null) {
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: userPoint, zoom: 13),
        ),
        animation:
            const MapAnimation(type: MapAnimationType.smooth, duration: 1),
      );
    }
    await _searchPlaces(userPoint);

    // Уточняем GPS в фоне и обновляем пин если получили лучшую позицию
    _refineLocationInBackground(userPoint);
  }

  void _refineLocationInBackground(Point initial) async {
    try {
      if (!await _ensurePermission()) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      final refined = Point(latitude: pos.latitude, longitude: pos.longitude);
      // Обновляем пин только если координаты заметно изменились (>50м)
      final dist = Geolocator.distanceBetween(
        initial.latitude, initial.longitude,
        refined.latitude, refined.longitude,
      );
      if (dist > 50 && mounted) {
        setState(() => _userLocation = refined);
        await _applyPlaces(_places);
      }
    } catch (_) {}
  }

  Future<void> _searchPlaces(Point center, {bool forceRefresh = false}) async {
    final cacheKey = _category.type;

    if (!forceRefresh &&
        _cachedPlaces.containsKey(cacheKey) &&
        _cachedAtMap.containsKey(cacheKey) &&
        DateTime.now().difference(_cachedAtMap[cacheKey]!) <
            const Duration(minutes: 15)) {
      await _applyPlaces(_cachedPlaces[cacheKey]!);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.getVets(
      lat: center.latitude,
      lon: center.longitude,
      placeType: _category.type,
    );

    if (!result['success']) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${result['message']}')),
        );
      }
      return;
    }

    final List data = result['data'];
    final places = data.map((e) => Map<String, dynamic>.from(e)).toList();
    _cachedPlaces[cacheKey] = places;
    _cachedAtMap[cacheKey] = DateTime.now();
    await _applyPlaces(places);
  }

  Future<void> _applyPlaces(List<Map<String, dynamic>> places) async {
    final objects = <MapObject>[];
    // Местоположение пользователя рисует нативный слой Yandex (toggleUserLayer)
    final pinBytes = await _buildPin(_category.color);

    for (var i = 0; i < places.length; i++) {
      final place = places[i];
      final idx = i;
      final lat = (place['lat'] as num).toDouble();
      final lon = (place['lon'] as num).toDouble();
      if (lat == 0 && lon == 0) continue;

      objects.add(PlacemarkMapObject(
        mapId: MapObjectId('place_$i'),
        point: Point(latitude: lat, longitude: lon),
        opacity: 1,
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: BitmapDescriptor.fromBytes(pinBytes),
          scale: 1.2,
          // Кончик хвостика — географическая точка (y≈54 из 60)
          anchor: const Offset(0.5, 0.9),
        )),
        onTap: (p, pt) => _showPlaceInfo(places[idx]),
      ));
    }

    if (mounted) {
      setState(() {
        _places = places;
        _mapObjects
          ..clear()
          ..addAll(objects);
        _isLoading = false;
      });
    }
  }

  void _openRoute(Map<String, dynamic> place) async {
    final lat = place['lat'];
    final lon = place['lon'];
    final yandexUrl =
        Uri.parse('yandexmaps://maps.yandex.ru/?rtext=~$lat,$lon&rtt=auto');
    final browserUrl =
        Uri.parse('https://yandex.ru/maps/?rtext=~$lat,$lon&rtt=auto');

    if (await canLaunchUrl(yandexUrl)) {
      await launchUrl(yandexUrl);
    } else {
      await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showPlaceInfo(Map<String, dynamic> place) {
    final cat = _categoryForType(place['place_type'] as String? ?? _category.type);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'] ?? '',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(ctx)),
                    ),
                    Text(
                      cat.label,
                      style: TextStyle(
                          fontSize: 12,
                          color: cat.color,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _infoRow(ctx, Icons.location_on_outlined, place['address'] ?? ''),
            const SizedBox(height: 8),
            _infoRow(ctx, Icons.phone_outlined, place['phone'] ?? ''),
            const SizedBox(height: 8),
            _infoRow(ctx, Icons.access_time, place['hours'] ?? ''),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openRoute(place);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cat.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Построить маршрут',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  _PlaceCategory _categoryForType(String type) {
    return _categories.firstWhere(
      (c) => c.type == type,
      orElse: () => _categories[0],
    );
  }

  Widget _infoRow(BuildContext ctx, IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _category.color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: AppColors.textSecondary(ctx),
                  fontSize: 14,
                  height: 1.4)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          _category.label,
          style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_mapReady)
            IconButton(
              onPressed: _isLoading
                  ? null
                  : () => _searchPlaces(_userLocation ?? _defaultPoint,
                      forceRefresh: true),
              icon: Icon(Icons.refresh, color: _category.color),
            ),
        ],
      ),
      body: Column(children: [
        // Полоса категорий
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final selected = i == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () async {
                  if (i == _selectedCategoryIndex) return;
                  setState(() {
                    _selectedCategoryIndex = i;
                    _places = [];
                  });
                  await _searchPlaces(
                      _userLocation ?? _defaultPoint);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  decoration: BoxDecoration(
                    color: selected
                        ? cat.color
                        : cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon,
                          size: 15,
                          color: selected ? Colors.white : cat.color),
                      const SizedBox(width: 5),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Индикатор радиуса поиска
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: AppColors.bg(context),
          child: Row(children: [
            Icon(Icons.radar, size: 14, color: _category.color),
            const SizedBox(width: 5),
            Text(
              'Поиск в вашем городе',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500),
            ),
            if (_places.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('·', style: TextStyle(color: AppColors.textSecondary(context))),
              const SizedBox(width: 8),
              Text(
                'Найдено: ${_places.length}',
                style: TextStyle(
                    fontSize: 12,
                    color: _category.color,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ]),
        ),

        Expanded(
          child: Stack(children: [
            YandexMap(
              mapObjects: _mapObjects,
              onUserLocationAdded: (view) async {
                return view.copyWith(
                  accuracyCircle: view.accuracyCircle.copyWith(
                    fillColor: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    strokeColor: const Color(0xFF2979FF).withValues(alpha: 0.4),
                    strokeWidth: 1.5,
                  ),
                );
              },
              onMapCreated: (controller) async {
                _mapController = controller;
                await _mapController!.moveCamera(
                  CameraUpdate.newCameraPosition(
                    const CameraPosition(target: _defaultPoint, zoom: 13),
                  ),
                );
                setState(() => _mapReady = true);
                // Сначала запрашиваем разрешения, затем включаем слой Yandex
                final granted = await _ensurePermission();
                if (granted) {
                  await _mapController!.toggleUserLayer(visible: true);
                }
                await _initMap();
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _category.color),
                          const SizedBox(height: 12),
                          Text('Ищем ${_category.label.toLowerCase()}...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: _places.isNotEmpty ? 140 : 16,
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: () async {
                  if (_mapController == null) return;
                  // Берём позицию из нативного слоя Yandex, fallback на Geolocator
                  final yandexPos = await _mapController!.getUserCameraPosition();
                  final target = yandexPos?.target ?? _userLocation ?? _defaultPoint;
                  await _mapController!.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: target, zoom: 15),
                    ),
                    animation: const MapAnimation(
                        type: MapAnimationType.smooth, duration: 1),
                  );
                },
                backgroundColor: AppColors.card(context),
                foregroundColor: _category.color,
                child: const Icon(Icons.my_location),
              ),
            ),
            Positioned(
              right: 16,
              bottom: _places.isNotEmpty ? 200 : 80,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () async {
                      if (_mapController != null) {
                        final pos = await _mapController!.getCameraPosition();
                        await _mapController!.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                                target: pos.target, zoom: pos.zoom + 1),
                          ),
                        );
                      }
                    },
                    backgroundColor: AppColors.card(context),
                    child: Icon(Icons.add, color: _category.color),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () async {
                      if (_mapController != null) {
                        final pos = await _mapController!.getCameraPosition();
                        await _mapController!.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                                target: pos.target, zoom: pos.zoom - 1),
                          ),
                        );
                      }
                    },
                    backgroundColor: AppColors.card(context),
                    child: Icon(Icons.remove, color: _category.color),
                  ),
                ],
              ),
            ),
          ]),
        ),

        // Горизонтальный список мест
        if (_places.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _places.length,
              itemBuilder: (ctx, i) {
                final place = _places[i];
                return GestureDetector(
                  onTap: () {
                    _showPlaceInfo(place);
                    final lat = (place['lat'] as num).toDouble();
                    final lon = (place['lon'] as num).toDouble();
                    _mapController?.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: Point(latitude: lat, longitude: lon),
                          zoom: 15,
                        ),
                      ),
                      animation: const MapAnimation(
                          type: MapAnimationType.smooth, duration: 1),
                    );
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(_category.icon,
                              color: _category.color, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place['name'] ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textPrimary(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          place['address'] ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(children: [
                          Icon(Icons.directions,
                              color: _category.color, size: 12),
                          const SizedBox(width: 4),
                          Text('Маршрут',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _category.color,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
}
