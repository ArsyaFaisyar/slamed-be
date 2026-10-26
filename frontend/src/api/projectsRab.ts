import { http } from "./http";

export interface RabItem {
  id: number;
  nama_barang: string;
  spesifikasi: string | null;
  jumlah: number | string;
  satuan: string | null;
  harga_pagu: number | string | null;
  subtotal: number | string | null;
}

export interface RabRequest {
  request_penawaran_id: number;
  tanggal_request: string;
  mode_pagu: string;
  total_pagu: number | string | null;
  items: RabItem[];
}

export interface ProjectRab {
  nama_project: string;
  jumlah_request_penawaran: number;
  [key: string]: unknown;
}

export async function getProjectRab(projectId: number): Promise<ProjectRab> {
  const { data } = await http.get<ProjectRab>(`/projects/${projectId}/rab`);
  return data;
}
