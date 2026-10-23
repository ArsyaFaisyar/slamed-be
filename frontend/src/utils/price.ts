import type { Numeric, RequestItem } from "../api/requestPenawaran.ts";

export type Draft = Record<number, number | null>;

export function toNumber(value: Numeric | null | undefined): number | null {
  if (value === null || value === undefined || value === "") return null;
  const number = Number(value);
  return Number.isNaN(number) ? null : number;
}

export function formatRupiah(value: Numeric | null | undefined) {
  const number = toNumber(value);
  if (number === null) return "-";
  return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(number);
}

export function formatQty(value: Numeric | null | undefined) {
  const number = toNumber(value);
  if (number === null) return "-";
  return new Intl.NumberFormat("id-ID", { maximumFractionDigits: 2 }).format(number);
}

export function lineTotal(item: RequestItem, price: number | null | undefined) {
  if (price === null || price === undefined) return null;
  return (toNumber(item.jumlah) ?? 0) * price;
}

export function draftTotal(items: RequestItem[], draft: Draft) {
  return items.reduce((sum, item) => sum + (lineTotal(item, draft[item.id]) ?? 0), 0);
}
