class CreditoRejeitado(Exception):
    """O credito nao pode ser aplicado e a mensagem deve ir para a dead-letter queue."""


def aplicar_credito_remoto(contas, relogio, registro, creditos_processados):
    """Devolve o tratador das mensagens de credito vindas de outras agencias."""

    def tratar(mensagem):
        id_conta = mensagem["idConta"]
        valor = mensagem["valor"]
        origem = mensagem["origemAgencia"]

        # A fila entrega ao menos uma vez: uma mensagem reentregue nao pode creditar duas vezes.
        if not creditos_processados.registrar_se_novo(f"credito:{mensagem['idTransferencia']}"):
            return

        with relogio.exclusivo():
            # Regra 3 do relogio vetorial: ao receber, funde o vetor recebido com o local.
            vetor = relogio.ao_receber(mensagem["vetorEnvio"])
            conta_existe = contas.existe(id_conta)
            if conta_existe:
                contas.creditar(id_conta, valor)

        if not conta_existe:
            registro.registrar("CREDITO_REMOTO_FALHOU", vetor, {
                "idConta": id_conta, "valor": valor, "origemAgencia": origem, "motivo": "conta nao encontrada",
            })
            # Rejeitar a mensagem (nack sem requeue) a manda para a dead-letter queue, onde pode ser inspecionada.
            raise CreditoRejeitado(f"conta {id_conta} nao encontrada")

        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", vetor, {
            "idConta": id_conta, "valor": valor, "origemAgencia": origem,
        })

    return tratar
