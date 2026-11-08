# Respostas Sprint 1 - ICEIBank

Linguagem escolhida: Python, com FastAPI. Autenticação com PyJWT, senha guardada com hash PBKDF2-HMAC-SHA256 e salt. Frontend em Vue 3 com Vite.

Vídeo de apresentação: https://www.youtube.com/watch?v=RhjO11qtAps

## Parte B. Relógio de Lamport

### 1. Por que usar max(contador_local, timestampRecebido) + 1 em vez de adotar o timestamp recebido diretamente?

Se o processo simplesmente adotasse o timestamp recebido, ele poderia andar para trás no tempo lógico. Imagina a Agência 0 no contador 10, processando eventos locais o tempo todo, e recebendo uma mensagem de outra agência com timestamp 3. Se ela adotasse o 3 diretamente, o próximo evento local dela teria timestamp 4, um valor menor que o 10 que ela já tinha alcançado antes. Isso quebraria a garantia central do algoritmo: que todo evento que acontece depois, na perspectiva causal daquele processo, tem um timestamp maior que os anteriores. Usar o máximo entre o contador local e o recebido garante que o relógio só anda para frente, nunca para trás, e o +1 garante que o evento de recebimento em si também conta como um evento novo, posterior a ambos.

### 2. Agência 0 no contador 10 recebe uma mensagem com timestamp 3. Qual o novo valor? O que isso implica?

O novo valor é max(10, 3) + 1 = 11. Isso implica que agências que processam muitos eventos rapidamente (como a Agência 0 nesse exemplo) têm seus contadores sempre avançando bem à frente das agências mais lentas, e uma mensagem vinda de uma agência atrasada não consegue "puxar para trás" o contador de quem está adiantado, ela só empurra para frente quando o valor recebido é maior que o local. Na prática, isso significa que o valor absoluto do contador de Lamport não serve para comparar o quão "rápida" ou "devagar" uma agência está, ele só serve para ordenar causalmente os eventos dentro do que cada processo efetivamente viu.

## Parte D. Transferências

### 1. Por que a transferência local não usa aoEnviar()/aoReceber(), e a transferência entre agências usa?

O relógio de Lamport existe para ordenar eventos que atravessam processos diferentes, quando uma mensagem sai de um processo e chega em outro. Na transferência local, o débito e o crédito acontecem dentro do mesmo processo (a mesma agência), então não existe uma mensagem sendo enviada para lugar nenhum, os dois eventos já estão naturalmente ordenados porque são sequenciais no mesmo código, no mesmo relógio. Por isso os dois usam evento_local(), que apenas incrementa o contador sem envolver comunicação entre processos. Já a transferência entre agências envolve uma requisição HTTP real de uma agência para outra, então o timestamp precisa "viajar" junto com a mensagem: quem envia usa ao_enviar() para marcar aquele envio, e quem recebe usa ao_receber(timestampLamport) para atualizar seu próprio relógio em função do que recebeu, seguindo a regra 3 do algoritmo.

### 2. Reproduza a falha conhecida e observe o saldo da origem. Ele foi revertido? O que isso significa?

Reproduzi a falha derrubando a Agência 1 e tentando transferir da conta 0 (Agência 0) para uma conta da Agência 1. A resposta foi 502, com a mensagem avisando que o débito já tinha sido aplicado. Consultei o saldo da conta de origem depois do erro e o valor debitado não voltou, o saldo ficou reduzido mesmo sem o crédito ter acontecido do outro lado. Em termos de consistência bancária isso é grave: o dinheiro efetivamente sumiu do sistema por um tempo, ele saiu de uma conta e não chegou em nenhuma outra. Isso só é aceitável aqui porque o próprio roteiro deixa claro que essa limitação é proposital neste sprint, ela é o motivo de existir o Sprint 4 (transações distribuídas).

### 3. Duas formas possíveis de corrigir esse problema no futuro (alto nível)

A primeira é um protocolo de duas fases (2PC), onde a agência de origem primeiro pergunta para a agência de destino se ela está pronta para receber o crédito, sem debitar nada ainda, e só confirma o débito depois de ter certeza de que o crédito também vai acontecer. A segunda é um padrão Saga, onde a transferência é tratada como uma sequência de passos com uma ação compensatória para cada um: se o crédito remoto falhar, o sistema dispara automaticamente uma operação que desfaz o débito que já tinha sido aplicado, em vez de simplesmente registrar a inconsistência no log como acontece hoje.

## Parte E. Linha do tempo unificada

### 1. Lamport garante timestamp(A) < timestamp(B) quando A aconteceu antes de B, mas não garante a volta. O que isso significa na prática?

Significa que, ao olhar dois eventos na linha do tempo com timestamps diferentes, não dá para concluir automaticamente que um influenciou o outro. Pode ser que sim, mas também pode ser pura coincidência de contadores que evoluíram de forma independente em agências diferentes. O relógio de Lamport só me dá uma ordem total consistente com a causalidade quando ela existe, ele não me diz quando ela não existe. Então um timestamp maior não é prova de dependência causal, é só uma ordenação válida entre as possíveis.

### 2. O relógio de Lamport sozinho seria suficiente para distinguir "A e B são concorrentes" de "A aconteceu antes de B"? Por que isso motiva o relógio vetorial?

