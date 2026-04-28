import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_theme.dart';
import '../../core/services/models.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/error_state_widget.dart';

class AiCopilotScreen extends StatefulWidget {
  const AiCopilotScreen({super.key});
  @override
  State<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends State<AiCopilotScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _tts = FlutterTts();
  final _speech = stt.SpeechToText();
  final AiService _ai = MockAiService.instance;

  bool _isListening = false;
  bool _isLoading = false; // AI response in-flight
  bool _historyLoaded = false;
  String? _historyError;
  String _selectedLang = 'English';
  final _langs = ['English', 'हिन्दी', 'ಕನ್ನಡ'];
  List<ChatMessage> _messages = [];

  static const _suggestions = [
    'What should I sell today?',
    'Is it safe to sow?',
    'How to store onions?',
  ];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-IN');
    _tts.setSpeechRate(0.45);
    _loadHistory();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final history = await StorageService.instance.loadChatHistory();
      if (mounted) {
        setState(() {
          _messages = history;
          _historyLoaded = true;
        });
        _scrollBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyLoaded = true;
          _historyError = 'ERR_STORAGE: ${e.runtimeType}';
        });
      }
    }
  }

  Future<void> _persistHistory() async {
    try {
      await StorageService.instance.saveChatHistory(_messages);
    } catch (_) {
      // Persistence failure is non-fatal; chat still works in-session.
    }
  }

  // ── Messaging ────────────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    final userMsg = ChatMessage(text: text.trim(), isUser: true, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _textCtrl.clear();
    _scrollBottom();

    final result = await _ai.getResponse(text.trim(), _selectedLang);

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Couldn\'t retrieve content  [${result.errorCode ?? 'ERR_UNKNOWN'}]\n${result.errorMessage ?? ''}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } else {
      final aiMsg = ChatMessage(text: result.data!, isUser: false, timestamp: DateTime.now());
      setState(() {
        _messages.add(aiMsg);
        _isLoading = false;
      });
      _tts.speak(result.data!);
    }

    _scrollBottom();
    await _persistHistory();
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _startListen() async {
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'notListening' && mounted) setState(() => _isListening = false);
      },
    );
    if (ok && mounted) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (r) {
        if (r.finalResult) {
          _send(r.recognizedWords);
          setState(() => _isListening = false);
        }
      });
    }
  }

  Future<void> _clearHistory() async {
    await StorageService.instance.clearChatHistory();
    setState(() => _messages = []);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_historyLoaded) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(child: LoadingStateWidget(label: 'Loading chat history…')),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(children: [
          _header(),
          _langRow(),
          Expanded(child: _chatArea()),
          if (_messages.isEmpty && !_isLoading) _chips(),
          if (_isLoading) _typingIndicator(),
          _inputBar(),
        ]),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.urgencyGreen, Color(0xFF16A34A)]), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Copilot', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Row(children: [
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.urgencyGreen, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Online • KrishiRaksha AI', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
          ]),
        ]),
        const Spacer(),
        if (_messages.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.cardDark,
                title: Text('Clear history?', style: GoogleFonts.poppins(color: Colors.white)),
                content: Text('This will permanently delete all chat messages.', style: GoogleFonts.poppins(color: Colors.white54)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Clear', style: GoogleFonts.poppins(color: AppTheme.urgencyRed))),
                ],
              ));
              if (confirm == true) _clearHistory();
            },
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 22),
          ),
      ]),
    );
  }

  Widget _langRow() {
    return Container(height: 44, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListView(scrollDirection: Axis.horizontal, children: _langs.map((l) {
        final s = l == _selectedLang;
        return Padding(padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(l, style: GoogleFonts.poppins(color: s ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
            selected: s, selectedColor: AppTheme.forestGreen, backgroundColor: AppTheme.cardDark,
            side: BorderSide(color: s ? AppTheme.harvestAmber.withAlpha(120) : Colors.white10),
            onSelected: (_) => setState(() => _selectedLang = l),
          ));
      }).toList()));
  }

  Widget _chatArea() {
    if (_messages.isEmpty && _historyError != null) {
      return ErrorStateWidget(errorCode: _historyError, errorMessage: 'Chat history could not be loaded.', onRetry: _loadHistory);
    }
    if (_messages.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.eco_rounded, color: AppTheme.forestGreen.withAlpha(120), size: 64),
        const SizedBox(height: 16),
        Text('Ask me anything about\nyour farm & crops',
            textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 16)),
      ]));
    }
    return ListView.builder(
      controller: _scrollCtrl, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(ChatMessage msg) {
    final u = msg.isUser;
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: u ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!u) ...[
            Container(width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.urgencyGreen.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.eco_rounded, color: AppTheme.urgencyGreen, size: 18)),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: u ? AppTheme.forestGreen : AppTheme.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(u ? 16 : 4), bottomRight: Radius.circular(u ? 4 : 16)),
              border: Border.all(color: u ? AppTheme.greenMid : Colors.white10),
            ),
            child: Text(msg.text, style: GoogleFonts.poppins(color: Colors.white.withAlpha(220), fontSize: 13, height: 1.5)),
          )),
          if (u) const SizedBox(width: 8),
        ],
      ));
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.urgencyGreen.withAlpha(30), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.eco_rounded, color: AppTheme.urgencyGreen, size: 18)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 4), _dot(150), const SizedBox(width: 4), _dot(300),
          ])),
      ]),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, v, child) => Container(width: 6, height: 6,
          decoration: BoxDecoration(color: AppTheme.harvestAmber.withAlpha((v * 200 + 55).toInt()), shape: BoxShape.circle)),
    );
  }

  Widget _chips() {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Try asking:', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _suggestions.map((s) => ActionChip(
          label: Text(s, style: GoogleFonts.poppins(color: AppTheme.harvestAmber, fontSize: 12)),
          backgroundColor: AppTheme.forestGreen.withAlpha(80),
          side: BorderSide(color: AppTheme.harvestAmber.withAlpha(60)),
          onPressed: () => _send(s),
        )).toList()),
      ]));
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(color: AppTheme.cardDark, border: Border(top: BorderSide(color: Colors.white.withAlpha(10)))),
      child: Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
          child: TextField(
            controller: _textCtrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type your question…',
              hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 14),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            onSubmitted: _send,
          ),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _isListening ? () { _speech.stop(); setState(() => _isListening = false); } : _startListen,
          child: Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: _isListening ? AppTheme.urgencyRed.withAlpha(30) : AppTheme.forestGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _isListening ? AppTheme.urgencyRed : AppTheme.greenMid)),
            child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isListening ? AppTheme.urgencyRed : AppTheme.harvestAmber, size: 22)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _send(_textCtrl.text),
          child: Container(width: 48, height: 48,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.forestGreen, AppTheme.greenMid]), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.send_rounded, color: AppTheme.harvestAmber, size: 20)),
        ),
      ]),
    );
  }
}
