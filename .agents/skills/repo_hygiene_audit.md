# Repo Hygiene Audit

## Purpose
Standardized workflow for auditing repository health, classifying generated debris, and ensuring critical platform folders are preserved.

## Instructions
1.  **Classify Debris**:
    -   `build/`, `.dart_tool/`, `.gradle/`, `.kotlin/` -> Safe to delete.
    -   Stale root files (e.g., `package.json` in non-JS projects) -> Safe to delete.
2.  **Platform Protection**:
    -   **CRITICAL**: NEVER delete `android/gradlew`, `android/gradlew.bat`, or the `android/gradle/` folder.
    -   **CRITICAL**: NEVER delete `ios/Podfile` or `ios/Runner.xcodeproj`.
3.  **Security Audit**:
    -   Check for `serviceAccountKey.json`, `.env`, or hardcoded API keys.
    -   Ensure `firebase_options.dart` is the only tracked config if necessary.
4.  **Embedding Check**:
    -   Verify `android/app/src/main/AndroidManifest.xml` contains `<meta-data android:name="flutterEmbedding" android:value="2" />`.

## Execution Phases
1.  **Audit**: Run `git status` and `du -sh` on debris folders.
2.  **Cleanup**: Delete identified debris.
3.  **Repair**: If wrappers are missing, run `flutter create --platforms=[platform] .`.
4.  **Validate**: Run `flutter pub get` and `flutter analyze`.
