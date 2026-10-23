import { http } from "./http";

export type Numeric = string | number;

export interface RequestPenawaran {
  id: number;
  lkh_id: number;
  tanggal_request: string;
  diminta_oleh: string;
  media_pengadaan_id: number;
  branch_id: number;
  mode_pagu: string;
  pajak_harga_modal: string;
  status_request: string;
  total_pagu: Numeric | null;
  total_harga_modal: Numeric | null;
  total_harga_jual: Numeric | null;
  created_at: string;
  completed_at: string | null;
  sla_label: string | null;
}

export interface RequestPenawaranInput {
  lkh_id: number;
  diminta_oleh: string;
  media_pengadaan_id: number;
  branch_id: number;
  mode_pagu: string;
  pajak_harga_modal: string;
}

export interface RequestItem {
  id: number;
  request_penawaran_id: number;
  nama_barang: string;
  merk: string | null;
  tkdn: string | null;
  tkdn_persen: Numeric | null;
  spesifikasi: string | null;
  catatan_sales: string | null;
  jumlah: Numeric;
  satuan: string;
  harga_pagu: Numeric | null;
  harga_modal: Numeric | null;
  harga_jual: Numeric | null;
}

export interface RequestPenawaranUpdate {
  diminta_oleh?: string;
  media_pengadaan_id?: number;
  branch_id?: number;
  mode_pagu?: string;
  pajak_harga_modal?: string;
  total_pagu?: number | null;
}

export type RequestItemUpdate = {
  nama_barang?: string;
  merk?: string | null;
  tkdn?: string | null;
  tkdn_persen?: number | null;
  spesifikasi?: string | null;
  catatan_sales?: string | null;
  jumlah?: number;
  satuan?: string;
};

export async function deleteRequestItem(requestId: number, itemId: number) {
  await http.delete(`/request-penawaran/${requestId}/items/${itemId}`);
}

export interface RequestItemInput {
  nama_barang: string;
  jumlah: number;
  satuan: string;
  merk?: string;
  tkdn?: string;
  tkdn_persen?: number;
  spesifikasi?: string;
  catatan_sales?: string;
}

export interface RequestItemPriceUpdate {
  harga_pagu?: number | null;
  harga_modal?: number | null;
  harga_jual?: number | null;
}

export const MODE_PAGU_OPTIONS = [
  { value: "DETAIL", label: "Detail" },
  { value: "TOTAL", label: "Total" },
];

export const PAJAK_OPTIONS = [
  { value: "TERMASUK", label: "Termasuk pajak" },
  { value: "TIDAK_TERMASUK", label: "Tidak termasuk pajak" },
];

export const REQUEST_PENAWARAN_LIST_PATH = "/support/request-penawaran";

export async function getRequestPenawaranList(lkhId?: number): Promise<RequestPenawaran[]> {
  const { data } = await http.get<RequestPenawaran[]>("/request-penawaran/", {
    params: lkhId === undefined ? undefined : { lkh_id: lkhId },
  });

  return data;
}

export async function createRequestPenawaran(payload: RequestPenawaranInput): Promise<RequestPenawaran> {
  const { data } = await http.post<RequestPenawaran>("/request-penawaran/", payload);

  return data;
}

export async function getRequestPenawaran(requestId: number): Promise<RequestPenawaran> {
  const { data } = await http.get<RequestPenawaran>(`/request-penawaran/${requestId}`);

  return data;
}

export async function updateRequestPenawaran(requestId: number, payload: RequestPenawaranUpdate): Promise<RequestPenawaran> {
  const { data } = await http.patch<RequestPenawaran>(`/request-penawaran/${requestId}`, payload);

  return data;
}

export async function getRequestItems(requestId: number): Promise<RequestItem[]> {
  const { data } = await http.get<RequestItem[]>(`/request-penawaran/${requestId}/items`);

  return data;
}

export async function createRequestItem(requestId: number, payload: RequestItemInput): Promise<RequestItem> {
  const { data } = await http.post<RequestItem>(`/request-penawaran/${requestId}/items`, payload);

  return data;
}

export async function updateRequestItem(requestId: number, itemId: number, payload: RequestItemPriceUpdate): Promise<RequestItem> {
  const { data } = await http.patch<RequestItem>(`/request-penawaran/${requestId}/items/${itemId}`, payload);

  return data;
}

export function requestPenawaranDetailPath(requestId: number) {
  return `/aktivitas/request-penawaran/${requestId}`;
}

const storageKey = (lkhId: number) => `request-penawaran:lkh:${lkhId}`;

export function rememberRequestId(lkhId: number, requestId: number) {
  try {
    localStorage.setItem(storageKey(lkhId), String(requestId));
  } catch {
    return;
  }
}

export function recallRequestId(lkhId: number): number | null {
  try {
    const value = Number(localStorage.getItem(storageKey(lkhId)));

    return Number.isInteger(value) && value > 0 ? value : null;
  } catch {
    return null;
  }
}

export function forgetRequestId(lkhId: number) {
  try {
    localStorage.removeItem(storageKey(lkhId));
  } catch {
    return;
  }
}
