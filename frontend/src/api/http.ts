import axios from "axios";
import { clearToken, getToken } from "../utils/token";

let unauthorizedHandler: (() => void) | null = null;

export function setUnauthorizedHandler(handler: () => void): void {
  unauthorizedHandler = handler;
}

export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
});

http.interceptors.request.use((config) => {
  const token = getToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

http.interceptors.response.use(
  (response) => response,
  (error) => {
    const isLoginRequest = error.config?.url?.startsWith("/auth/login");
    if (axios.isAxiosError(error) && error.response?.status === 401 && !isLoginRequest && getToken()) {
      clearToken();
      unauthorizedHandler?.();
    }
    return Promise.reject(error);
  },
);
