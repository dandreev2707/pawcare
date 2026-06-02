import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class HeatCycleScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const HeatCycleScreen({super.key, required this.petId, required this.petName});

  @override
  State<HeatCycleScreen> createState() => _HeatCycleScreenState();
}

class _HeatCycleScreenState extends State<HeatCycleScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _cycles = [];
  bool _isLoading = true;
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();

  static const _pink = Color(0xFFE91E8C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getHeatCycles(widget.petId);
    if (result['success']) {
      setState(() {
        _cycles = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? get _activeCycle {
    for (final c in _cycles) {
      if (c['ended_at'] == null) return c;
    }
    return null;
  }

  DateTime? get _nextPredicted {
    final completed = _cycles.where((c) => c['ended_at'] != null).toList();
    if (completed.isEmpty) return null;

    final sorted = List.from(completed)
      ..sort((a, b) => (a['started_at'] as String).compareTo(b['started_at'] as String));

    if (sorted.length == 1) {
      return DateTime.parse(sorted.last['started_at']).add(const Duration(days: 180));
    }

    int totalDays = 0;
    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]['started_at']);
      final curr = DateTime.parse(sorted[i]['started_at']);
      totalDays += curr.difference(prev).inDays;
    }
    final avgInterval = (totalDays / (sorted.length - 1)).round();
    return DateTime.parse(sorted.last['started_at']).add(Duration(days: avgInterval));
  }

  int? get _avgDuration {
    final completed = _cycles.where((c) => c['ended_at'] != null).toList();
    if (completed.isEmpty) return null;
    int total = 0;
    for (final c in completed) {
      final start = DateTime.parse(c['started_at']);
      final end = DateTime.parse(c['ended_at']);
      total += end.difference(start).inDays;
    }
    return (total / completed.length).round();
  }

  // Проверяем, входит ли день в диапазон какого-либо цикла
  bool _isDayCycle(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (final c in _cycles) {
      final start = _dayOnly(DateTime.parse(c['started_at']));
      final end = c['ended_at'] != null
          ? _dayOnly(DateTime.parse(c['ended_at']))
          : _dayOnly(DateTime.now());
      if (!d.isBefore(start) && !d.isAfter(end)) return true;
    }
    return false;
  }

  // Первый день цикла
  bool _isCycleStart(DateTime day) {
    final d = _dayOnly(day);
    return _cycles.any((c) => _dayOnly(DateTime.parse(c['started_at'])) == d);
  }

  // Последний день цикла (только завершённого)
  bool _isCycleEnd(DateTime day) {
    final d = _dayOnly(day);
    return _cycles.any((c) =>
        c['ended_at'] != null && _dayOnly(DateTime.parse(c['ended_at'])) == d);
  }

  bool _isPredicted(DateTime day) {
    final predicted = _nextPredicted;
    if (predicted == null) return false;
    return _dayOnly(day) == _dayOnly(predicted);
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _startCycle() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final result = await ApiService.addHeatCycle(petId: widget.petId, startedAt: today);
    if (result['success']) {
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'] ?? 'Ошибка')));
    }
  }

  Future<void> _endCycle(String cycleId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final result = await ApiService.updateHeatCycle(
        petId: widget.petId, cycleId: cycleId, endedAt: today);
    if (result['success']) {
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'] ?? 'Ошибка')));
    }
  }

  Future<void> _editCycle(Map<String, dynamic> cycle) async {
    DateTime startDate = DateTime.parse(cycle['started_at']);
    DateTime? endDate = cycle['ended_at'] != null
        ? DateTime.parse(cycle['ended_at'])
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Редактировать цикл',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(ctx))),
              const SizedBox(height: 20),

              // Дата начала
              Text('Дата начала',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(ctx))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: _pink),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => startDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(ctx),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(ctx)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: _pink, size: 18),
                    const SizedBox(width: 10),
                    Text(_fmtDate(startDate),
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary(ctx))),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Дата окончания
              Text('Дата окончания',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(ctx))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate,
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: _pink),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => endDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(ctx),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: endDate != null
                            ? _pink
                            : AppColors.border(ctx)),
                  ),
                  child: Row(children: [
                    Icon(Icons.event_available_outlined,
                        color: endDate != null
                            ? _pink
                            : AppColors.textSecondary(ctx),
                        size: 18),
                    const SizedBox(width: 10),
                    Text(
                      endDate != null
                          ? _fmtDate(endDate!)
                          : 'Не указана (течка ещё идёт)',
                      style: TextStyle(
                          fontSize: 15,
                          color: endDate != null
                              ? AppColors.textPrimary(ctx)
                              : AppColors.textSecondary(ctx)),
                    ),
                    if (endDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setModal(() => endDate = null),
                        child: Icon(Icons.close,
                            size: 18,
                            color: AppColors.textSecondary(ctx)),
                      ),
                    ],
                  ]),
                ),
              ),

              // Длительность — показываем если обе даты выбраны
              if (endDate != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.timelapse, size: 15,
                      color: AppColors.textSecondary(ctx)),
                  const SizedBox(width: 6),
                  Text(
                    () {
                      final days = endDate!.difference(startDate).inDays;
                      return 'Длительность: $days ${_dayWord(days)}';
                    }(),
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(ctx)),
                  ),
                ]),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    // Валидация
                    if (endDate != null && endDate!.isBefore(startDate)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Дата окончания не может быть раньше начала')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final result = await ApiService.updateHeatCycle(
                      petId: widget.petId,
                      cycleId: cycle['id'],
                      startedAt: startDate.toIso8601String().split('T').first,
                      endedAt: endDate?.toIso8601String().split('T').first,
                    );
                    if (result['success']) {
                      _load();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(result['message'] ?? 'Ошибка')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Сохранить',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _deleteCycle(String cycleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteHeatCycle(petId: widget.petId, cycleId: cycleId);
      _load();
    }
  }

  String _fmt(String s) {
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return s;
    }
  }

  String _dayWord(int n) {
    final abs = n.abs() % 100;
    final last = abs % 10;
    if (abs >= 11 && abs <= 19) return 'дней';
    if (last == 1) return 'день';
    if (last >= 2 && last <= 4) return 'дня';
    return 'дней';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.petName,
                style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('Календарь течек',
                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _pink,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: _pink,
          tabs: const [
            Tab(text: 'Список'),
            Tab(text: 'Календарь'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListTab(),
                _buildCalendarTab(isDark),
              ],
            ),
    );
  }

  // ── Вкладка «Список» ────────────────────────────────
  Widget _buildListTab() {
    final active = _activeCycle;
    final predicted = _nextPredicted;
    final avgDur = _avgDuration;

    return RefreshIndicator(
      onRefresh: _load,
      color: _pink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(active, predicted, avgDur),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: active == null
                  ? ElevatedButton.icon(
                      onPressed: _startCycle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Начать течку',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _endCycle(active['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _pink,
                        side: const BorderSide(color: _pink),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Завершить течку',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
            ),
            const SizedBox(height: 28),
            Text('История циклов',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context))),
            const SizedBox(height: 12),
            if (_cycles.isEmpty)
              _buildEmpty()
            else
              ..._cycles.map((c) => _buildCycleItem(c)),
          ],
        ),
      ),
    );
  }

  // ── Вкладка «Календарь» ─────────────────────────────
  Widget _buildCalendarTab(bool isDark) {
    final predicted = _nextPredicted;
    final active = _activeCycle;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: TableCalendar(
              locale: 'ru_RU',
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary(context)),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: AppColors.textPrimary(context)),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: AppColors.textPrimary(context)),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  border: Border.all(color: _pink, width: 1.5),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.bold),
                defaultTextStyle: TextStyle(color: AppColors.textPrimary(context)),
                weekendTextStyle:
                    TextStyle(color: AppColors.textSecondary(context)),
                outsideTextStyle:
                    TextStyle(color: AppColors.textSecondary(context).withValues(alpha: 0.4)),
              ),
              onPageChanged: (day) => setState(() => _focusedDay = day),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, focused) => _buildCalendarDay(day),
                todayBuilder: (ctx, day, focused) => _buildCalendarDay(day, isToday: true),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Легенда
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Обозначения',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context))),
                const SizedBox(height: 10),
                _legendItem(
                  widget: _miniCircle(filled: true),
                  label: 'Начало / конец течки',
                ),
                const SizedBox(height: 8),
                _legendItem(
                  widget: _miniCircle(soft: true),
                  label: 'Дни течки',
                ),
                const SizedBox(height: 8),
                _legendItem(
                  widget: _miniCircle(predicted: true),
                  label: 'Ожидаемая следующая течка',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Подсказка о прогнозе
          if (predicted != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pink.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.auto_awesome, color: _pink, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _predictedLabel(predicted),
                    style: const TextStyle(
                        color: _pink, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),

          if (active != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_pink, _pink.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Text('🌸', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Течка активна с ${_fmt(active['started_at'])}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, {bool isToday = false}) {
    final inCycle = _isDayCycle(day);
    final isStart = _isCycleStart(day);
    final isEnd   = _isCycleEnd(day);
    final isPred  = _isPredicted(day);
    final isAnchor = isStart || isEnd; // дни с заполненным кружком

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAnchor
                ? _pink
                : inCycle
                    ? _pink.withValues(alpha: 0.18)
                    : isToday
                        ? _pink.withValues(alpha: 0.12)
                        : null,
            border: isToday && !inCycle
                ? Border.all(color: _pink, width: 1.5)
                : isPred && !inCycle
                    ? Border.all(color: _pink.withValues(alpha: 0.5), width: 1.5)
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isAnchor || isToday ? FontWeight.bold : FontWeight.normal,
              color: isAnchor
                  ? Colors.white
                  : inCycle
                      ? _pink
                      : AppColors.textPrimary(context),
            ),
          ),
        ),
        // Точка — только для прогноза
        const SizedBox(height: 2),
        if (isPred && !inCycle)
          Container(
            width: 4, height: 4,
            decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.6), shape: BoxShape.circle),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  Widget _miniCircle({bool filled = false, bool soft = false, bool predicted = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? _pink
                : soft
                    ? _pink.withValues(alpha: 0.18)
                    : null,
            border: predicted
                ? Border.all(color: _pink.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text('7',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: filled
                    ? Colors.white
                    : soft
                        ? _pink
                        : AppColors.textPrimary(context),
              )),
        ),
        const SizedBox(height: 2),
        if (predicted)
          Container(
            width: 4, height: 4,
            decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.6), shape: BoxShape.circle),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  Widget _legendItem({required Widget widget, required String label}) {
    return Row(children: [
      widget,
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
    ]);
  }

  String _predictedLabel(DateTime predicted) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(predicted.year, predicted.month, predicted.day);
    final days = target.difference(today).inDays;
    if (days < 0) return 'Ожидалась ${(-days)} ${_dayWord(-days)} назад (${_fmt(predicted.toIso8601String())})';
    if (days == 0) return 'Ожидается сегодня';
    if (days == 1) return 'Ожидается завтра';
    return 'Следующая примерно через $days ${_dayWord(days)} (${_fmt(predicted.toIso8601String())})';
  }

  Widget _buildStatusCard(
      Map<String, dynamic>? active, DateTime? predicted, int? avgDur) {
    if (active != null) {
      final start = DateTime.parse(active['started_at']);
      final days = DateTime.now().difference(start).inDays;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_pink, Color(0xFFFF6BB3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🌸', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Течка активна',
                    style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Начало: ${_fmt(active['started_at'])}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Продолжается $days ${_dayWord(days)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite_outline, color: _pink, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Течки нет',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context))),
                  if (predicted != null)
                    Text(_predictedLabel(predicted),
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context))),
                ],
              ),
            ),
          ]),
          if (avgDur != null) ...[
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.timelapse, size: 16, color: AppColors.textSecondary(context)),
              const SizedBox(width: 6),
              Text('Средняя длительность: $avgDur ${_dayWord(avgDur)}',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary(context))),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: AppColors.card(context), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Text('🌸', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Записей пока нет',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context))),
        const SizedBox(height: 4),
        Text('Нажмите кнопку выше\nчтобы начать отслеживание',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
      ]),
    );
  }

  Widget _buildCycleItem(Map<String, dynamic> cycle) {
    final isActive = cycle['ended_at'] == null;
    final start = DateTime.parse(cycle['started_at']);
    final int? durationDays = isActive
        ? null
        : DateTime.parse(cycle['ended_at']).difference(start).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: _pink, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: isActive ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isActive ? Icons.favorite : Icons.favorite_border,
              color: _pink, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_fmt(cycle['started_at']),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary(context))),
                if (!isActive) ...[
                  Text(' — ',
                      style: TextStyle(color: AppColors.textSecondary(context))),
                  Text(_fmt(cycle['ended_at']),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary(context))),
                ],
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _pink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('активна',
                        style: TextStyle(
                            color: _pink,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              if (durationDays != null)
                Text('$durationDays ${_dayWord(durationDays)}',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary(context))),
              if (cycle['notes'] != null &&
                  (cycle['notes'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(cycle['notes'],
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context))),
                ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editCycle(cycle),
              icon: Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary(context), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteCycle(cycle['id']),
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ]),
    );
  }
}
