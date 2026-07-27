class DenemeKaydi {
  final String id;
  final String ad;
  final DateTime tarih;

  final int sayisalDogru;
  final int sayisalYanlis;
  double get sayisalBos => (50 - sayisalDogru - sayisalYanlis).toDouble();
  double get sayisalNet => sayisalDogru - (sayisalYanlis / 4);

  final int sozelDogru;
  final int sozelYanlis;
  double get sozelBos => (50 - sozelDogru - sozelYanlis).toDouble();
  double get sozelNet => sozelDogru - (sozelYanlis / 4);

  double get toplamNet => sayisalNet + sozelNet;
  double get tahminiPuan => 120 + (toplamNet * 3);

  final String? notlar;

  DenemeKaydi({
    required this.id,
    required this.ad,
    required this.tarih,
    required this.sayisalDogru,
    required this.sayisalYanlis,
    required this.sozelDogru,
    required this.sozelYanlis,
    this.notlar,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'tarih': tarih.toIso8601String(),
        'sayisalDogru': sayisalDogru,
        'sayisalYanlis': sayisalYanlis,
        'sozelDogru': sozelDogru,
        'sozelYanlis': sozelYanlis,
        'notlar': notlar,
      };

  factory DenemeKaydi.fromJson(Map<String, dynamic> json) => DenemeKaydi(
        id: json['id'] as String,
        ad: json['ad'] as String,
        tarih: DateTime.parse(json['tarih'] as String),
        sayisalDogru: json['sayisalDogru'] as int,
        sayisalYanlis: json['sayisalYanlis'] as int,
        sozelDogru: json['sozelDogru'] as int,
        sozelYanlis: json['sozelYanlis'] as int,
        notlar: json['notlar'] as String?,
      );
}
