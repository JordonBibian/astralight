# Astralight 1.0.0 (1) release validation

Checked October 27, 2026 using Xcode 27.1 (27A9275).

## Identity

- App Store name: Astralight
- App Store Connect SKU: `com.jordonbibian.astralight` (verified in App Information)
- App Store Connect app ID: `6827730489`
- Bundle identifier: `com.jordonbibian.Moonlight` (retained for installed-app identity and pairing data)
- Version/build: `1.0.0` / `1`
- Minimum iOS/iPadOS: `27.0`
- Device families: iPhone and iPad. Apple TV is deferred.

The SKU is an App Store Connect field, independent of the app's bundle identifier. Do not rename the bundle identifier solely to change the SKU.

## Passed

- Release archive for generic iOS device with automatic signing.
- App Store Connect export using the paid developer team and Apple Distribution signing; `get-task-allow` is false.
- Xcode Organizer **Validate App**: “Astralight 1.0.0 (1) validated. Your app successfully passed all validation checks.”
- Archive inspection confirms the version, minimum OS, device families, privacy manifest, and complete offline privacy/license resources.
- Release build and launch on iPad Pro 13-inch (M5), iPadOS 27.0 Simulator. Home/discovery and Settings render; native resolution reports 2752 × 2064. About buttons, privacy text, and license text are readable with safe-area padding. Privacy modal returns to Settings.
- iPhone 18 Pro Max Simulator: new About, Privacy Policy, and Credits & Licenses screens open and return correctly.
- Valid/malformed synthetic HTTP pairing-response regression tests pass without leaking the secret fixture into app logs or parser stderr.
- Dependency source/library/patch hashes, exact submodule revisions, and generated legal resources pass integrity checks.
- Filtered iPad runtime logs contain no uncaught-exception, unsatisfiable-constraint, or missing-legal-document messages during this smoke test.

Signing initially showed a stale Personal Team in Xcode. The same account's paid membership and team were verified, distribution export succeeded, and restarting Xcode refreshed Organizer's team. Validation then succeeded.

## Remaining warnings and limits

The initialized C variables and ENet enum casts remove their compiler warnings. The remaining build messages concern the signed OpenSSL binary not being stripped, deprecated `UIRequiresFullScreen`, and skipped App Intents metadata because this app has no App Intents dependency. No new compiler errors remain.

The iPad still uses the existing full-screen landscape architecture. Resizable iPad scene migration is separate work. Simulator MetalFX availability differs from a physical iPhone. This release-preparation pass did not pair the new simulators to a host or repeat a live AV1/game-stream test; UI smoke tests are not evidence of host/network or streaming performance.

The OpenSSL privacy-manifest concern and unresolved STUN/diagnostic privacy-label details are documented in [PrivacyAnswers.md](PrivacyAnswers.md). Apple validation passing is not a legal review or App Review approval.

## Artifacts

Local archive, App Store IPA, source archive/checksum, and simulator screenshots are retained under the ignored `Build/Release` directory. The self-contained source archive records its immutable Git revision; regenerate it after any release change. Build products and signing artifacts are not committed to the public repository.

This task validates and prepares the release. It does not submit the app for App Review or release it publicly on the App Store.
