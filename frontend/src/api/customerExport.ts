import axios from "axios";

import { http } from "./http.ts";

export interface CustomerExportParams {
  area?: string[];
  sales?: string[];
  status_approval?: string[];
  tanggal_mulai?: string | null;
  tanggal_selesai?: string | null;
}

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

function defaultFilename() {
  const now = new Date();
  const pad = (value: number) => String(value).padStart(2, "0");
  return `customer-${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}.xlsx`;
}

export async function exportCustomersExcel(params: CustomerExportParams): Promise<void> {
  const query = Object.fromEntries(Object.entries(params).filter(([, value]) => (Array.isArray(value) ? value.length > 0 : value !== null && value !== undefined && value !== "")));

  const response = await http.get<Blob>("/customers/export/excel", {
    params: query,
    paramsSerializer: { indexes: null },
    responseType: "blob",
  });

  const url = URL.createObjectURL(response.data);
  const link = document.createElement("a");
  link.href = url;
  link.download = filenameFrom(response.headers["content-disposition"]) ?? defaultFilename();
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
