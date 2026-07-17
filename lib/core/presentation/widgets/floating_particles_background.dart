import 'dart:math';
import 'package:flutter/material.dart';

class FloatingParticlesBackground extends StatefulWidget {
  const FloatingParticlesBackground({super.key});

  @override
  State<FloatingParticlesBackground> createState() => _FloatingParticlesBackgroundState();
}

class _FloatingParticlesBackgroundState extends State<FloatingParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  final List<String> _emojis = [
    '🍎', '🍌', '🍇', '🍓', '🍒', '🍑', '🍍', '🍅', '🥕', '🥦', '🥑', '🍋', '🍊'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _updateParticles();
        });
      })..repeat();
  }

  _Particle _createParticle(Size screenSize, {bool isInitial = false}) {
    return _Particle(
      emoji: _emojis[_random.nextInt(_emojis.length)],
      x: _random.nextDouble() * screenSize.width,
      y: isInitial
          ? _random.nextDouble() * screenSize.height
          : screenSize.height + 50,
      size: 20.0 + _random.nextDouble() * 30.0,
      speed: 0.5 + _random.nextDouble() * 1.5,
      angle: _random.nextDouble() * 2 * pi,
      rotationSpeed: -0.02 + _random.nextDouble() * 0.04,
      opacity: 0.15 + _random.nextDouble() * 0.20,
    );
  }

  void _updateParticles() {
    final screenSize = MediaQuery.of(context).size;
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y -= p.speed;
      p.angle += p.rotationSpeed;

      if (p.y < -50) {
        _particles[i] = _createParticle(screenSize);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_particles.isEmpty && size.width > 0 && size.height > 0) {
      for (int i = 0; i < 15; i++) {
        _particles.add(_createParticle(size, isInitial: true));
      }
    }

    return SizedBox.expand(
      child: Stack(
        children: _particles.map((p) {
          return Positioned(
            left: p.x,
            top: p.y,
            child: Transform.rotate(
              angle: p.angle,
              child: Opacity(
                opacity: p.opacity,
                child: Text(
                  p.emoji,
                  style: TextStyle(fontSize: p.size),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Particle {
  final String emoji;
  double x;
  double y;
  final double size;
  final double speed;
  double angle;
  final double rotationSpeed;
  final double opacity;

  _Particle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
    required this.opacity,
  });
}
