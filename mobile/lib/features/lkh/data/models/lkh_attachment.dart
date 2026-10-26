/// Satu berkas pada LKH (`GET /lkh/{id}/attachments`). `jenis`: FOTO atau LAMPIRAN.
class LkhAttachment {
  LkhAttachment({
    required this.id,
    required this.lkhId,
    required this.namaFile,
    required this.tipeFile,
    required this.jenis,
  });

  final int id, lkhId;
  final String namaFile, tipeFile, jenis;

  bool get isFoto => jenis.toUpperCase() == 'FOTO';

  factory LkhAttachment.fromJson(Map<String, dynamic> j) => LkhAttachment(
        id: (j['id'] as num).toInt(),
        lkhId: (j['lkh_id'] as num).toInt(),
        namaFile: (j['nama_file'] ?? 'lampiran').toString(),
        tipeFile: (j['tipe_file'] ?? '').toString(),
        jenis: (j['jenis'] ?? 'LAMPIRAN').toString(),
      );
} 