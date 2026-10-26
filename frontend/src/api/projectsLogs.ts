import { http } from "./http";

export interface ProjectLog {
  id: number;
  project_id: number;
  aktivitas?: string | null;
  aksi?: string | null;
  deskripsi: string | null;
  user_id: number | null;
  user_rel?: { id: number; nama: string } | null;
  created_at: string;
}

export async function getProjectLogs(projectId: number): Promise<ProjectLog[]> {
  const { data } = await http.get<ProjectLog[]>(`/projects/${projectId}/logs`);
  return data;
}
