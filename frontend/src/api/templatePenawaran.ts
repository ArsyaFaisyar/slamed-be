import { http } from "./http.ts";

const PREVIEW_FIELD = "file";

export interface TemplatePenawaran {
  id: number;
  judul: string;
  konten: string;
  preview_path: string | null;
  created_by: number | null;
  created_at: string;
  updated_at: string | null;
}

export interface TemplatePenawaranInput {
  judul: string;
  konten: string;
}

export type TemplatePenawaranUpdate = Partial<TemplatePenawaranInput>;

export async function getTemplatePenawaranList(): Promise<TemplatePenawaran[]> {
  const { data } = await http.get<TemplatePenawaran[]>("/template-penawaran/");
  return data;
}

export async function getTemplatePenawaran(id: number): Promise<TemplatePenawaran> {
  const { data } = await http.get<TemplatePenawaran>(`/template-penawaran/${id}`);
  return data;
}

export async function createTemplatePenawaran(payload: TemplatePenawaranInput): Promise<TemplatePenawaran> {
  const { data } = await http.post<TemplatePenawaran>("/template-penawaran/", payload);
  return data;
}

export async function updateTemplatePenawaran(id: number, payload: TemplatePenawaranUpdate): Promise<void> {
  await http.patch(`/template-penawaran/${id}`, payload);
}

export async function deleteTemplatePenawaran(id: number): Promise<void> {
  await http.delete(`/template-penawaran/${id}`);
}

export async function uploadTemplatePreview(id: number, file: File): Promise<void> {
  const body = new FormData();
  body.append(PREVIEW_FIELD, file);
  await http.post(`/template-penawaran/${id}/preview`, body);
}
