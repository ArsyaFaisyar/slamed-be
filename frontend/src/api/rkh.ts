import { http } from "./http";

export interface Rkh {
  id: number;
  sales_id: number;
  customer_id: number;
  project_id: number;
  tanggal_rencana: string;
  tanggal_pelaksanaan: string | null;
  judul_kegiatan: string;
  rencana_kegiatan: string;
  tipe_aktivitas: string;
  estimasi_biaya_harian: string;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface CreateRkhPayload {
  customer_id: number;
  project_id: number;
  tanggal_rencana: string;
  tanggal_pelaksanaan?: string;
  judul_kegiatan: string;
  rencana_kegiatan: string;
  tipe_aktivitas: string;
  estimasi_biaya_harian: number;
}

export type UpdateRkhPayload = Partial<CreateRkhPayload>;

export async function getRkh(): Promise<Rkh[]> {
  const { data } = await http.get<Rkh[]>("/rkh/");
  return data;
}

export async function getRkhById(rkhId: number): Promise<Rkh> {
  const { data } = await http.get<Rkh>(`/rkh/${rkhId}`);
  return data;
}

export async function createRkh(payload: CreateRkhPayload): Promise<void> {
  await http.post("/rkh/", payload);
}

export async function updateRkh(rkhId: number, payload: UpdateRkhPayload): Promise<Rkh> {
  const { data } = await http.patch<Rkh>(`/rkh/${rkhId}`, payload);
  return data;
}

export async function deleteRkh(rkhId: number): Promise<void> {
  await http.delete(`/rkh/${rkhId}`);
}
