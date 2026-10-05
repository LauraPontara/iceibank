import json
import os
import threading
import time

import pika

EXCHANGE = "iceibank.eventos"
EXCHANGE_MORTAS = "iceibank.mortas"
FILA_MORTAS = "fila-mensagens-mortas"
INTERVALO_RECONEXAO_S = 3


def exigir_configuracao():
    if not os.environ.get("RABBITMQ_URL"):
        raise SystemExit(
            "Defina a variável de ambiente RABBITMQ_URL com a URL AMQP do RabbitMQ antes de iniciar "
            "(ex.: amqp://guest:guest@localhost:5672/)."
        )


def _conectar():
    return pika.BlockingConnection(pika.URLParameters(os.environ["RABBITMQ_URL"]))


def nome_fila(id_agencia):
    return f"fila-agencia-{id_agencia}"


def _chave_creditar(id_agencia):
    return f"agencia.{id_agencia}.creditar"


def _preparar_fila(canal, id_agencia):
    # Mensagens rejeitadas (nack sem requeue) vao para a dead-letter queue em vez de se perderem.
    canal.exchange_declare(exchange=EXCHANGE_MORTAS, exchange_type="fanout", durable=True)
    canal.queue_declare(queue=FILA_MORTAS, durable=True)
    canal.queue_bind(queue=FILA_MORTAS, exchange=EXCHANGE_MORTAS)

    canal.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)
    canal.queue_declare(
        queue=nome_fila(id_agencia),
        durable=True,
        arguments={"x-dead-letter-exchange": EXCHANGE_MORTAS},
    )
    canal.queue_bind(queue=nome_fila(id_agencia), exchange=EXCHANGE, routing_key=_chave_creditar(id_agencia))


def publicar_credito(id_agencia_destino, mensagem):
    """Publica o credito na exchange. A fila do destino e declarada aqui tambem,
    para que a mensagem fique retida mesmo que aquela agencia nunca tenha subido."""
    conexao = _conectar()
    try:
        canal = conexao.channel()
        _preparar_fila(canal, id_agencia_destino)
        canal.confirm_delivery()
        canal.basic_publish(
            exchange=EXCHANGE,
            routing_key=_chave_creditar(id_agencia_destino),
            body=json.dumps(mensagem).encode("utf-8"),
            properties=pika.BasicProperties(delivery_mode=pika.DeliveryMode.Persistent, content_type="application/json"),
            mandatory=True,
        )
    finally:
        conexao.close()


def assinar(id_agencia, ao_receber_mensagem):
    """Consome a fila da agencia numa thread propria, reconectando se o broker cair."""

    def ao_chegar(canal, metodo, _propriedades, corpo):
        try:
            ao_receber_mensagem(json.loads(corpo))
            canal.basic_ack(delivery_tag=metodo.delivery_tag)
        except Exception as erro:
            print(f"[mensageria] falha ao processar mensagem: {erro!r}")
            canal.basic_nack(delivery_tag=metodo.delivery_tag, requeue=False)

    def laco():
        while True:
            try:
                conexao = _conectar()
                canal = conexao.channel()
                _preparar_fila(canal, id_agencia)
                canal.basic_qos(prefetch_count=1)
                canal.basic_consume(queue=nome_fila(id_agencia), on_message_callback=ao_chegar)
                print(f"[mensageria] consumindo {nome_fila(id_agencia)}")
                canal.start_consuming()
            except pika.exceptions.AMQPError as erro:
                print(f"[mensageria] conexão perdida ({erro!r}); tentando de novo em {INTERVALO_RECONEXAO_S}s")
                time.sleep(INTERVALO_RECONEXAO_S)

    threading.Thread(target=laco, name=f"consumidor-agencia-{id_agencia}", daemon=True).start()
