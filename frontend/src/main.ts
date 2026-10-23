import { createApp } from "vue";
import { createPinia } from "pinia";
import PrimeVue from "primevue/config";
import Tooltip from "primevue/tooltip";

import "./assets/main.css";
import "primeicons/primeicons.css";
import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/plus-jakarta-sans/600.css";
import "@fontsource/plus-jakarta-sans/700.css";

import App from "./App.vue";
import router from "./router";
import { setUnauthorizedHandler } from "./api/http";
import { useAuthStore } from "./stores/auth";
import { applyThemeMode, getInitialThemeMode, primeVueOptions } from "./theme";
import ConfirmationService from "primevue/confirmationservice";
import ToastService from "primevue/toastservice";

applyThemeMode(getInitialThemeMode());

const app = createApp(App);

app.use(createPinia());
app.use(router);
app.use(PrimeVue, primeVueOptions);
app.directive("tooltip", Tooltip);
app.use(ConfirmationService);
app.use(ToastService);

setUnauthorizedHandler(() => {
  useAuthStore().logout();
  router.push({ name: "login" });
});

app.mount("#app");
