<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Enhance your video playback experience with modern_player—a feature-rich Flutter package for flutter_vlc_player. Enjoy auto-hiding controls, double-tap to seek, customizable UI, automatic subtitle and audio track detection, and more on both Android and iOS.

## Features

Introducing modern_player, the ultimate Flutter package designed to elevate your video playback experience with flutter_vlc_player. This feature-packed solution offers a seamless and engaging video playback interface with the following key features:

**Auto Hide Controls:** Say goodbye to cluttered screens with auto-hiding controls that ensure an immersive viewing experience.

**Double Tap to Seek:** Effortlessly seek through your video content by double-tapping on the screen.

**Change Video Quality:** Switch between video quality options to ensure the best playback experience.

**Auto-Detect Video Subtitles and Audio Tracks:** modern_player automatically detects and offers options for video subtitles and audio tracks.

**Fully Customizable UI:** Tailor the user interface to your liking, giving you full control over the look and feel.

**Brightness Control:** Slide left to adjust brightness on the fly for a comfortable viewing experience.

**Volume Control:** Slide vertically on the right side to fine-tune the audio volume to your preference.

**Cross-Platform Support:** Enjoy modern_player's features on both Android and iOS devices.

With modern_player, you can provide a top-notch video playback experience to your users, complete with an intuitive and fully customizable interface. Say goodbye to mundane video controls and give your app an edge with modern_player.

## To-do

* Callback options
* Add manual subtitle and audio track
* Picture-in-picture mode
* Video Cast/Screen Mirroring (Chromecast)
* Support for fullscreen
* Custom ErrorBuilder
* Playbackspeed Control
* Placeholder Widget
* Loop Support
* Video start at
* Custom options

## Installation

In your pubspec.yaml file within your Flutter Project add modern_player under dependencies:

```yaml
dependencies:
  modern_player: <latest_version>
```

## Using it

```dart
import 'package:modern_player/modern_player.dart';

final modernPlayerWidget = SizedBox(
    height: 200,
    child: ModernPlayer.createPlayer(
      qualityOptions: [
        ModernPlayerQualityOptions(
            name: "Default",
            url:
                "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4")
      ],
    ),
  );
```

## Options

Modern player has some option to adjust and theme your controls. By default all button and features are enabled.

To enable disable button, you can add these lines to your `modern_player`

```dart
  controlsOptions: ModernPlayerControlsOptions(
      showControls: true,
      doubleTapToSeek: false,
      showMenu: true,
      showMute: false,
      showBackbutton: false,
      enableVolumeSlider: true,
      enableBrigthnessSlider: true,
      showBottomBar: true)
```
### Theme Customization

To customize theme or colors of your player, you can add these lines to your `controlsOptions`

```dart
  themeOptions: ModernPlayerThemeOptions(
      backgroundColor: Colors.black,
      menuBackgroundColor: Colors.black,
      loadingColor: Colors.white,
      menuIcon: const Icon(
        Icons.settings,
        color: Colors.white,
      ))
```
To customize theme of progress slider, you can add these lines to your `controlsOptions`

```dart
  progressSliderTheme: ModernPlayerProgressSliderTheme(
      activeSliderColor: Colors.blue,
      inactiveSliderColor: Colors.white70,
      bufferSliderColor: Colors.black54,
      thumbColor: Colors.white,
      progressTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.white,
          fontSize: 18))
```

## Example

Please run the app in the `example/` folder to start playing!

## Description for Developers (Contributors)

### 🚀 Join the modern_player Development Team!

Are you passionate about enhancing the video playback experience in Flutter apps? Do you have a knack for creating polished, feature-rich, and highly customizable UI components? If so, we'd love to welcome you to the modern_player project!

### What is modern_player?
modern_player is a Flutter package designed to take the flutter_vlc_player to the next level. We're on a mission to provide users with an exceptional video playback experience, and we believe in the power of open-source collaboration to make it happen.

### Why Contribute to modern_player?

* **Cutting-Edge Features:** We've already implemented a range of impressive features like auto-hiding controls, double-tap seeking, video quality adjustment, and more.

* **Cross-Platform Support:** Our package works seamlessly on both Android and iOS devices, making it accessible to a wide audience.

* **Customization:** We empower users with a fully customizable UI, allowing them to tailor the video playback interface to their liking.

### How Can You Contribute?

* **Feature Development:** Whether you have an idea for a new feature or want to improve an existing one, your contributions are highly valuable.

* **Bug Fixes:** Help us keep modern_player running smoothly by identifying and fixing issues.

* **Documentation:** Clear and concise documentation is key. Contribute to documentation efforts to make it easier for others to use modern_player.

* **Testing:** Rigorous testing is crucial. Help ensure that modern_player is reliable and bug-free by testing its functionalities.

* **Design & UI:** If you have a knack for UI/UX design, we welcome your ideas and design improvements.

### Get Started:
Join our development team, and let's collectively take modern_player to new heights. Whether you're an experienced developer or just getting started, there's a place for you in our community.

GitHub Repository: https://github.com/itsSagarBro/modern_player

**Together, we can create the ultimate Flutter video playback package. Join us on this exciting journey!**
