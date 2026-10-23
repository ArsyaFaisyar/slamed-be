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
/// Untuk 422, nama field ikut ditampilkan (mis. "nama_pic: Field required").
String detailFrom(dynamic data, int status) {
  if (data is Map && data['detail'] != null) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is List) {
      return d.map((e) {
        if (e is! Map) return '$e';
        final msg = (e['msg'] ?? e).toString();
        final loc = e['loc'];
        // loc contoh: ["body", "nama_pic"] -> ambil nama field terakhir.
        final field = (loc is List && loc.isNotEmpty) ? loc.last.toString() : null;
        return (field == null || field == 'body') ? msg : '$field: $msg';
      }).join('\n');
    }
  }
  if (status == 403) return 'Akses ditolak.';
  if (status == 404) return 'Data tidak ditemukan.';
  if (status >= 500) return 'Terjadi kesalahan server. Coba lagi.';
  return 'Request gagal ($status).';
}