Rodando o mesclar_logs.py encontrei exatamente esse caso: logo no início da minha timeline, a Agência 0 registra CRIAR_CONTA com timestampLamport 1 (criando a conta 0) e a Agência 1 registra CRIAR_CONTA também com timestampLamport 1 (criando a conta 1), mas com horaParede completamente diferente entre os dois eventos. Esses dois eventos são claramente concorrentes, um não tem nenhuma relação causal com o outro, cada agência simplesmente incrementou seu próprio contador a partir do zero de forma independente. Comparando com a horaParede, a ordem por relógio físico nem sempre bate com a ordem por Lamport, porque o Lamport é lógico e local a cada processo, ele não sincroniza relógios de parede entre agências. Isso mostra o limite do algoritmo: com timestamps iguais (ou até diferentes), o Lamport não consegue provar concorrência, ele só consegue provar ordem causal quando ela existe. É exatamente essa limitação que motiva o relógio vetorial do Sprint 2, que consegue detectar concorrência de verdade porque guarda um contador por processo, não um único número compartilhado.

## Parte F. Autenticação JWT

### Justificativas de design

Escolhi como credencial de login o próprio par id da conta mais senha, em vez de criar um sistema de usuários separado das contas bancárias. Achei que fazia mais sentido para o domínio: cada conta já tem um dono, então autenticar com o id da conta e uma senha cadastrada na criação dela é direto e evita duplicar conceito de "usuário" e "conta".

Isso trouxe uma tensão de bootstrap que decidi documentar aqui em vez de esconder: o roteiro pede que a rota de criar conta também exija token, mas se toda rota exigisse token, incluindo a de criar conta, seria impossível criar a primeira conta de qualquer agência, porque não existe token sem antes existir uma conta para logar. Minha decisão foi deixar POST /contas sem exigir token, como a única exceção às rotas protegidas. Entendo que isso é um desvio do requisito literal, e um efeito colateral real é que qualquer pessoa sem autenticação pode criar contas novas com saldo inicial arbitrário. Uma correção melhor para um sprint futuro seria separar autenticação de usuário do conceito de conta bancária, com um cadastro de aluno que depois vincula contas, mas isso fugia do escopo de tempo deste sprint.

Sobre a chamada entre agências (creditar-remoto), decidi que ela precisava de autenticação, mas não fazia sentido usar o mesmo tipo de token de um usuário logado, porque não existe uma pessoa por trás dessa chamada, é uma agência falando com outra. Criei um segundo tipo de token, marcado com "tipo": "inter-agencia", de vida curta (5 minutos), gerado pela agência de origem no momento da chamada e validado por uma dependência separada (exigir_token_servico) na agência de destino. Isso impede que qualquer requisição anônima credite contas via creditar-remoto, sem misturar esse conceito com o de sessão de usuário.

### 1. Diferença entre autenticação e autorização. Minha implementação verifica as duas?

Autenticação é provar quem você é, autorização é decidir o que você pode fazer depois de saber quem você é. Minha implementação só verifica autenticação: o dependency exigir_token confirma que o JWT é válido e não expirou, mas nenhuma rota confere se o dono do token (o campo sub do payload) é realmente o dono da conta que está sendo movimentada. Na prática, hoje, um usuário autenticado com um token válido de qualquer conta consegue sacar, depositar ou transferir usando o id de outra conta, desde que ela pertença à mesma agência, porque o id da conta vem da URL ou do corpo da requisição e nunca é comparado com o sub do token. Isso é uma lacuna real de autorização que ficou fora do escopo deste sprint. Uma correção simples seria comparar payload["sub"] com o id da conta antes de qualquer operação e devolver 403 quando não bater.

### 2. Por que o servidor não precisa consultar banco de dados para validar a assinatura de um JWT?

Porque o token carrega sua própria prova de integridade: ele é assinado com uma chave secreta que só o servidor conhece, e validar a assinatura é uma operação matemática local (recalcular o HMAC com a mesma chave e comparar), sem precisar perguntar para lugar nenhum se aquele token "existe" em algum registro. Isso é diferente de guardar sessão em memória no servidor, onde cada requisição precisaria bater numa tabela ou cache central para saber se aquele identificador de sessão ainda é válido. Em termos de escalabilidade, isso significa que qualquer instância da agência consegue validar qualquer token sozinha, sem compartilhar estado entre instâncias, o que facilita rodar múltiplas réplicas de uma mesma agência no futuro sem precisar de um armazenamento de sessão compartilhado.

### 3. O que aconteceria se a chave secreta do JWT vazasse?

Qualquer pessoa de posse da chave conseguiria forjar tokens válidos para qualquer conta, de qualquer agência, sem nunca ter feito login de verdade, porque a validação confia inteiramente na assinatura ser inviolável com aquela chave. Seria possível gerar um token para o campo sub de qualquer id de conta, com qualquer tempo de expiração, e o servidor aceitaria como legítimo. Seria uma quebra total do sistema de autenticação, equivalente a vazar a senha mestra de todo o banco.

## Parte G. Frontend

### 1. Como o frontend "lembra" de reenviar o token em cada requisição?

Depois do login, guardo o token retornado (junto com o id da conta e a URL da agência) num objeto de sessão salvo no localStorage do navegador, através de um composable (useSessao.js) que usa o reactive do Vue para manter esse estado sincronizado em toda a aplicação. Toda chamada autenticada passa por uma função central (chamarAutenticado, em useContaApi.js) que lê o token da sessão atual e o inclui no cabeçalho Authorization: Bearer <token> antes de disparar o fetch. Como esse objeto fica salvo no localStorage, a sessão também sobrevive a um refresh da página.

