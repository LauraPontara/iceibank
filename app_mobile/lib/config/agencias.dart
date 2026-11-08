/// Mesmo OFFSET pessoal do agencia/src/config.py.
const portaBase = 4030;
const numeroAgencias = 3;

/// IP do PC na rede Wi-Fi. Pode ser trocado na hora de compilar
/// (--dart-define=AGENCIA_HOST=...) ou na tela de login.
const hostPadrao = String.fromEnvironment('AGENCIA_HOST', defaultValue: '192.168.0.11');

class Agencia {
  const Agencia(this.id, this.url);

  final int id;
  final String url;

  String get nome => 'Agência $id';
}

List<Agencia> agenciasDoHost(String host) =>
    List.generate(numeroAgencias, (id) => Agencia(id, 'http://$host:${portaBase + id}'));

int agenciaDaConta(int idConta) => idConta.abs() % numeroAgencias;
