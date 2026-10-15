import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_message_model.dart';
import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';

/// Chat with Tulip, the farm assistant. Replies stream in from POST /assistant/chat
/// while they are written; Tulip knows the farm from its records. The conversation
/// is kept on the phone.
class TulipChatScreen extends StatefulWidget {
  const TulipChatScreen({super.key});

  @override
  State<TulipChatScreen> createState() => _TulipChatScreenState();
}

class _TulipChatScreenState extends State<TulipChatScreen> {
  static const _storageKey = 'tulip_ai_chat_history';
  static const _sendLast = 20; // messages Tulip reads, most recent first

  static const _suggestions = [
    'Why are my hens laying fewer eggs?',
    'When should I top-dress my maize?',
    'What should I do before the rains?',
    'Mifugo yangu ina kupe. Nifanye nini?',
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
        _failed = error?.message ?? 'Tulip could not answer. Try again.';
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
            _failed = 'Tulip could not answer. Try again.';
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
          _failed = 'The connection dropped. Try again.';
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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final empty = _messages.isEmpty && !_busy;

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _avatar(c, 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tulip', style: AppType.titleM.copyWith(color: c.textPrimary)),
                Text(_busy ? 'Writing…' : 'Your farm assistant',
                    style: AppType.caption.copyWith(color: _busy ? c.brandText : c.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              onPressed: _busy ? null : _newChat,
              icon: Icon(PhosphorIconsRegular.notePencil, color: c.textPrimary),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: empty ? _welcome(c) : _conversation(c)),
          _composer(c),
        ],
      ),
    );
  }

  // ── Empty chat: what Tulip can help with ─────────────────
  Widget _welcome(AppColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      children: [
        Center(child: _avatar(c, 64)),
        const SizedBox(height: 16),
        Text('Karibu! I\'m Tulip.', textAlign: TextAlign.center, style: AppType.titleL.copyWith(color: c.textPrimary)),
        const SizedBox(height: 6),
        Text(
          'Ask me about your crops, animals, weather or the market. I know your farm from your records. Write in Swahili or English.',
          textAlign: TextAlign.center,
          style: AppType.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 24),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: c.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.divider)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _send(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.chatCircleText, size: 20, color: c.brandText),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s, style: AppType.label.copyWith(color: c.textPrimary))),
                      Icon(PhosphorIconsRegular.arrowUpRight, size: 18, color: c.textHint),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── The conversation ──────────────────────────────────────
  Widget _conversation(AppColors c) {
    final items = <Widget>[
      for (final m in _messages) _bubble(c, m.text, m.isUser),
      if (_streaming != null) _streaming!.isEmpty ? _typing(c) : _bubble(c, _streaming!, false, live: true),
      if (_failed != null) _failure(c),
    ];
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: items,
    );
  }

  Widget _bubble(AppColors c, String text, bool mine, {bool live = false}) {
    final maxW = MediaQuery.sizeOf(context).width * 0.8;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[_avatar(c, 28), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? c.shamba : c.cardBackground,
                border: mine ? null : Border.all(color: c.divider),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
              ),
              child: SelectableText(
                live ? '$text ▍' : text,
                style: AppType.bodyL.copyWith(fontSize: 16, height: 1.45, color: mine ? c.onShamba : c.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typing(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _avatar(c, 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.cardBackground,
              border: Border.all(color: c.divider),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Semantics(label: 'Tulip is writing', child: _Dots(color: c.textHint)),
          ),
        ],
      ),
    );
  }

  Widget _failure(AppColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 36),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.warningCircle, size: 20, color: c.dangerInk),
          const SizedBox(width: 10),
          Expanded(child: Text(_failed!, style: AppType.body.copyWith(color: c.dangerInk))),
          TextButton(onPressed: _ask, child: const Text('Try again')),
        ],
      ),
    );
  }

  // ── Writing a message ─────────────────────────────────────
  Widget _composer(AppColors c) {
    return Container(
      decoration: BoxDecoration(color: c.cardBackground, border: Border(top: BorderSide(color: c.divider))),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.paddingOf(context).bottom),
      child: Row(
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
                hintText: 'Ask Tulip about your farm…',
                counterText: '',
                filled: true,
                fillColor: c.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: c.focus, width: 2)),
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
                label: 'Send',
                excludeSemantics: true,
                child: Material(
                  color: ready ? c.shamba : c.surfaceMuted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: ready ? () => _send() : null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(PhosphorIconsFill.paperPlaneRight, size: 20, color: ready ? c.onShamba : c.textHint),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _avatar(AppColors c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
      padding: EdgeInsets.all(size * 0.18),
      child: Image.asset(
        'images/assets/icons/tulip.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(PhosphorIconsFill.sparkle, size: size * 0.5, color: c.brandText),
      ),
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
