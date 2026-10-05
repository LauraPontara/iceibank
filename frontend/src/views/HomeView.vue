<script setup>
import { RouterLink } from "vue-router";
import { motion } from "motion-v";
import { ArrowRight, Network, ShieldCheck, Clock, Zap } from "lucide-vue-next";
import LogoMark from "../components/ui/LogoMark.vue";
import MetalCard from "../components/ui/MetalCard.vue";

const SUAVE = [0.22, 1, 0.36, 1];

const aparecer = (atraso = 0, deslocamento = 18) => ({
  initial: { opacity: 0, transform: `translateY(${deslocamento}px)` },
  animate: { opacity: 1, transform: "translateY(0px)" },
  transition: { duration: 0.6, delay: atraso, ease: SUAVE },
});

const aoRolar = (atraso = 0) => ({
  initial: { opacity: 0, transform: "translateY(24px)" },
  whileInView: { opacity: 1, transform: "translateY(0px)" },
  inViewOptions: { once: true, amount: 0.25 },
  transition: { duration: 0.55, delay: atraso, ease: SUAVE },
});

const elevar = {
  whileHover: { transform: "translateY(-3px)" },
  whileTap: { transform: "translateY(0px)" },
};
</script>

<template>
  <main>
    <section class="hero container">
      <div class="hero-texto">
        <motion.span class="chip" v-bind="aparecer(0.05)">Novo · Cartão ICEI Metal já disponível</motion.span>
        <motion.h1 v-bind="aparecer(0.12)">Um banco que se move como <em>luz.</em></motion.h1>
        <motion.p class="muted lead" v-bind="aparecer(0.2)">
          Conta digital, cartão metal com brilho rosé e transferências entre agências que nunca dormem.
          ICEIBank é dinheiro, refinado.
        </motion.p>
        <motion.div class="cta" v-bind="aparecer(0.28)">
          <RouterLink to="/abrir-conta" class="btn-primary">Abrir sua conta <ArrowRight :size="16" /></RouterLink>
          <RouterLink to="/#recursos" class="btn-ghost">Conhecer o cartão</RouterLink>
        </motion.div>
        <motion.ul class="garantias muted" v-bind="aparecer(0.36)">
          <li>Sem tarifas escondidas</li>
          <li>Transferência entre agências</li>
          <li>Sessão protegida por JWT</li>
        </motion.ul>
      </div>
      <motion.div class="hero-cartao" v-bind="aparecer(0.2, 40)">
        <div class="halo" />
        <MetalCard titular="ICEIBank" conta="8842" saldo="R$ 48.210,90" />
        <p class="dica muted">Passe o mouse e clique no cartão</p>
      </motion.div>
    </section>

    <section id="recursos" class="container bento">
      <motion.article class="surface tile grande" v-bind="{ ...aoRolar(0), ...elevar }">
        <p class="eyebrow marcador">Conta</p>
        <h3>Uma conta, tudo que seu dinheiro precisa.</h3>
        <p class="muted">
          Abra em minutos, sem papelada. Deposite, saque e transfira para qualquer conta informando apenas o número.
        </p>
        <div class="mini">
          <div><span class="eyebrow">Abertura</span><strong>Grátis</strong></div>
          <div><span class="eyebrow">Anuidade</span><strong>R$ 0</strong></div>
          <div><span class="eyebrow">Agências</span><strong>3</strong></div>
        </div>
      </motion.article>

      <motion.article class="tile escuro" v-bind="{ ...aoRolar(0.08), ...elevar }">
        <span class="icone"><ShieldCheck :size="18" /></span>
        <h3>Cada acesso é autenticado e expira.</h3>
        <p>Tokens JWT de 15 minutos protegem todas as operações da sua conta.</p>
      </motion.article>

      <motion.article class="surface tile" v-bind="{ ...aoRolar(0.16), ...elevar }">
        <span class="icone"><Network :size="18" /></span>
        <h3>Entre agências</h3>
        <p class="muted">Contas particionadas em 3 agências independentes que se falam por mensageria.</p>
      </motion.article>

      <motion.article class="surface tile grande vitrine card-sheen" v-bind="{ ...aoRolar(0.24), ...elevar }">
        <div class="brilho-vitrine glow-mesh" />
        <div class="vitrine-texto">
          <h3>ICEI <em>Metal</em></h3>
          <p>Aço escovado, brilho rosé e zero anuidade.</p>
        </div>
      </motion.article>
    </section>

    <section id="numeros" class="container faixa-wrap">
      <motion.div class="faixa" v-bind="aoRolar(0)">
        <div class="glow-mesh brilho-faixa" />
        <div class="faixa-grade">
          <motion.div v-bind="aoRolar(0.1)">
            <Network :size="20" class="rosa" />
            <p class="numero">3 agências</p>
            <p>Serviços REST independentes, cada um dono de uma fatia das contas.</p>
          </motion.div>
          <motion.div v-bind="aoRolar(0.2)">
            <Clock :size="20" class="rosa" />
            <p class="numero rosa">Vetorial</p>
            <p>Cada evento carrega um vetor de contadores, e dá para saber o que é causal e o que é concorrente.</p>
          </motion.div>
          <motion.div v-bind="aoRolar(0.3)">
            <Zap :size="20" class="rosa" />
            <p class="numero">Idempotente</p>
            <p>Reenviar uma transferência não debita duas vezes o mesmo valor.</p>
          </motion.div>
        </div>
      </motion.div>
    </section>

    <footer class="rodape">
      <div class="container rodape-conteudo">
        <div>
          <LogoMark />
          <p class="muted">O banco digital para quem se move rápido e pensa longe.</p>
        </div>
        <p class="muted pequeno">
          Projeto acadêmico, Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas.
        </p>
      </div>
    </footer>
  </main>
