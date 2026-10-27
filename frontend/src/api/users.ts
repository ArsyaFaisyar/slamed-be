import { http } from "./http";
import type { UserRole } from "../constant/roles";

export interface User {
  id: number;
  nama: string;
  username: string;
  email: string;
  role: string;
  is_active: number;
  branch_id: number | null;
  area_id: number | null;
}

export interface UserOption {
  id: number;
  nama: string;
}

export interface CreateUserPayload {
  nama: string;
  username: string;
  email: string;
  password: string;
  role: UserRole;
  branch_id: number | null;
  area_id: number | null;
}

export interface UpdateUserPayload {
  nama?: string;
  email?: string;
  role?: UserRole;
  is_active?: boolean | number;
  branch_id?: number | null;
  area_id?: number | null;
}

export async function getUsers(): Promise<User[]> {
  const { data } = await http.get<User[]>("/users/");
  return data;
}

export async function getUserOptions(): Promise<UserOption[]> {
  const { data } = await http.get<UserOption[]>("/users/options");
  return data;
}

export async function createUser(payload: CreateUserPayload): Promise<void> {
  await http.post("/users/", payload);
}

export async function resetUserPassword(userId: number, password: string): Promise<void> {
  await http.patch(`/users/${userId}/password`, { password });
}

export async function updateUser(userId: number, payload: UpdateUserPayload): Promise<User> {
  const { data } = await http.patch<User>(`/users/${userId}`, payload);
  return data;
}
