# M4-T08 — Protected Android Play release workflow

Photo Cut's Android upload keystore is not committed to the repository. The
manual `Play Release AAB` workflow runs only from `main` and is protected by
the GitHub Environment named `play-release`.

## Required environment secrets

The environment owns these secrets:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`

The workflow reconstructs the JKS only inside the ephemeral GitHub runner and
never writes signing credentials into the repository.

## Signing identity guard

The expected upload certificate SHA-256 fingerprint is:

`1B:3D:D6:00:F2:6A:E5:1F:89:5F:24:75:E5:62:63:CA:A6:C9:1A:D2:AD:0C:A7:ED:F9:E1:0A:7E:10:C1:EC:04`

The workflow checks that fingerprint before building and checks the signer of
the generated AAB again afterwards. A mismatch fails the job.

## Invocation

From GitHub Actions, select **Play Release AAB**, choose the `main` branch and
run the workflow. Optional `build_name` and `build_number` inputs can override
the values from `pubspec.yaml`; `build_number` must be a monotonically
increasing Play `versionCode`.

The output artifact is named:

`PhotoCut-<version>-build<versionCode>-GooglePlay.aab`

Ordinary repository CI does not receive the protected environment secrets and
therefore retains the existing debug-signed release-APK fallback used for
installable test artifacts.
