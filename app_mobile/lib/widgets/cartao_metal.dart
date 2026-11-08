import 'dart:math';

import 'package:flutter/material.dart';

import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../util/formato.dart';

/// Versao mobile do MetalCard: sem mouse para inclinar, ele vira com um toque.
class CartaoMetal extends StatefulWidget {
  const CartaoMetal({super.key, required this.titular, required this.conta, required this.saldo, this.rotuloSaldo = 'Saldo'});

  final String titular;
  final int conta;
  final double? saldo;
  final String rotuloSaldo;

  @override
  State<CartaoMetal> createState() => _CartaoMetalState();
}

class _CartaoMetalState extends State<CartaoMetal> {
  bool _virado = false;

  @override
  Widget build(BuildContext context) {
    final reduzido = MediaQuery.disableAnimationsOf(context);
    final finais = widget.conta.toString().padLeft(4, '0');
    final ultimos = finais.substring(finais.length - 4);
    return Semantics(
      button: true,
      label: 'Cartão ICEIBank Metal final $ultimos, titular ${widget.titular}. Toque para virar o cartão.',
      child: GestureDetector(
        onTap: () => setState(() => _virado = !_virado),
        // A altura vem da proporcao do cartao, entao a fonte do sistema nao pode crescer sem limite
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AspectRatio(
              aspectRatio: 1.586,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _virado ? pi : 0),
                duration: reduzido ? Duration.zero : const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, angulo, _) {
                  final mostrandoVerso = angulo > pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angulo),
                    child: mostrandoVerso
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: _Verso(titular: widget.titular, conta: widget.conta),
                          )
                        : _Frente(ultimos: ultimos, saldo: widget.saldo, rotuloSaldo: widget.rotuloSaldo),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _decoracaoFace(Tokens t) => BoxDecoration(
  borderRadius: BorderRadius.circular(26),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [t.metalInicio, t.metalMeio, t.metalFim],
    stops: const [0, 0.42, 1],
  ),
  border: Border.all(color: t.metalBorda),
  boxShadow: [
    BoxShadow(color: t.primary.withValues(alpha: 0.4), blurRadius: 60, offset: const Offset(0, 24), spreadRadius: -30),
    BoxShadow(color: t.metalSombra, blurRadius: 60, offset: const Offset(0, 36), spreadRadius: -24),
  ],
);

TextStyle _estiloRotulo(Tokens t) => corpo(10, peso: 500, espacamento: 2, cor: t.metalRotulo);

class _Frente extends StatelessWidget {
  const _Frente({required this.ultimos, required this.saldo, required this.rotuloSaldo});

  final String ultimos;
  final double? saldo;
  final String rotuloSaldo;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _decoracaoFace(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ICEIBank', style: display(14, cor: t.metalTexto)),
              Text('METAL', style: corpo(12, peso: 500, espacamento: 2.4, cor: t.metalRotulo)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: t.metalChip,
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  boxShadow: [BoxShadow(color: t.metalChipBrilho, blurRadius: 20, spreadRadius: -2)],
                ),
              ),
              const SizedBox(width: 12),
              Text('5301 ···· $ultimos', style: corpo(13, espacamento: 3.4, cor: t.metalTextoSuave)),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotuloSaldo.toUpperCase(), style: _estiloRotulo(t)),
                    const SizedBox(height: 2),
                    if (saldo == null)
                      Text('...', style: display(22, peso: 500, cor: t.metalTexto))
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: saldo),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, valor, _) => Text(
                          formatarMoeda(valor),
                          style: display(22, peso: 500, cor: t.metalTexto),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Text('VISA', style: corpo(14, peso: 500, cor: t.metalTextoSuave)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Verso extends StatelessWidget {
  const _Verso({required this.titular, required this.conta});

  final String titular;
  final int conta;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: _decoracaoFace(t),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 40, margin: const EdgeInsets.only(top: 20), color: t.metalTarja),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TITULAR', style: _estiloRotulo(t)),
                const SizedBox(height: 2),
                Text(
                  titular,
                  style: display(16, peso: 500, cor: t.metalTexto),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text('CONTA', style: _estiloRotulo(t)),
                const SizedBox(height: 2),
                Text('$conta', style: mono(16, peso: 500, cor: t.metalTexto)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
