import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../tema/tokens.dart';

const _duracaoDeriva = Duration(seconds: 24);
const _intervaloDeriva = Duration(milliseconds: 200);

/// Glow mesh do design system: tres brilhos rosa que derivam devagar.
/// O movimento e de poucos pixels, entao 5 quadros por segundo bastam e poupam
/// bateria. Fica estatico quando o sistema pede para reduzir animacoes.
class FundoAmbiente extends StatefulWidget {
  const FundoAmbiente({super.key, required this.child});

  final Widget child;

  @override
  State<FundoAmbiente> createState() => _FundoAmbienteState();
}

class _FundoAmbienteState extends State<FundoAmbiente> {
  final _progresso = ValueNotifier<double>(0);
  Timer? _temporizador;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _temporizador?.cancel();
      _temporizador = null;
    } else {
      _temporizador ??= Timer.periodic(_intervaloDeriva, (_) {
        _progresso.value = (_progresso.value + _intervaloDeriva.inMilliseconds / _duracaoDeriva.inMilliseconds) % 1;
      });
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _progresso.dispose();
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
            child: RepaintBoundary(child: CustomPaint(painter: _PintorBrilho(t.primary, _progresso))),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _PintorBrilho extends CustomPainter {
  _PintorBrilho(this.cor, this.progresso) : super(repaint: progresso);

  final Color cor;
  final ValueNotifier<double> progresso;

  void _brilho(Canvas canvas, Size tamanho, double x, double y, double raio, double opacidade, double fase) {
    final angulo = 2 * pi * (progresso.value + fase);
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
  bool shouldRepaint(_PintorBrilho antigo) => antigo.cor != cor;
}
