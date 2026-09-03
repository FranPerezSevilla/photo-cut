# Release and signing

## Automated path

The target release path is:

```text
tag -> GitHub Actions -> tests -> Android AAB / iOS archive -> internal tracks
```

Release automation is added only after app functionality is stable. Build and
store metadata remain in the repository; credentials do not.

## Secrets outside Git

- Android upload keystore and passwords.
- Apple distribution certificate and password.
- Apple provisioning profiles.
- App Store Connect API credentials.
- Google Play service-account credentials.

Use protected GitHub Environments for release jobs and require owner approval.

## Human gates

A human must confirm bundle ID ownership, create store applications and products,
complete legal/tax agreements, run sandbox purchases and approve final submission.