### 2. O que acontece se o token expirar durante o uso?

A função chamarAutenticado trata isso de forma centralizada: se a API responder 401, ela limpa a sessão (removendo o token do localStorage e do estado reativo) e mostra uma mensagem visível na tela, "Sessão expirada. Faça login novamente.", através do composable useMensagem.js. A interface volta automaticamente para a tela de login, então a pessoa usuária não vê um erro genérico de rede, ela vê uma explicação direta do que aconteceu e já é levada de volta para reautenticar.

### 3. Onde fica o M, o V e o C no frontend?

O Model está nos composables e no serviço de API: services/api.js concentra a comunicação HTTP crua, e os composables (useSessao.js, useMensagem.js, useContaApi.js) guardam e expõem o estado da aplicação (sessão do usuário, mensagens de erro ou sucesso, chamadas autenticadas), sem saber nada sobre como isso é desenhado na tela. A View são os arquivos .vue, com seus blocos <template>, responsáveis só por mostrar o estado atual e capturar interações do usuário. O Controller é o bloco <script setup> de cada componente, que reage aos eventos da View (como o submit de um formulário), chama os composables do Model, e decide o que fazer com o resultado. A separação existe de forma bem clara na maior parte do código, mas não é perfeita: como o Vue com Composition API mistura naturalmente estado e lógica de controle no mesmo <script setup>, a linha entre Model e Controller dentro de cada componente fica mais fina do que num MVC clássico de três camadas totalmente isoladas.

## Funcionalidade adicional: idempotência de transferências

Implementei idempotência na rota POST /transferencias. O corpo da requisição agora exige um campo idempotencyKey, um identificador único gerado pelo cliente para aquela tentativa de transferência (no frontend, gerado automaticamente com crypto.randomUUID() a cada envio do formulário). A agência guarda em memória (app.state.idempotencia) o resultado de toda transferência que terminou com sucesso, indexado por essa chave. Se uma requisição chegar de novo com uma chave que já teve sucesso antes, a agência devolve o mesmo resultado sem debitar a conta de novo.

Escolhi essa funcionalidade porque ela ataca um problema clássico de sistemas distribuídos que o próprio roteiro menciona como motivação do domínio bancário: uma requisição pode ser reenviada por engano, seja porque o cliente não recebeu a resposta a tempo e tentou de novo, seja por uma falha de rede que faz um retry automático. Sem proteção, isso causaria um débito duplicado real. Uma decisão importante de escopo: só guardo em cache tentativas que terminaram com sucesso. Uma tentativa que falhou (por exemplo, saldo insuficiente, ou a própria falha conhecida de transferência entre agências da Parte D) não fica presa em cache, então pode ser reenviada de verdade com a mesma chave depois. Isso é proposital, essa funcionalidade resolve o problema de retry duplicado depois de um sucesso, não o problema de atomicidade entre débito e crédito quando a chamada remota falha, que continua sendo um problema em aberto deste sprint, do jeito que o roteiro já esperava.

Testei o comportamento enviando duas vezes a mesma requisição de transferência com a mesma idempotencyKey e confirmei que o saldo da conta de origem só foi debitado uma vez, com o log mostrando um único evento TRANSFERENCIA_DEBITO mesmo com duas chamadas HTTP idênticas. Também testei que uma chave usada numa tentativa que falhou por saldo insuficiente pôde ser reutilizada com sucesso numa tentativa seguinte com um valor válido. Evidência em evidencias/sprint1/funcionalidade-adicional.png.

## Nota de uso de IA

Usei o Claude (Anthropic), através do Claude Code, como apoio ao longo deste sprint, para redigir e revisar código, redigir este documento de respostas e revisar a organização dos commits. As implementações do relógio de Lamport, do registro de eventos, do particionamento de contas, das transferências, da autenticação JWT, do frontend em Vue e da funcionalidade adicional de idempotência foram desenvolvidas com apoio da IA, mas testadas e verificadas por mim em cada etapa, rodando as três agências localmente, chamando os endpoints e conferindo o comportamento antes de considerar cada parte concluída. As respostas deste arquivo foram redigidas como rascunho pela IA a partir do código efetivamente implementado e do que foi observado nos testes, e revisadas por mim, que sou capaz de explicar e defender qualquer trecho entregue. Declaro esse uso conforme pedido na nota de transparência do próprio roteiro deste sprint.


---

# Respostas Sprint 2 - ICEIBank

Linguagem: Python com FastAPI, a mesma do Sprint 1. Mensageria com RabbitMQ via biblioteca pika. O desenvolvimento e os primeiros testes foram feitos com o RabbitMQ local em Docker (`docker run -d --name rabbitmq-iceibank -p 5672:5672 -p 15672:15672 rabbitmq:3-management`, `RABBITMQ_URL=amqp://guest:guest@localhost:5672/`), alternativa prevista na seção 4.1 do roteiro. Depois criei a instância `iceibank` no CloudAMQP (plano Little Lemur, Azure Brazil South) e repeti na nuvem a transferência assíncrona, o teste de resiliência e a dead-letter queue, com o mesmo resultado. A única mudança entre os dois ambientes é o valor de `RABBITMQ_URL`.

Antes de começar o sprint, a camada de dados foi separada dos controllers em repositórios (`ContaRepository` e `IdempotenciaRepository`), e foi corrigida a falha em que um cliente logado conseguia operar a conta de outro (agora o token precisa ser do dono da conta, ou de um administrador).

