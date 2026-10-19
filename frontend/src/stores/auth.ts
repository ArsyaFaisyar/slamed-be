import { computed, ref } from "vue";
import { defineStore } from "pinia";
import { getMe, login as loginRequest, type AuthUser, type LoginPayload } from "../api/auth";
import { clearToken, getToken, setToken } from "../utils/token";
import { useProfileStore } from "./profile";

export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(getToken());
  const user = ref<AuthUser | null>(null);

  const isAuthenticated = computed(() => !!token.value);

  async function login(payload: LoginPayload) {
    const data = await loginRequest(payload);
    token.value = data.access_token;
    setToken(data.access_token);
    user.value = data.user ?? null;
  }

  async function fetchMe() {
    user.value = await getMe();
  }

  function logout() {
    token.value = null;
    user.value = null;
    clearToken();
    useProfileStore().reset();
  }

  return { token, user, isAuthenticated, login, fetchMe, logout };
});
