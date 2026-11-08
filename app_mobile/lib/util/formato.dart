import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _dataHora = DateFormat('dd/MM/yy HH:mm');
final _hora = DateFormat('HH:mm:ss');

String formatarMoeda(num valor) => _moeda.format(valor);

String formatarDataHora(DateTime momento) => _dataHora.format(momento);

String formatarHora(DateTime momento) => _hora.format(momento);

/// Aceita tanto 12,50 quanto 12.50.
double? lerValor(String texto) {
  final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
  return valor != null && valor.isFinite ? valor : null;
}
