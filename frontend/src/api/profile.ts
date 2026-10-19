import { http } from "./http";

const PHOTO_FIELD = "file";

export interface Profile {
  nama?: string;
  username?: string;
  email?: string;
  role?: string;
  foto_profil?: string | null;
}

export interface ChangePasswordPayload {
  password_lama: string;
  password_baru: string;
}

export async function getProfile(): Promise<Profile> {
  const { data } = await http.get<Profile>("/profile/");
  return data;
}

export async function changePassword(payload: ChangePasswordPayload): Promise<void> {
  await http.patch("/profile/password", payload);
}

export async function uploadPhoto(file: File): Promise<void> {
  const body = new FormData();
  body.append(PHOTO_FIELD, file);
  await http.post("/profile/photo", body);
}

export async function getPhotoUrl(): Promise<string | null> {
  try {
    const { data } = await http.get<Blob>("/profile/photo", { responseType: "blob" });
    if (data.type.startsWith("image/")) return URL.createObjectURL(data);

    const text = (await data.text()).trim().replace(/^"|"$/g, "");
    if (!text) return null;
    return new URL(text, http.defaults.baseURL).toString();
  } catch {
    return null;
  }
}
