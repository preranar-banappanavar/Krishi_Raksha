import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/models.dart';
import '../../core/services/farm_data_service.dart';
import '../../core/widgets/error_state_widget.dart';

class MarketAlertsScreen extends StatefulWidget {
  const MarketAlertsScreen({super.key});
  @override
  State<MarketAlertsScreen> createState() => _MarketAlertsScreenState();
}

class _MarketAlertsScreenState extends State<MarketAlertsScreen> {
  late Future<ServiceResult<MarketData>> _future;
  int _selectedCrop = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = FarmDataService.instance.fetchMarketData();
      _selectedCrop = 0;
    });
  }

  Color _badgeColor(String b) => b == 'Sell' ? AppTheme.urgencyGreen : b == 'Hold' ? AppTheme.harvestAmber : AppTheme.accentBlue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: FutureBuilder<ServiceResult<MarketData>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingStateWidget(label: 'Fetching market prices…');
            }
            final result = snap.data;
            if (result == null || !result.isSuccess) {
              return ErrorStateWidget(
                errorCode: result?.errorCode,
                errorMessage: result?.errorMessage,
                onRetry: _load,
              );
            }
            return _body(result.data!);
          },
        ),
      ),
    );
  }

  Widget _body(MarketData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Market Alerts', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Live mandi prices & intelligence', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),
        ...data.crops.asMap().entries.map((e) => _cropTile(e.key, e.value)),
        const SizedBox(height: 24),
        _chartSection(data.crops[_selectedCrop]),
        const SizedBox(height: 24),
        _mandiSection(data.mandis),
      ]),
    );
  }

  Widget _cropTile(int idx, CropPrice c) {
    final sel = idx == _selectedCrop;
    final up = c.changePercent >= 0;
    return GestureDetector(
      onTap: () => setState(() => _selectedCrop = idx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? AppTheme.forestGreen.withAlpha(120) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppTheme.harvestAmber.withAlpha(120) : Colors.white10, width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppTheme.forestGreen, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            Text(c.unit, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${c.price}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  color: up ? AppTheme.urgencyGreen : AppTheme.urgencyRed, size: 20),
              Text('${c.changePercent.abs()}%', style: GoogleFonts.poppins(
                  color: up ? AppTheme.urgencyGreen : AppTheme.urgencyRed, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _badgeColor(c.badge).withAlpha(30), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _badgeColor(c.badge).withAlpha(100))),
            child: Text(c.badge, style: GoogleFonts.poppins(color: _badgeColor(c.badge), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _chartSection(CropPrice c) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final cc = c.changePercent >= 0 ? AppTheme.urgencyGreen : AppTheme.urgencyRed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('7-Day Trend: ${c.name}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cc.withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text('${c.changePercent >= 0 ? '+' : ''}${c.changePercent}%',
                  style: GoogleFonts.poppins(color: cc, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 180, child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 0.5)),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                getTitlesWidget: (v, _) => Text('₹${v.toInt()}', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(days[v.toInt() % 7], style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10))))),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [LineChartBarData(
            spots: c.weeklyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true, color: cc, barWidth: 2.5,
            dotData: FlDotData(show: true,
                getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(radius: 3, color: cc, strokeWidth: 0)),
            belowBarData: BarAreaData(show: true, color: cc.withAlpha(25)),
          )],
        ))),
      ]),
    );
  }

  Widget _mandiSection(List<MandiInfo> mandis) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nearest Mandi', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ...mandis.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.forestGreen, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.store_rounded, color: AppTheme.harvestAmber, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(m.contact, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.forestGreen, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.directions_rounded, color: AppTheme.harvestAmber, size: 14),
                const SizedBox(width: 4),
                Text(m.distance, style: GoogleFonts.poppins(color: AppTheme.harvestAmber, fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
        ]),
      )),
    ]);
  }
}
