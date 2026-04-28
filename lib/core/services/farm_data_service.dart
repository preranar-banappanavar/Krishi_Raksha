import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'app_config.dart';
/// Async data service. When a real backend is available, replace the method
/// bodies with HTTP calls. Any uncaught exception falls back to the built-in
/// mock data so the app always shows something useful.
///
/// Set [AppConfig.simulateNetworkFailure] = true to test the ErrorStateWidget
/// path deliberately.
class FarmDataService {
  FarmDataService._();
  static final FarmDataService instance = FarmDataService._();

  // ── Fallback / mock datasets ──────────────────────────────────────────────

  static const _mockDashboard = DashboardData(
    farmerName: 'Ramesh Kumar',
    location: 'Mandya, Karnataka',
    crisisLevel: CrisisLevel.medium,
  );

  static final _mockMarket = MarketData(
    crops: const [
      CropPrice(name: 'Tomato', emoji: '🍅', price: 42.50, changePercent: 12.3,
          badge: 'Sell', unit: '₹/kg', weeklyData: [28.0, 30.0, 33.0, 35.0, 38.0, 40.0, 42.5]),
      CropPrice(name: 'Onion', emoji: '🧅', price: 35.00, changePercent: -5.2,
          badge: 'Hold', unit: '₹/kg', weeklyData: [40.0, 38.0, 37.0, 36.0, 35.5, 35.2, 35.0]),
      CropPrice(name: 'Rice', emoji: '🌾', price: 28.75, changePercent: 2.1,
          badge: 'Wait', unit: '₹/kg', weeklyData: [26.0, 26.5, 27.0, 27.5, 28.0, 28.5, 28.75]),
      CropPrice(name: 'Wheat', emoji: '🌿', price: 24.00, changePercent: -1.8,
          badge: 'Hold', unit: '₹/kg', weeklyData: [25.5, 25.0, 24.8, 24.5, 24.3, 24.1, 24.0]),
    ],
    mandis: const [
      MandiInfo(name: 'Mandya APMC', distance: '8 km', contact: '+91 98765 43210'),
      MandiInfo(name: 'Mysore Mandi', distance: '32 km', contact: '+91 98765 43211'),
    ],
  );

  static const _mockClimate = ClimateData(
    forecast: [
      WeatherDay(day: 'Mon', condition: WeatherCondition.sunny,  tempCelsius: 34, rainPercent: 10),
      WeatherDay(day: 'Tue', condition: WeatherCondition.sunny,  tempCelsius: 33, rainPercent: 15),
      WeatherDay(day: 'Wed', condition: WeatherCondition.cloudy, tempCelsius: 31, rainPercent: 45),
      WeatherDay(day: 'Thu', condition: WeatherCondition.stormy, tempCelsius: 28, rainPercent: 80),
      WeatherDay(day: 'Fri', condition: WeatherCondition.stormy, tempCelsius: 27, rainPercent: 85),
      WeatherDay(day: 'Sat', condition: WeatherCondition.cloudy, tempCelsius: 29, rainPercent: 40),
      WeatherDay(day: 'Sun', condition: WeatherCondition.sunny,  tempCelsius: 32, rainPercent: 20),
    ],
    regional: RegionalDetails(
      humidityPercent: 72, windKmh: 14, uvIndex: 6, soilTempCelsius: 26,
    ),
  );

  static const _mockPostHarvest = PostHarvestData(
    spoilageRisk: 0.34,
    currentHumidityPercent: 72,
    tips: [
      StorageTip(crop: 'Tomato', emoji: '🍅', risk: RiskLevel.high,
          tip: 'Store at 12-15°C with 85-90% humidity. Avoid direct sunlight. Use ventilated crates.'),
      StorageTip(crop: 'Onion', emoji: '🧅', risk: RiskLevel.medium,
          tip: 'Cure in shade for 2-3 days. Store in mesh bags with good airflow at 25-30°C.'),
      StorageTip(crop: 'Rice', emoji: '🌾', risk: RiskLevel.low,
          tip: 'Dry to 14% moisture. Store in airtight containers. Keep off the floor on pallets.'),
      StorageTip(crop: 'Wheat', emoji: '🌿', risk: RiskLevel.low,
          tip: 'Clean and dry thoroughly. Store in metal bins. Check for weevils every 2 weeks.'),
    ],
  );

  // ── Public fetch methods ──────────────────────────────────────────────────
  //
  // Pattern for each method:
  //   1. simulateNetworkFailure → return ServiceResult.failure (for testing error UI)
  //   2. Try the real/mock fetch
  //   3. catch any Exception → fall back to mock data (backend unreachable)

