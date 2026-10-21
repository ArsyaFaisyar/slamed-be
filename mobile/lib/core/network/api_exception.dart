class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => message;
}

/// Teks yang aman ditampilkan ke pengguna.
String errorMessage(Object e) => e is ApiException ? e.message : 'Terjadi kesalahan. Coba lagi.';

/// Ambil pesan dari `detail` FastAPI (string, atau daftar error validasi 422).
String detailFrom(dynamic data, int status) {
  if (data is Map && data['detail'] != null) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is List) {
      return d.map((e) => e is Map ? (e['msg'] ?? e).toString() : '$e').join('\n');
    }
  }
  if (status == 403) return 'Akses ditolak.';
  if (status == 404) return 'Data tidak ditemukan.';
  if (status >= 500) return 'Terjadi kesalahan server. Coba lagi.';
  return 'Request gagal ($status).';
}