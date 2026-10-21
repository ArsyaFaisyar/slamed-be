import { http } from "./http";

export interface ProjectStatus {
  id: number;
  nama: string;
  warna: string | null;
  urutan: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ProjectStatusInput {
  nama: string;
  warna?: string | null;
  urutan?: number;
}

export interface ProjectStatusUpdate extends Partial<ProjectStatusInput> {
  is_active?: boolean;
}

export async function getProjectStatuses(): Promise<ProjectStatus[]> {
  const { data } = await http.get<ProjectStatus[]>("/project-statuses");
  return data;
}

export async function createProjectStatus(payload: ProjectStatusInput): Promise<void> {
  await http.post("/project-statuses", payload);
}

export async function updateProjectStatus(id: number, payload: ProjectStatusUpdate): Promise<void> {
  await http.patch(`/project-statuses/${id}`, payload);
}

export async function deactivateProjectStatus(id: number): Promise<void> {
  await http.delete(`/project-statuses/${id}`);
}
