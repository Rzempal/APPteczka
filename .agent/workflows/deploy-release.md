---
description: Deploy APK to production channel
---
// turbo-all

# Deploy Release

Deploys the APK to the production (release) channel on the server.

## Steps

1. Run the deployment script:

```powershell
.\scripts\run_deploy_release.bat
```

1. Wait for the build and upload to complete. The script will display:
   - Build progress
   - Upload status
   - Final version number and duration

## Notes

- The script builds Flutter APK with `--flavor production`
- Uploads to `michalrapala.app/releases/`
- Updates `version.json` on the server