## Parte B. Relógio vetorial

### 1. Com 10 agências, o que acontece com o tamanho do vetor anexado a cada mensagem? É um problema?

O vetor tem uma posição por agência, então com 10 agências cada mensagem carrega 10 inteiros em vez de 3. O custo cresce linearmente com o número de processos. Para 3 ou 10 agências isso é desprezível, porque o vetor é minúsculo perto do restante da mensagem. O problema aparece em sistemas com milhares de processos, onde o vetor passa a dominar o tamanho da mensagem e comparar vetores fica caro. Nesses casos se usam variações, como vetores de versão com poda de entradas antigas ou relógios híbridos.

### 2. V1 = [3, 1, 0] e V2 = [3, 2, 0]: qual evento aconteceu primeiro?

O evento de V1 aconteceu antes. Comparando posição a posição: 3 <= 3, 1 <= 2 e 0 <= 0. Todas as posições de V1 são menores ou iguais às de V2, e os vetores são diferentes, então existe um caminho causal de V1 até V2.

### 3. V1 = [3, 1, 0] e V2 = [1, 3, 0]: qual evento aconteceu primeiro?

São concorrentes. Na posição 0, V1 tem 3 e V2 tem 1, então V2 não é menor ou igual a V1. Na posição 1, V1 tem 1 e V2 tem 3, então V1 não é menor ou igual a V2. Nenhum domina o outro, o que significa que nenhum dos eventos influenciou o outro.

## Parte C. Publish/Subscribe entre agências

### 1. O que aconteceu quando a Agência 1 voltou?

Derrubei a Agência 1 e transferi R$ 40 da conta 3 (Agência 0) para a conta 4 (Agência 1). A resposta foi 200 e o painel do RabbitMQ (CloudAMQP) mostrou a `fila-agencia-1` com 1 mensagem pronta (Ready) enquanto as outras filas estavam vazias, ou seja, a mensagem ficou retida em disco (prints `resiliencia-fila.png` e `resiliencia-fila-2.png`). Quando subi a Agência 1 de novo, o consumidor reconectou e a mensagem foi entregue. O log da agência registrou:

`CREDITO_REMOTO_FALHOU [5, 1, 0] {"idConta": 4, "valor": 40.0, "origemAgencia": 0, "motivo": "conta nao encontrada"}`

A mensagem não sumiu por falha da mensageria. Ela chegou, o vetor foi atualizado pela regra de recebimento (a posição 0 passou a 5, vinda da origem), e o crédito não pôde ser aplicado porque a conta 4 não existia mais. As contas ficam só em memória, então reiniciar a agência apagou a conta. Confirmei isso tentando logar na conta 4 depois da reinicialização: resposta 401. Enquanto isso, a conta 3 já tinha sido debitada: o log da Agência 0 mostra o `TRANSFERENCIA_DEBITO` de 40 antes do envio, então os R$ 40 ficaram perdidos.

### 2. O que melhorou em relação ao Sprint 1 e o que continua em aberto?

No Sprint 1, com a chamada REST direta, se a agência de destino estivesse fora do ar a chamada falhava na hora, com erro 502, e o débito já aplicado ficava sem reverter. Agora a transferência é publicada e retida na fila durável até o destino voltar, então a mensagem não se perde em trânsito e o cliente não recebe erro só porque a outra agência está indisponível.

O que continua em aberto é a diferença entre "a mensagem não se perde" e "o sistema está correto". O experimento mostrou isso: a mensagem foi entregue e mesmo assim o dinheiro sumiu, porque o estado das contas não é persistente. Também continua sem solução a atomicidade entre débito e crédito: o débito é aplicado antes de se saber se o crédito vai dar certo, e um 200 agora significa apenas "publicado", não "creditado". O chamador não descobre o resultado final. Resolver isso de forma correta exige persistência das contas e uma transação distribuída com compensação, assunto do Sprint 4. A funcionalidade adicional (dead-letter queue) não corrige o saldo, mas pelo menos preserva a mensagem rejeitada para investigação.

Quando a publicação em si falha (broker fora do ar), a agência estorna o débito e responde 502, para não perder dinheiro nesse caso.

### 3. O consumidor aplica créditos sem verificar JWT. Isso é um problema de segurança?

É um problema, e a gravidade depende de quem consegue publicar na exchange. No meu ambiente de desenvolvimento o RabbitMQ roda local com o usuário padrão `guest`, que o RabbitMQ só aceita a partir de localhost, então a exposição é pequena. Mas quem conseguisse publicar uma mensagem em `iceibank.eventos` com a routing key `agencia.1.creditar` criaria dinheiro em qualquer conta, sem nenhuma autenticação de usuário, porque o consumidor confia em tudo que chega pela fila. Em produção isso exigiria usuários e permissões por vhost no broker, TLS na conexão e assinatura das mensagens (por exemplo HMAC ou um token dentro da mensagem) para o consumidor validar a origem. A confiança que antes estava no token HTTP entre agências passa a depender do controle de acesso ao broker.

## Parte D. Linha do tempo causal

### 1. O que no relógio vetorial torna a comparação confiável?

O vetor guarda um contador por processo, então ele registra exatamente quantos eventos de cada agência já influenciaram aquele evento. Com isso vale a equivalência: o evento A aconteceu antes de B se e somente se o vetor de A é menor ou igual ao de B em todas as posições. O relógio de Lamport comprime tudo em um único número e só garante uma direção (se A aconteceu antes de B, então L(A) < L(B)), sem permitir concluir o contrário. Como o vetor preserva a informação por processo, dá para distinguir "antes" de "concorrente" com certeza.

