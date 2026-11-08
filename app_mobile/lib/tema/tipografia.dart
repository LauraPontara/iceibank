import 'package:flutter/painting.dart';

/// As fontes sao variaveis e ficam no proprio app (o laboratorio pode estar sem
/// internet). Fonte variavel precisa do eixo wght explicito para mudar de peso.
TextStyle _estilo(String familia, double tamanho, double peso, {double? espacamento, double? altura, Color? cor}) {
  return TextStyle(
    fontFamily: familia,
    fontSize: tamanho,
    fontWeight: FontWeight.values[((peso / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', peso)],
    letterSpacing: espacamento,
    height: altura,
    color: cor,
  );
}

TextStyle display(double tamanho, {double peso = 600, double? espacamento, double? altura, Color? cor}) =>
    _estilo('SpaceGrotesk', tamanho, peso, espacamento: espacamento, altura: altura, cor: cor);

TextStyle corpo(double tamanho, {double peso = 400, double? espacamento, double? altura, Color? cor}) =>
    _estilo('Inter', tamanho, peso, espacamento: espacamento, altura: altura, cor: cor);

TextStyle mono(double tamanho, {double peso = 400, double? espacamento, Color? cor}) =>
    _estilo('JetBrainsMono', tamanho, peso, espacamento: espacamento, cor: cor);

/// Rotulo em caixa alta: 11px a 12px com letter-spacing de 0.15em.
TextStyle rotulo(Color cor, {double tamanho = 11}) =>
    _estilo('Inter', tamanho, 500, espacamento: tamanho * 0.15, cor: cor);
