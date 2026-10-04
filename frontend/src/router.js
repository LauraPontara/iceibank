import { createRouter, createWebHistory } from "vue-router";
import { useSessao } from "./composables/useSessao";
import HomeView from "./views/HomeView.vue";
import LoginView from "./views/LoginView.vue";
import AbrirContaView from "./views/AbrirContaView.vue";
import PainelView from "./views/PainelView.vue";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", component: HomeView },
    { path: "/entrar", component: LoginView },
    { path: "/abrir-conta", component: AbrirContaView },
    { path: "/painel", component: PainelView, meta: { exigeSessao: true } },
    { path: "/:resto(.*)*", redirect: "/" },
  ],
  scrollBehavior: (to) => (to.hash ? { el: to.hash, behavior: "smooth" } : { top: 0 }),
});

router.beforeEach((to) => {
  const { estado } = useSessao();
  if (to.meta.exigeSessao && !estado.sessao) return "/entrar";
  if (to.path === "/entrar" && estado.sessao) return "/painel";
});

export default router;