### 2. Um par que o script classificou como concorrente

Na minha execução o script listou, entre outros:

`[agencia-0] CRIAR_CONTA ([1, 0, 0]) x [agencia-1] CRIAR_CONTA ([0, 1, 0])`

Faz sentido: criei a conta 3 na Agência 0 e a conta 4 na Agência 1 sem nenhuma mensagem trocada entre elas, então nenhum dos dois eventos pode ter influenciado o outro. Cada agência só conhecia seus próprios eventos, e os vetores refletem isso. Também apareceu como concorrente o par `[agencia-1] CRIAR_CONTA ([0, 1, 0])` com `[agencia-0] TRANSFERENCIA_DEBITO ([2, 0, 0])`, porque a Agência 1 ainda não tinha recebido nada da Agência 0 quando criou a conta. Já o débito `[2, 0, 0]` e o crédito remoto `[3, 2, 0]` da transferência 3 para 4 não aparecem na lista, porque o vetor do crédito domina o do débito: há relação causal (o crédito só existe por causa da mensagem publicada depois do débito).

### 3. O algoritmo é O(n²). É um problema com milhões de eventos?

É. Com milhões de eventos seriam da ordem de 10^12 comparações, inviável. Dá para escalar de algumas formas. Como a posição i do vetor conta os eventos da agência i, a relação "A aconteceu antes de B" pode ser checada em tempo constante comparando só `A.vetor[A.agencia] <= B.vetor[A.agencia]`, sem varrer o vetor inteiro. Também dá para indexar os eventos por agência, em ordem, e usar busca binária para achar a faixa de eventos concorrentes de cada evento, em vez de testar todos os pares. E, na prática, normalmente se analisa uma janela de tempo ou um subconjunto de interesse (por exemplo, só as transferências), não o histórico inteiro.

## Funcionalidade adicional: fila de mensagens mortas (dead-letter queue)

Configurei uma dead-letter queue no RabbitMQ. A exchange `iceibank.mortas` (fanout, durável) está ligada à fila durável `fila-mensagens-mortas`, e as filas das agências são declaradas com o argumento `x-dead-letter-exchange` apontando para ela. Quando o consumidor não consegue aplicar um crédito, por exemplo porque a conta não existe, ele registra o evento `CREDITO_REMOTO_FALHOU` no log e rejeita a mensagem sem recolocá-la na fila (`nack` com `requeue=False`). O RabbitMQ então encaminha a mensagem para a fila de mensagens mortas, em vez de ela simplesmente desaparecer depois do ack, que era o comportamento da versão anterior.

Testei transferindo R$ 5 da conta 3 para a conta 7 (que não existe, e que pertence à Agência 1). A resposta foi 200, o consumidor da Agência 1 rejeitou a mensagem (`CreditoRejeitado('conta 7 nao encontrada')`) e a fila `fila-mensagens-mortas` passou a ter 1 mensagem, com o conteúdo `{"idConta": 7, "valor": 5.0, "vetorEnvio": [7, 0, 0], "origemAgencia": 0, "idTransferencia": "0a932f8a-7250-4d24-baaa-a91a4aee7cdc"}`, vindo da `fila-agencia-1` e com motivo `rejected`. Uma transferência válida feita logo em seguida foi aplicada normalmente.

Uma observação prática: o RabbitMQ não permite mudar os argumentos de uma fila já existente. Ao ativar a dead-letter queue sobre filas criadas antes dela, foi preciso apagá-las uma vez (`rabbitmqctl delete_queue fila-agencia-N`), e elas são recriadas com o argumento novo quando a agência sobe.

## Evidências (`evidencias/sprint2/`)

- `transferencia-assincrona.png`: transferência da conta 3 (Agência 0) para a conta 4 (Agência 1) por mensageria. Mostra o `Get-Date`, a resposta 200, o débito e o envio na Agência 0 e o crédito remoto na Agência 1, com os vetores `[2, 0, 0]`, `[3, 0, 0]` e `[3, 2, 0]`.
- `resiliencia-fila.png`: Agência 1 fora do ar, transferência respondendo 200 e a `fila-agencia-1` com 1 mensagem pronta no painel do RabbitMQ.
- `resiliencia-fila-2.png`: Agência 1 de volta, com o log `CREDITO_REMOTO_FALHOU [5, 1, 0]` por conta ausente, o login da conta 4 retornando 401 e a fila já em 0.
- `linha-do-tempo-causal.png`: saída do `mesclar_logs.py`, com os pares concorrentes (por exemplo as criações de conta em agências diferentes) e o `Get-Date`.
- `funcionalidade-adicional.png` e `funcionalidade-adicional-2.png`: dead-letter queue com a mensagem rejeitada na `fila-mensagens-mortas` e o conteúdo dela aberto no painel.

## Regressão do JWT e do frontend

Depois das mudanças deste sprint verifiquei, rodando as agências e o frontend, que o que já funcionava no Sprint 1 continua funcionando: login com JWT, consulta de saldo, depósito, saque, transferência na mesma agência e entre agências pela interface web (a mensagem de resposta agora diz que a entrega é assíncrona, e o saldo do destino é atualizado pelo consumidor). Rotas protegidas continuam respondendo 401 sem token, e um cliente só consegue operar a própria conta (403 nas outras). O particionamento por `id % 3` segue valendo na criação de contas. Os testes de unidade do relógio vetorial passam (`python -m unittest discover -s tests`).

