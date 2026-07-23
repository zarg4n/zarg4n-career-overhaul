# zarg4n Career Overhaul

Independent career-mode work for EA SPORTS FC 26 TU1.6.4.

Author / Yapımcı: **zarg4n**

Repository: [github.com/zarg4n/zarg4n-career-overhaul](https://github.com/zarg4n/zarg4n-career-overhaul)

## Türkçe

Bu proje KIARIKA’dan veya başka bir kariyer modundan dosya almaz. Statik paket FIFA Editing Toolsuite ile sıfırdan oluşturuldu; dinamik sistemler `zarg4n_*` isim alanındaki Live Editor Lua dosyalarında çalışır.

### 0.1.0-alpha içeriği

- TU1.6.4 için derlenmiş tek `.fifamod`
- Daha tutarlı yerel genç oyuncu üretimi
- Her scout seviyesinde daha seyrek “hazır wonderkid” üretimi
- Save’e özel, deterministik genç oyuncu profilleri
- Sezonluk maç puanı, forma sayısı, gol, asist, clean sheet ve kurtarış verilerini kullanan gelişim
- Az maçlık güçlü bir örneği küçük ölçüde ödüllendiren fakat tek maçla potansiyel artırmayan örnek güveni
- Sezon başına `-2..+3` ile sınırlı dinamik potansiyel
- Performans gelişimini 27–28 yaş prime dönemini kapsayacak şekilde 29 yaş sonuna kadar sürdürme
- Boy gelişimini 20, kilo/güç gelişimini 23 yaş civarında tamamlayan; stat artışını performansa bağlayan kademeli fizik modeli
- İnce yapılı kalan, hızlı gelişen veya Bruiser’a yatkın olabilen farklı fizik profilleri
- Bruiser, Aerial Fortress, Power Shot, Relentless, Quick Step ve Intercept adayları
- 80 OVR’de ilk, 85 OVR’de ikinci PlayStyle+ için performans ve mevcut PlayStyle şartları
- Aynı sezon sonu olayını iki kez uygulamayan save güvenliği
- Oyun kaydedilmeden kapanırsa hedef değerleri sonraki yüklemede EA save ile uzlaştırma
- Oyun kapatılmadan başka kariyere geçildiğinde doğru save profilini yeniden yükleme
- Gameplay fiziği, CPU davranışı ve attribulator tablolarına sıfır yazma

Bu sürüm bir **alpha çekirdek sürümdür**. Kariyer HUD’si, Türkçe/İngilizce konuşmalar, transfer rol yapma sistemi, geniş isim havuzları, Create-a-Club seçici ve “pozisyonunda kal” maç puanı cezası henüz pakette değildir. Bu sistemler için FC 26’da güvenli veri kaynağı doğrulanmadan gameplay veya bellek yaması eklenmeyecektir.

## English

This project does not reuse files from KIARIKA or another career mod. The static package was created from a clean FIFA Editing Toolsuite project; dynamic systems live in uniquely named `zarg4n_*` Live Editor Lua files.

### Included in 0.1.0-alpha

- One TU1.6.4 `.fifamod`
- More consistent local youth generation
- Fewer ready-made wonderkids at every scout level
- Save-specific deterministic prospect profiles
- Development driven by seasonal rating, appearances, goals, assists, clean sheets and saves
- Strong small appearance samples receive a modest reward but cannot raise potential from one match
- Dynamic potential capped to `-2..+3` per season
- Performance development through the 27–28 prime window, with dynamic potential supported through age 29
- Gradual height development to roughly age 20, with body and performance-led physical attributes through age 23
- Distinct physical identities, including slight, fast and Bruiser-oriented prospects
- Candidate logic for Bruiser, Aerial Fortress, Power Shot, Relentless, Quick Step and Intercept
- Performance and existing-style requirements for a first PlayStyle+ at 80 OVR and a second at 85 OVR
- Idempotent end-of-season processing
- Career-save reconciliation when the game closes before EA persists the database changes
- Safe state reload when switching career saves without restarting the game
- No gameplay physics, CPU behaviour or attribulator edits

This is an **alpha core release**. The career HUD, Turkish/English conversations, transfer role-play, expanded name pools, Create-a-Club selector and the “stay in position” rating penalty fix are not included yet. Those systems will not be shipped through speculative gameplay or memory patches.

## Compatibility

- EA SPORTS FC 26 PC, TU1.6.4
- FIFA Mod Manager 2.0.4
- FC 26 Live Editor v26.3.5
- New career recommended and required for supported behaviour
- KIARIKA Career Mode Overhaul must not be enabled in the same setup
- Anth James gameplay mods are outside this mod’s data scope

Original code and authored data are by zarg4n. EA SPORTS FC 26 and its game assets remain the property of Electronic Arts.

Live Editor's public season-stat interface exposes appearances, not reliable per-match minutes. “Small sample” therefore means few appearances; the alpha does not pretend to detect an exact 15-minute cameo.
