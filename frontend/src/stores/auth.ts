import { computed, ref } from "vue";
import { defineStore } from "pinia";
import { getMe, login as loginRequest, type AuthUser, type LoginPayload } from "../api/auth";
import { clearToken, getToken, setToken } from "../utils/token";
import { useProfileStore } from "./profile";

function isTokenUsable(token: string): boolean {
  try {
    const payload = token.split(".")[1];
    if (!payload) return false;

    const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");

    const decoded = JSON.parse(atob(normalized)) as {
      sub?: string;
      exp?: number;
    };

    if (decoded.exp && decoded.exp * 1000 <= Date.now()) {
      return false;
    }

    const id = Number(decoded.sub);

    return Number.isInteger(id) && id > 0;
  } catch {
    return false;
  }
}

export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(getToken());
  const user = ref<AuthUser | null>(null);

  const isAuthenticated = computed(() => !!token.value);

  async function login(payload: LoginPayload) {
    const data = await loginRequest(payload);

    token.value = data.access_token;
    setToken(data.access_token);

    if (data.user) {
      user.value = data.user;
    } else {
      await fetchMe();
    }
  }

  async function fetchMe() {
    if (!token.value) {
      throw new Error("Token tidak tersedia");
    }

    if (!isTokenUsable(token.value)) {
      logout();
      throw new Error("Token tidak valid atau sudah kedaluwarsa");
    }

    user.value = await getMe();
  }

  function logout() {
    token.value = null;
    user.value = null;
    clearToken();
    useProfileStore().reset();
  }

  return {
    token,
    user,
    isAuthenticated,
    login,
    fetchMe,
    logout,
  };
});
