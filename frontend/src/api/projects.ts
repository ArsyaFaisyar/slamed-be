import { http } from "./http";

export interface Project {
  id: number;
  customer_id: number;
  nama_project: string;
  jenis: string | null;
  deskripsi: string | null;
  status: string | null;
  created_at: string;
}

export type ProjectInput = {
  customer_id: number;
  nama_project: string;
} & Partial<Record<"jenis" | "deskripsi" | "status", string | null>>;

export type ProjectUpdate = Partial<ProjectInput>;

export async function getProjects(): Promise<Project[]> {
  const { data } = await http.get<Project[]>("/projects/");
  return data;
}

export async function getProject(id: number): Promise<Project> {
  const { data } = await http.get<Project>(`/projects/${id}`);
  return data;
}

export async function createProject(payload: ProjectInput): Promise<void> {
  await http.post("/projects/", payload);
}

export async function updateProject(id: number, payload: ProjectUpdate): Promise<void> {
  await http.patch(`/projects/${id}`, payload);
}

export async function deleteProject(id: number): Promise<void> {
  await http.delete(`/projects/${id}`);
}