## Nota de uso de IA (Sprint 2)

O Sprint 2 foi implementado com o Claude Code (Anthropic), que escreveu o código, rodou o RabbitMQ em Docker, executou os testes descritos acima (transferência assíncrona, resiliência, dead-letter queue, linha do tempo causal e regressão do frontend e do JWT) e redigiu um rascunho deste documento a partir do que foi observado. As respostas devem ser revisadas e compreendidas antes da entrega, porque preciso ser capaz de explicar e defender qualquer trecho entregue, como pede a nota de transparência do roteiro.

---

# Respostas Sprint 3 - ICEIBank

Backend em Python com FastAPI, a mesma linguagem dos sprints anteriores, seguindo as orientações da seção 11 do roteiro: `requests` com timeout de 1 segundo nas chamadas entre agências e uma thread separada para o heartbeat, com `threading.Lock` protegendo a líder atual. O app é em Flutter e foi testado em um celular Android físico conectado por USB, alternativa prevista na seção 4 do roteiro.

Pontos em que a implementação foi além do exemplo do roteiro, ou o adaptou:

- A função `comparar_vetores` já existia desde o Sprint 2, em `relogio_vetorial.py`, então o endpoint de sincronização a reaproveita em vez de criar um arquivo novo.
- O endpoint `/contas/{id}/sincronizar` exige o JWT do dono da conta, como as outras rotas de conta, e nunca devolve o hash da senha na resposta de conflito.
- Comparar o vetor e aplicar a operação acontece em um único bloco protegido pelo lock do relógio. Testei 8 sincronizações simultâneas com o mesmo vetor: exatamente 1 foi aplicada e 7 receberam 409.
- A sincronização também cobre transferências, como o roteiro deixa em aberto na seção 9.3.

## Parte A. Mensagens de eleição e coordenador

### 1. Por que o Bully elege o maior ID, e não o menor? O resultado seria diferente se a regra fosse invertida?

A regra só precisa ser uma ordem total que todos os processos conheçam, para que não exista empate. Escolher o maior é uma convenção do algoritmo original. Com a regra invertida o resultado seria outra líder (a agência de menor ID entre as ativas), mas o algoritmo continuaria correto: cada agência perguntaria às de ID menor, e a de menor ID ativa não teria a quem perguntar e venceria. O que garante a correção é todos aplicarem o mesmo critério, não o critério em si.

### 2. Mais de uma agência declarar `TORNOU_LIDER` durante a subida é bug ou comportamento esperado?

É comportamento esperado. Na execução dos prints, as 3 agências iniciaram eleição ao mesmo tempo e o log registrou 3 eventos `TORNOU_LIDER` em 25 milissegundos, todos da Agência 2. Isso acontece porque cada eleição recebida pela Agência 2 dispara uma eleição nova, e como ninguém tem ID maior que o dela, cada uma termina em uma nova declaração. Nessa execução outra agência não chegou a se declarar, porque a Agência 2 já estava respondendo quando as outras perguntaram. Se a Agência 2 subisse alguns instantes depois, a Agência 1 poderia se declarar líder antes, e seria corrigida assim que a 2 se anunciasse. Em todos os casos o sistema converge para o maior ID ativo.

### 3. A falta de autenticação em `/bully/eleicao` é um problema de segurança real?

É um problema real, com impacto limitado neste sprint. Hoje a líder é só informativa, então forjar uma eleição não movimenta dinheiro. Mesmo assim há dois efeitos concretos. Quem alcança a rota pode forçar eleições sem parar e gerar tráfego. E cada eleição avança o relógio vetorial das agências, o que faria toda sincronização offline em andamento receber um 409 falso. As rotas validam o intervalo de IDs e o tamanho do vetor, então um `liderId` inexistente é recusado com 422, mas qualquer ID válido ainda é aceito. No Sprint 4, quando a líder coordenar transações, isso seria grave: quem forjar uma mensagem de coordenador passa a decidir quem coordena. A correção seria autenticar a comunicação entre agências, por exemplo com um segredo compartilhado assinando as mensagens ou mTLS.

## Parte B. Heartbeat e failover automático

### 1. E se o heartbeat fosse de 100ms ou de 60 segundos?

Com 100ms a queda seria percebida quase na hora, mas cada agência faria 10 requisições por segundo só para isso, e um atraso momentâneo da rede viraria falsa suspeita com muito mais frequência, disparando eleições desnecessárias. Com 60 segundos o custo seria desprezível, porém o sistema poderia ficar quase um minuto apontando para uma líder morta. O intervalo de 3 segundos fica entre os dois: nos meus testes a nova líder estava definida entre 1 e 2 segundos depois da detecção da queda, com poucas requisições por segundo no total.

### 2. A agência que volta "tomar" a liderança é desejável? Que problema pode causar?

Não é desejável em um sistema real, embora seja como o Bully funciona. No teste, derrubei a Agência 2, a Agência 1 assumiu às 17:55:42 (UTC) e, quando religuei a 2, ela retomou a liderança às 17:56:11 mesmo com a 1 funcionando bem. Essa troca não traz benefício nenhum e tem custo. Se ela acontecer no meio de uma transação coordenada, como o 2PC do Sprint 4, a coordenadora nova não conhece as decisões em andamento da antiga, e participantes podem ficar presos esperando uma decisão. Na prática se evita isso com um período de carência, ou só permitindo a troca quando a líder atual realmente falhar.

