# zarg4n Career Overhaul Tasarım Belgesi

## Kapsam

EA SPORTS FC 26 TU1.6.4 için, KIARIKA dosyalarından bağımsız çalışan tek `.fifamod` ve zorunlu Live Editor Lua runtime paketi. Yapımcı adı `zarg4n`.

Mod, gameplay fiziğine ve Anth James gameplay tablolarına dokunmaz. Yalnızca kariyer verileri, kariyer olayları, oyuncu gelişimi, maç reytingi, PlayStyle evrimi, diyaloglar, transfer görüşmeleri, isim havuzları ve kariyer HUD'si hedeflenir.

## Onaylanan davranışlar

- Yeni kariyer zorunludur.
- Genç oyuncu gelişimi dakika, maç reytingi, pozisyon istatistikleri, sezon toplamları, antrenman planı, yaş, takım seviyesi ve gizli gelişim profiliyle hesaplanır.
- Kısa süreli ama etkili katkılar kaybolmaz; dakika katsayısı aşırı gelişimi engeller.
- Sezon sonunda potansiyel yalnızca sınırlı aralıkta güncellenir.
- Boy ve kilo değişimleri düşük ihtimalli, yaşa bağlı ve oyuncu profilinden bağımsız olmayan bir sistemle yapılır.
- Pozisyon dışı kalma uyarısı tek başına maç reytingini düşürmez.
- PlayStyle başlangıçta pozisyon ve kaliteyle dağıtılır; PlayStyle+ adayları kullanıcıya 2–3 seçenek olarak gösterilir.
- Bruiser gibi fiziksel PlayStyle'lar güç ve kontrollü vücut gelişimiyle ilişkilidir; pozisyonlar kesin kalıp değildir.
- PlayStyle'lar uzun vadeli performans ve profil değişimine göre zayıflayabilir veya evrilebilir.
- Oyuncu hafızası olay-temelli ve kişilik katsayılarıyla sınırlıdır.
- Maç sonrası mesajlar ve basın toplantıları maç olaylarına duyarlıdır; önemli olaylar önceliklidir.
- Türkçe ve İngilizce metinler aynı içerik anahtarlarını kullanır; çeviriler doğal yerelleştirme olarak yazılır.
- Oyuncular blöf yapabilir, vaatleri hatırlayabilir ve kişiliklerine göre tepki verebilir.
- İlişkiler yalnızca olay yaşanan oyuncu çiftlerinde oluşturulur.
- HUD, oyuncu detayları ve gelişim planı ekranlarına bağlanır; kariyer merkezi tamamen değiştirilmez.

## Runtime sınırı

`.fifamod` statik database ve UI varlıklarını taşır. Maç olayları, save kimliği, sezon istatistikleri, kişilik/hafıza ve dinamik diyaloglar Live Editor Lua runtime ile yürütülür. Runtime olmadan mod güvenli biçimde devre dışı kalır; oyunun açılışını engellemez.

## Faz 1

İlk uygulanabilir dilim; kariyer doğrulaması, save durumu, oyuncu profili, istatistik toplama, gelişim skoru, sınırlı POT güncellemesi, Bruiser/fizik profili ve log/test altyapısıdır. UI ve diyaloglar sonraki fazlarda aynı veri sözleşmesini kullanır.

## Güvenlik ve uyumluluk

- TU1.6.4 dışındaki sürümlerde runtime çalışmayı durdurur ve log yazar.
- Mevcut save desteklenmez; yeni kariyer doğrulaması yapılır.
- Her yazma işleminden önce kariyer modu, oyuncu varlığı ve kullanıcı takımı kontrol edilir.
- Database editleri whitelist ile sınırlanır.
- Runtime state save UID bazında saklanır.
- Mod, gameplay tablolarına yazmaz.
