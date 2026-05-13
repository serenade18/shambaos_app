import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message_model.dart';

class TulipAiScreen extends StatefulWidget {
  const TulipAiScreen({super.key});

  @override
  State<TulipAiScreen> createState() => _TulipAiScreenState();
}

class _TulipAiScreenState extends State<TulipAiScreen>
    with SingleTickerProviderStateMixin {
  bool _chatStarted = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // WELCOME SCREEN
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_chatStarted) {
      return _buildChatScreen();
    }
    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chat with Tulip',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // ── Chip ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'YOUR FARM ASSISTANT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ──
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(text: 'Welcome to '),
                        TextSpan(
                          text: 'Tulip AI',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your intelligent farming companion,\nalways ready to help',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Avatar ──
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F5E9),
                        border: Border.all(
                          color: const Color(0xFFA5D6A7),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Image.asset(
                          'images/assets/icons/tulip.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF4CAF50),
                            size: 72,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Status badges ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badge(
                        icon: Icons.circle,
                        iconColor: const Color(0xFF4CAF50),
                        label: 'Online now',
                      ),
                      const SizedBox(width: 10),
                      _badge(
                        icon: Icons.access_time_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        label: '24 / 7',
                      ),
                      const SizedBox(width: 10),
                      _badge(
                        icon: Icons.bolt_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        label: 'Instant',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Description card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8),
                        width: 1,
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF555555),
                          height: 1.65,
                        ),
                        children: [
                          TextSpan(
                            text: 'Tulip AI ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          TextSpan(
                            text:
                                'is your personal farming assistant. Get advice on crops, livestock, markets, and weather — all in one place.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer CTA ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0F0F0),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _chatStarted = true),
                    icon: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Start Chatting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Powered by ShambaOS · Available in Swahili & English',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CHAT SCREEN (placeholder — wire up your chat logic here)
  // ══════════════════════════════════════════════════════════
  Widget _buildChatScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() => _chatStarted = false),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F5E9),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  'images/assets/icons/tulip.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF4CAF50),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tulip AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        ),
      ),
      body: const Center(
        child: Text(
          'Chat UI goes here',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      ),
    );
  }
}