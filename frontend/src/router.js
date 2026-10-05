import { createRouter, createWebHistory } from "vue-router";
import { useSessao } from "./composables/useSessao";
import HomeView from "./views/HomeView.vue";
import LoginView from "./views/LoginView.vue";
import AbrirContaView from "./views/AbrirContaView.vue";
import PainelView from "./views/PainelView.vue";
import AdminLoginView from "./views/AdminLoginView.vue";
import AdminView from "./views/AdminView.vue";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", component: HomeView },
    { path: "/entrar", component: LoginView },
    { path: "/abrir-conta", component: AbrirContaView },
    { path: "/painel", component: PainelView, meta: { exigeCliente: true } },
    { path: "/admin/entrar", component: AdminLoginView },
    { path: "/admin", component: AdminView, meta: { exigeAdmin: true } },
    { path: "/:resto(.*)*", redirect: "/" },
  ],
  scrollBehavior: (to) => (to.hash ? { el: to.hash, top: 72, behavior: "smooth" } : { top: 0 }),
});

router.beforeEach((to) => {
  const { estado } = useSessao();
  const sessao = estado.sessao;
  const admin = sessao?.papel === "admin";

  if (to.meta.exigeAdmin && !admin) return "/admin/entrar";
  if (to.meta.exigeCliente && !sessao) return "/entrar";
  if (to.meta.exigeCliente && admin) return "/admin";
  if (["/entrar", "/abrir-conta"].includes(to.path) && sessao) return admin ? "/admin" : "/painel";
  if (to.path === "/admin/entrar" && admin) return "/admin";
});

export default router;
