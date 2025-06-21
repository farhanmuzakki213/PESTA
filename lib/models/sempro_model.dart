class Sempro {
  final String judul;
  final String mahasiswa;
  final int idMahasiswa;
  final String pembimbing1;
  final int idPembimbing1;
  final String pembimbing2;
  final int idPembimbing2;
  final String penguji;
  final int idPenguji;

  Sempro({
    required this.judul,
    required this.mahasiswa,
    required this.idMahasiswa,
    required this.pembimbing1,
    required this.idPembimbing1,
    required this.pembimbing2,
    required this.idPembimbing2,
    required this.penguji,
    required this.idPenguji,
  });

  factory Sempro.fromJson(Map<String, dynamic> json) {
    return Sempro(
      judul: json['judul_sempro'],
      mahasiswa: json['mahasiswa']['nama'] ?? 'Nama Tidak Diketahui',
      idMahasiswa: int.tryParse(json['mahasiswa']['id'].toString()) ?? 0, // Perbaikan
      pembimbing1: json['pembimbing_1']['nama_pembimbing_1'],
      idPembimbing1: int.tryParse(json['pembimbing_1']['id_dosen'].toString()) ?? 0, // Perbaikan
      pembimbing2: json['pembimbing_2']['nama_pembimbing_2'],
      idPembimbing2: int.tryParse(json['pembimbing_2']['id_dosen'].toString()) ?? 0, // Perbaikan
      penguji: json['penguji']['nama_penguji'],
      idPenguji: int.tryParse(json['penguji']['id_dosen'].toString()) ?? 0, // Perbaikan
    );
  }
}