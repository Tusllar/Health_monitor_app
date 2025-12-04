import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../services/health_api.dart';
import '../models/sensor_data.dart';
import '../models/alert_event.dart';

class HealthMonitorScreen extends StatefulWidget {
  final String esp32Ip;

  const HealthMonitorScreen({Key? key, required this.esp32Ip}) : super(key: key);

  @override
  State<HealthMonitorScreen> createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen>
    with TickerProviderStateMixin {
  late HealthApiService _api;
  SensorData? _currentData;
  SensorData? _cachedData;
  bool _isLoading = true;
  Timer? _pollingTimer;

  final List<double> _heartRateHistory = [];
  final List<double> _spo2History = [];
  static const int _maxHistoryPoints = 50;

  List<AlertEvent> _alerts = [];
  int _lastAlertCount = 0;

  late AnimationController _heartBeatController;

  @override
  void initState() {
    super.initState();
    _api = HealthApiService('http://${widget.esp32Ip}');

    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _startPolling();
  }

  void _startPolling() {
    _fetchData();
    _fetchAlerts();
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        _fetchData();
        _fetchAlerts();
      },
    );
  }

  Future<void> _fetchData() async {
    final data = await _api.fetchSensorData();
    if (!mounted) return;

    setState(() {
      if (data != null) {
        _currentData = data;
        _cachedData = data;
        _updateHistory(data);
      } else if (_cachedData != null) {
        _currentData = _cachedData;
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchAlerts() async {
    final alerts = await _api.fetchAlerts();
    if (!mounted) return;

    if (alerts.isNotEmpty && alerts.length > _lastAlertCount) {
      final newAlertsCount = alerts.length - _lastAlertCount;
      for (int i = 0; i < newAlertsCount; i++) {
        _showAlertNotification(alerts[i]);
      }
    }

    setState(() {
      _alerts = alerts;
      _lastAlertCount = alerts.length;
    });
  }

  void _updateHistory(SensorData data) {
    _heartRateHistory.add(data.heartRate);
    _spo2History.add(data.spo2);

    if (_heartRateHistory.length > _maxHistoryPoints) {
      _heartRateHistory.removeAt(0);
    }
    if (_spo2History.length > _maxHistoryPoints) {
      _spo2History.removeAt(0);
    }
  }

  Future<void> _onRefresh() async {
    _api.resetRetry();
    await _fetchData();
    await _fetchAlerts();
  }

  Color _getConnectionColor() {
    switch (_api.status) {
      case ConnectionStatus.connected:
        return const Color(0xFF10B981);
      case ConnectionStatus.connecting:
        return const Color(0xFFF59E0B);
      case ConnectionStatus.disconnected:
        return const Color(0xFFEF4444);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _heartBeatController.dispose();
    super.dispose();
  }

OverlayEntry? _overlayEntry;

  void _showAlertNotification(AlertEvent alert) {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    final seconds = alert.t / 1000.0;

    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(offset: Offset(0, value), child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF97316).withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_active, color: Color(0xFFF97316), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(alert.msg,
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${seconds.toStringAsFixed(1)}s',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _showSettingsDialog() {
    final TextEditingController ipController = TextEditingController(
      text: widget.esp32Ip,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF2D3748),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cài đặt kết nối',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Địa chỉ IP ESP32',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ipController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 192.168.1.100',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D3748),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D3748),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.wifi,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nhập địa chỉ IP của ESP32 trong mạng LAN',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2D3748),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getConnectionColor(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getConnectionColor(),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trạng thái hiện tại',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _api.status == ConnectionStatus.connected
                                ? 'Đã kết nối đến ${widget.esp32Ip}'
                                : 'Không kết nối',
                            style: TextStyle(
                              fontSize: 13,
                              color: _getConnectionColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(
                            color: Color(0xFF2D3748),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newIp = ipController.text.trim();
                          if (newIp.isNotEmpty && newIp != widget.esp32Ip) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => HealthMonitorScreen(
                                  esp32Ip: newIp,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

@override
  Widget build(BuildContext context) {
    // LẤY KÍCH THƯỚC MÀN HÌNH ĐỂ TỰ ĐỘNG SCALE
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF1E293B),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16 + MediaQuery.of(context).padding.top, // tránh notch
                    16,
                    100, // tránh nút điều hướng
                  ),
                  children: [
                    // AppBar cố định
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2D3748)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flash_on, color: Color(0xFF6366F1), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Health Monitor',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('ESP32C3 STREAM',
                                    style: TextStyle(fontSize: 7, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getConnectionColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getConnectionColor()),
                            ),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: _getConnectionColor(), shape: BoxShape.circle)),
                                // const SizedBox(width: 5),
                                Text(
                                  _api.status == ConnectionStatus.connected ? 'CONNECTED' : 'OFFLINE',
                                  style: TextStyle(color: _getConnectionColor(), fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
                            onPressed: _showSettingsDialog,
                      
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2 card chính
                    _buildMetricsRow(),

                    const SizedBox(height: 20),

                    // 2 biểu đồ
                    _buildChartsColumn(),

                    const SizedBox(height: 20),

                    // Lịch sử cảnh báo
                    _buildAlertHistoryCard(),

                    const SizedBox(height: 16),

                    // Thanh trạng thái
                    _buildStatusBar(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildHeartRateCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSpO2Card(),
        ),
      ],
    );
  }

  Widget _buildHeartRateCard() {
    final heartRate = _currentData?.heartRate.toInt() ?? 0;
    final status = heartRate >= 60 && heartRate <= 100 ? 'Normal Sinus Rhythm' : 'Abnormal';
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3748),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'HEART RATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _heartBeatController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_heartBeatController.value * 0.15),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                heartRate.toString(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpO2Card() {
    final spo2 = _currentData?.spo2 ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3748),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'BLOOD OXYGEN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Color(0xFF06B6D4),
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spo2.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF06B6D4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Optimal Saturation',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildChartCard(
            title: 'BPM Trend History',
            data: _heartRateHistory,
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildChartCard(
            title: 'SpO2 Trend History',
            data: _spo2History,
            color: const Color(0xFF06B6D4),
          ),
        ),
      ],
    );
  }
    Widget _buildChartsColumn() {
    return Column(
      children: [
        _buildChartCard(
          title: 'BPM Trend History',
          data: _heartRateHistory,
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16), // Khoảng cách giữa 2 biểu đồ
        _buildChartCard(
          title: 'SpO2 Trend History',
          data: _spo2History,
          color: const Color(0xFF06B6D4),
        ),
      ],
    );
  }

