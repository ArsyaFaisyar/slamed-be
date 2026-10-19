
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import tailwindcss from "@tailwindcss/vite";
import vueDevTools from "vite-plugin-vue-devtools";

export default defineConfig({
  devtools: {
    apply: "serve",
  },
  plugins: [
    vue(),
    tailwindcss(),
    vueDevTools(),
  ],
});
