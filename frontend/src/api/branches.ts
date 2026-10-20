import { http } from "./http";

const LOGO_FIELD = "file";

export interface Branch {
  id: number;
  nama: string;
  kode: string;
  alamat: string | null;
  no_telepon: string | null;
  email: string | null;
  website: string | null;
  nama_direktur: string | null;
  logo: string | null;
}

export type BranchInput = {
  nama: string;
  kode: string;
} & Partial<Record<"alamat" | "no_telepon" | "email" | "website" | "nama_direktur", string | null>>;

export type BranchUpdate = Partial<BranchInput>;

export async function getBranches(): Promise<Branch[]> {
  const { data } = await http.get<Branch[]>("/branches/");
  return data;
}

export async function getBranch(id: number): Promise<Branch> {
  const { data } = await http.get<Branch>(`/branches/${id}`);
  return data;
}

export async function createBranch(payload: BranchInput): Promise<Partial<Branch> | undefined> {
  const { data } = await http.post<Partial<Branch> | undefined>("/branches/", payload);
  return data;
}

export async function updateBranch(id: number, payload: BranchUpdate): Promise<void> {
  await http.patch(`/branches/${id}`, payload);
}

export async function deleteBranch(id: number): Promise<void> {
  await http.delete(`/branches/${id}`);
}

export async function uploadBranchLogo(id: number, file: File): Promise<void> {
  const body = new FormData();
  body.append(LOGO_FIELD, file);
  await http.post(`/branches/${id}/logo`, body);
}
