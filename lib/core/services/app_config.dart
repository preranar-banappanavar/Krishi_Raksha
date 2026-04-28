/// Dynamic thresholds for risk assessment.
/// Values can be loaded from a remote config in future without touching screens.
class AppConfig {
  AppConfig._();

  // ── Rain / Climate ──────────────────────────────────────────────────────────
  /// Rain probability above which the alert banner is shown.
  static int rainAlertThresholdPercent = 70;

  // ── Spoilage risk bands ─────────────────────────────────────────────────────
  /// Below this value → Low Risk (green).
  static double spoilageLowThreshold = 0.30;

  /// Below this value → Moderate (amber); at or above → High Risk (red).
  static double spoilageHighThreshold = 0.60;

  // ── Crisis level ────────────────────────────────────────────────────────────
  /// Price change magnitude (%) above which is flagged as "urgent".
  static double priceUrgencyThresholdPercent = 10.0;

  // ── Simulated latency for mock fetches ──────────────────────────────────────
  static const Duration mockFetchDelay = Duration(milliseconds: 900);

  // ── Simulated failure toggle (flip to true to test error states) ────────────
  static bool simulateNetworkFailure = false;
}
