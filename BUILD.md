# Build / Derleme

## Türkçe

Bu klasördeki Lua runtime doğrudan Live Editor ile çalıştırılabilir. Statik `.fifamod` paketi için FIFA Editing Toolsuite 2.0.4 ve FC 26 TU1.6.4 oyun kurulumu gerekir.

1. FIFA Editing Toolsuite 2.0.4’ü kur.
2. FC 26 TU1.6.4 kurulumunu araçta tanıt.
3. `src/package_manifest.json` içindeki author ve title update değerlerini koru.
4. `src` altındaki kariyer database/UI/localization kaynaklarını FIFA Editing Toolsuite’te tek mod projesine aktar.
5. Gameplay, attribulator, Anth James ve KIARIKA kaynaklarını projeye ekleme.
6. Çıktıyı `dist/zarg4n Career Overhaul.fifamod` adıyla üret.
7. `runtime/lua/scripts/*.lua` dosyalarının tamamını Live Editor `lua/scripts` klasörüne kopyala.

Bu makinede FIFA Editing Toolsuite kurulu olmadığı için derlenmiş `.fifamod` dosyası kaynak pakete eklenmedi. Derleyici olmadan geçerli bir `.fifamod` üretmek yerine kaynak bütünlüğü korunmuştur.

## English

The Lua runtime can be loaded by Live Editor directly. Building the static `.fifamod` requires FIFA Editing Toolsuite 2.0.4 and an EA FC 26 TU1.6.4 installation.

1. Install FIFA Editing Toolsuite 2.0.4.
2. Configure the FC 26 TU1.6.4 installation in the tool.
3. Keep the author and title update values from `src/package_manifest.json`.
4. Import the career database/UI/localization sources from `src` into one FIFA Editing Toolsuite mod project.
5. Do not import gameplay, attribulator, Anth James or KIARIKA sources.
6. Build the output as `dist/zarg4n Career Overhaul.fifamod`.
7. Copy every file from `runtime/lua/scripts` to the Live Editor `lua/scripts` folder.

FIFA Editing Toolsuite is not installed on this machine, so a fake or invalid `.fifamod` was not generated. The source package remains honest and buildable instead.
