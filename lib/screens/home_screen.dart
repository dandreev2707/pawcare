import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getPets();
    if (result['success']) {
      setState(() {
        _pets = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePet(String petId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить питомца?'),
        content: const Text('Это действие нельзя отменить'),
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
      await ApiService.deletePet(petId);
      _loadPets();
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
                      Text('Мои питомцы',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B1B1B),
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2C6E49),
                        ),
                      )
                    : _pets.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadPets,
                            color: const Color(0xFF2C6E49),
                            child: ListView.builder(
                              itemCount: _pets.length,
                              itemBuilder: (ctx, i) =>
                                  _buildPetCard(_pets[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-pet');
          _loadPets();
        },
        backgroundColor: const Color(0xFF2C6E49),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить питомца',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.pets,
                size: 60, color: Color(0xFF2C6E49)),
          ),
          const SizedBox(height: 24),
          const Text('Питомцев пока нет',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B1B))),
          const SizedBox(height: 8),
          const Text(
            'Нажмите кнопку ниже\nчтобы добавить питомца',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5),
          ),
        ],
      ),
    );
  }

Widget _buildPetCard(Map<String, dynamic> pet) {
  final sex = pet['sex'] == 'male' ? '♂' :
              pet['sex'] == 'female' ? '♀' : '';
  return GestureDetector(
    onTap: () => context.push('/pet-detail', extra: pet),
    child: Container(
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: pet['photo_url'] != null
                ? Image.network(
                    '${ApiService.baseUrl}${pet['photo_url']}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.pets,
                        color: Color(0xFF2C6E49),
                        size: 28),
                  )
                : const Icon(Icons.pets,
                    color: Color(0xFF2C6E49), size: 28),
          ),
        ),
        title: Text(
          '${pet['name']} $sex',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1B1B1B)),
        ),
        subtitle: Text(
          pet['breed'] ?? 'Порода не указана',
          style: const TextStyle(
              color: Color(0xFF666666), fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_right,
                color: Color(0xFF2C6E49)),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red),
              onPressed: () => _deletePet(pet['id']),
            ),
          ],
        ),
      ),
    ),
  );
}
}