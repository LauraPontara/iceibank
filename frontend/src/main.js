import { createApp } from "vue";
import "./styles/tokens.css";
import "./styles/base.css";
import "./styles/components.css";
import "./styles/effects.css";
import App from "./App.vue";
import router from "./router";

createApp(App).use(router).mount("#app");
