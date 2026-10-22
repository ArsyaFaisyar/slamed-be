/// Nilai role sesuai enum di OpenAPI (UserCreate.role).
abstract final class Roles {
  static const superadmin = 'SUPERADMIN';
  static const spv = 'SPV';
  static const sales = 'SALES';
  static const ppic = 'PPIC';
  static const adminMarketing = 'ADMIN_MARKETING';
  static const adminKeuangan = 'ADMIN_KEUANGAN';

  /// Role yang memakai alur RKH/LKH di lapangan.
  static bool isField(String? role) => role == sales || role == spv;
}