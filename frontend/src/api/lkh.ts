import { downloadExcel } from "../utils/exportFile.ts";
import { http } from "./http";

export const LKH_DONE = "DONE";
export const LKH_REOPEN = "NOT_YET";

export type AttachmentJenis = "FOTO" | "LAMPIRAN";

export interface LkhAttachment {
  id: number;
  lkh_id: number;
  nama_file: string;
  tipe_file: string;
  jenis: AttachmentJenis;
  url: string;
}

export interface Lkh {
  id: number;
  rkh_id: number;
  sales_id: number;
  tanggal_kunjungan: string;
  hasil_kunjungan: string | null;
  nama_pic: string | null;
  nomor_pic: string | null;
  status_lkh: string | null;
  tindak_lanjut: string | null;
  tanggal_follow_up?: string | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateLkhPayload {
  rkh_id: number;
  tanggal_kunjungan: string;
  hasil_kunjungan: string;
  nama_pic: string;
  nomor_pic: string;
  tindak_lanjut?: string | null;
  tanggal_follow_up?: string | null;
  latitude?: number | null;
  longitude?: number | null;
}

  export interface LkhExportParams {
    status_lkh?: string[];
    customer_id?: number[];
    nama_pic?: string | null;
    tanggal_mulai?: string | null;
    tanggal_selesai?: string | null;
  }

export type UpdateLkhPayload = Partial<Omit<CreateLkhPayload, "rkh_id">> & {
  status_lkh?: string;
};

export interface LkhExportParams {
  sales_id?: number[];
  customer_id?: number[];
  tanggal_mulai?: string | null;
  tanggal_selesai?: string | null;
}

export function isLkhDone(lkh: Lkh | null | undefined): boolean {
  return lkh?.status_lkh?.toUpperCase() === LKH_DONE;
}

function toFormData(payload: object): FormData {
  const body = new FormData();

  for (const [key, value] of Object.entries(payload)) {
    if (value === undefined || value === null) continue;
    body.append(key, value instanceof File ? value : String(value));
  }

  return body;
}

export async function getLkh(): Promise<Lkh[]> {
  const { data } = await http.get<Lkh[]>("/lkh/");
  return data;
}

export async function getLkhById(lkhId: number): Promise<Lkh> {
  const { data } = await http.get<Lkh>(`/lkh/${lkhId}`);
  return data;
}

export async function createLkh(payload: CreateLkhPayload): Promise<Lkh> {
  const { data } = await http.post<Lkh>("/lkh/", toFormData(payload));
  return data;
}

export async function updateLkh(lkhId: number, payload: UpdateLkhPayload): Promise<Lkh> {
  const { data } = await http.patch<Lkh>(`/lkh/${lkhId}`, payload);
  return data;
}

export async function reopenLkh(lkhId: number): Promise<Lkh> {
  return updateLkh(lkhId, { status_lkh: LKH_REOPEN });
}

export async function deleteLkh(lkhId: number): Promise<void> {
  await http.delete(`/lkh/${lkhId}`);
}

export function exportLkhExcel(params: LkhExportParams): Promise<void> {
  return downloadExcel("/lkh/export/excel", { ...params }, "lkh");
}

export async function getAttachments(lkhId: number): Promise<LkhAttachment[]> {
  const { data } = await http.get<LkhAttachment[]>(`/lkh/${lkhId}/attachments`);
  return data;
}

export async function uploadAttachment(lkhId: number, file: File, jenis: AttachmentJenis): Promise<LkhAttachment> {
  const { data } = await http.post<LkhAttachment>(`/lkh/${lkhId}/attachments`, toFormData({ file, jenis }));
  return data;
}

export async function fetchAttachmentBlob(attachmentId: number): Promise<Blob> {
  const { data } = await http.get<Blob>(`/lkh/attachments/${attachmentId}/file`, {
    responseType: "blob",
  });
  return data;
}
