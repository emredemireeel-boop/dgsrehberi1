import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gizlilik Politikası',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                colors,
                '1. Cihazda Saklanan Veriler',
                'Çalışma süreleri, hedefler, deneme sonuçları, soru kayıtları, '
                    'notlar, seçtiğiniz fotoğraflar ve uygulama tercihleri '
                    'yalnızca cihazınızda saklanır. Bu veriler geliştiriciye '
                    'veya bir sunucuya gönderilmez.',
              ),
              _section(
                colors,
                '2. Kamera ve Fotoğraflar',
                'Kamera ve fotoğraf arşivi izinleri yalnızca soru ve notlarınıza '
                    'görsel eklemeniz için kullanılır. Seçtiğiniz veya çektiğiniz '
                    'görseller cihazınızda kalır ve reklam sağlayıcısına aktarılmaz.',
              ),
              _section(
                colors,
                '3. Google AdMob',
                'Uygulama reklam göstermek için Google Mobile Ads (AdMob) '
                    'hizmetini kullanır. Google; reklam sunma, ölçüm, sahtekârlığı '
                    'önleme ve güvenlik amaçlarıyla reklam kimliği, IP adresi, '
                    'yaklaşık konum, cihaz bilgileri, reklam etkileşimleri, '
                    'performans ve tanılama verilerini işleyebilir.',
              ),
              _section(
                colors,
                '4. Reklam ve Gizlilik Tercihleri',
                'Gerekli bölgelerde Google User Messaging Platform üzerinden '
                    'reklam ve kişisel veri kullanım tercihleri sorulur. İzin '
                    'durumu alınmadan reklam isteği başlatılmaz. Sunulduğu '
                    'bölgelerde tercihlerinizi Ayarlar ekranındaki Reklam '
                    'Gizliliği seçeneğinden yeniden değiştirebilirsiniz.',
              ),
              _section(
                colors,
                '5. iOS Reklamları',
                'iOS cihazlarda reklam istekleri kişiselleştirilmemiş olarak '
                    'gönderilir. DGS Rehberi uygulamalar ve web siteleri arasında '
                    'takip izni istemez.',
              ),
              _section(
                colors,
                '6. Resmî Kurumlarla İlişki',
                'DGS Rehberi, ÖSYM veya başka bir resmî kurum tarafından '
                    'sunulmaz ya da desteklenmez. Bağımsız bir çalışma ve '
                    'planlama aracıdır.',
              ),
              _section(
                colors,
                '7. İletişim',
                'Gizlilikle ilgili sorularınız için '
                    'emre.demireeel@gmail.com adresine yazabilirsiniz.',
              ),
              Text(
                'Son güncelleme: 1 Ağustos 2026',
                style: TextStyle(
                  color: textColor?.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _section(
    ColorScheme colors,
    String title,
    String body,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(body),
        ],
      ),
    );
  }
}
