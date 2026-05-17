import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/api_service.dart';

class HealthScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const HealthScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  List<dynamic> _records = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    final result = await ApiService.exportHealthPdf(widget.petId);
    setState(() => _isExporting = false);

    if (!mounted) return;

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Ошибка экспорта')),
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/health_${widget.petName}.pdf');
      await file.writeAsBytes(result['bytes'] as List<int>);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть PDF')),
        );
      }
    }
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getHealthRecords(widget.petId);
    if (result['success']) {
      setState(() {
        _records = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'vaccination':
        return {
          'icon': Icons.vaccines,
          'color': const Color(0xFF2C6E49),
          'bg': const Color(0xFFE8F5EE),
          'label': 'Вакцинация',
        };
      case 'deworming':
        return {
          'icon': Icons.medication,
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'label': 'Дегельминтизация',
        };
      case 'antiparasitic':
        return {
          'icon': Icons.bug_report,
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
          'label': 'От паразитов',
        };
      case 'vet_visit':
        return {
          'icon': Icons.local_hospital,
          'color': const Color(0xFFC62828),
          'bg': const Color(0xFFFFEBEE),
          'label': 'Визит к ветеринару',
        };
      default:
        return {
          'icon': Icons.note,
          'color': const Color(0xFF555555),
          'bg': const Color(0xFFF5F5F5),
          'label': 'Запись',
        };
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.petName,
              style: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              'Медицинский журнал',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isExporting ? null : _exportPdf,
            icon: _isExporting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF2C6E49)))
                : const Icon(Icons.picture_as_pdf_outlined,
                    color: Color(0xFF2C6E49)),
            tooltip: 'Экспорт PDF',
          ),
          IconButton(
            onPressed: () => context.push(
              '/weight/${widget.petId}/${Uri.encodeComponent(widget.petName)}',
            ),
            icon: const Icon(
              Icons.monitor_weight_outlined,
              color: Color(0xFF2C6E49),
            ),
            tooltip: 'Вес',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2C6E49),
              ),
            )
          : _records.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  color: const Color(0xFF2C6E49),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _records.length,
                    itemBuilder: (ctx, i) =>
                        _buildRecordCard(_records[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-health/${widget.petId}');
          _loadRecords();
        },
        backgroundColor: const Color(0xFF2C6E49),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Добавить запись',
          style: TextStyle(fontWeight: FontWeight.w600),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 50,
              color: Color(0xFF2C6E49),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Записей пока нет',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте первую запись\nо здоровье питомца',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
  final info = _getTypeInfo(record['record_type']);
  return Dismissible(
    key: Key(record['id']),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) async {
      return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Удалить запись?'),
          content: Text(
              'Запись "${record['title']}" будет удалена без возможности восстановления.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена',
                  style: TextStyle(color: Color(0xFF666666))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    },
    onDismissed: (_) async {
      await ApiService.deleteHealthRecord(
        petId: widget.petId,
        recordId: record['id'],
      );
      _loadRecords();
    },
    background: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Удалить',
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: info['bg'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(info['label'],
                            style: TextStyle(
                                color: info['color'],
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(record['record_date'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(record['title'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1B1B1B))),
                  if (record['description'] != null &&
                      record['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(record['description'],
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 13)),
                  ],
                  if (record['next_date'] != null &&
                      record['next_date'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 13, color: Color(0xFF2C6E49)),
                      const SizedBox(width: 4),
                      Text('Следующий раз: ${record['next_date']}',
                          style: const TextStyle(
                              color: Color(0xFF2C6E49),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ],
                  const SizedBox(height: 4),
                  const Text('← свайп для удаления',
                      style: TextStyle(
                          color: Color(0xFFCCCCCC), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}