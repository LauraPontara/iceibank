import 'package:flutter/material.dart';

import 'tipografia.dart';
import 'tokens.dart';

ThemeData criarTema(Tokens t, Brightness brilho) {
  final esquema = ColorScheme.fromSeed(
    seedColor: t.primary,
    brightness: brilho,
    primary: t.primary,
    onPrimary: t.primaryForeground,
    surface: t.background,
    onSurface: t.foreground,
    error: t.destructive,
  );

  final bordaCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: t.input),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: esquema,
    scaffoldBackgroundColor: t.background,
    fontFamily: 'Inter',
    extensions: [t],
    textTheme: TextTheme(bodyMedium: corpo(14, cor: t.foreground), bodyLarge: corpo(16, cor: t.foreground)),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.primary,
      selectionHandleColor: t.primary,
      selectionColor: t.primary.withValues(alpha: 0.3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: corpo(15, cor: t.mutedForeground.withValues(alpha: 0.6)),
      border: bordaCampo,
      enabledBorder: bordaCampo,
      focusedBorder: bordaCampo.copyWith(borderSide: BorderSide(color: t.primary)),
      errorBorder: bordaCampo.copyWith(borderSide: BorderSide(color: t.destructive)),
      focusedErrorBorder: bordaCampo.copyWith(borderSide: BorderSide(color: t.destructive)),
      errorStyle: corpo(12, cor: t.destructive),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: brilho == Brightness.dark ? const Color(0xFF191417) : t.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: t.border)),
      titleTextStyle: display(18, cor: t.foreground),
      contentTextStyle: corpo(14, cor: t.mutedForeground, altura: 1.5),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
  );
}
