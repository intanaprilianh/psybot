import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class MeditasiSession {
  final String title;
  final String subtitle;
  final String kategori;
  final int durasiMenit;
  final IconData icon;
  final Color color;

  const MeditasiSession({
    required this.title,
    required this.subtitle,
    required this.kategori,
    required this.durasiMenit,
    required this.icon,
    required this.color,
  });
}

class SesiMeditasiPage extends StatefulWidget {
  final MeditasiSession session;

  const SesiMeditasiPage({super.key, required this.session});

  @override
  State<SesiMeditasiPage> createState() => _SesiMeditasiPageState();
}

class _SesiMeditasiPageState extends State<SesiMeditasiPage>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  int _elapsedSeconds = 0;
  bool _isPlaying = false;
  Timer? _timer;
  late AnimationController _pulseController;

  // Breathing guide (Relaksasi Napas): a slow, steady inhale–hold–exhale cycle.
  static const List<({String label, int seconds, double scale})> _breathPhases =
      [
    (label: 'Tarik napas perlahan...', seconds: 4, scale: 1.18),
    (label: 'Tahan sejenak...', seconds: 4, scale: 1.18),
    (label: 'Hembuskan perlahan...', seconds: 6, scale: 0.85),
  ];

  bool get _isBreathing =>
      widget.session.kategori == 'Pernapasan' ||
      widget.session.kategori == 'Relaksasi';

  // Derive the breathing phase from elapsed time so it follows the timeline
  // (including skip forward/back) instead of running on its own clock.
  int get _breathIndex {
    final int cycle =
        _breathPhases.fold<int>(0, (sum, p) => sum + p.seconds);
    int t = _elapsedSeconds % cycle;
    for (int i = 0; i < _breathPhases.length; i++) {
      if (t < _breathPhases[i].seconds) return i;
      t -= _breathPhases[i].seconds;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.session.durasiMenit * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_elapsedSeconds < _totalSeconds) {
            _elapsedSeconds++;
          } else {
            _isPlaying = false;
            _timer?.cancel();
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  void _skipBack() {
    setState(() {
      _elapsedSeconds = (_elapsedSeconds - 15).clamp(0, _totalSeconds);
    });
  }

  void _skipForward() {
    setState(() {
      _elapsedSeconds = (_elapsedSeconds + 15).clamp(0, _totalSeconds);
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : _elapsedSeconds / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;

    final Widget iconCircle = Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 3,
        ),
      ),
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.session.icon,
            size: 68,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Show the breathing guide once the session has started, so it keeps
    // following the timeline even while paused or after skipping.
    final bool breathStarted = _isPlaying || _elapsedSeconds > 0;

    // The breathing session expands/contracts the circle to pace each
    // inhale/hold/exhale; other sessions keep the gentle pulse.
    final Widget animatedIcon = _isBreathing
        ? AnimatedScale(
            scale: breathStarted ? _breathPhases[_breathIndex].scale : 1.0,
            duration: Duration(
              seconds: breathStarted ? _breathPhases[_breathIndex].seconds : 1,
            ),
            curve: Curves.easeInOut,
            child: iconCircle,
          )
        : AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double scale =
                  _isPlaying ? 1.0 + (_pulseController.value * 0.04) : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: iconCircle,
          );

    return Scaffold(
      backgroundColor:
          context.isDark ? AppColors.darkPurple : const Color(0xFFFFEDEA),
      body: Stack(
        children: [
          // Decorative blob at top
          Positioned(
            top: -screenHeight * 0.08,
            left: -40,
            right: -40,
            child: Container(
              height: screenHeight * 0.55,
              decoration: const BoxDecoration(
                color: Color(0xFFB172B4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(120),
                  bottomRight: Radius.circular(120),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _CircleButton(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.purple,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.session.kategori,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Session icon, sitting inside the top blob
                animatedIcon,

                const SizedBox(height: 28),

                // Session title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        widget.session.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.darkPurple,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.session.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.purple,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Breathing guide, centered in the area below the blob.
                if (_isBreathing)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            breathStarted
                                ? _breathPhases[_breathIndex].label
                                : 'Tekan tombol putar, lalu ikuti irama napasnya',
                            key: ValueKey(
                              breathStarted ? _breathIndex : -1,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.purple,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                // Bottom control panel
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.accentPurple,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Time labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatTime(_totalSeconds),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Controls: skip back, play/pause, skip forward
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Skip back 15s
                          _ControlButton(
                            onTap: _skipBack,
                            icon: Icons.replay_10_rounded,
                            size: 32,
                          ),

                          const SizedBox(width: 32),

                          // Play / Pause
                          GestureDetector(
                            onTap: _togglePlay,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.accentPurple,
                                size: 42,
                              ),
                            ),
                          ),

                          const SizedBox(width: 32),

                          // Skip forward 15s
                          _ControlButton(
                            onTap: _skipForward,
                            icon: Icons.forward_10_rounded,
                            size: 32,
                          ),
                        ],
                      ),

                      SizedBox(
                        height:
                            MediaQuery.paddingOf(context).bottom + 32,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;

  const _ControlButton({
    required this.onTap,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
