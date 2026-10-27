import { http } from "./http.ts";

export type Numeric = string | number;

export type RevisiStatus = "DIMINTA" | "DIKIRIM" | "SELESAI" | "DITOLAK";

export interface RevisiItem {
  id: number;
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

export interface RevisiRiwayat {
  id: number;
  nomor_revisi: number;
  alasan_revisi: string;
  catatan_sales: string | null;
  status_revisi: RevisiStatus;
  diminta_oleh: number;
  dikirim_oleh: number | null;
  disetujui_oleh: number | null;
  tanggal_diminta: string;
  tanggal_dikirim: string | null;
  tanggal_disetujui: string | null;
  items: Partial<RevisiItem>[];
}

export interface RevisiRiwayatResponse {
  request_penawaran_id: number;
  total_revisi_dikirim: number;
  total_riwayat: number;
  riwayat: RevisiRiwayat[];
}

export interface RevisiDetail {
  id: number;
  request_penawaran_id: number;
  nomor_revisi: number;
  alasan_revisi: string;
  catatan_sales: string | null;
  status_revisi: RevisiStatus;
  tanggal_diminta: string;
  items: RevisiItem[];
}

export interface RevisiItemUpdate {
  id: number;
  nama_barang: string;
  merk: string | null;
  tkdn: string | null;
  tkdn_persen: number | null;
  spesifikasi: string | null;
  catatan_sales: string | null;
  jumlah: number;
  satuan: string;
  harga_pagu: number | null;
  harga_modal: number | null;
  harga_jual: number | null;
}

export interface RevisiUpdate {
  catatan_sales: string | null;
  items: RevisiItemUpdate[];
}

export const REVISI_STATUS_LABEL: Record<RevisiStatus, string> = {
  DIMINTA: "Menunggu perbaikan Sales",
  DIKIRIM: "Menunggu persetujuan SPV",
  SELESAI: "Disetujui",
  DITOLAK: "Ditolak SPV",
};

export function revisiDetailPath(requestId: number, revisiId: number) {
  return `/aktivitas/request-penawaran/${requestId}/revisi/${revisiId}`;
}

export async function createRevisi(requestId: number, alasanRevisi: string): Promise<{ revisi_id: number }> {
  const { data } = await http.post<{ revisi_id: number }>(`/request-penawaran/${requestId}/revisi`, {
    alasan_revisi: alasanRevisi,
  });
  return data;
}

export async function getRiwayatRevisi(requestId: number): Promise<RevisiRiwayatResponse> {
  const { data } = await http.get<RevisiRiwayatResponse>(`/request-penawaran/${requestId}/revisi`);
  return data;
}

export async function getDetailRevisi(requestId: number, revisiId: number): Promise<RevisiDetail> {
  const { data } = await http.get<RevisiDetail>(`/request-penawaran/${requestId}/revisi/${revisiId}`);
  return data;
}

export async function updateRevisi(requestId: number, revisiId: number, payload: RevisiUpdate): Promise<void> {
  await http.put(`/request-penawaran/${requestId}/revisi/${revisiId}`, payload);
}

export async function submitRevisi(requestId: number, revisiId: number): Promise<void> {
  await http.post(`/request-penawaran/${requestId}/revisi/${revisiId}/submit`);
}

export async function approveRevisi(requestId: number, revisiId: number): Promise<void> {
  await http.post(`/request-penawaran/${requestId}/revisi/${revisiId}/approve`);
}