### 3. E se a rede estiver lenta e a resposta passar de 1 segundo?

A agência trataria uma agência viva como fora do ar. Se isso ocorrer na eleição, uma agência de ID menor conclui que ninguém maior respondeu e se declara líder, gerando duas líderes por um tempo. Se ocorrer no heartbeat, ela descarta uma líder saudável e inicia uma eleição desnecessária. Esse é o limite conhecido de detectar falhas por timeout: em uma rede assíncrona não dá para distinguir uma agência lenta de uma agência caída. Para reduzir o efeito, um anúncio de líder de ID menor só é aceito se a líder maior conhecida realmente tiver deixado de responder, e o sistema converge de novo assim que a rede normaliza. Também precisei trocar `localhost` por `127.0.0.1` nas URLs internas: no Windows o `localhost` tenta IPv6 primeiro e cada chamada perdia cerca de 1 segundo, exatamente o valor do timeout.

## Parte C. Observando a eleição

### 1. Quantas vezes a liderança mudou de mãos na subida? Isso tem custo real?

Nenhuma vez de fato: nos prints, a liderança foi sempre da Agência 2, declarada 3 vezes. O que houve foi repetição. Em 80 milissegundos os logs registraram 17 eventos de eleição: 5 eleições iniciadas, 3 recebidas, 3 declarações de líder e 6 anúncios recebidos. O resultado final não muda, mas o custo existe: são requisições HTTP que não precisariam ter acontecido, e cada mensagem avança o relógio vetorial. Com 3 agências isso é desprezível, mas o número de mensagens do Bully cresce com o quadrado do número de processos no pior caso.

## Parte D. App Flutter

### 1. Como o app decide a frequência de consulta a `/bully/lider`?

O intervalo é fixo em 3 segundos, o mesmo do heartbeat das agências. Consultar mais rápido não adiantaria, porque as agências só percebem a queda no ritmo do heartbeat. Consultar mais devagar atrasaria a atualização do painel. Para não gastar bateria, o app para de consultar quando vai para segundo plano e retoma ao voltar. O tempo limite de cada consulta é de 1,5 segundo.

### 2. E se duas agências responderem líderes diferentes durante uma transição?

Isso é normal e se resolve na consulta seguinte, porque as agências convergem em poucos segundos. O app consulta as 3 ao mesmo tempo e decide assim: ignora votos em uma líder que não respondeu, fica com a mais votada e, em caso de empate, escolhe o maior ID, como faria o Bully. Enquanto houver divergência, o painel mostra o selo "Em transição" em vez de "Consenso", deixando claro que a informação ainda não é definitiva. Como a líder neste sprint é só informativa, uma resposta momentaneamente errada não causa efeito nenhum sobre o dinheiro.

### 3. O que foi reaproveitável do frontend web e o que mudou por ser mobile?

Reaproveitei os conceitos: o particionamento por `id % 3` para saber a agência da conta, o JWT no cabeçalho, o tratamento de erros da API, a chave de idempotência das transferências, os componentes e os tokens do design system. Mudou o seguinte: o token fica no armazenamento seguro do Android, e não no armazenamento do navegador; o app fala com o IP do computador na rede Wi-Fi, porque `localhost` no celular é o próprio celular; foi preciso liberar HTTP em desenvolvimento, já que o Android bloqueia tráfego sem TLS; as cores em oklch viraram valores sRGB; as fontes ficaram embutidas no app; o cartão vira com um toque, já que não há mouse para inclinar; e, principalmente, a conexão passa a ser algo que pode faltar, o que levou a tratar o ciclo de vida do app e o modo offline.

## Parte E. Sincronização offline-first no backend

### 1. Por que comparar o vetor inteiro, e não só o saldo?

O saldo pode acabar igual depois de mudar. Se entrar um depósito de R$ 50 e sair um saque de R$ 50 enquanto o app está offline, o saldo final é o mesmo, e uma comparação de saldo diria que nada aconteceu. O vetor conta eventos, então ele avança nas duas operações e denuncia que o estado mudou. Ele também captura o que veio de outras agências, como créditos recebidos pelo RabbitMQ, pela posição das outras agências no vetor.

### 2. Por que qualquer mudança no vetor é tratada como conflito, e como tornar isso mais preciso?

O vetor existe por agência, não por conta. Ele avança com qualquer evento da agência, inclusive operações de outras contas e até mensagens de eleição, e nada nele diz qual conta foi afetada. Isso gera falsos conflitos: nos logs, o evento `LIDER_NAO_RESPONDEU` também avança o vetor da agência, então uma queda de líder entre a leitura e a sincronização bastaria para recusar a operação. A simplificação existe porque reaproveita o relógio que já estava pronto. Para ser preciso por conta, cada conta precisaria da própria versão, seja um contador incrementado a cada mudança de saldo, seja um vetor por conta guardado junto com ela. A consulta devolveria essa versão e a sincronização compararia apenas ela. Eventos de eleição deixariam de interferir.

### 3. O que o app deveria fazer com a resposta 409?

Perguntar à pessoa. Descartar sozinho faria o dinheiro de um depósito sumir da tela sem explicação. Tentar de novo automaticamente aplicaria uma decisão tomada sobre um saldo que a pessoa não conhecia, por exemplo um saque que ela não faria se soubesse que a conta mudou. Em um banco, a escolha precisa ser de quem é dona da conta. Por isso o app mostra o saldo real e oferece "Aplicar sobre o saldo real" ou "Descartar".

