# Astralight for iOS

Astralight is an open source fork of [Moonlight for iOS/tvOS](https://github.com/moonlight-stream/moonlight-ios). It lets you stream games and desktop apps from your PC to your iPhone or iPad.

## Requirements and video modes

The iPhone and iPad app requires **iOS/iPadOS 27.0 or later**. Build it with Xcode 27 or later. Apple TV support is planned for later; the inherited tvOS target is outside the current iOS feature scope.

**Native** is the default resolution mode. Each new stream uses the active device screen's native landscape pixel dimensions, independent of Display Zoom, safe-area insets, or an old saved resolution. Encoded dimensions are rounded to even pixels where required by 4:2:0 video. Restart a stream after changing displays or folding/unfolding to a different display size.

**Upscaled (SDR)** is optional under Settings → Resolution. It requests approximately half the native width and height, decodes using VideoToolbox, and uses Apple's MetalFX spatial scaler to produce native-sized frames. This is spatial GPU upscaling, not a downloaded neural model. HDR is inactive in this mode; the HDR preference is retained for Native mode. Frame queues are bounded to avoid accumulating latency. If the GPU/decoder fails, Astralight requests a fresh keyframe and falls back to the standard display renderer for the remainder of the stream.

**AV1 + upscaling** is supported in SDR on devices with hardware AV1 decoding. Select **AV1** in the codec setting and **Upscaled (SDR)** under Resolution. Apollo/Sunshine must offer AV1 encoding for the live stream to use AV1. The decoder-to-MetalFX path has been verified on the physical Duo; this does not yet establish sustained gameplay performance.

The upscaling option is disabled on unsupported devices and in the iOS Simulator, whose installed iOS 27.1 SDK and runtime do not include MetalFX. Installing the Metal compiler provides shader tools but does not add that simulator framework. Native mode remains available there.

Apollo/Sunshine may need a matching host or virtual-display resolution to fill the screen. Astralight requests the stream resolution; it cannot guarantee that every host changes the game's or desktop's resolution.

## Host compatibility

Astralight uses Moonlight's streaming protocol and works with Moonlight-compatible hosts, including:

* [Apollo](https://github.com/ClassicOldSong/Apollo)
* [Sunshine](https://github.com/LizardByte/Sunshine)
* Existing NVIDIA GameStream hosts

Moonlight and Astralight are streaming clients; install host software such as Apollo or Sunshine on the PC you want to connect to.

## iPhone Duo compatibility

Astralight has been verified to build, install, and launch on both a physical iPhone Duo and the iPhone Duo simulator. This fork includes the scene lifecycle changes needed for the tested iOS versions to launch the app successfully.

Apollo pairing and app-list retrieval have also been verified on the physical iPhone Duo. Synthetic H.264/HEVC/AV1 decode-and-MetalFX tests also pass on the physical Duo at its reported **2034 × 1398** native size. The AV1 test includes **1018 × 700 → 2034 × 1398** upscaling, 32 frames with temporal dependencies, moving-patch color checks, a resolution change, a 40-frame burst, and teardown. Metal API validation was enabled. Full gameplay streaming, sustained frame-rate/thermal measurements, and input validation on the Duo remain to be completed.

## In-app documentation

Tap **Documentation** next to Settings on the host picker or app list to open the official Apollo setup/downloads and client-permission guides, or Moonlight's setup and troubleshooting guides. Each link opens in your browser.

## Apollo permissions

Apollo controls permissions separately for each paired client. If pairing succeeds and apps appear, but launching an app returns **Permission denied**, open Apollo's web interface on the host PC, edit the paired Astralight client, enable **Launch Apps**, and save. Enable the input permissions you need for touch, controllers, a mouse, or a keyboard as well. See [Apollo's permission guide](https://github.com/ClassicOldSong/Apollo/wiki/Permission-System).

A separately installed development build may have its own paired client entry, so check the permissions for the build you are using.

## Building

* Install Xcode from the [App Store page](https://apps.apple.com/us/app/xcode/id497799835)
* Run `git clone --recursive https://github.com/JordonBibian/moonlight-ios.git`
  * If you've already cloned the repo without `--recursive`, run `git submodule update --init --recursive`
* Open `Astralight.xcodeproj` in Xcode.
* Select the **Astralight** app scheme for iPhone/iPad, then choose your device or simulator, including iPhone Duo. The `moonlight-common` scheme builds the shared library and does not launch the app.
* To run on a real device, you will need to locally modify the signing options:
    * Click on "Astralight" at the top of the left sidebar
    * Click on the "Signing & Capabilities" tab
    * Under "Targets", select "Astralight" (for iOS/iPadOS)
    * In the "Team" dropdown, select your name. If your name doesn't appear, you may need to sign into Xcode with your Apple account.
    * Change the "Bundle Identifier" to something different. You can add your name or some random letters to make it unique.
    * Now you can select your Apple device in the top bar as a target and click the Play button to run.

## Video regression checks

On a Mac with MetalFX support, run:

```sh
sh Tests/run-video-smoke-tests.sh
```

For the same checks on an iPhone, build the **Astralight** scheme in Debug and add `--video-pipeline-self-test` to the scheme's launch arguments. The test uses the phone's native output dimensions and prints `PASS` or `FAIL` to the debug console. Remove the argument for normal use. The diagnostic is excluded from Release builds. On Simulator it checks resolution math and explicitly skips MetalFX.

The AV1 checks use original synthetic Main8 SDR fixtures in `Tests/AV1TestFixtures.h`, containing a keyframe and 15 dependent frames at each of two resolutions. The iPhone test uses the production AV1 sequence-header parser. AV1 is explicitly skipped when hardware decoding is unavailable; the H.264/HEVC checks still run. Fixtures are included only in the Debug diagnostic, and no AV1 encoder is added to the app. To regenerate them, run `Tests/generate-av1-fixtures.py` with Python and PyAV 19.0.2 (including its libsvtav1 encoder).

The legacy C warning fixes also modify the `moonlight-common/moonlight-common-c` and nested `enet` submodule working trees. Preserve those submodule changes when committing or distributing this checkout.

The iOS build still reports the deprecated `UIRequiresFullScreen` setting. Removing it requires a separate migration of the stream and input layout to resizable iPad scenes; see [Apple's migration guide](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key). Xcode may also emit an App Intents metadata message because this app has no App Intents dependency.

## Upstream project

Astralight builds on the work of the [Moonlight project](https://moonlight-stream.org). Moonlight also provides a [PC client](https://github.com/moonlight-stream/moonlight-qt) and an [Android client](https://github.com/moonlight-stream/moonlight-android).

See the [Moonlight wiki](https://github.com/moonlight-stream/moonlight-docs/wiki) for general setup and troubleshooting. The [upstream Moonlight App Store listing](https://apps.apple.com/us/app/moonlight-game-streaming/id1000551566) distributes Moonlight, not this Astralight fork.

See [LICENSE.txt](LICENSE.txt) for the GPLv3 license and App Store Distribution Exception.
