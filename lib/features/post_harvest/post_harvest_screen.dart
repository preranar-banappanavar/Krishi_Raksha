import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/models.dart';
import '../../core/services/farm_data_service.dart';
import '../../core/services/app_config.dart';
import '../../core/widgets/error_state_widget.dart';

class PostHarvestScreen extends StatefulWidget {
  const PostHarvestScreen({super.key});
  @override
  State<PostHarvestScreen> createState() => _PostHarvestScreenState();
}

class _PostHarvestScreenState extends State<PostHarvestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _animValue;
  late Future<ServiceResult<PostHarvestData>> _future;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _animValue = Tween<double>(begin: 0, end: 0).animate(_animCtrl);
    // Direct assignment — no setState allowed inside initState.
    _future = FarmDataService.instance.fetchPostHarvestData();
  }

  void _load() {
    // Block form so the callback returns void, not a Future.
    setState(() {
      _future = FarmDataService.instance.fetchPostHarvestData();
    });
  }

  void _animateTo(double target) {
    _animValue = Tween<double>(begin: 0, end: target)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Thresholds driven by [AppConfig] — not hardcoded in the widget.
  Color _riskColor(double v) {
    if (v < AppConfig.spoilageLowThreshold) return AppTheme.urgencyGreen;
    if (v < AppConfig.spoilageHighThreshold) return AppTheme.harvestAmber;
    return AppTheme.urgencyRed;
  }

  String _riskLabel(double v) {
    if (v < AppConfig.spoilageLowThreshold) return 'Low Risk';
    if (v < AppConfig.spoilageHighThreshold) return 'Moderate';
    return 'High Risk';
  }

  Color _riskLevelColor(RiskLevel r) => switch (r) {
        RiskLevel.low => AppTheme.urgencyGreen,
        RiskLevel.medium => AppTheme.harvestAmber,
        RiskLevel.high => AppTheme.urgencyRed,
      };

  String _riskLevelLabel(RiskLevel r) => switch (r) {
        RiskLevel.low => 'Low',
        RiskLevel.medium => 'Medium',
        RiskLevel.high => 'High',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: FutureBuilder<ServiceResult<PostHarvestData>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingStateWidget(label: 'Loading harvest data…');
            }
            final result = snap.data;
            if (result == null || !result.isSuccess) {
              return ErrorStateWidget(
                errorCode: result?.errorCode,
                errorMessage: result?.errorMessage,
                onRetry: _load,
              );
            }
            // Kick off ring animation once data arrives.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _animateTo(result.data!.spoilageRisk);
            });
            return _body(result.data!);
          },
        ),
      ),
    );
  }

  Widget _body(PostHarvestData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Post-Harvest', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Storage intelligence & buyer connect', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        _spoilageMeter(data),
        const SizedBox(height: 24),
        _tipsList(data.tips),
        const SizedBox(height: 24),
        _buyerCTA(),
      ]),
    );
  }

  Widget _spoilageMeter(PostHarvestData data) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(children: [
        Text('SPOILAGE RISK METER', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _animValue,
          builder: (context, child) {
            final v = _animValue.value;
            final c = _riskColor(v);
            return SizedBox(width: 180, height: 180,
              child: CustomPaint(
                painter: _RingPainter(progress: v, color: c),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(v * 100).toInt()}%', style: GoogleFonts.poppins(color: c, fontSize: 40, fontWeight: FontWeight.w800)),
                  Text(_riskLabel(v), style: GoogleFonts.poppins(color: c.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w600)),
                ])),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Based on current humidity (${data.currentHumidityPercent}%) and storage conditions',
            textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  Widget _tipsList(List<StorageTip> tips) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Storage Tips by Crop', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ...tips.map((t) {
        final rc = _riskLevelColor(t.risk);
        return Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: rc.withAlpha(60))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.forestGreen, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t.crop, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: rc.withAlpha(25), borderRadius: BorderRadius.circular(6), border: Border.all(color: rc.withAlpha(80))),
                    child: Text('${_riskLevelLabel(t.risk)} Risk', style: GoogleFonts.poppins(color: rc, fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 6),
              Text(t.tip, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, height: 1.5)),
            ])),
          ]),
        );
      }),
    ]);
  }

  Widget _buyerCTA() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.forestGreen, AppTheme.greenMid]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.forestGreen.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Material(color: Colors.transparent, child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Connecting to nearest verified buyer…', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.forestGreen, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.handshake_rounded, color: AppTheme.harvestAmber, size: 24)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connect to Buyer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              Text('Find verified buyers near you', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
            ]),
            const Spacer(),
            const Icon(Icons.arrow_forward_rounded, color: AppTheme.harvestAmber, size: 24),
          ])),
      )),
    );
  }
}

/// Isolated painter — uses [math] aliased import to avoid polluting namespace.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    canvas.drawCircle(center, radius,
        Paint()..color = Colors.white.withAlpha(10)..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = color.withAlpha(30)..style = PaintingStyle.stroke..strokeWidth = 20..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.progress != progress || o.color != color;
}
