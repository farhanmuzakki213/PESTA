class Pkl {
  final String judul;
  final String mahasiswa;
  final int idMahasiswa;
  final String pembimbing;
  final int idPembimbing;
  final String penguji;
  final int idPenguji;

  Pkl({
    required this.judul,
    required this.mahasiswa,
    required this.idMahasiswa,
    required this.pembimbing,
    required this.idPembimbing,
    required this.penguji,
    required this.idPenguji,
  });

  factory Pkl.fromJson(Map<String, dynamic> json) {
    return Pkl(
      judul: json['judul_pkl'],
      mahasiswa: json['mahasiswa']['nama'] ?? 'Nama Tidak Diketahui',
      idMahasiswa: int.tryParse(json['mahasiswa']['id'].toString()) ?? 0, // Perbaikan
      pembimbing: json['pembimbing']['nama_pembimbing'],
      idPembimbing: int.tryParse(json['pembimbing']['id_dosen'].toString()) ?? 0, // Perbaikan
      penguji: json['penguji']['nama_penguji'],
      idPenguji: int.tryParse(json['penguji']['id_dosen'].toString()) ?? 0, // Perbaikan
    );
  }
}