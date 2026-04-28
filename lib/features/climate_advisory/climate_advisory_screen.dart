import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/models.dart';
import '../../core/services/farm_data_service.dart';
import '../../core/services/app_config.dart';
import '../../core/widgets/error_state_widget.dart';

class ClimateAdvisoryScreen extends StatefulWidget {
  const ClimateAdvisoryScreen({super.key});
  @override
  State<ClimateAdvisoryScreen> createState() => _ClimateAdvisoryScreenState();
}

class _ClimateAdvisoryScreenState extends State<ClimateAdvisoryScreen> {
  late Future<ServiceResult<ClimateData>> _future;

  @override
  void initState() {
    super.initState();
    // Direct assignment — no setState allowed inside initState.
    _future = FarmDataService.instance.fetchClimateData();
  }

  void _load() {
    // Block form so the callback returns void, not a Future.
    setState(() {
      _future = FarmDataService.instance.fetchClimateData();
    });
  }

  bool _hasRainAlert(List<WeatherDay> forecast) =>
      forecast.any((d) => d.rainPercent > AppConfig.rainAlertThresholdPercent);

  IconData _conditionIcon(WeatherCondition c) => switch (c) {
        WeatherCondition.sunny => Icons.wb_sunny_rounded,
        WeatherCondition.cloudy => Icons.cloud_rounded,
        WeatherCondition.stormy => Icons.thunderstorm_rounded,
      };

  Color _conditionColor(WeatherCondition c) => switch (c) {
        WeatherCondition.sunny => AppTheme.harvestAmber,
        WeatherCondition.cloudy => const Color(0xFF94A3B8),
        WeatherCondition.stormy => AppTheme.accentBlue,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: FutureBuilder<ServiceResult<ClimateData>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingStateWidget(label: 'Loading weather data…');
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

  Widget _body(ClimateData data) {
    final rainAlert = _hasRainAlert(data.forecast);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Climate Advisory', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('7-day weather intelligence for your region', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),
        if (rainAlert) _rainAlert(data.forecast),
        if (rainAlert) const SizedBox(height: 16),
        _forecastScroll(data.forecast),
        const SizedBox(height: 24),
        _sowingCard(rainAlert),
        const SizedBox(height: 24),
        _detailCards(data.regional),
      ]),
    );
  }

  Widget _rainAlert(List<WeatherDay> forecast) {
    final rainyDays = forecast
        .where((d) => d.rainPercent > AppConfig.rainAlertThresholdPercent)
        .map((d) => d.day)
        .join(', ');
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.urgencyRed.withAlpha(35), AppTheme.urgencyRed.withAlpha(10)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.urgencyRed.withAlpha(100))),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.urgencyRed.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.flood_rounded, color: AppTheme.urgencyRed, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⚠️ Heavy Rainfall Alert', style: GoogleFonts.poppins(color: AppTheme.urgencyRed, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('Heavy rain expected on $rainyDays. Protect crops and delay sowing.',
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _forecastScroll(List<WeatherDay> forecast) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('7-Day Forecast', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      SizedBox(height: 160, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: forecast.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = forecast[i]; final isToday = i == 0;
          final alertRain = d.rainPercent > AppConfig.rainAlertThresholdPercent;
          return Container(width: 100, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isToday ? AppTheme.forestGreen : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isToday ? AppTheme.harvestAmber.withAlpha(100) : Colors.white10)),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(isToday ? 'Today' : d.day, style: GoogleFonts.poppins(
                  color: isToday ? AppTheme.harvestAmber : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(_conditionIcon(d.condition), color: _conditionColor(d.condition), size: 32),
              Text('${d.tempCelsius}°C', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.water_drop_rounded, color: alertRain ? AppTheme.urgencyRed : AppTheme.accentBlue, size: 12),
                const SizedBox(width: 3),
                Text('${d.rainPercent}%', style: GoogleFonts.poppins(
                    color: alertRain ? AppTheme.urgencyRed : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _sowingCard(bool hasRainAlert) {
    final c = hasRainAlert ? AppTheme.urgencyRed : AppTheme.urgencyGreen;
    final title = hasRainAlert ? '🚫 Avoid Sowing Now' : '✅ Good Time to Sow';
    final reason = hasRainAlert
        ? 'Heavy rainfall expected soon. Wait until conditions stabilize to avoid seed washout and root rot.'
        : 'Soil moisture is optimal and no heavy rainfall expected this week. Ideal for planting Rabi crops.';
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withAlpha(30), c.withAlpha(10)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withAlpha(80), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.eco_rounded, color: c, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SOWING RECOMMENDATION', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.poppins(color: c, fontSize: 16, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(reason, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _detailCards(RegionalDetails r) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Regional Details', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _tile('Humidity', '${r.humidityPercent}%', Icons.opacity_rounded, AppTheme.accentBlue)),
        const SizedBox(width: 12),
        Expanded(child: _tile('Wind', '${r.windKmh} km/h', Icons.air_rounded, AppTheme.urgencyGreen)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _tile('UV Index', '${r.uvIndex} (${r.uvIndex >= 6 ? "High" : "Moderate"})', Icons.wb_sunny_outlined, AppTheme.harvestAmber)),
        const SizedBox(width: 12),
        Expanded(child: _tile('Soil Temp', '${r.soilTempCelsius}°C', Icons.thermostat_rounded, AppTheme.soilBrown)),
      ]),
    ]);
  }

  Widget _tile(String label, String val, IconData icon, Color c) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 22), const SizedBox(height: 10),
        Text(val, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
      ]));
  }
}
