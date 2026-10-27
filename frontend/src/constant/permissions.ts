import type { UserRole } from "./roles";

export type AppRole = UserRole;

const ALL_ROLES: AppRole[] = ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES", "PPIC", "PAJAK", "PURCHASING", "ADMIN_MARKETING", "ADMIN_KEUANGAN"];

const rolePermissions: Record<string, AppRole[]> = {
  "/dashboard": ALL_ROLES,

  "/transaksi/customer": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES"],
  "/transaksi/project": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES", "PPIC", "PAJAK", "PURCHASING"],
  "/transaksi/customer-approval": ["SUPERADMIN", "SPV"],

  "/aktivitas/rkh": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES"],
  "/aktivitas/lkh": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES"],

  "/support/request-penawaran": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES", "PPIC", "PURCHASING"],
  "/support/proses-ppic": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "PPIC"],
  "/support/terima-dan-kirim": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "PURCHASING"],
  "/support/permintaan-pajak": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "PAJAK"],
  "/support/bopod-administrasi": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV"],
  "/support/penyelesaian-cashback": ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV"],

  "/laporan/sla-admin": ["SUPERADMIN"],
  "/laporan/sales": ["SUPERADMIN"],

  "/master/branch": ["SUPERADMIN"],
  "/master/media-pengadaan": ["SUPERADMIN"],
  "/master/kategori-customer": ["SUPERADMIN"],
  "/master/status-project": ["SUPERADMIN"],
  "/master/area": ["SUPERADMIN"],
  "/master/user": ["SUPERADMIN"],

  "/setting/pengaturan": ["SUPERADMIN", "DIREKTUR"],
  "/setting/template-penawaran": ["SUPERADMIN", "DIREKTUR"],
  "/setting/role": ["SUPERADMIN", "DIREKTUR"],
  "/setting/rbca": ["SUPERADMIN", "DIREKTUR"],
};

const dynamicRoutes: { pattern: RegExp; base: string }[] = [
  { pattern: /^\/aktivitas\/lkh\/\d+$/, base: "/aktivitas/lkh" },
  { pattern: /^\/master\/branch\/\d+$/, base: "/master/branch" },
  { pattern: /^\/aktivitas\/lkh\/\d+\/request-penawaran$/, base: "/aktivitas/lkh" },
  { pattern: /^\/aktivitas\/request-penawaran\/\d+$/, base: "/support/request-penawaran" },
  { pattern: /^\/aktivitas\/request-penawaran\/\d+\/revisi\/\d+$/, base: "/support/request-penawaran" },
];

function resolvePermissionPath(path: string): string {
  return dynamicRoutes.find(({ pattern }) => pattern.test(path))?.base ?? path;
}

export function canAccessRoute(path: string, role?: string | null): boolean {
  if (!role) return false;

  if (role === "SUPERADMIN") return true;

  if (path === "/profile") return true;

  if (role === "ADMIN_MARKETING" || role === "ADMIN_KEUANGAN") {
    return path === "/dashboard";
  }

  const allowedRoles = rolePermissions[resolvePermissionPath(path)];

  return allowedRoles?.includes(role as AppRole) ?? false;
}

export function canAccessMenu(path: string, role?: string | null): boolean {
  return canAccessRoute(path, role);
}
