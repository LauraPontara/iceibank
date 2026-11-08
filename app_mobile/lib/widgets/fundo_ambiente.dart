import 'dart:math';

import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Glow mesh do design system: tres brilhos rosa que derivam devagar.
/// Fica estatico quando o sistema pede para reduzir animacoes.
class FundoAmbiente extends StatefulWidget {
  const FundoAmbiente({super.key, required this.child});

  final Widget child;

  @override
  State<FundoAmbiente> createState() => _FundoAmbienteState();
}

class _FundoAmbienteState extends State<FundoAmbiente> with SingleTickerProviderStateMixin {
  late final AnimationController _deriva = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _deriva.stop();
    } else if (!_deriva.isAnimating) {
      _deriva.repeat();
    }
  }

  @override
  void dispose() {
    _deriva.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ColoredBox(
      color: t.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _deriva,
                builder: (context, _) => CustomPaint(painter: _PintorBrilho(t.primary, _deriva.value)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _PintorBrilho extends CustomPainter {
  const _PintorBrilho(this.cor, this.progresso);

  final Color cor;
  final double progresso;

  void _brilho(Canvas canvas, Size tamanho, double x, double y, double raio, double opacidade, double fase) {
    final angulo = 2 * pi * (progresso + fase);
    final centro = Offset(tamanho.width * x + cos(angulo) * 24, tamanho.height * y + sin(angulo) * 18);
    final raioPx = tamanho.longestSide * raio;
    final tinta = Paint()
      ..shader = RadialGradient(colors: [cor.withValues(alpha: opacidade), cor.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: centro, radius: raioPx));
    canvas.drawCircle(centro, raioPx, tinta);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _brilho(canvas, size, 0.18, 0.04, 0.42, 0.28, 0);
    _brilho(canvas, size, 0.9, 0.2, 0.34, 0.14, 0.35);
    _brilho(canvas, size, 0.55, 1, 0.42, 0.12, 0.7);
  }

  @override
  bool shouldRepaint(_PintorBrilho antigo) => antigo.progresso != progresso || antigo.cor != cor;
}
