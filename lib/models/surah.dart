// To parse this JSON data, do
//
//     final surah = surahFromJson(jsonString);

import 'dart:convert';

import 'package:quran_app/models/ayat.dart';

List<Surah> surahFromJson(String str) =>
    List<Surah>.from(json.decode(str)["data"].map((x) => Surah.fromJson(x)));

Surah surahDetailFromJson(String str) => Surah.fromJson(json.decode(str)["data"]);

String surahToJson(List<Surah> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Surah {
  Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
    required this.audio,
    this.ayat,
  });

  int nomor;
  String nama;
  String namaLatin;
  int jumlahAyat;
  TempatTurun tempatTurun;
  String arti;
  String deskripsi;
  String audio;
  List<Ayat>? ayat;

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        nomor: json["nomor"],
        nama: json["nama"],
        namaLatin: json["namaLatin"],
        jumlahAyat: json["jumlahAyat"],
        tempatTurun: json["tempatTurun"].toString().toLowerCase() == 'mekah'
            ? TempatTurun.MEKAH
            : TempatTurun.MADINAH,
        arti: json["arti"],
        deskripsi: json["deskripsi"],
        audio: json["audioFull"]["05"], // Default to Misyari Rasyid Al-Afasi
        ayat: json.containsKey('ayat')
            ? List<Ayat>.from(json["ayat"]!.map((x) => Ayat.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "nomor": nomor,
        "nama": nama,
        "nama_latin": namaLatin,
        "jumlah_ayat": jumlahAyat,
        "tempat_turun": tempatTurunValues.reverse[tempatTurun],
        "arti": arti,
        "deskripsi": deskripsi,
        "audio": audio,
        "ayat": ayat != null
            ? List<dynamic>.from(ayat!.map((e) => e.toJson()))
            : [],
      };
}

enum TempatTurun { MEKAH, MADINAH }

final tempatTurunValues =
    EnumValues({"mekah": TempatTurun.MEKAH, "madinah": TempatTurun.MADINAH});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map) {
    reverseMap = map.map((k, v) => MapEntry(v, k));
  }

  Map<T, String> get reverse {
    return reverseMap;
  }
}
