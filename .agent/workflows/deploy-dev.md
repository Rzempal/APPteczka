---
description: Deploy APK to internal (DEV) channel
---
// turbo-all

# Deploy DEV

Deploys the APK to the internal (DEV) channel on the server.

## Steps

1. Run the deployment script:

```powershell
.\scripts\run_deploy_dev.bat
```

1. Wait for the build and upload to complete. The script will display:
   - Build progress
   - Upload status
   - Final version number and duration

## Notes

- The script builds Flutter APK with `--flavor internal`
- Uploads to `michalrapala.app/releases/internal/`
- Updates `version-internal.json` on the server
