class Ta {
  final String judul;
  final String mahasiswa;
  final int idMahasiswa;
  final String pembimbing1;
  final int idPembimbing1;
  final String pembimbing2;
  final int idPembimbing2;
  final String penguji1;
  final int idPenguji1;
  final String penguji2;
  final int idPenguji2;
  final String ketua;
  final int idKetua;
  final String sekretaris;
  final int idSekretaris;

  Ta({
    required this.judul,
    required this.mahasiswa,
    required this.idMahasiswa,
    required this.pembimbing1,
    required this.idPembimbing1,
    required this.pembimbing2,
    required this.idPembimbing2,
    required this.penguji1,
    required this.idPenguji1,
    required this.penguji2,
    required this.idPenguji2,
    required this.ketua,
    required this.idKetua,
    required this.sekretaris,
    required this.idSekretaris,
  });

  factory Ta.fromJson(Map<String, dynamic> json) {
    return Ta(
      judul: json['judul_ta'],
      mahasiswa: json['mahasiswa']['nama'] ?? 'Nama Tidak Diketahui',
      idMahasiswa: int.tryParse(json['mahasiswa']['id'].toString()) ?? 0, // Perbaikan
      pembimbing1: json['pembimbing_1']['nama_pembimbing_1'],
      idPembimbing1: int.tryParse(json['pembimbing_1']['id_dosen'].toString()) ?? 0, // Perbaikan
      pembimbing2: json['pembimbing_2']['nama_pembimbing_2'],
      idPembimbing2: int.tryParse(json['pembimbing_2']['id_dosen'].toString()) ?? 0, // Perbaikan
      penguji1: json['penguji_1']['nama_penguji_1'],
      idPenguji1: int.tryParse(json['penguji_1']['id_dosen'].toString()) ?? 0, // Perbaikan
      penguji2: json['penguji_2']['nama_penguji_2'],
      idPenguji2: int.tryParse(json['penguji_2']['id_dosen'].toString()) ?? 0, // Perbaikan
      ketua: json['ketua']['nama_ketua'],
      idKetua: int.tryParse(json['ketua']['id_dosen'].toString()) ?? 0, // Perbaikan
      sekretaris: json['sekretaris']['nama_sekretaris'],
      idSekretaris: int.tryParse(json['sekretaris']['id_dosen'].toString()) ?? 0, // Perbaikan
    );
  }
}