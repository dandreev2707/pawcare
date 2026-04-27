import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

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
  List<Map<String, dynamic>> _clinics = [];
  Point? _userLocation;

  // Таганрог по умолчанию
  static const _defaultPoint = Point(latitude: 47.2085, longitude: 38.9371);

  Future<Point> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _defaultPoint;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _defaultPoint;
      }
      if (permission == LocationPermission.deniedForever) return _defaultPoint;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
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
        animation: const MapAnimation(
            type: MapAnimationType.smooth, duration: 1),
      );
    }
    await _searchClinics(userPoint);
  }

  Future<void> _searchClinics(Point center) async {
    setState(() => _isLoading = true);

    final result = await ApiService.getVets(
      lat: center.latitude,
      lon: center.longitude,
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
    final clinics = data.map((e) => Map<String, dynamic>.from(e)).toList();
    final objects = <MapObject>[];

    // Маркер пользователя
    if (_userLocation != null) {
      objects.add(PlacemarkMapObject(
        mapId: const MapObjectId('user_location'),
        point: _userLocation!,
        opacity: 1,
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage(
              'packages/yandex_mapkit/lib/assets/yandex_logo.png'),
          scale: 2.0,
        )),
      ));
    }

    // Маркеры клиник
    for (var i = 0; i < clinics.length; i++) {
      final clinic = clinics[i];
      final idx = i;
      final lat = (clinic['lat'] as num).toDouble();
      final lon = (clinic['lon'] as num).toDouble();
      if (lat == 0 && lon == 0) continue;

      objects.add(PlacemarkMapObject(
        mapId: MapObjectId('clinic_$i'),
        point: Point(latitude: lat, longitude: lon),
        opacity: 1,
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage(
              'packages/yandex_mapkit/lib/assets/yandex_logo.png'),
          scale: 1.5,
        )),
        onTap: (_, __) => _showClinicInfo(clinics[idx]),
      ));
    }

    setState(() {
      _clinics = clinics;
      _mapObjects
        ..clear()
        ..addAll(objects);
      _isLoading = false;
    });
  }

  void _openRoute(Map<String, dynamic> clinic) async {
    final lat = clinic['lat'];
    final lon = clinic['lon'];
    // Открываем маршрут через Яндекс.Навигатор или браузер
    final yandexUrl = Uri.parse(
        'yandexmaps://maps.yandex.ru/?rtext=~$lat,$lon&rtt=auto');
    final browserUrl = Uri.parse(
        'https://yandex.ru/maps/?rtext=~$lat,$lon&rtt=auto');

    if (await canLaunchUrl(yandexUrl)) {
      await launchUrl(yandexUrl);
    } else {
      await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showClinicInfo(Map<String, dynamic> clinic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital,
                    color: Color(0xFF2C6E49)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(clinic['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1B1B))),
              ),
            ]),
            const SizedBox(height: 16),
            _infoRow(Icons.location_on_outlined, clinic['address'] ?? ''),
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, clinic['phone'] ?? ''),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, clinic['hours'] ?? ''),
            const SizedBox(height: 20),
            // Кнопка маршрута
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openRoute(clinic);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C6E49),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Построить маршрут',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF2C6E49), size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF444444), fontSize: 14, height: 1.4)),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FAF6),
        elevation: 0,
        title: const Text('Ветклиники на карте',
            style: TextStyle(
                color: Color(0xFF1B1B1B), fontWeight: FontWeight.bold)),
        actions: [
          if (_mapReady)
            IconButton(
              onPressed: _isLoading
                  ? null
                  : () => _searchClinics(
                      _userLocation ?? _defaultPoint),
              icon: const Icon(Icons.refresh, color: Color(0xFF2C6E49)),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            YandexMap(
              mapObjects: _mapObjects,
              onMapCreated: (controller) async {
                _mapController = controller;
                await _mapController!.moveCamera(
                  CameraUpdate.newCameraPosition(
                    const CameraPosition(
                        target: _defaultPoint, zoom: 13),
                  ),
                );
                setState(() => _mapReady = true);
                await _initMap();
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFF2C6E49)),
                          SizedBox(height: 12),
                          Text('Ищем ветклиники...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Кнопка моего местоположения
            Positioned(
              right: 16,
              bottom: _clinics.isNotEmpty ? 140 : 16,
              child: FloatingActionButton.small(
                onPressed: () async {
                  if (_userLocation != null && _mapController != null) {
                    await _mapController!.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                            target: _userLocation!, zoom: 14),
                      ),
                      animation: const MapAnimation(
                          type: MapAnimationType.smooth, duration: 1),
                    );
                  }
                },
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2C6E49),
                child: const Icon(Icons.my_location),
              ),
            ),
          ]),
        ),
        // Карточки клиник снизу
        if (_clinics.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              itemCount: _clinics.length,
              itemBuilder: (ctx, i) {
                final clinic = _clinics[i];
                return GestureDetector(
                  onTap: () {
                    _showClinicInfo(clinic);
                    final lat = (clinic['lat'] as num).toDouble();
                    final lon = (clinic['lon'] as num).toDouble();
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.local_hospital,
                              color: Color(0xFF2C6E49), size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(clinic['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1B1B1B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(clinic['address'] ?? '',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF666666)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.directions,
                              color: Color(0xFF2C6E49), size: 12),
                          const SizedBox(width: 4),
                          const Text('Маршрут',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2C6E49),
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