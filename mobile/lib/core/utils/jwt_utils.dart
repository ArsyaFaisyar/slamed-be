import 'dart:convert';

/// Membaca payload JWT (tanpa verifikasi; verifikasi tetap tugas backend).
Map<String, dynamic>? jwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  } catch (_) {
    return null;
  }
}

/// True jika klaim `exp` sudah lewat (margin 30 detik).
bool jwtExpired(String token, {DateTime? now}) {
  final exp = jwtPayload(token)?['exp'];
  if (exp is! num) return false;
  final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch / 1000;
  return seconds >= exp - 30;
}