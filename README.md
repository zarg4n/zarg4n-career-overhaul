# zarg4n Career Overhaul

Independent career-mode work for EA SPORTS FC 26 TU1.6.4.

Author / Yapımcı: **zarg4n**


## Türkçe

Bu proje başka bir kariyer modundan dosya almaz. Statik paket FIFA Editing Toolsuite ile sıfırdan oluşturuldu; dinamik sistemler `zarg4n_*` isim alanındaki Live Editor Lua dosyalarında çalışır.

### 0.2.0 içeriği

- TU1.6.4 için derlenmiş tek `.fifamod`
- Daha tutarlı yerel genç oyuncu üretimi
- Her scout seviyesinde daha seyrek “hazır wonderkid” üretimi
- Yalnızca yeni kariyer oluşturulurken etkinleşen, save’e özel deterministik oyuncu profilleri
- Sezonluk maç puanı, forma sayısı, gol, asist, clean sheet ve kurtarış verilerini kullanan gelişim
- Az maçlık güçlü bir örneği küçük ölçüde ödüllendiren fakat tek maçla potansiyel artırmayan örnek güveni
- Sezon başına `-2..+3` ile sınırlı dinamik potansiyel
- Performans gelişimini 27–28 yaş prime dönemini kapsayacak şekilde 29 yaş sonuna kadar sürdürme
- Boy gelişimini 20, kilo/güç gelişimini 23 yaş civarında tamamlayan; stat artışını performansa bağlayan kademeli fizik modeli
- İnce yapılı kalan, hızlı gelişen veya Bruiser’a yatkın olabilen farklı fizik profilleri
- Pozisyon, fizik, performans ve kişiliğe göre 15 PlayStyle adayı
- 80 OVR’de ilk, 85 OVR’de ikinci PlayStyle+ için performans ve mevcut PlayStyle şartları
- Aynı sezon sonu olayını iki kez uygulamayan kalıcı işlem günlüğü
- Yarım kalan işlemleri güvenli ve idempotent biçimde yeniden deneyen write-ahead state sistemi
- Oyun kapatılmadan başka kariyere geçildiğinde doğru save profilini yeniden yükleme
- Deterministik oyuncu kişilikleri, sınırlı hafıza ve Türkçe/İngilizce anlatı metni altyapısı
- Transfer olaylarını oyun verisine veya görüşme akışına müdahale etmeden kaydeden salt-okunur gözlemci
- Gameplay fiziği, CPU davranışı ve attribulator tablolarına sıfır yazma

**Yeni kariyer zorunludur.** Mod kurulduktan sonra oluşturulmayan kariyerlerde dinamik sistem bilerek etkinleşmez. Kariyer HUD’si, oyun içi yeni diyalog seçenekleri, transfer reddini aşan ikna ekranı, geniş isim havuzları, Create-a-Club seçici, yedek kulübesi sayısı değişikliği ve “pozisyonunda kal” maç puanı cezası düzeltmesi bu sürümde yoktur. Bunlar için güvenli ve belgelenmiş bir veri/UI yolu doğrulanmadan gameplay veya bellek yaması eklenmeyecektir.

## English

This project does not reuse files from other career mods. The static package was created from a clean FIFA Editing Toolsuite project; dynamic systems live in uniquely named `zarg4n_*` Live Editor Lua files.

### Included in 0.2.0

- One TU1.6.4 `.fifamod`
- More consistent local youth generation
- Fewer ready-made wonderkids at every scout level
- Save-specific deterministic player profiles activated only when a new career is created
- Development driven by seasonal rating, appearances, goals, assists, clean sheets and saves
- Strong small appearance samples receive a modest reward but cannot raise potential from one match
- Dynamic potential capped to `-2..+3` per season
- Performance development through the 27–28 prime window, with dynamic potential supported through age 29
- Gradual height development to roughly age 20, with body and performance-led physical attributes through age 23
- Distinct physical identities, including slight, fast and Bruiser-oriented prospects
- Fifteen PlayStyle candidates selected from position, physical profile, performance and personality
- Performance and existing-style requirements for a first PlayStyle+ at 80 OVR and a second at 85 OVR
- Durable, idempotent end-of-season processing
- Write-ahead state checkpoints and safe retries for interrupted transactions
- Safe state reload when switching career saves without restarting the game
- Deterministic personalities, bounded memory and Turkish/English narrative text infrastructure
- Read-only transfer-event observation without modifying negotiation flow or game data
- No gameplay physics, CPU behaviour or attribulator edits

**A fresh career is required.** Dynamic systems deliberately remain disabled in careers that were not created after installing the mod. A career HUD, new in-game dialogue choices, persuasion UI that bypasses transfer refusal, expanded name pools, a Create-a-Club selector, bench-size changes and the “stay in position” rating penalty fix are not included. They will not be shipped through speculative gameplay or memory patches.

## Compatibility

- EA SPORTS FC 26 PC, TU1.6.4
- FIFA Mod Manager 2.0.4
- FC 26 Live Editor v26.3.5
- A new Manager Career created after installation is mandatory
- Do not combine it with another career database mod that edits the same youth-scout asset
- Gameplay mods are outside this mod’s data scope

Original code and authored data are by zarg4n. EA SPORTS FC 26 and its game assets remain the property of Electronic Arts.

Live Editor's public season-stat interface exposes appearances, not reliable per-match minutes. “Small sample” therefore means few appearances; the mod does not pretend to detect an exact 15-minute cameo.