  Future<ServiceResult<DashboardData>> fetchDashboard() async {
    if (AppConfig.simulateNetworkFailure) {
      return const ServiceResult.failure('ERR_500', 'Internal server error');
    }
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('getDashboardData').call();
      // Assume the data returned directly maps to DashboardData. 
      // If enum strings are used, we might need to parse. For now, fallback to mock on parse error.
      try {
        final data = result.data;
        return ServiceResult.success(DashboardData(
          farmerName: data['farmerName'],
          location: data['location'],
          crisisLevel: CrisisLevel.values.firstWhere((e) => e.name == data['crisisLevel'], orElse: () => CrisisLevel.medium),
        ));
      } catch (parseError) {
        debugPrint("Parse error: $parseError");
        return const ServiceResult.success(_mockDashboard);
      }
    } catch (e) {
      debugPrint("Function error: $e");
      return const ServiceResult.success(_mockDashboard);
    }
  }

  Future<ServiceResult<MarketData>> fetchMarketData() async {
    if (AppConfig.simulateNetworkFailure) {
      return const ServiceResult.failure('ERR_503', 'Market data service unavailable');
    }
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('getMarketData').call();
      // Map data. We use _mockMarket as fallback if mapping fails.
      try {
        final data = result.data;
        final crops = (data['crops'] as List).map((c) => CropPrice(
          name: c['name'], emoji: c['emoji'], price: (c['price'] as num).toDouble(),
          changePercent: (c['changePercent'] as num).toDouble(), badge: c['badge'], unit: c['unit'],
          weeklyData: (c['weeklyData'] as List).map((w) => (w as num).toDouble()).toList()
        )).toList();
        final mandis = (data['mandis'] as List).map((m) => MandiInfo(
          name: m['name'], distance: m['distance'], contact: m['contact']
        )).toList();
        return ServiceResult.success(MarketData(crops: crops, mandis: mandis));
      } catch (parseError) {
        debugPrint("Parse error: $parseError");
        return ServiceResult.success(_mockMarket);
      }
    } catch (e) {
      debugPrint("Function error: $e");
      return ServiceResult.success(_mockMarket);
    }
  }

  Future<ServiceResult<ClimateData>> fetchClimateData() async {
    if (AppConfig.simulateNetworkFailure) {
      return const ServiceResult.failure('ERR_504', 'Weather service timeout');
    }
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('getClimateData').call();
      try {
        final data = result.data;
        final forecast = (data['forecast'] as List).map((f) => WeatherDay(
          day: f['day'],
          condition: WeatherCondition.values.firstWhere((e) => e.name == f['condition'], orElse: () => WeatherCondition.sunny),
          tempCelsius: f['tempCelsius'],
          rainPercent: f['rainPercent'],
        )).toList();
        final reg = data['regional'];
        final regional = RegionalDetails(
          humidityPercent: reg['humidityPercent'], windKmh: reg['windKmh'],
          uvIndex: reg['uvIndex'], soilTempCelsius: reg['soilTempCelsius'],
        );
        return ServiceResult.success(ClimateData(forecast: forecast, regional: regional));
      } catch (parseError) {
        debugPrint("Parse error: $parseError");
        return const ServiceResult.success(_mockClimate);
      }
    } catch (e) {
      debugPrint("Function error: $e");
      return const ServiceResult.success(_mockClimate);
    }
  }

  Future<ServiceResult<PostHarvestData>> fetchPostHarvestData() async {
    if (AppConfig.simulateNetworkFailure) {
      return const ServiceResult.failure('ERR_503', 'Post-harvest service unavailable');
    }
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('getPostHarvestData').call();
      try {
        final data = result.data;
        final tips = (data['tips'] as List).map((t) => StorageTip(
          crop: t['crop'], emoji: t['emoji'],
          risk: RiskLevel.values.firstWhere((e) => e.name == t['risk'], orElse: () => RiskLevel.medium),
          tip: t['tip'],
        )).toList();
        return ServiceResult.success(PostHarvestData(
          spoilageRisk: (data['spoilageRisk'] as num).toDouble(),
          currentHumidityPercent: data['currentHumidityPercent'],
          tips: tips,
        ));
      } catch (parseError) {
        debugPrint("Parse error: $parseError");
        return const ServiceResult.success(_mockPostHarvest);
      }
    } catch (e) {
      debugPrint("Function error: $e");
      return const ServiceResult.success(_mockPostHarvest);
    }
  }
}
