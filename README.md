# HueWarn

### Server (Express.js - Port 4007)

```bash
cd server
npm install
npm run dev
```

### Mobile (Flutter Web, iOS & Android)

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
   - Automatically increments build number with `${{ github.run_number }}`.
   - Uploads artifacts: individual APK, individual IPA, and a combined package containing both files.

2. **Deploy Server (`.github/workflows/deploy-server.yml`)**:
   - Triggers on push to `main`/`master` under `server/**` or manual `workflow_dispatch`.
   - Reads `ENV_VPS` secret from GitHub Repository Secrets (containing `VPS_HOST`, `VPS_PORT`, `VPS_USERNAME`, `VPS_PASSWORD`).
   - Connects via SSH to VPS, pulls latest code, builds and runs on port `4007` via PM2.
