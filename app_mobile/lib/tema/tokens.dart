import 'package:flutter/material.dart';

/// Tokens semanticos do design system (frontend/DESIGN_SYSTEM.md), convertidos
/// de oklch para sRGB. Os widgets nunca usam cores fixas, so estes tokens.
@immutable
class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.background,
    required this.foreground,
    required this.card,
    required this.mutedForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.accent,
    required this.border,
    required this.input,
    required this.destructive,
    required this.ink,
    required this.metalInicio,
    required this.metalMeio,
    required this.metalFim,
    required this.metalTexto,
    required this.metalTextoSuave,
    required this.metalRotulo,
    required this.metalBorda,
    required this.metalTarja,
    required this.metalSombra,
    required this.metalChip,
    required this.metalChipBrilho,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color mutedForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color accent;
  final Color border;
  final Color input;
  final Color destructive;
  final Color ink;
  final Color metalInicio;
  final Color metalMeio;
  final Color metalFim;
  final Color metalTexto;
  final Color metalTextoSuave;
  final Color metalRotulo;
  final Color metalBorda;
  final Color metalTarja;
  final Color metalSombra;
  final Color metalChip;
  final Color metalChipBrilho;

  static const escuro = Tokens(
    background: Color(0xFF0C090B),
    foreground: Color(0xFFF5F0F2),
    card: Color(0x0AFFFFFF),
    mutedForeground: Color(0xFFA09599),
    primary: Color(0xFFF5289F),
    primaryForeground: Color(0xFFFDFBFC),
    secondary: Color(0x0FFFFFFF),
    accent: Color(0xFF442031),
    border: Color(0x1AFFFFFF),
    input: Color(0x26FFFFFF),
    destructive: Color(0xFFFF6467),
    ink: Color(0xFF100C0E),
    metalInicio: Color(0xFF3A3237),
    metalMeio: Color(0xFF191417),
    metalFim: Color(0xFF040304),
    metalTexto: Color(0xFFFFFFFF),
    metalTextoSuave: Color(0xB3FFFFFF),
    metalRotulo: Color(0x73FFFFFF),
    metalBorda: Color(0x29FFFFFF),
    metalTarja: Color(0xFF040304),
    metalSombra: Color(0x80000000),
    metalChip: Color(0xCCF5289F),
    metalChipBrilho: Color(0xFFF5289F),
  );

  static const claro = Tokens(
    background: Color(0xFFFCF9FB),
    foreground: Color(0xFF130E11),
    card: Color(0xFFFFFFFF),
    mutedForeground: Color(0xFF6C5F66),
    primary: Color(0xFFEA1496),
    primaryForeground: Color(0xFFFDFBFC),
    secondary: Color(0xFFF3ECEF),
    accent: Color(0xFFF7E6EC),
    border: Color(0xFFE9E2E5),
    input: Color(0xFFE9E2E5),
    destructive: Color(0xFFE7000B),
    ink: Color(0xFF100C0E),
    metalInicio: Color(0xFFEA1496),
    metalMeio: Color(0xFFE10B8F),
    metalFim: Color(0xFFB2006F),
    metalTexto: Color(0xFFFFFFFF),
    metalTextoSuave: Color(0xEBFFFFFF),
    metalRotulo: Color(0xE6FFFFFF),
    metalBorda: Color(0x40FFFFFF),
    metalTarja: Color(0xFF590034),
    metalSombra: Color(0x8CEA1496),
    metalChip: Color(0x47FFFFFF),
    metalChipBrilho: Color(0x73FFFFFF),
  );

  @override
  Tokens copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? mutedForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? accent,
    Color? border,
    Color? input,
    Color? destructive,
    Color? ink,
    Color? metalInicio,
    Color? metalMeio,
    Color? metalFim,
    Color? metalTexto,
    Color? metalTextoSuave,
    Color? metalRotulo,
    Color? metalBorda,
    Color? metalTarja,
    Color? metalSombra,
    Color? metalChip,
    Color? metalChipBrilho,
  }) {
    return Tokens(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      input: input ?? this.input,
      destructive: destructive ?? this.destructive,
      ink: ink ?? this.ink,
      metalInicio: metalInicio ?? this.metalInicio,
      metalMeio: metalMeio ?? this.metalMeio,
      metalFim: metalFim ?? this.metalFim,
      metalTexto: metalTexto ?? this.metalTexto,
      metalTextoSuave: metalTextoSuave ?? this.metalTextoSuave,
      metalRotulo: metalRotulo ?? this.metalRotulo,
      metalBorda: metalBorda ?? this.metalBorda,
      metalTarja: metalTarja ?? this.metalTarja,
      metalSombra: metalSombra ?? this.metalSombra,
      metalChip: metalChip ?? this.metalChip,
      metalChipBrilho: metalChipBrilho ?? this.metalChipBrilho,
    );
  }

  @override
  Tokens lerp(ThemeExtension<Tokens>? other, double t) {
    if (other is! Tokens) return this;
    return Tokens(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      metalInicio: Color.lerp(metalInicio, other.metalInicio, t)!,
      metalMeio: Color.lerp(metalMeio, other.metalMeio, t)!,
      metalFim: Color.lerp(metalFim, other.metalFim, t)!,
      metalTexto: Color.lerp(metalTexto, other.metalTexto, t)!,
      metalTextoSuave: Color.lerp(metalTextoSuave, other.metalTextoSuave, t)!,
      metalRotulo: Color.lerp(metalRotulo, other.metalRotulo, t)!,
      metalBorda: Color.lerp(metalBorda, other.metalBorda, t)!,
      metalTarja: Color.lerp(metalTarja, other.metalTarja, t)!,
      metalSombra: Color.lerp(metalSombra, other.metalSombra, t)!,
      metalChip: Color.lerp(metalChip, other.metalChip, t)!,
      metalChipBrilho: Color.lerp(metalChipBrilho, other.metalChipBrilho, t)!,
    );
  }
}

extension TokensDoContexto on BuildContext {
  Tokens get tokens => Theme.of(this).extension<Tokens>()!;
}
