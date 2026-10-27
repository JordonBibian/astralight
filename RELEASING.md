# Astralight 1.0.0 release source and build instructions

This release targets iPhone and iPad on iOS/iPadOS 27.0 or later. The app's public name is Astralight. Its bundle identifier remains `com.jordonbibian.Moonlight` to preserve installed-app identity and local pairing data. The App Store Connect SKU is `com.jordonbibian.astralight` (a separate field from the bundle identifier). Version is `1.0.0`, build `1`. Apple TV is outside this release's scope.

## Corresponding source

The public repository contains Astralight's preferred source, resources, build project, dependency patches, and complete dependency source archives. Clone recursively, because GitHub's automatically generated ZIP does not expand submodules:

```sh
git clone --recursive https://github.com/JordonBibian/astralight.git
cd astralight
sh BuildScripts/apply-dependency-fixes.sh
python3 BuildScripts/verify-release-inputs.py
```

`ThirdParty/release-inputs.json` records source URLs, SHA-256 checksums, exact submodule revisions, prebuilt library hashes, and the pinned OpenSSL package revision. `ThirdParty/Sources` contains the corresponding FFmpeg, SDL, Opus and OpenSSL sources; no dependency source needs to be requested from the maintainer. `ThirdParty/OpenSSLBuild` contains the vendor's Apple build scripts, configuration, patches, support files, and license, extracted unchanged from release 3.6.3000. Its duplicate prebuilt frameworks are omitted.

`Patches` preserves Astralight's three C initializers and ENet enum casts. The apply script is idempotent and refuses conflicting local modifications. A modified submodule working tree after applying these documented patches is expected; its base revision stays pinned. All other Astralight changes are in the main repository's history. Preserve the original copyright notices and full `LICENSE.txt`, including the App Store Distribution Exception. Dependency terms remain in their source trees and `ThirdParty/Licenses`. The app also includes full offline notices under Settings → About Astralight → Credits & Licenses.

## Building the app

The release was built with Xcode 27.1 (27A9275). Apple SDKs and signing tools are supplied by Xcode and are not redistributed here. The project uses the checked-in static libraries and resolves OpenSSL-Package **exactly** to 3.6.3000; do not update dependencies during a release build.

```sh
sh Tests/run-privacy-tests.sh
python3 BuildScripts/generate-legal-documents.py --check
xcodebuild -project Astralight.xcodeproj -scheme Astralight \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath Build/Release/Astralight-1.0.0.xcarchive \
  -allowProvisioningUpdates archive
```

A contributor must select their own signing team and, if needed, their own bundle ID. The maintainer's public team ID is not a signing credential. Keep version/build values synchronized in both iOS configurations, and increment the build number for each new App Store Connect upload.

The committed inputs make a source build repeatable. Bit-for-bit equality with a signed App Store binary is not promised: Xcode, SDK versions, code-signing timestamps, and Apple processing can change output.

## Rebuilding or modifying bundled libraries

The app is provided with complete source so you can rebuild/relink it with modified libraries.

* **FFmpeg:** extract `ThirdParty/Sources/ffmpeg-3f890fbfd9014843c51408c8f7ab3ba4aef7d354.tar.gz`. The included historical `moonlight-mobile-deps-dad1ce6d964b6d4cc61116f1b7170954eb08ef20.tar.gz` contains the original `FFmpeg.sh`, `appveyor.yml`, and `archive.sh` build settings. These enable only avcodec, avformat, FLV muxing, and the AV1 decoder with autodetection and other features disabled. Build arm64 for iOS and arm64/x86_64 for Simulator, then replace the matching `libs/FFmpeg` headers and static libraries. The app uses FFmpeg's private CBS headers, so update headers and libraries together. Those upstream scripts clean their source checkout with `git reset`/`git clean`; run them only in a disposable dependency checkout. The scripts are included as source provenance and are not run by the app build.
* **SDL 2.28.5:** extract its source archive and build `Xcode/SDL/SDL.xcodeproj`, target `Static Library-iOS`, Release, once with `-sdk iphoneos` and once with `-sdk iphonesimulator`. The historical `SDL-ios.sh` records these commands. Replace `libs/SDL2/include` and the matching iOS libraries.
* **Opus 1.4:** the official release tarball includes `configure`. The historical `opus.sh` records `--disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc`, platform compiler flags, and architectures. Copy the resulting headers and `libopus.a` to `libs/opus` (combine simulator architectures with `lipo`).
* **OpenSSL 3.6.3 / Apple package 3.6.3000:** copy the OpenSSL source archive beside `ThirdParty/OpenSSLBuild/Makefile` as `openssl-3.6.3.tar.gz` in a disposable work directory. Follow the included vendor README/Makefile and scripts to generate the XCFramework using Xcode and Tuist. The package wrapper source is included separately. For a locally rebuilt framework, use a local Swift package binary target pointing at that XCFramework instead of the remote package reference. Code signing of your build uses your own identity.

Rebuilding all third-party binaries from these sources has not been revalidated with Xcode 27; the app release uses the hashed prebuilt libraries. Do not claim a newly rebuilt dependency is tested until its device/simulator checks pass.

## Self-contained source archive

After committing root changes and applying the documented dependency patches:

```sh
python3 BuildScripts/package-release-source.py Build/Release/Astralight-1.0.0-source.tar.gz
```

This expands submodules, includes exact patched sources and dependency source archives, records the Git revision, and writes a SHA-256 checksum. It excludes `.git`, local credentials, device data, DerivedData, and untracked files. Its timestamps/order are normalized. An extracted source archive already contains the dependency fixes; do not run the Git patch script inside that archive. Open its Xcode project directly after verifying inputs.

## App Store preparation

Use `AppStore/PrivacyAnswers.md` for the audited data flows and remaining confirmation before publishing privacy answers. Use the public [Privacy Policy](https://github.com/JordonBibian/astralight/blob/master/PRIVACY.md) URL in App Store Connect. See `AppStore/ReleaseValidation.md` for results and known limits. A successful archive/export is separate from App Store validation or App Review approval. No public App Store release is performed by these scripts.
