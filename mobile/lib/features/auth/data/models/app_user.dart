class AppUser {
  AppUser({
    required this.id,
    required this.nama,
    required this.username,
    required this.email,
    required this.role,
    this.fotoProfil,
  });

  final int id;
  final String nama, username, email, role;
  final String? fotoProfil;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        nama: (j['nama'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        role: (j['role'] ?? '').toString(),
        fotoProfil: j['foto_profil'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'username': username,
        'email': email,
        'role': role,
        'foto_profil': fotoProfil,
      };
}