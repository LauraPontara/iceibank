class CreditoRejeitado(Exception):
    """O credito nao pode ser aplicado e a mensagem deve ir para a dead-letter queue."""


def aplicar_credito_remoto(contas, relogio, registro):
    """Devolve o tratador das mensagens de credito vindas de outras agencias."""

    def tratar(mensagem):
        id_conta = mensagem["idConta"]
        valor = mensagem["valor"]
        origem = mensagem["origemAgencia"]

        # Regra 3 do relogio vetorial: ao receber, funde o vetor recebido com o local.
        vetor = relogio.ao_receber(mensagem["vetorEnvio"])

        if not contas.existe(id_conta):
            registro.registrar("CREDITO_REMOTO_FALHOU", vetor, {
                "idConta": id_conta, "valor": valor, "origemAgencia": origem, "motivo": "conta nao encontrada",
            })
            # Rejeitar a mensagem (nack sem requeue) a manda para a dead-letter queue, onde pode ser inspecionada.
            raise CreditoRejeitado(f"conta {id_conta} nao encontrada")

        contas.creditar(id_conta, valor)
        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", vetor, {
            "idConta": id_conta, "valor": valor, "origemAgencia": origem,
        })

    return tratar
