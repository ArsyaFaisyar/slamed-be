export const USER_ROLES = ["SUPERADMIN", "SPV", "SALES", "PPIC", "ADMIN_MARKETING", "ADMIN_KEUANGAN"] as const;

export type UserRole = (typeof USER_ROLES)[number];

export const roleOptions = USER_ROLES.map((role) => ({
  value: role,
  label: role.replaceAll("_", " "),
}));
