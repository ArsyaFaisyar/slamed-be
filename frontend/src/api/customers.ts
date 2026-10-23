import { http } from "./http";

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
