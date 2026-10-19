import { createApp } from "vue";
import { createPinia } from "pinia";

import PrimeVue from "primevue/config";
import ToastService from "primevue/toastservice";
import ConfirmationService from "primevue/confirmationservice";

import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/inter/700.css";

import "@fontsource/plus-jakarta-sans/400.css";
import "@fontsource/plus-jakarta-sans/500.css";
import "@fontsource/plus-jakarta-sans/600.css";
import "@fontsource/plus-jakarta-sans/700.css";

import "primeicons/primeicons.css";
import "./assets/main.css";

import App from "./App.vue";
import router from "./router/index";
import { applyThemeMode, getInitialThemeMode, primeVueOptions } from "./theme";

applyThemeMode(getInitialThemeMode());

const app = createApp(App);

app.use(createPinia());
app.use(router);
app.use(ToastService);
app.use(ConfirmationService);
app.use(PrimeVue, primeVueOptions);

app.mount("#app");
