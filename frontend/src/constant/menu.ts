import type { Component } from "vue";
import { ArrowLeftRight, CalendarCheck, ChartColumn, Database, LayoutDashboard, LifeBuoy, Settings } from "@lucide/vue";

export interface MenuLeaf {
  label: string;
  title?: string;
  to: string;
}

export interface MenuItem {
  label: string;
  icon: Component;
  title?: string;
  to?: string;
  children?: MenuLeaf[];
}

export const menu: MenuItem[] = [
  { label: "Dashboard", icon: LayoutDashboard, to: "/dashboard" },
  {
    label: "Transaksi",
    icon: ArrowLeftRight,
    children: [
      { label: "Customer", to: "/transaksi/customer" },
      { label: "Project", to: "/transaksi/project" },
    ],
  },
  {
    label: "Aktivitas",
    icon: CalendarCheck,
    children: [
      { label: "RKH", title: "Rencana Kegiatan Harian", to: "/aktivitas/rkh" },
      { label: "LKH", title: "Laporan Kegiatan Harian", to: "/aktivitas/lkh" },
    ],
  },
  {
    label: "Support",
    icon: LifeBuoy,
    children: [
      { label: "Request Penawaran", to: "/support/request-penawaran" },
      { label: "Proses PPIC", to: "/support/proses-ppic" },
      { label: "Terima Dan Kirim", to: "/support/terima-dan-kirim" },
      { label: "Permintaan Pajak", to: "/support/permintaan-pajak" },
      { label: "Bopod dan Administrasi", to: "/support/bopod-administrasi" },
      { label: "Penyelesaian Cashback", to: "/support/penyelesaian-cashback" },
    ],
  },
  {
    label: "Laporan",
    icon: ChartColumn,
    children: [
      { label: "Laporan SLA Admin", to: "/laporan/sla-admin" },
      { label: "Laporan Sales", to: "/laporan/sales" },
    ],
  },
  {
    label: "Master Data",
    icon: Database,
    children: [
      { label: "Branch", to: "/master/branch" },
      { label: "Media Pengadaan", to: "/master/media-pengadaan" },
      { label: "Kategori Customer", to: "/master/kategori-customer" },
      { label: "Area", to: "/master/area" },
      { label: "User", to: "/master/user" },
    ],
  },
  {
    label: "Setting",
    icon: Settings,
    children: [
      { label: "Pengaturan", to: "/setting/pengaturan" },
      { label: "Template Penawaran", to: "/setting/template-penawaran" },
      { label: "Role", to: "/setting/role" },
      { label: "RBCA", to: "/setting/rbca" },
    ],
  },
];
