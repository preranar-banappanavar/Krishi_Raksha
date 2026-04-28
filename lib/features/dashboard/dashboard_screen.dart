import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/models.dart';
import '../../core/services/farm_data_service.dart';
import '../../core/widgets/error_state_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Future<ServiceResult<DashboardData>> _future;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _load();
  }

  void _load() {
    setState(() {
      _future = FarmDataService.instance.fetchDashboard();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: FutureBuilder<ServiceResult<DashboardData>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingStateWidget(label: 'Loading dashboard…');
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

  Widget _body(DashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _greeting(data),
        const SizedBox(height: 20),
        _crisisBanner(data.crisisLevel),
        const SizedBox(height: 24),
        Text('Quick Actions',
            style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _featureGrid(),
      ]),
    );
  }

  Widget _greeting(DashboardData data) {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening';
    return Row(children: [
      Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.forestGreen, AppTheme.greenMid]),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.agriculture_rounded, color: AppTheme.harvestAmber, size: 26)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$g 👋', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        Text(data.farmerName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      ])),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppTheme.forestGreen.withAlpha(180),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.greenMid)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_rounded, color: AppTheme.harvestAmber, size: 14),
            const SizedBox(width: 4),
            Text(data.location, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
    ]);
  }

  Color _crisisColor(CrisisLevel l) => l == CrisisLevel.high
      ? AppTheme.urgencyRed
      : l == CrisisLevel.medium
          ? AppTheme.harvestAmber
          : AppTheme.urgencyGreen;

  IconData _crisisIcon(CrisisLevel l) => l == CrisisLevel.high
      ? Icons.warning_rounded
      : l == CrisisLevel.medium
          ? Icons.info_rounded
          : Icons.check_circle_rounded;

  String _crisisLabel(CrisisLevel l) =>
      l.name[0].toUpperCase() + l.name.substring(1);

  Widget _crisisBanner(CrisisLevel level) {
    final c = _crisisColor(level);
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, _) {
        final v = _pulseCtrl.value;
        return Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.withAlpha(40), c.withAlpha(15)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withAlpha((100 * (0.5 + 0.5 * v)).round()), width: 1.5),
            boxShadow: [BoxShadow(color: c.withAlpha((30 * v).round()), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(children: [
            Container(width: 52, height: 52,
                decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                child: Icon(_crisisIcon(level), color: c, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TODAY\'S CRISIS LEVEL', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(_crisisLabel(level).toUpperCase(), style: GoogleFonts.poppins(color: c, fontSize: 26, fontWeight: FontWeight.w800)),
            ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withAlpha(80))),
                child: Text('LIVE', style: GoogleFonts.poppins(color: c, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
          ]),
        );
      },
    );
  }

  Widget _featureGrid() {
    final items = [
      {'icon': Icons.trending_up_rounded, 'title': 'Market Alerts', 'sub': 'Tomato ↑12% today', 'urgency': 'red', 'c1': AppTheme.urgencyRed, 'c2': const Color(0xFFDC2626)},
      {'icon': Icons.cloud_rounded, 'title': 'Climate Advisory', 'sub': 'Rain likely Thu-Fri', 'urgency': 'yellow', 'c1': AppTheme.harvestAmber, 'c2': const Color(0xFFD97706)},
      {'icon': Icons.inventory_2_rounded, 'title': 'Post-Harvest Risk', 'sub': 'Spoilage risk: 34%', 'urgency': 'green', 'c1': AppTheme.urgencyGreen, 'c2': const Color(0xFF16A34A)},
      {'icon': Icons.smart_toy_rounded, 'title': 'AI Copilot', 'sub': 'Ask anything now', 'urgency': 'green', 'c1': AppTheme.accentBlue, 'c2': const Color(0xFF2563EB)},
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
      children: items.map((f) {
        final bc = f['urgency'] == 'red' ? AppTheme.urgencyRed : f['urgency'] == 'yellow' ? AppTheme.harvestAmber : AppTheme.urgencyGreen;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bc.withAlpha(100), width: 1.2),
              boxShadow: [BoxShadow(color: bc.withAlpha(15), blurRadius: 12, spreadRadius: 1)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [f['c1'] as Color, f['c2'] as Color]), borderRadius: BorderRadius.circular(12)),
                child: Icon(f['icon'] as IconData, color: Colors.white, size: 22)),
            const Spacer(),
            Text(f['title'] as String, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: bc, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(f['sub'] as String, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}
