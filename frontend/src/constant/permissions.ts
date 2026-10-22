import type { UserRole } from "./roles";

export type AppRole = UserRole;

const ALL_ROLES: AppRole[] = ["SUPERADMIN", "SPV", "SALES", "PPIC", "ADMIN_MARKETING", "ADMIN_KEUANGAN"];

// Permission mengikuti matriks RBAC yang kamu kirim.
// SUPERADMIN mendapatkan seluruh akses.
const rolePermissions: Record<string, AppRole[]> = {
  "/dashboard": ALL_ROLES,

  "/transaksi/customer": ["SUPERADMIN", "SPV", "SALES"],

  "/transaksi/project": ["SUPERADMIN", "SPV", "SALES", "PPIC"],

  "/aktivitas/rkh": ["SUPERADMIN", "SPV", "SALES"],

  "/aktivitas/lkh": ["SUPERADMIN", "SPV", "SALES"],

  "/support/request-penawaran": ["SUPERADMIN", "SPV", "SALES", "PPIC"],

  "/support/proses-ppic": ["SUPERADMIN", "SPV", "PPIC"],

  "/support/terima-dan-kirim": ["SUPERADMIN", "SPV"],

  "/support/permintaan-pajak": ["SUPERADMIN", "SPV"],

  "/support/bopod-administrasi": ["SUPERADMIN", "SPV"],

  "/support/penyelesaian-cashback": ["SUPERADMIN", "SPV"],

  "/laporan/sla-admin": ["SUPERADMIN"],
  "/laporan/sales": ["SUPERADMIN"],

  "/master/branch": ["SUPERADMIN"],
  "/master/media-pengadaan": ["SUPERADMIN"],
  "/master/area": ["SUPERADMIN"],
  "/master/user": ["SUPERADMIN"],

  "/setting/pengaturan": ["SUPERADMIN"],
  "/setting/kategori-customer": ["SUPERADMIN"],
  "/setting/template-penawaran": ["SUPERADMIN"],
  "/setting/role": ["SUPERADMIN"],
  "/setting/rbca": ["SUPERADMIN"],
};

const dynamicRoutes: { pattern: RegExp; base: string }[] = [{ pattern: /^\/aktivitas\/lkh\/\d+$/, base: "/aktivitas/lkh" }];

function resolvePermissionPath(path: string): string {
  return dynamicRoutes.find(({ pattern }) => pattern.test(path))?.base ?? path;
}

export function canAccessRoute(path: string, role?: string | null): boolean {
  if (!role) return false;

  // Role yang belum memiliki pemetaan khusus
  // hanya boleh mengakses Dashboard untuk sementara.
  if (role === "ADMIN_MARKETING" || role === "ADMIN_KEUANGAN") {
    return path === "/dashboard" || path === "/profile";
  }

  if (role === "SUPERADMIN") return true;

  if (path === "/profile") return true;

  const allowedRoles = rolePermissions[resolvePermissionPath(path)];

  return allowedRoles?.includes(role as AppRole) ?? false;
}

export function canAccessMenu(path: string, role?: string | null): boolean {
  return canAccessRoute(path, role);
}