/// BIỂU ĐỒ ĐÃ ĐƯỢC CỐ ĐỊNH TRỤC Y + THÊM ĐƯỜNG THAM CHIẾU
  Widget _buildChartCard({
    required String title,
    required List<double> data,
    required Color color,
  }) {
    // CỐ ĐỊNH TRỤC Y
    final bool isBpm = title.contains('BPM');
    final double minY = isBpm ? 0 : 0;
    final double maxY = isBpm ? 200 : 100;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D3748), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
              const Spacer(),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.5), blurRadius: 4, spreadRadius: 1)])),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: data.isEmpty
                ? Center(child: Text('Waiting for data...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)))
                : LineChart(
                    LineChartData(
                      clipData: FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 5,
                        getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF2D3748), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: (maxY - minY) / 5,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(value.toInt().toString(), style: const TextStyle(color: Color(0xFF475569), fontSize: 10)),
                            ),
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: color,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [color.withOpacity(0.3), color.withOpacity(0.05), Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                      // CỐ ĐỊNH TRỤC Y TẠI ĐÂY
                      minY: minY,
                      maxY: maxY,
                      minX: 0,
                      maxX: math.max(0, (data.length - 1).toDouble()),

                      // ĐƯỜNG NGANG THAM CHIẾU (vùng nguy hiểm/bình thường)
                      extraLinesData: ExtraLinesData(
                        horizontalLines: isBpm
                            ? [
                                HorizontalLine(y: 60, color: Colors.yellow.withOpacity(0.6), strokeWidth: 1, dashArray: [8, 5]),
                                HorizontalLine(y: 100, color: Colors.yellow.withOpacity(0.6), strokeWidth: 1, dashArray: [8, 5]),
                                HorizontalLine(y: 120, color: Colors.orange.withOpacity(0.8), strokeWidth: 1.5),
                                HorizontalLine(y: 160, color: Colors.red.withOpacity(0.9), strokeWidth: 2),
                              ]
                            : [
                                HorizontalLine(y: 95, color: Colors.orange.withOpacity(0.8), strokeWidth: 1.5, dashArray: [8, 5]),
                                HorizontalLine(y: 90, color: Colors.red.withOpacity(0.9), strokeWidth: 2),
                              ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3748),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Color(0xFFF97316), size: 20),
              SizedBox(width: 8),
              Text(
                'Lịch sử cảnh báo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFBBF24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _alerts.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có cảnh báo nào',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final seconds = alert.t / 1000.0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                alert.msg,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${seconds.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withOpacity(0.08),
                        height: 10,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2D3748),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusItem('SYS_STATUS', 'OK', const Color(0xFF10B981)),
          _buildStatusItem('BUFFER_SIZE', '${_heartRateHistory.length}/$_maxHistoryPoints', const Color(0xFF64748B)),
          _buildStatusItem('UPTIME', '${DateTime.now().second}s', const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}