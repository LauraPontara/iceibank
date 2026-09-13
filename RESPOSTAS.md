# Respostas Sprint 1 - ICEIBank

Linguagem escolhida: Python, com FastAPI. Autenticação com PyJWT, senha guardada com hash PBKDF2-HMAC-SHA256 e salt. Frontend em Vue 3 com Vite.

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
