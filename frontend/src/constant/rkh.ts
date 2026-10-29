export const tipeAktivitasOptions = [
  "Canvas",
  "Follow Up Canvas",
  "Penawaran",
  "Follow Up Penawaran",
  "Negosiasi",
  "Follow Up Negosiasi",
  "Revisi Penawaran",
  "Proses SPK",
  "Pengiriman Barang",
  "Proses Administrasi",
  "Proses penyelesaian administrasi",
].map((label) => ({ label, value: label }));

// Setelah sebuah project punya request penawaran, RKH berikutnya hanya boleh memilih tipe ini.
export const tipeAktivitasSetelahRequest = ["Follow Up Penawaran", "Negosiasi", "Revisi Penawaran"];

export const tipeAktivitasSetelahRequestOptions = tipeAktivitasOptions.filter((option) =>
  tipeAktivitasSetelahRequest.includes(option.value),
);