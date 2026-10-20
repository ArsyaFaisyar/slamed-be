import { http } from "./http";

export interface Area {
  id: number;
  nama: string;
  spv_id: number;
  target: number;
}

export interface CreateAreaPayload {
  nama: string;
  spv_id: number;
  target: number;
}

export type UpdateAreaPayload = Partial<CreateAreaPayload>;

export async function getAreas(): Promise<Area[]> {
  const { data } = await http.get<Area[]>("/areas/");
  return data;
}

export async function getAreaById(areaId: number): Promise<Area> {
  const { data } = await http.get<Area>(`/areas/${areaId}`);
  return data;
}

export async function createArea(payload: CreateAreaPayload): Promise<void> {
  await http.post("/areas/", payload);
}

export async function updateArea(areaId: number, payload: UpdateAreaPayload): Promise<Area> {
  const { data } = await http.patch<Area>(`/areas/${areaId}`, payload);
  return data;
}

export async function deleteArea(areaId: number): Promise<void> {
  await http.delete(`/areas/${areaId}`);
}
