import axios from "axios";
import { clearToken, getToken } from "../utils/token";

let unauthorizedHandler: (() => void) | null = null;
let handlingUnauthorized = false;

export function setUnauthorizedHandler(handler: () => void): void {
  unauthorizedHandler = handler;
}

export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
});

http.interceptors.request.use((config) => {
  const token = getToken();

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  } else {
    delete config.headers.Authorization;
  }

  return config;
});

http.interceptors.response.use(
  (response) => response,
  (error: unknown) => {
    if (!axios.isAxiosError(error)) {
      return Promise.reject(error);
    }

    const status = error.response?.status;
    const requestUrl = error.config?.url ?? "";

    const isLoginRequest = /\/auth\/login\/?$/.test(requestUrl);

    if (status === 401 && !isLoginRequest && getToken() && !handlingUnauthorized) {
      handlingUnauthorized = true;

      try {
        clearToken();
        unauthorizedHandler?.();
      } finally {
        handlingUnauthorized = false;
      }
    }

    return Promise.reject(error);
  },
);
