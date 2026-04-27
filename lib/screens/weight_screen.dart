import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class WeightScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const WeightScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getWeightLogs(widget.petId);
    if (result['success']) {
      setState(() {
        _logs = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWeight() async {
    final text = _weightController.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(text);

    if (weight == null || weight <= 0 || weight > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Введите корректный вес (например: 4.5)')),
      );
      return;
    }

    Navigator.pop(context);
    _weightController.clear();

    final result = await ApiService.addWeight(
      petId: widget.petId,
      weightKg: weight,
    );

    if (result['success']) {
      _loadLogs();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Добавить измерение',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Введите текущий вес питомца',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например: 4.5',
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.monitor_weight_outlined,
                    color: Color(0xFF2C6E49)),
                suffixText: 'кг',
                suffixStyle: const TextStyle(
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _addWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C6E49),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Данные для графика
  List<FlSpot> _buildSpots() {
    if (_logs.isEmpty) return [];
    final reversed = _logs.reversed.toList();
    return List.generate(reversed.length, (i) {
      final w = (reversed[i]['weight_kg'] as num).toDouble();
      return FlSpot(i.toDouble(), w);
    });
  }

  // Минимальный и максимальный вес
  double get _minY {
    if (_logs.isEmpty) return 0;
    final weights =
        _logs.map((l) => (l['weight_kg'] as num).toDouble()).toList();
    return (weights.reduce((a, b) => a < b ? a : b) - 1)
        .clamp(0, double.infinity);
  }

  double get _maxY {
    if (_logs.isEmpty) return 10;
    final weights =
        _logs.map((l) => (l['weight_kg'] as num).toDouble()).toList();
    return weights.reduce((a, b) => a > b ? a : b) + 1;
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    final lastWeight = _logs.isNotEmpty
        ? '${(_logs.first['weight_kg'] as num).toStringAsFixed(1)} кг'
        : '—';

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
              'Динамика веса',
              style: TextStyle(
                  color: Color(0xFF666666), fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2C6E49)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Карточка текущего веса
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C6E49),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monitor_weight_outlined,
                            color: Colors.white, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Текущий вес',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13),
                            ),
                            Text(
                              lastWeight,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // График
                  if (spots.length >= 2) ...[
                    const Text(
                      'График веса',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
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
                      child: LineChart(
                        LineChartData(
                          minY: _minY,
                          maxY: _maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: const Color(0xFFEEEEEE),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (v, _) => Text(
                                  '${v.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF888888)),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  final reversed =
                                      _logs.reversed.toList();
                                  if (i < 0 ||
                                      i >= reversed.length)
                                    return const Text('');
                                  return Text(
                                    _formatDate(reversed[i]
                                        ['measured_at']),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF888888)),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFF2C6E49),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (s, p, b, i) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFF2C6E49),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF2C6E49)
                                    .withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // История измерений
                  const Text(
                    'История измерений',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_logs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.monitor_weight_outlined,
                              size: 48,
                              color: Color(0xFF2C6E49)),
                          SizedBox(height: 12),
                          Text(
                            'Измерений пока нет',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1B1B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Нажмите кнопку ниже\nчтобы добавить вес',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._logs.map((log) => _buildLogItem(log)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2C6E49),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить вес',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    String dateStr = '';
    try {
      final d = DateTime.parse(log['measured_at']);
      dateStr =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monitor_weight_outlined,
                color: Color(0xFF2C6E49), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              dateStr,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
          Text(
            '${(log['weight_kg'] as num).toStringAsFixed(1)} кг',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C6E49),
            ),
          ),
        ],
      ),
    );
  }
}