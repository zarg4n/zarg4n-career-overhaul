# Build / Derleme

The checked-in `zarg4n Career Overhaul.fifaproject` targets FIFA Editing Toolsuite 2.0.4 and FC 26 TU1.6.4.

## Türkçe

1. `zarg4n Career Overhaul.fifaproject` dosyasını FIFA Editing Toolsuite 2.0.4 ile aç.
2. Modified Assets görünümünde yalnızca `youth_scout.ini` bulunduğunu doğrula.
3. `File > Export to Mod` ile çıktıyı `release/zarg4n Career Overhaul 0.1.0-alpha.fifamod` olarak üret.
4. `FCGameplay`, attribulator, KIARIKA veya Anth James varlığı ekleme.
5. Lua kaynaklarını `src/lua` altında düzenle. Giriş dosyasını `runtime/lua/autorun`, kalan modülleri `runtime/lua/scripts` altına yansıt.

## English

1. Open `zarg4n Career Overhaul.fifaproject` in FIFA Editing Toolsuite 2.0.4.
2. Confirm that Modified Assets contains only `youth_scout.ini`.
3. Use `File > Export to Mod` and write `release/zarg4n Career Overhaul 0.1.0-alpha.fifamod`.
4. Do not add `FCGameplay`, attribulator, KIARIKA or Anth James assets.
5. Edit Lua sources under `src/lua`; mirror the entrypoint to `runtime/lua/autorun` and supporting modules to `runtime/lua/scripts`.