</template>

<style scoped>
.hero {
  display: grid;
  align-items: center;
  gap: 48px;
  padding-top: 80px;
  padding-bottom: 80px;
}

.hero-texto {
  max-width: 560px;
}

h1 {
  margin-top: 24px;
  font-size: clamp(40px, 6vw, 64px);
  font-weight: 600;
  line-height: 1.05;
}

h1 em,
h3 em {
  color: var(--primary);
  font-style: normal;
}

.lead {
  margin-top: 24px;
  max-width: 48ch;
  font-size: 17px;
  line-height: 1.6;
}

.cta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  margin-top: 32px;
}

.garantias {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 24px;
  margin: 32px 0 0;
  padding: 0;
  list-style: none;
  font-size: 12px;
}

.hero-cartao {
  position: relative;
}

.halo {
  position: absolute;
  inset: -16px;
  border-radius: 40px;
  background: color-mix(in oklch, var(--primary) 20%, transparent);
  filter: blur(60px);
}

.dica {
  position: relative;
  margin-top: 24px;
  text-align: center;
  font-size: 12px;
}

.bento {
  display: grid;
  gap: 16px;
  padding-bottom: 32px;
}

.bento > * {
  min-width: 0;
}

.bento article {
  border-radius: 20px;
  padding: clamp(20px, 5vw, 28px);
}

.bento h3 {
  margin-top: 16px;
  font-size: 22px;
  line-height: 1.2;
}

.bento p {
  margin-top: 12px;
  font-size: 14px;
  line-height: 1.6;
}

.marcador {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
  color: var(--primary);
}

.marcador::before {
  content: "";
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--primary);
}

.mini {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(96px, 1fr));
  gap: 12px;
  margin-top: 24px;
}

.mini div {
  padding: 12px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: var(--secondary);
}

.mini .eyebrow {
  display: block;
  font-size: 10px;
}

.mini strong {
  display: block;
  margin-top: 4px;
  font-family: var(--font-display);
  font-size: 18px;
  font-weight: 500;
}

.escuro {
  border: 1px solid var(--border);
  background: var(--ink);
  color: white;
}

.escuro p {
  color: rgb(255 255 255 / 50%);
}

.icone {
  display: inline-grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border-radius: 12px;
  background: color-mix(in oklch, var(--primary) 15%, transparent);
  box-shadow: inset 0 0 0 1px color-mix(in oklch, var(--primary) 20%, transparent);
  color: var(--primary);
}

.vitrine {
  position: relative;
  display: flex;
  align-items: flex-end;
  min-height: 240px;
  overflow: hidden;
  color: white;
}

.brilho-vitrine,
.brilho-faixa {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.vitrine-texto {
  position: relative;
}

.vitrine-texto p {
  color: rgb(255 255 255 / 55%);
}

.faixa-wrap {
  padding-top: 64px;
  padding-bottom: 64px;
}

.faixa {
  position: relative;
  overflow: hidden;
  padding: clamp(24px, 6vw, 48px);
  border: 1px solid var(--border);
  border-radius: 24px;
  background: var(--ink);
  color: white;
}

.faixa-grade {
  position: relative;
  display: grid;
  gap: 40px;
}

.faixa-grade p:not(.numero) {
  margin-top: 8px;
  max-width: 26ch;
  font-size: 14px;
  color: rgb(255 255 255 / 50%);
}

.numero {
  margin-top: 12px;
  font-family: var(--font-display);
  font-size: clamp(28px, 8vw, 40px);
  font-weight: 600;
  letter-spacing: -0.02em;
}

.rosa {
  color: var(--primary);
}

.rodape {
  border-top: 1px solid var(--border);
}

.rodape-conteudo {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 24px;
  padding-top: 48px;
  padding-bottom: 48px;
}

.rodape-conteudo p {
  margin-top: 16px;
  max-width: 34ch;
  font-size: 14px;
}

.rodape-conteudo .pequeno {
  align-self: flex-end;
  max-width: 48ch;
  font-size: 12px;
}

@media (min-width: 1024px) {
  .hero {
    grid-template-columns: 1fr 1fr;
    padding-top: 112px;
    padding-bottom: 112px;
  }

  .bento {
    grid-template-columns: repeat(3, 1fr);
  }

  .grande {
    grid-column: span 2;
  }

  .faixa-grade {
    grid-template-columns: repeat(3, 1fr);
  }
}
</style>
