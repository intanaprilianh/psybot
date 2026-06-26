class CallCenterService {
  final String id;
  final String nama;
  final String deskripsi;
  final String nomor;
  final String jamOperasional;
  final String tipe;
  final bool gratis;
  final String? url;

  CallCenterService({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.nomor,
    required this.jamOperasional,
    required this.tipe,
    required this.gratis,
    this.url,
  });

  factory CallCenterService.fromJson(Map<String, dynamic> json) {
    return CallCenterService(
      id: json['id'] as String,
      nama: json['nama'] as String,
      deskripsi: json['deskripsi'] as String,
      nomor: json['nomor'] as String,
      jamOperasional: json['jam_operasional'] as String,
      tipe: json['tipe'] as String,
      gratis: json['gratis'] as bool,
      url: json['url'] as String?,
    );
  }
}
