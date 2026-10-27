# Astralight iOS/tvOS

Astralight is an open source fork of [Moonlight for iOS/tvOS](https://github.com/moonlight-stream/moonlight-ios). It lets you stream games and desktop apps from your PC to your iPhone, iPad, or Apple TV.

## Host compatibility

Astralight uses Moonlight's streaming protocol and works with Moonlight-compatible hosts, including:

* [Apollo](https://github.com/ClassicOldSong/Apollo)
* [Sunshine](https://github.com/LizardByte/Sunshine)
* Existing NVIDIA GameStream hosts

Moonlight and Astralight are streaming clients; install host software such as Apollo or Sunshine on the PC you want to connect to.

## iPhone Duo compatibility

Astralight has been verified to build, install, and launch on both a physical iPhone Duo and the iPhone Duo simulator. This fork includes the scene lifecycle changes needed for the tested iOS versions to launch the app successfully.

Apollo pairing and app-list retrieval have also been verified on the physical iPhone Duo. Full gameplay streaming and input validation on the Duo remain to be completed.

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
    * Under "Targets", select "Astralight" (for iOS/iPadOS) or "Astralight TV" (for tvOS)
    * In the "Team" dropdown, select your name. If your name doesn't appear, you may need to sign into Xcode with your Apple account.
    * Change the "Bundle Identifier" to something different. You can add your name or some random letters to make it unique.
    * Now you can select your Apple device in the top bar as a target and click the Play button to run.

## Upstream project

Astralight builds on the work of the [Moonlight project](https://moonlight-stream.org). Moonlight also provides a [PC client](https://github.com/moonlight-stream/moonlight-qt) and an [Android client](https://github.com/moonlight-stream/moonlight-android).

See the [Moonlight wiki](https://github.com/moonlight-stream/moonlight-docs/wiki) for general setup and troubleshooting. The [upstream Moonlight App Store listing](https://apps.apple.com/us/app/moonlight-game-streaming/id1000551566) distributes Moonlight, not this Astralight fork.

See [LICENSE.txt](LICENSE.txt) for the GPLv3 license and App Store Distribution Exception.
