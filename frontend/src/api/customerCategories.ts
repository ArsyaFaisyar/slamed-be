import { http } from "./http";

export interface CustomerCategory {
  id: number;
  nama: string;
}

export interface CustomerCategoryInput {
  nama: string;
}

export async function getCustomerCategories(): Promise<CustomerCategory[]> {
  const { data } = await http.get<CustomerCategory[]>("/customer-categories/");
  return data;
}

export async function createCustomerCategory(payload: CustomerCategoryInput): Promise<void> {
  await http.post("/customer-categories/", payload);
}

export async function updateCustomerCategory(id: number, payload: Partial<CustomerCategoryInput>): Promise<void> {
  await http.patch(`/customer-categories/${id}`, payload);
}

export async function deleteCustomerCategory(id: number): Promise<void> {
  await http.delete(`/customer-categories/${id}`);
}
