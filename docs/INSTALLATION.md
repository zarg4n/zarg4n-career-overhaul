# Kurulum / Installation

## Türkçe

Gereksinimler: EA SPORTS FC 26 PC TU1.6.4, FIFA Mod Manager 2.0.4 ve FC 26 Live Editor v26.3.5.

1. `release/zarg4n Career Overhaul 0.2.0.fifamod` dosyasını FIFA Mod Manager’a sürükle.
2. Modu etkinleştir ve **Apply Mods** işlemini tamamla.
3. Runtime ZIP’ini FC 26 Live Editor ana klasörüne çıkar. Dosya yapısı aynen şöyle olmalıdır:

   - `lua\autorun\zarg4n_career_overhaul.lua`
   - `lua\scripts\` altında 17 adet yardımcı `zarg4n_*.lua` dosyası

4. Aynı `youth_scout.ini` kaynağını değiştiren başka bir kariyer veritabanı modunu birlikte kullanma.
5. Gameplay modlarını kendi sıralarında bırak; zarg4n Career Overhaul `FCGameplay` veya attribulator kaynağı içermez.
6. Live Editor’ı aç, ardından Mod Manager’ın uyguladığı modlarla oyunu başlat.
7. Mod kurulduktan sonra **yeni bir Manager Career oluştur**. Eski kariyerler desteklenmez ve runtime bu kariyerlerde yazma yapmaz.
8. Live Editor logunda `[zarg4n] Loaded zarg4n runtime for TU1.6.4` satırını kontrol et.

Runtime state dosyası `LE_DATA_PATH` altında (normalde Live Editor veri klasörü) `zarg4n_career_<SAVE_UID>.json` adıyla tutulur. Bu dosya EA save’inin parçası değildir ama oyuncu profilleri ve sezon işleme kaydı için gereklidir.

Kaldırırken modu Mod Manager’dan çıkar, autorun giriş dosyasını ve 17 yardımcı Lua dosyasını sil; yalnızca ilgili kariyeri artık kullanmayacaksan state JSON’unu kaldır.

## English

Requirements: EA SPORTS FC 26 PC TU1.6.4, FIFA Mod Manager 2.0.4 and FC 26 Live Editor v26.3.5.

1. Import `release/zarg4n Career Overhaul 0.2.0.fifamod` into FIFA Mod Manager.
2. Enable it and complete **Apply Mods**.
3. Extract the Runtime ZIP into the FC 26 Live Editor root. Preserve this exact structure:

   - `lua\autorun\zarg4n_career_overhaul.lua`
   - 17 supporting `zarg4n_*.lua` files under `lua\scripts`

4. Do not combine it with another career database mod that controls the same `youth_scout.ini` asset.
5. Leave gameplay mods in their normal order; this package contains no `FCGameplay` or attribulator asset.
6. Open Live Editor, then launch the game with the mods already applied by Mod Manager.
7. **Create a new Manager Career after installation.** Existing careers are unsupported and the runtime will not write to them.
8. Confirm `[zarg4n] Loaded zarg4n runtime for TU1.6.4` in the Live Editor log.

Runtime state is stored under `LE_DATA_PATH` (normally the Live Editor data directory) as `zarg4n_career_<SAVE_UID>.json`. It is separate from the EA save but required for prospect profiles and season idempotency.

To uninstall, remove the Mod Manager entry, delete the autorun entrypoint and 17 supporting Lua files, and remove the state JSON only if that career will no longer be used.
