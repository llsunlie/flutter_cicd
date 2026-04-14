# flutter_cicd

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI/CD

- Pushes and pull requests to `main` run validation in GitHub Actions.
- Version tags like `v1.0.0` trigger a release workflow.
- Web releases are published to GitHub Pages.
- Android releases are uploaded to GitHub Releases together with `version.json`.

### Release Flow

1. Update `pubspec.yaml` version.
2. Create a tag such as `v1.0.0`.
3. Push the tag to GitHub.
4. GitHub Actions builds the Web bundle and Android APK.
5. The workflow publishes Web to GitHub Pages and uploads the APK plus `version.json` to GitHub Releases.

## GitHub Configuration

- Enable GitHub Pages and configure the source as GitHub Actions.
- Allow workflow permissions to read and write repository contents.
- Create releases by pushing `v*` tags.
- Keep the update manifest URL in sync with the repository owner and name.
