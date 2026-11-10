# HueWarn

### Server (Express.js - Port 4007)

```bash
cd server
npm install
npm run dev
```

### Mobile (Flutter Web, iOS & Android)

API Endpoint: `https://hue-warn.spit-husc.io.vn/api`

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

```bash
cd mobile
flutter run -d android
```

```bash
cd mobile
flutter run -d ios
```

### CI/CD Workflows

1. **Build Mobile (`.github/workflows/build-mobile.yml`)**:
   - Triggers on push/PR to `main`/`master` or manual `workflow_dispatch`.
   - Builds Android APK (`HueWarn-v1.0.<RUN_NUMBER>.apk`) and iOS IPA (`HueWarn-v1.0.<RUN_NUMBER>.ipa`).
   - Automatically increments version with `${{ github.run_number }}`.
   - Uploads artifacts: individual APK, individual IPA, and a combined package containing both files.

2. **Deploy Server (`.github/workflows/deploy-server.yml`)**:
   - Triggers on push to `main`/`master` under `server/**` or manual `workflow_dispatch`.
   - Secrets required:
     - `ENV_VPS`: VPS SSH credentials (`VPS_HOST`, `VPS_PORT`, `VPS_USERNAME`, `VPS_PASSWORD`).
     - `ENV`: Full server environment configuration content (automatically written to `.env` on VPS with `PORT=4007`).
   - Packages server bundle in GitHub Actions, transfers directly to VPS via SSH stream, creates `.env` from `ENV`, runs `npm install`, `npm run build`, and starts/restarts on port `4007` via PM2.
