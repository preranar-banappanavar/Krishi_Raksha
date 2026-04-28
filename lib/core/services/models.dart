// Typed data models for KrishiRaksha.
// All screens consume these instead of raw Map.

class CropPrice {
  final String name;
  final String emoji;
  final double price;
  final double changePercent;
  final String badge; // "Sell" | "Hold" | "Wait"
  final String unit;
  final List<double> weeklyData;

  const CropPrice({
    required this.name,
    required this.emoji,
    required this.price,
    required this.changePercent,
    required this.badge,
    required this.unit,
    required this.weeklyData,
  });
}

class MandiInfo {
  final String name;
  final String distance;
  final String contact;

  const MandiInfo({
    required this.name,
    required this.distance,
    required this.contact,
  });
}

class MarketData {
  final List<CropPrice> crops;
  final List<MandiInfo> mandis;
  const MarketData({required this.crops, required this.mandis});
}

// ── Climate ──────────────────────────────────────────────────────────────────

class WeatherDay {
  final String day;
  final WeatherCondition condition;
  final int tempCelsius;
  final int rainPercent;

  const WeatherDay({
    required this.day,
    required this.condition,
    required this.tempCelsius,
    required this.rainPercent,
  });
}

enum WeatherCondition { sunny, cloudy, stormy }

class RegionalDetails {
  final int humidityPercent;
  final int windKmh;
  final int uvIndex;
  final int soilTempCelsius;

  const RegionalDetails({
    required this.humidityPercent,
    required this.windKmh,
    required this.uvIndex,
    required this.soilTempCelsius,
  });
}

class ClimateData {
  final List<WeatherDay> forecast;
  final RegionalDetails regional;
  const ClimateData({required this.forecast, required this.regional});
}

// ── Post-Harvest ─────────────────────────────────────────────────────────────

class StorageTip {
  final String crop;
  final String emoji;
  final String tip;
  final RiskLevel risk;

  const StorageTip({
    required this.crop,
    required this.emoji,
    required this.tip,
    required this.risk,
  });
}

enum RiskLevel { low, medium, high }

class PostHarvestData {
  final double spoilageRisk; // 0.0 – 1.0
  final int currentHumidityPercent;
  final List<StorageTip> tips;
  const PostHarvestData({
    required this.spoilageRisk,
    required this.currentHumidityPercent,
    required this.tips,
  });
}

// ── AI Copilot ────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  /// Serialise to a pipe-delimited string for SharedPreferences storage.
  String serialize() =>
      '${isUser ? '1' : '0'}|${timestamp.millisecondsSinceEpoch}|$text';

  static ChatMessage? deserialize(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    return ChatMessage(
      isUser: parts[0] == '1',
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[1]) ?? 0),
      text: parts.sublist(2).join('|'), // text may contain pipes
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

enum CrisisLevel { low, medium, high }

class DashboardData {
  final String farmerName;
  final String location;
  final CrisisLevel crisisLevel;
  const DashboardData({
    required this.farmerName,
    required this.location,
    required this.crisisLevel,
  });
}

// ── Service result wrapper ────────────────────────────────────────────────────

class ServiceResult<T> {
  final T? data;
  final String? errorCode;
  final String? errorMessage;

  bool get isSuccess => data != null;

  const ServiceResult.success(this.data)
      : errorCode = null,
        errorMessage = null;

  const ServiceResult.failure(this.errorCode, this.errorMessage)
      : data = null;
}
