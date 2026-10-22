import { http } from "./http";

export interface Lkh {
  id: number;
  rkh_id: number;
  sales_id: number;
  tanggal_kunjungan: string;
  hasil_kunjungan: string | null;
  status_id: number | null;
  tindak_lanjut: string | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateLkhPayload {
  rkh_id: number;
  tanggal_kunjungan: string;
  hasil_kunjungan: string;
  tindak_lanjut: string;
  latitude: number;
  longitude: number;
}

export type UpdateLkhPayload = Partial<Omit<CreateLkhPayload, "rkh_id">>;

export async function getLkh(): Promise<Lkh[]> {
  const { data } = await http.get<Lkh[]>("/lkh/");
  return data;
}

export async function getLkhById(lkhId: number): Promise<Lkh> {
  const { data } = await http.get<Lkh>(`/lkh/${lkhId}`);
  return data;
}

export async function createLkh(payload: CreateLkhPayload): Promise<Lkh> {
  const { data } = await http.post<Lkh>("/lkh/", payload);
  return data;
}

export async function updateLkh(lkhId: number, payload: UpdateLkhPayload): Promise<Lkh> {
  const { data } = await http.patch<Lkh>(`/lkh/${lkhId}`, payload);
  return data;
}

export async function deleteLkh(lkhId: number): Promise<void> {
  await http.delete(`/lkh/${lkhId}`);
}

export interface LkhAttachment {
  id: number;
  [key: string]: unknown;
}

const attachmentNameKeys = ["file_name", "filename", "original_filename", "original_name", "nama_file", "nama", "name"];

export function attachmentName(attachment: LkhAttachment): string {
  for (const key of attachmentNameKeys) {
    const value = attachment[key];
    if (typeof value === "string" && value) return value;
  }
  return `Lampiran ${attachment.id}`;
}

export async function getLkhAttachments(lkhId: number): Promise<LkhAttachment[]> {
  const { data } = await http.get<LkhAttachment[]>(`/lkh/${lkhId}/attachments`);
  return data;
}

export async function uploadLkhAttachment(lkhId: number, file: File): Promise<void> {
  const body = new FormData();
  body.append("file", file);
  await http.post(`/lkh/${lkhId}/attachments`, body);
}

export async function getLkhAttachmentBlob(attachmentId: number): Promise<Blob> {
  const { data } = await http.get<Blob>(`/lkh/attachments/${attachmentId}/file`, {
    responseType: "blob",
  });
  return data;
}
