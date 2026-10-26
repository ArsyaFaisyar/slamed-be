import { http } from "./http";
import type { ProjectStatus } from "./projectStatuses";

export interface ProjectSales {
  id: number;
  nama: string;
}

export interface Project {
  id: number;
  customer_id: number;
  nama_project: string;
  deskripsi: string | null;
  status_id: number | null;
  status_rel?: ProjectStatus | null;
  sales_id: number;
  sales_rel?: ProjectSales | null;
  pipeline_status: string | null;
  nilai_proyek: string | null;
  estimasi_closing: string | null;
  created_at: string;
}

export interface ProjectInput {
  customer_id: number;
  sales_id: number;
  nama_project: string;
  deskripsi?: string | null;
  status_id?: number | null;
  nilai_proyek?: number | null;
  estimasi_closing?: string | null;
}

export type ProjectUpdate = Partial<ProjectInput>;

export interface ProjectDashboardSummary {
  jumlah_project: number;
  total_nilai_project: string | null;
  jumlah_prospek: number;
  jumlah_hot_prospek: number;
  nilai_prospek: string | null;
  nilai_hot_prospek: string | null;
}

export async function getProjects(): Promise<Project[]> {
  const { data } = await http.get<Project[]>("/projects/");
  return data;
}

export async function getProjectDashboardSummary(): Promise<ProjectDashboardSummary> {
  const { data } = await http.get<ProjectDashboardSummary>("/projects/dashboard/summary");
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
