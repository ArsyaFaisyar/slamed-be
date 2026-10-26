export interface TemplateTag {
  key: string;
  label: string;
}

export const TEMPLATE_TAGS: TemplateTag[] = [
  { key: "nama_customer", label: "Nama customer" },
  { key: "nama_pic", label: "Nama PIC customer" },
  { key: "telepon_pic", label: "Telepon PIC" },
  { key: "alamat_customer", label: "Alamat customer" },
  { key: "kota_customer", label: "Kota customer" },
  { key: "nama_project", label: "Nama project" },
  { key: "nomor_penawaran", label: "Nomor penawaran" },
  { key: "nilai_project", label: "Nilai project" },
  { key: "tautan_katalog", label: "Tautan katalog" },
  { key: "nama_sales", label: "Nama sales" },
  { key: "telepon_sales", label: "Telepon sales" },
  { key: "email_sales", label: "Email sales" },
  { key: "kontak_sales", label: "Kalimat kontak sales" },
  { key: "nama_pt", label: "Nama PT" },
  { key: "alamat_pt", label: "Alamat PT" },
  { key: "telepon_pt", label: "Telepon PT" },
  { key: "email_pt", label: "Email / web PT" },
];
