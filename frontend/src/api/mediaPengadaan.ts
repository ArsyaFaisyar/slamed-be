import { http } from "./http";

export interface MediaPengadaan {
  id: number;
  nama: string;
}

export interface MediaPengadaanPayload {
  nama: string;
}

export async function getMediaPengadaan(): Promise<MediaPengadaan[]> {
  const { data } = await http.get<MediaPengadaan[]>("/media-pengadaan/");
  return data;
}

export async function getMediaPengadaanById(mediaId: number): Promise<MediaPengadaan> {
  const { data } = await http.get<MediaPengadaan>(`/media-pengadaan/${mediaId}`);
  return data;
}

export async function createMediaPengadaan(payload: MediaPengadaanPayload): Promise<void> {
  await http.post("/media-pengadaan/", payload);
}

export async function updateMediaPengadaan(mediaId: number, payload: MediaPengadaanPayload): Promise<MediaPengadaan> {
  const { data } = await http.patch<MediaPengadaan>(`/media-pengadaan/${mediaId}`, payload);
  return data;
}

export async function deleteMediaPengadaan(mediaId: number): Promise<void> {
  await http.delete(`/media-pengadaan/${mediaId}`);
}
