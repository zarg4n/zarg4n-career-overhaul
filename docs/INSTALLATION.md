# zarg4n Career Overhaul Kurulum / Installation

## Türkçe

### Gereksinimler

- EA SPORTS FC 26 PC
- Title Update 1.6.4
- FIFA Mod Manager 2.0.4
- FC 26 Live Editor v26.3.5
- FIFA Editing Toolsuite 2.0.4 yalnızca derleme yapmak için gereklidir

### Kurulum

1. Oyunun ve FIFA Mod Manager’ın yedeğini al.
2. `dist/zarg4n Career Overhaul.fifamod` dosyasını FIFA Mod Manager’ın FC26 mod klasörüne kopyala.
3. Mod Manager’da `zarg4n Career Overhaul.fifamod` dosyasını etkinleştir.
4. `runtime/lua/scripts/zarg4n_career_overhaul.lua` dosyasını Live Editor kurulumundaki `lua/scripts` klasörüne kopyala.
5. Oyunu Mod Manager’dan başlat.
6. Live Editor’ın çalıştığını doğrula.
7. Yeni bir Manager Career başlat. Eski save’ler desteklenmez.
8. İlk kariyer ekranında mod logunu kontrol et. Runtime, save UID’sine göre masaüstünde `zarg4n_career_<SAVE_UID>.json` oluşturur.

### Mod sırası

Bu mod Anth James gameplay modlarının yerine geçmez ve onların gameplay tablolarına dokunmaz. Gameplay modlarını kendi kurulum talimatlarına göre kullanabilirsin.

KIARIKA ile aynı kariyerde birlikte çalışması hedeflenmez; zarg4n Career Overhaul bağımsız tam moddur.

### Kaldırma

1. Kariyer save’ini yedekle.
2. Mod Manager’da zarg4n modunu kapat.
3. Live Editor `lua/scripts` klasöründen runtime dosyasını kaldır.
4. Masaüstündeki `zarg4n_career_<SAVE_UID>.json` dosyasını yalnızca artık kullanmayacaksan sil.

## English

### Requirements

- EA SPORTS FC 26 PC
- Title Update 1.6.4
- FIFA Mod Manager 2.0.4
- FC 26 Live Editor v26.3.5
- FIFA Editing Toolsuite 2.0.4 for building the static package

### Installation

1. Back up the game and your FIFA Mod Manager setup.
2. Copy `dist/zarg4n Career Overhaul.fifamod` to the FC26 mod folder used by FIFA Mod Manager.
3. Enable `zarg4n Career Overhaul.fifamod` in Mod Manager.
4. Copy `runtime/lua/scripts/zarg4n_career_overhaul.lua` into the Live Editor installation’s `lua/scripts` folder.
5. Launch the game through Mod Manager.
6. Confirm that Live Editor is running.
7. Start a new Manager Career. Existing saves are not supported.
8. Check the runtime log. The script creates `zarg4n_career_<SAVE_UID>.json` on the desktop.

### Load order

This project does not replace Anth James gameplay mods and does not write to their gameplay tables. Use gameplay mods according to their own installation instructions.

It is not designed to run alongside KIARIKA in the same career. zarg4n Career Overhaul is an independent full career mod.

### Removal

1. Back up the career save.
2. Disable the zarg4n mod in Mod Manager.
3. Remove the runtime file from Live Editor’s `lua/scripts` folder.
4. Delete `zarg4n_career_<SAVE_UID>.json` from the desktop only when the save is no longer needed.
