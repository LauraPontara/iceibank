import 'package:flutter/material.dart';

import '../tema/tipografia.dart';
import '../tema/tokens.dart';

/// Cartao de vidro (.surface): fundo translucido, borda de 1px e raio de 24.
class Superficie extends StatelessWidget {
  const Superficie({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
      ),
      child: child,
    );
  }
}

/// Botao pilula rosa com brilho (.btn-primary).
class BotaoPrimario extends StatefulWidget {
  const BotaoPrimario({super.key, required this.rotulo, required this.aoTocar, this.carregando = false});

  final String rotulo;
  final VoidCallback? aoTocar;
  final bool carregando;

  @override
  State<BotaoPrimario> createState() => _BotaoPrimarioState();
}

class _BotaoPrimarioState extends State<BotaoPrimario> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ativo = widget.aoTocar != null && !widget.carregando;
    return Semantics(
      button: true,
      enabled: ativo,
      child: GestureDetector(
        onTapDown: ativo ? (_) => setState(() => _pressionado = true) : null,
        onTapUp: ativo ? (_) => setState(() => _pressionado = false) : null,
        onTapCancel: ativo ? () => setState(() => _pressionado = false) : null,
        onTap: ativo ? widget.aoTocar : null,
        child: AnimatedScale(
          scale: _pressionado ? 0.98 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: ativo ? 1 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.primary,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [BoxShadow(color: t.primary.withValues(alpha: 0.45), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -10)],
              ),
              child: widget.carregando
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: t.primaryForeground))
                  : Text(widget.rotulo, style: corpo(14, peso: 500, cor: t.primaryForeground)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botao so com contorno (.btn-ghost), para acoes terciarias.
class BotaoFantasma extends StatelessWidget {
  const BotaoFantasma({super.key, required this.rotulo, required this.aoTocar, this.icone, this.cor});

  final String rotulo;
  final VoidCallback? aoTocar;
  final IconData? icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final corTexto = cor ?? t.foreground;
    return Opacity(
      opacity: aoTocar == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: t.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[Icon(icone, size: 14, color: corTexto), const SizedBox(width: 8)],
                Text(rotulo, style: corpo(13, peso: 500, cor: corTexto)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo com rotulo em caixa alta pequena (.field).
class Campo extends StatelessWidget {
  const Campo({
    super.key,
    required this.titulo,
    required this.controlador,
    this.dica,
    this.teclado,
    this.senha = false,
    this.destaque = false,
    this.validador,
    this.sufixo,
    this.aoMudar,
  });

  final String titulo;
  final TextEditingController controlador;
  final String? dica;
  final TextInputType? teclado;
  final bool senha;
  final bool destaque;
  final String? Function(String?)? validador;
  final Widget? sufixo;
  final ValueChanged<String>? aoMudar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo.toUpperCase(), style: rotulo(t.mutedForeground)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          keyboardType: teclado,
          obscureText: senha,
          validator: validador,
          onChanged: aoMudar,
          style: destaque ? display(24, peso: 500, cor: t.foreground) : corpo(15, cor: t.foreground),
          decoration: InputDecoration(hintText: dica, suffixIcon: sufixo),
        ),
      ],
    );
  }
}

/// Pilula pequena com ponto colorido (.chip).
class ChipStatus extends StatelessWidget {
  const ChipStatus({super.key, required this.texto, this.desligado = false, this.semPonto = false, this.monoespacado = false});

  final String texto;
  final bool desligado;
  final bool semPonto;
  final bool monoespacado;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final estilo = monoespacado ? mono(12, peso: 500, cor: t.mutedForeground) : corpo(12, peso: 500, cor: t.mutedForeground);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!semPonto) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: desligado ? t.destructive : t.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(texto, style: estilo, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

enum TipoAlerta { sucesso, erro, info }

/// Aviso em bloco (.alert). Sucesso e erro usam texto alem da cor.
class Alerta extends StatelessWidget {
  const Alerta({super.key, required this.texto, this.tipo = TipoAlerta.erro, this.opaco = false});

  final String texto;
  final TipoAlerta tipo;
  final bool opaco;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cor = switch (tipo) {
      TipoAlerta.sucesso => t.primary,
      TipoAlerta.erro => t.destructive,
      TipoAlerta.info => t.mutedForeground,
    };
    final tinta = cor.withValues(alpha: 0.1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: opaco ? Color.alphaBlend(tinta, t.background) : tinta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Text(texto, style: corpo(14, cor: cor, altura: 1.4)),
    );
  }
}

void mostrarAviso(BuildContext context, String texto, {TipoAlerta tipo = TipoAlerta.erro}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 4),
      content: Alerta(texto: texto, tipo: tipo, opaco: true),
    ));
}
