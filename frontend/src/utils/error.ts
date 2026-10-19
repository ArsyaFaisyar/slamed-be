import axios from "axios";

export function getErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError(error)) {
    if (!error.response) return "Tidak dapat terhubung ke server";
    const detail = error.response.data?.detail;
    if (typeof detail === "string") return detail;
    if (Array.isArray(detail)) return "Data yang dikirim tidak valid";
  }
  return fallback;
}

export function getFieldErrors(error: unknown): Record<string, string> {
  const result: Record<string, string> = {};
  if (!axios.isAxiosError(error)) return result;

  const detail = error.response?.data?.detail;
  if (!Array.isArray(detail)) return result;

  for (const item of detail) {
    const field = Array.isArray(item?.loc) ? item.loc[item.loc.length - 1] : undefined;
    if (typeof field === "string" && typeof item.msg === "string" && !result[field]) {
      result[field] = item.msg;
    }
  }
  return result;
}
