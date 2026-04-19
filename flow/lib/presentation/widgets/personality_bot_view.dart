import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalityBotView extends StatefulWidget {
  final String? message;
  final bool isError;
  final bool isLoading;

  const PersonalityBotView({
    super.key,
    this.message,
    this.isError = false,
    this.isLoading = false,
  });

  @override
  State<PersonalityBotView> createState() => _PersonalityBotViewState();
}

class _PersonalityBotViewState extends State<PersonalityBotView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounceAnim;
  late final String _emoji;
  late final String _quirkyMessage;

  static const _errorEmojis = [
    '>_<',
    'T_T',
    'O_O',
    '¬_¬',
    '+_+',
    'Y.Y',
    '(*>﹏<*)′',
    '(>_<)',
  ];

  static const _loadingEmojis = [
    '☆*: .｡. o(≧▽≦)o .｡.:*☆',
    '^_~',
    '~(￣▽￣)~*',
    '(＠⌒ー⌒＠)ノ',
    '♪(´▽｀)',
    '(๑•̀ㅂ•́)و✧',
  ];

  static const _successEmojis = [
    '(〃￣︶￣)人(￣︶￣〃)',
    'd=====(￣▽￣*)b',
    '(👉ﾟヮﾟ)👉',
    '👈(ﾟヮﾟ👈)',
    '👈(⌒▽⌒)👉',
    '(⌐■_■)ノ♪',
  ];

  static const _errorMessages = [
    'Oopsy! I tripped over a cable... ( >_< )',
    'The server is playing hide and seek. I can\'t find it! ( T_T )',
    'Something went "boom". Don\'t worry, I\'m fixing it! ( +_+ )',
    'My circuits are a bit tangled. One moment... ( ¬_¬ )',
    'Wait, where did the music go? ( O_O )',
  ];

  static const _loadingMessages = [
    'Cooking up some fresh beats... ( ^_~ )',
    'Polishing the records for you! ( ☆▽☆ )',
    'Searching the musical galaxy... ( ~(￣▽￣)~* )',
    'Almost there! Just catching some notes... ( ๑•̀ㅂ•́)و✧',
  ];

  @override
  void initState() {
    super.initState();
    final rand = Random();
    
    if (widget.isError) {
      _emoji = _errorEmojis[rand.nextInt(_errorEmojis.length)];
      _quirkyMessage = widget.message ?? _errorMessages[rand.nextInt(_errorMessages.length)];
    } else if (widget.isLoading) {
      _emoji = _loadingEmojis[rand.nextInt(_loadingEmojis.length)];
      _quirkyMessage = widget.message ?? _loadingMessages[rand.nextInt(_loadingMessages.length)];
    } else {
      _emoji = _successEmojis[rand.nextInt(_successEmojis.length)];
      _quirkyMessage = widget.message ?? 'All systems go! (⌐■_■)ノ♪';
    }

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_bounceAnim.value),
                child: child,
              );
            },
            child: Text(
              _emoji,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _quirkyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
