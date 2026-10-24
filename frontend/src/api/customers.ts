import { http } from "./http";

// Nilai ini ASUMSI. Sesuaikan dengan enum approval_status di backend.
export type ApprovalStatus = "PENDING" | "APPROVED" | "REJECTED";

export const APPROVAL_LABELS: Record<ApprovalStatus, string> = {
  PENDING: "Menunggu",
  APPROVED: "Disetujui",
  REJECTED: "Ditolak",
};

export interface Customer {
  id: number;
  nama_instansi: string;
  nama_pic: string | null;
  kontak_pic: string | null;
  kota: string | null;
  kategori: string | null;

  area_id: number | null;
  area_nama: string | null;

  sales_id: number | null;
  sales_nama: string | null;

  approval_status: ApprovalStatus | null;
  verified_by: number | null;
  verified_at: string | null;
  rejection_reason: string | null;
  created_at: string;
}

export interface CustomerInput {
  nama_instansi: string;
  nama_pic: string;
  kontak_pic: string;
  kota: string;
  kategori: string;
  area_id: number;
  sales_id: number;
}

export type CustomerUpdate = Partial<CustomerInput>;

// Customer yang masih menunggu atau ditolak tidak boleh dipakai di RKH/project.
export function isCustomerApproved(customer: Pick<Customer, "approval_status">): boolean {
  return customer.approval_status !== "PENDING" && customer.approval_status !== "REJECTED";
}

export async function getCustomers(): Promise<Customer[]> {
  const { data } = await http.get<Customer[]>("/customers/");
  return data;
}

export async function getCustomer(id: number): Promise<Customer> {
  const { data } = await http.get<Customer>(`/customers/${id}`);
  return data;
}

export async function createCustomer(payload: CustomerInput): Promise<void> {
  await http.post("/customers/", payload);
}

export async function updateCustomer(id: number, payload: CustomerUpdate): Promise<void> {
  await http.patch(`/customers/${id}`, payload);
}

export async function deleteCustomer(id: number): Promise<void> {
  await http.delete(`/customers/${id}`);
}

export async function approveCustomer(id: number): Promise<void> {
  await http.patch(`/customers/${id}/approve`);
}

// Body reject di backend memakai field "alasan".
export async function rejectCustomer(id: number, alasan: string): Promise<void> {
  await http.patch(`/customers/${id}/reject`, { alasan });
}