## Parte F. App Flutter em modo offline-first

### 1. Qual biblioteca de armazenamento local e por quê?

Escolhi o `sqflite`. Os dados têm formato de tabela e a fila precisa de ordem garantida de criação, além de atualizar várias linhas de uma vez, como a troca do vetor das operações que ficam depois de uma sincronização. Tudo isso é natural em SQL. Considerei o Hive, que é simples, mas para a fila eu teria de ordenar e filtrar à mão, e o Drift, que traz tipagem forte, mas exige geração de código, exagero para três tabelas. O JWT não fica no banco: vai para o `flutter_secure_storage`, que usa o armazenamento protegido do Android.

### 2. O que aconteceu na tela quando a sincronização foi recusada?

Com o celular em modo avião, fiz um depósito de R$ 30 pelo app e, pelo terminal, um depósito de R$ 100 na mesma conta. Ao desligar o modo avião, o app tentou sincronizar sozinho, recebeu o 409 e mostrou o cartão "Conflito detectado" com o texto "A conta mudou enquanto o app estava offline, então esta operação não foi aplicada automaticamente. Saldo real agora: R$ 675,00", além dos botões "Aplicar sobre o saldo real" e "Descartar" (print `app-conflito.png`). O saldo principal volta a ser o real, sem somar a operação recusada. As operações que vierem depois ficam aguardando a decisão, porque foram feitas contando com a que falhou.

### 3. Que risco a UI otimista traz para um banco? Como o design reduz esse risco?

O risco é a pessoa acreditar em um dinheiro que ainda não existe e tomar decisões com base nele. Pior, uma operação que parecia feita pode nem acontecer. O design reduz isso de quatro formas. O cartão troca o rótulo para "Saldo provisório" enquanto houver fila, e o valor pendente aparece em uma lista própria, com a marcação "Aguardando sincronização". Saques e transferências offline só são aceitos dentro do saldo provisório. Nada é aplicado ou apagado em silêncio quando há conflito ou recusa. E cada operação tem uma chave de idempotência: se a agência aplicou e a resposta se perdeu, o reenvio devolve o resultado anterior em vez de movimentar o dinheiro duas vezes.

## Funcionalidade adicional: indicador de agências ativas

O painel de liderança mostra o estado de cada uma das 3 agências: "Ativa", "Líder" ou "Fora do ar". Para isso o app consulta `GET /bully/lider` nas 3 ao mesmo tempo, a cada 3 segundos, em vez de parar na primeira que responde. Além do indicador, o painel informa quantas agências ativas concordam com a líder e registra a última troca com o horário. O print `funcionalidade-adicional.png` mostra a Agência 2 fora do ar, a Agência 1 como líder e a troca registrada, depois de eu derrubar a líder com o app aberto.

## Evidências (`evidencias/sprint3/`)

- `eleicao-inicial.png`: as 3 agências concordando que a Agência 2 é a líder depois de subirem juntas.
- `failover.png`: a Agência 2 sendo derrubada e as 2 restantes concordando com a Agência 1.
- `historico-lideranca.png` e `historico-lideranca-2.png`: saída do `historico_lideranca.py`, com os eventos de eleição e, no segundo print, a linha do tempo completa: Agência 2, depois Agência 1, depois Agência 2 ao voltar, em duas rodadas de queda da líder.
- `conflito-sincronizacao.png`: resposta 409 ao sincronizar com o vetor antigo e sucesso ao repetir com o `vetorAtual` devolvido.
- `app-lider-atual.png`: o app mostrando a líder atual.
- `app-failover.png`: o painel atualizado sozinho depois da queda, com "Última troca: Agência 2 → Agência 1".
- `app-offline.png`: modo avião ligado, com o depósito pendente e o saldo provisório.
- `app-sincronizacao.png`: a operação sincronizada sozinha depois de religar a rede.
- `app-conflito.png`: tratamento visível do 409 no app, pedido na tarefa 5 da seção 10.2.
- `funcionalidade-adicional.png`: indicador de agências ativas com uma agência fora do ar.

Os prints do celular foram capturados pelo cabo USB com `adb exec-out screencap`. O horário deles é o da barra de status do aparelho, já que não há terminal na tela do celular.

## Regressão

Os 30 testes de unidade passam (`python -m unittest discover -s tests`), cobrindo o relógio vetorial, a eleição, o heartbeat e a sincronização. Os testes de integração em `app_mobile/integration_test` rodaram no celular e passaram: login, saldo, depósito, saque, transferência, erros da API, fila offline, sincronização automática e conflito. Também verifiquei o que já funcionava: rotas protegidas seguem respondendo 401 sem token ou com token inválido e 403 na conta de outra pessoa, a transferência entre agências pelo RabbitMQ continua entregando o crédito com o vetor atualizado, e no frontend web login, saldo e depósito funcionam normalmente.

## Nota de uso de IA (Sprint 3)

O Sprint 3 foi implementado com o Claude Code (Anthropic), que escreveu o código do backend e do app Flutter, instalou o ambiente, executou os testes descritos acima, operou o app no celular e capturou os prints do aparelho, revisou o código em busca de erros e redigiu um rascunho deste documento a partir do que foi observado. Os prints do terminal foram tirados por mim. As respostas devem ser revisadas e compreendidas antes da entrega, porque preciso ser capaz de explicar e defender qualquer trecho entregue, como pede a nota de transparência do roteiro.
