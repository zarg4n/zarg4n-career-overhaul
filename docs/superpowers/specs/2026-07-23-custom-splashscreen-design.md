# Custom Splashscreen Design

## Goal

Add `ChatGPT Image 23 Tem 2026 19_05_32.png` directly to the existing zarg4n Career Overhaul FIFAMOD so it replaces any lower-priority splashscreen without creating a separate addon.

## Image preparation

- Preserve the supplied artwork without generative alteration.
- Convert its near-16:9 canvas from 1672×941 to exactly 3840×2160.
- Apply a minimal centered crop before high-quality Lanczos resampling.
- Keep a lossless PNG source in the project.

## Game asset

- Replace `Fifa/FESplash/SplashScreen/SplashScreen`.
- Preserve the texture-group settings expected by `FE_SplashScreen_texgrp`.
- Keep `youth_scout.ini` and the Live Editor runtime unchanged.
- Export one updated `zarg4n Career Overhaul.fifamod`; do not create a separate splash addon.

## Priority and compatibility

FIFA Mod Manager gives the bottom/last applied mod the highest priority. The zarg4n mod must remain after gameplay packages that modify the same splash asset. No gameplay or attribulator asset is added.

## Verification

- Confirm the prepared PNG is 3840×2160 and valid.
- Confirm the project and FIFAMOD contain both the existing youth asset and the splash asset.
- Confirm the output FIFAMOD passes structural checks.
- Rebuild complete release archives, install/apply the updated mod, and verify the splash in game after resolving the existing RTSS/Live Editor DX12 hook conflict.
