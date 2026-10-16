import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_message_model.dart';
import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_ui.dart';
import '../../l10n/tr.dart';

/// Chat with Tulip, the farm assistant. Replies stream in from POST /assistant/chat
/// while they are written; Tulip knows the farm from its records. The conversation
/// is kept on the phone.
class TulipChatScreen extends StatefulWidget {
  final String? draft; // a question to start from, e.g. about a scanned photo
  const TulipChatScreen({super.key, this.draft});

  @override
  State<TulipChatScreen> createState() => _TulipChatScreenState();
}

class _TulipChatScreenState extends State<TulipChatScreen> {
  static const _storageKey = 'tulip_ai_chat_history';
  static const _sendLast = 20; // messages Tulip reads, most recent first

  static List<String> get _suggestions => [
    'Why are my hens laying fewer eggs?'.tr,
    'When should I top-dress my maize?'.tr,
    'What should I do before the rains?'.tr,
    'Mifugo yangu ina kupe. Nifanye nini?'.tr,
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  String? _streaming; // Tulip's reply as it arrives; null when not replying
  String? _failed; // why the last reply failed
  StreamSubscription<String>? _sub;

  bool get _busy => _streaming != null;

  @override
  void initState() {
    super.initState();
    if (widget.draft != null) _input.text = widget.draft!;
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || !mounted) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();
      setState(() => _messages = list);
      _toBottom(jump: true);
    } catch (_) {
      await prefs.remove(_storageKey); // an unreadable history starts fresh
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      jump ? _scroll.jumpTo(end) : _scroll.animateTo(end, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _failed = null;
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });
    await _save();
    await _ask();
  }

  /// Sends the conversation and streams Tulip's reply into the list.
  Future<void> _ask() async {
    setState(() {
      _streaming = '';
      _failed = null;
    });
    _toBottom();

    final recent = _messages.length > _sendLast ? _messages.sublist(_messages.length - _sendLast) : _messages;
    final (stream, error) = await ApiService.postStream('/assistant/chat', {
      'messages': [
        for (final m in recent) {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      ],
    });
    if (!mounted) return;
    if (stream == null) {
      setState(() {
        _streaming = null;
        _failed = error?.message ?? 'Tulip could not answer. Try again.'.tr;
      });
      return;
    }

    _sub = stream.listen(
      (chunk) {
        setState(() => _streaming = (_streaming ?? '') + chunk);
        _toBottom();
      },
      onDone: () async {
        final reply = (_streaming ?? '').trim();
        setState(() {
          _streaming = null;
          if (reply.isEmpty) {
            _failed = 'Tulip could not answer. Try again.'.tr;
          } else {
            _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
          }
        });
        await _save();
        _toBottom();
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _streaming = null;
          _failed = 'The connection dropped. Try again.'.tr;
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _newChat() async {
    await _sub?.cancel();
    setState(() {
      _messages = [];
      _streaming = null;
      _failed = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static const _sparkle = '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>';
  static const _sendIcon = '<path d="M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z"/><path d="m21.854 2.147-10.94 10.939"/>';
  static const _info = '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: Column(
        children: [
          _header(c),
          Expanded(child: _conversation(c)),
          _composer(c),
        ],
      ),
    );
  }

  // ── The bar: back, Tulip, New chat ───────────────────────
  Widget _header(AppColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 20, 8, 12),
      decoration: BoxDecoration(
        color: c.cardBackground,
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(children: [
        Semantics(
          button: true,
          label: 'Back'.tr,
          excludeSemantics: true,
          child: Material(
            color: c.surfaceMuted,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: LineIcon('<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>', size: 22, color: c.textPrimary)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _avatar(c, 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tulip'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w700, color: c.textPrimary)),
            Text(_busy ? 'Writing…'.tr : 'Your farm assistant · knows your records'.tr,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: _busy ? c.brandText : c.textSecondary)),
          ]),
        ),
        if (_messages.isNotEmpty)
          TextButton(
            onPressed: _busy ? null : _newChat,
            style: TextButton.styleFrom(minimumSize: const Size(0, 44), foregroundColor: c.brandText),
            child: Text('New chat'.tr, style: const TextStyle(fontFamily: AppType.text, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  // ── The conversation, opening with Tulip's greeting ──────
  Widget _conversation(AppColors c) {
    final replied = _messages.any((m) => !m.isUser);
    final items = <Widget>[
      _bubble(c, 'Ask me about your crops, animals, weather or the market. I know your farm from your records. Write in Swahili or English.'.tr, false),
      for (final m in _messages) _bubble(c, m.text, m.isUser),
      if (_streaming != null) _streaming!.isEmpty ? _typing(c) : _bubble(c, _streaming!, false, live: true),
      if (_failed != null) _failure(c),
      if (replied && !_busy) _warning(c),
    ];
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      children: items,
    );
  }

  /// A speech bubble: Tulip's white on the left, the farmer's green on the right.
  Widget _bubble(AppColors c, String text, bool mine, {bool live = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: mine ? c.shamba : c.cardBackground,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(mine ? 20 : 6),
              bottomRight: Radius.circular(mine ? 6 : 20),
            ),
            boxShadow: mine ? null : const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: SelectableText(
            live ? '$text ▍' : text,
            style: AppType.body.copyWith(color: mine ? c.onShamba : c.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _typing(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Semantics(label: 'Tulip is writing'.tr, child: _Dots(color: c.textHint)),
        ),
      ),
    );
  }

  /// The reminder under Tulip's answers.
  Widget _warning(AppColors c) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: c.rainTint, borderRadius: BorderRadius.circular(24)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LineIcon(_info, size: 20, color: c.rainInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text('AI can be wrong. For a sick animal, or anything spreading fast, call your vet or the county agriculture office.'.tr,
                style: AppType.caption.copyWith(color: c.textPrimary)),
          ),
        ]),
      );

  Widget _failure(AppColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Expanded(child: Text(_failed!, style: AppType.body.copyWith(color: c.dangerInk))),
          TextButton(onPressed: _ask, child: Text('Try again'.tr)),
        ],
      ),
    );
  }

  // ── Writing a message: suggestions, the box, Send ────────
  Widget _composer(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, -6))],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.paddingOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!_busy)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in _suggestions) ...[SlChip(s, onTap: () => _send(s)), const SizedBox(width: 8)],
            ]),
          ),
        if (!_busy) const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: AppType.bodyL.copyWith(fontSize: 16, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask Tulip about your farm…'.tr,
                  hintStyle: AppType.body.copyWith(color: c.textSecondary),
                  counterText: '',
                  filled: true,
                  fillColor: c.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide(color: c.focus, width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: _input,
              builder: (_, _) {
                final ready = _input.text.trim().isNotEmpty && !_busy;
                return Semantics(
                  button: true,
                  label: 'Send'.tr,
                  excludeSemantics: true,
                  child: Material(
                    color: ready ? c.shamba : c.surfaceMuted,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: ready ? () => _send() : null,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(child: LineIcon(_sendIcon, size: 22, color: ready ? c.onShamba : c.textHint)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ]),
    );
  }

  /// Tulip: a sparkle on shamba green.
  Widget _avatar(AppColors c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.shamba, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: LineIcon(_sparkle, size: size * 0.5, color: c.onShamba),
    );
  }
}

/// Three dots that rise in turn while Tulip starts writing.
class _Dots extends StatefulWidget {
  final Color color;
  const _Dots({required this.color});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            Transform.translate(
              // Each dot rises for the first half of its own third of the cycle.
              offset: Offset(0, still ? 0 : -4 * math.max(0.0, math.sin(2 * math.pi * ((_c.value - i / 3) % 1)))),
              child: Container(width: 7, height: 7, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
            ),
            if (i < 2) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}
