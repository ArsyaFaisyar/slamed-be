export const USER_ROLES = ["SUPERADMIN", "DIREKTUR", "MANAJER", "SPV", "SALES", "PPIC", "PAJAK", "PURCHASING", "ADMIN_MARKETING", "ADMIN_KEUANGAN"] as const;

export type UserRole = (typeof USER_ROLES)[number];

export const roleLabels: Record<UserRole, string> = {
  SUPERADMIN: "Admin",
  DIREKTUR: "Direktur",
  MANAJER: "Manajer",
  SPV: "SPV Area",
  SALES: "Sales",
  PPIC: "PPIC",
  PAJAK: "Pajak",
  PURCHASING: "Purchasing",
  ADMIN_MARKETING: "Admin Marketing",
  ADMIN_KEUANGAN: "Admin Keuangan",
};

export const roleOptions = USER_ROLES.map((role) => ({
  value: role,
  label: roleLabels[role],
}));
