import 'package:flutter/material.dart';

import '../tema/tipografia.dart';
import '../tema/tokens.dart';

/// Mesmo desenho do LogoIcon.vue do frontend, em uma grade de 64 por 64.
class LogoIcone extends StatelessWidget {
  const LogoIcone({super.key, this.tamanho = 34});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ICEIBank',
      child: CustomPaint(size: Size.square(tamanho), painter: const _PintorLogo()),
    );
  }
}

class _PintorLogo extends CustomPainter {
  const _PintorLogo();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    final fundo = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 64, 64), const Radius.circular(16));
    canvas.drawRRect(
      fundo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.75, -0.9),
          end: Alignment(0.75, 0.9),
          stops: [0, 0.55, 1],
          colors: [Color(0xFFFF5CB8), Color(0xFFF0289F), Color(0xFFA30D5F)],
        ).createShader(const Rect.fromLTWH(0, 0, 64, 64)),
    );
    canvas.drawRRect(
      fundo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.5],
          colors: [Color(0x47FFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTWH(0, 0, 64, 64)),
    );

    canvas.translate(0, 1.75);
    final branco = Paint()..color = Colors.white;
    canvas.drawPath(
      Path()
        ..moveTo(32, 9.5)
        ..lineTo(39, 17)
        ..lineTo(32, 24.5)
        ..lineTo(25, 17)
        ..close(),
      Paint()..color = const Color(0xFFFFE9F5),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 29, 16, 4), const Radius.circular(2)), branco);
    canvas.drawRect(const Rect.fromLTWH(28, 33, 8, 14), branco);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 47, 16, 4), const Radius.circular(2)), branco);
  }

  @override
  bool shouldRepaint(_PintorLogo antigo) => false;
}

class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, this.tamanho = 30});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoIcone(tamanho: tamanho),
        const SizedBox(width: 10),
        Text('ICEIBank', style: display(18, espacamento: -0.2, cor: context.tokens.foreground)),
      ],
    );
  }
}
