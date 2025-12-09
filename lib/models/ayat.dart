class Ayat {
  Ayat({
    required this.id,
    this.surah,
    required this.nomor,
    required this.ar,
    required this.tr,
    required this.idn,
    this.audio,
  });

  int id;
  int? surah;
  int nomor;
  String ar;
  String tr;
  String idn;
  String? audio;

  factory Ayat.fromJson(Map<String, dynamic> json) => Ayat(
        id: json["nomorAyat"],
        surah: null, // The surah number is not available in this part of the API response
        nomor: json["nomorAyat"],
        ar: json["teksArab"],
        tr: json["teksLatin"],
        idn: json["teksIndonesia"],
        audio: json["audio"]["05"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "surah": surah,
        "nomor": nomor,
        "ar": ar,
        "tr": tr,
        "idn": idn,
        "audio": audio,
      };
}
