import 'models.dart';
import 'app_config.dart';

/// Abstract AI response contract.
/// Swap [MockAiService] with a real LLM implementation without touching screens.
abstract class AiService {
  Future<ServiceResult<String>> getResponse(String query, String language);
}

/// Offline mock implementation.
/// Returns canned responses keyed by query + language.
/// Falls back to a generic multilingual message for unknown queries.
class MockAiService implements AiService {
  MockAiService._();
  static final MockAiService instance = MockAiService._();

  static const _delay = Duration(milliseconds: 800);

  static const Map<String, Map<String, String>> _responses = {
    'What should I sell today?': {
      'English': 'Based on current market trends, Tomato prices are up 12% today at ₹42.50/kg. I recommend selling your tomato stock now at Mandya APMC. Onion prices are declining — consider holding. Rice is stable — wait for better rates next week.',
      'हिन्दी': 'वर्तमान बाज़ार रुझानों के आधार पर, आज टमाटर की कीमतें 12% बढ़कर ₹42.50/किग्रा हो गई हैं। मैं अभी मंड्या APMC में अपना टमाटर स्टॉक बेचने की सलाह देता हूँ।',
      'ಕನ್ನಡ': 'ಪ್ರಸ್ತುತ ಮಾರುಕಟ್ಟೆ ಪ್ರವೃತ್ತಿಗಳ ಆಧಾರದ ಮೇಲೆ, ಇಂದು ಟೊಮೆಟೊ ಬೆಲೆಗಳು 12% ಹೆಚ್ಚಾಗಿ ₹42.50/ಕೆಜಿ ಆಗಿದೆ. ಈಗ ಮಂಡ್ಯ APMC ನಲ್ಲಿ ಮಾರಾಟ ಮಾಡಲು ಶಿಫಾರಸು.',
    },
    'Is it safe to sow?': {
      'English': '⚠️ Not recommended right now. Heavy rainfall (80-85%) is predicted for Thursday and Friday. Wait until Saturday when conditions improve. Soil moisture will be optimal for sowing Rabi crops by then.',
      'हिन्दी': '⚠️ अभी अनुशंसित नहीं है। गुरुवार और शुक्रवार को भारी वर्षा (80-85%) की भविष्यवाणी है। शनिवार तक प्रतीक्षा करें।',
      'ಕನ್ನಡ': '⚠️ ಈಗ ಶಿಫಾರಸು ಮಾಡಲಾಗಿಲ್ಲ. ಗುರುವಾರ ಮತ್ತು ಶುಕ್ರವಾರ ಭಾರೀ ಮಳೆ (80-85%) ನಿರೀಕ್ಷಿಸಲಾಗಿದೆ. ಶನಿವಾರದವರೆಗೆ ಕಾಯಿರಿ.',
    },
    'How to store onions?': {
      'English': 'For onion storage:\n1. Cure in shade for 2-3 days after harvest\n2. Store in mesh/net bags — never in plastic\n3. Keep in well-ventilated, dry area at 25-30°C\n4. Check weekly for sprouting or soft spots\n5. Separate damaged onions immediately\n\nExpected shelf life: 4-8 weeks with proper storage.',
      'हिन्दी': 'प्याज भंडारण:\n1. फसल कटाई के बाद 2-3 दिन छाया में सुखाएं\n2. जालीदार बैग में रखें — प्लास्टिक में कभी नहीं\n3. 25-30°C पर हवादार, सूखी जगह में रखें',
      'ಕನ್ನಡ': 'ಈರುಳ್ಳಿ ಸಂಗ್ರಹಣೆ:\n1. ಕೊಯ್ಲಿನ ನಂತರ 2-3 ದಿನ ನೆರಳಿನಲ್ಲಿ ಒಣಗಿಸಿ\n2. ಬಲೆ ಚೀಲಗಳಲ್ಲಿ ಸಂಗ್ರಹಿಸಿ — ಪ್ಲಾಸ್ಟಿಕ್‌ನಲ್ಲಿ ಎಂದಿಗೂ ಬೇಡ',
    },
  };

  static const Map<String, String> _fallback = {
    'English': "I'm here to help! Ask me about crops, market prices, weather, storage, or sowing recommendations. I analyse real-time data to give you actionable advice.",
    'हिन्दी': 'मैं आपकी मदद के लिए यहाँ हूँ। कृपया फसल, बाजार या मौसम के बारे में पूछें।',
    'ಕನ್ನಡ': 'ನಾನು ನಿಮಗೆ ಸಹಾಯ ಮಾಡಲು ಇಲ್ಲಿದ್ದೇನೆ. ಬೆಳೆ, ಮಾರುಕಟ್ಟೆ ಅಥವಾ ಹವಾಮಾನದ ಬಗ್ಗೆ ಕೇಳಿ.',
  };

  @override
  Future<ServiceResult<String>> getResponse(String query, String language) async {
    await Future.delayed(_delay);
    if (AppConfig.simulateNetworkFailure) {
      return const ServiceResult.failure('ERR_AI_503', 'AI service temporarily unavailable');
    }
    final byLang = _responses[query];
    final text = byLang?[language] ?? byLang?['English'] ?? _fallback[language] ?? _fallback['English']!;
    return ServiceResult.success(text);
  }
}
