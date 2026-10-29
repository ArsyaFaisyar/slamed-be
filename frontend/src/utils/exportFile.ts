import axios from "axios";

import { http } from "../api/http.ts";

function filenameFrom(disposition: string | undefined) {
  if (!disposition) return null;
  const encoded = /filename\*=UTF-8''([^;]+)/i.exec(disposition)?.[1];
  if (encoded) {
    try {
      return decodeURIComponent(encoded);
    } catch {
      return encoded;
    }
  }
  return /filename="?([^";]+)"?/i.exec(disposition)?.[1] ?? null;
}

function defaultFilename(prefix: string) {
  const now = new Date();
  const pad = (value: number) => String(value).padStart(2, "0");
  return `${prefix}-${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}.xlsx`;
}

export async function downloadExcel(path: string, params: Record<string, unknown>, filenamePrefix: string): Promise<void> {
  const query = Object.fromEntries(Object.entries(params).filter(([, value]) => (Array.isArray(value) ? value.length > 0 : value !== null && value !== undefined && value !== "")));

  const response = await http.get<Blob>(path, {
    params: query,
    paramsSerializer: { indexes: null },
    responseType: "blob",
  });

  const url = URL.createObjectURL(response.data);
  const link = document.createElement("a");
  link.href = url;
  link.download = filenameFrom(response.headers["content-disposition"]) ?? defaultFilename(filenamePrefix);
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

export async function exportErrorMessage(error: unknown, fallback: string): Promise<string> {
  if (!axios.isAxiosError(error)) return fallback;
  if (!error.response) return "Tidak dapat terhubung ke server";

  const data: unknown = error.response.data;
  if (data instanceof Blob) {
    try {
      const parsed: unknown = JSON.parse(await data.text());
      const detail = typeof parsed === "object" && parsed !== null ? (parsed as { detail?: unknown }).detail : null;
      if (typeof detail === "string") return detail;
    } catch {
      return fallback;
    }
  }

  return fallback;
}
