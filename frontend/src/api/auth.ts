import { http } from "./http";

export interface Captcha {
  captcha_id: string;
  question: string;
  expires_in: number;
}

export interface LoginPayload {
  username: string;
  password: string;
  captcha_id: string;
  captcha_answer: number;
}

export interface AuthUser {
  id: number;
  nama: string;
  username: string;
  email: string;
  role: string;
  foto_profil?: string | null;
  branch_id?: number | null;
  area_id?: number | null;
  [key: string]: unknown;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  message?: string;
  user?: AuthUser;
}

export async function getCaptcha(): Promise<Captcha> {
  const { data } = await http.get<Captcha>("/auth/captcha");
  return data;
}

export async function login(payload: LoginPayload): Promise<LoginResponse> {
  const { data } = await http.post<LoginResponse>("/auth/login", payload);
  return data;
}

export async function getMe(): Promise<AuthUser> {
  const { data } = await http.get<AuthUser>("/users/me");
  return data;
}
