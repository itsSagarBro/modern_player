# ModernPlayer v2 (see addons below)

Enhance your video playback experience with modern_player—a feature-rich Flutter package for flutter_vlc_player. Enjoy auto-hiding controls, double-tap to seek, customizable UI, automatic subtitle and audio track detection, and more on both Android and iOS.

[![Pub Version](https://img.shields.io/pub/v/modern_player)](https://pub.dev/packages/modern_player/versions)
[![License](https://img.shields.io/github/license/ItsSagarBro/modern_player)](https://pub.dev/packages/modern_player/license)
![Lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)
[![Generic badge](https://img.shields.io/badge/platform-android%20|%20ios%20-blue.svg)](https://pub.dev/packages/modern_player)

## Features

Introducing modern_player, the ultimate Flutter package designed to elevate your video playback experience with flutter_vlc_player. This feature-packed solution offers a seamless and engaging video playback interface with the following key features:

- **Auto Hide Controls:** Say goodbye to cluttered screens with auto-hiding controls that ensure an immersive viewing experience.

- **Double Tap to Seek:** Effortlessly seek through your video content by double-tapping on the screen.

- **Change Video Quality:** Switch between video quality options to ensure the best playback experience.

- **Auto-Detect Video Subtitles and Audio Tracks:** modern_player automatically detects and offers options for video subtitles and audio tracks.

- **Fully Customizable UI:** Tailor the user interface to your liking, giving you full control over the look and feel.

- **Brightness Control:** Slide left to adjust brightness on the fly for a comfortable viewing experience.

- **Volume Control:** Slide vertically on the right side to fine-tune the audio volume to your preference.

- **Video Start At:** You can now specify where the video starts with the `videoStartAt` option.

- **Playback Speed Controls:** Adjust playback speed to your preference with the new controls.

- **Custom Action Button Support:** Customize your controls with your own action buttons.

- **Manual Subtitle Support:** Manually add subtitles to your videos.

- **Manual Audio Tracks Support:** Handpick and manage audio tracks to suit your preferences.

- **YouTube Video Streaming:** You can now effortlessly stream YouTube videos by providing the video ID. Enjoy your favorite YouTube content right within your app!

- **Quality Selection for YouTube Videos:** Choose the video quality that suits your preference.

- **Translation Feature:** Menu items can now be translated to suit a broader audience.

- **Toggle Screen Sleep:** ModernPlayerOptions now include an option to toggle screen sleep.

- **Cross-Platform Support:** Enjoy modern_player's features on both Android and iOS devices.

- **FullScreen Support** Added in V2 the support for fullscreen.

- **getCurrentPosition Feature** Allows to continue playing for current position without restarting the playback.

With modern_player, you can provide a top-notch video playback experience to your users, complete with an intuitive and fully customizable interface. Say goodbye to mundane video controls and give your app an edge with modern_player.

## To-do

- Callback options
- Picture-in-picture mode
- Video Cast/Screen Mirroring (Chromecast)
- Support for fullscreen
- Custom ErrorBuilder
- Placeholder Widget
- Loop Support
- HLS & DASH resolution selection support
- Get subtitles from youtube player
- Making `modern_player` bug free and stable

## Installation

In your pubspec.yaml file within your Flutter Project add modern_player under dependencies:

```yaml
dependencies:
  modern_player: <latest_version>
```

## Instalation from flutter_vlc_player

### iOS

If you're unable to view media loaded from an external source, you should also add the following:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

For more information, or for more granular control over your App Transport Security (ATS) restrictions, you should
[read Apple's documentation](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/nsallowsarbitraryloads).

Make sure that following line in `<project root>/ios/Podfile` uncommented:

`platform :ios, '9.0'`

> NOTE: While the Flutter `video_player` is not functional on iOS Simulators, this package (`flutter_vlc_player`) **is**
> fully functional on iOS simulators.

To enable vlc cast functionality for external displays (chromecast), you should also add the following:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Used to search for chromecast devices</string>
<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
</array>
```

<hr>

### Android

To load media/subitle from an internet source, your app will need the `INTERNET` permission.  
This is done by ensuring your `<project root>/android/app/src/main/AndroidManifest.xml` file contains a `uses-permission`
declaration for `android.permission.INTERNET`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

As Flutter includes this permission by default, the permission is likely already declared in the file.

Note that if you got "Cleartext HTTP traffic to \* is not permitted"
you need to add the `android:usesClearTextTraffic="true"` flag in the AndroidManifest.xml file, or define a new "Network Security Configuration" file. For more information, check https://developer.android.com/training/articles/security-config

<br>

In order to load media/subtitle from internal device storage, you should put the storage permissions as follows:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

In some cases you also need to add the `android:requestLegacyExternalStorage="true"` flag to the Application tag in AndroidManifest.xml file.

After that you can access the media/subtitle file by

    "/storage/emulated/0/{FilePath}"
    "/sdcard/{FilePath}"

<hr>

#### Android build configuration

1. In `android/app/build.gradle`:

```groovy
android {
    packagingOptions {
       // Fixes duplicate libraries build issue,
       // when your project uses more than one plugin that depend on C++ libs.
        pickFirst 'lib/**/libc++_shared.so'
    }

   buildTypes {
      release {
         minifyEnabled true
         proguardFiles getDefaultProguardFile(
                 'proguard-android-optimize.txt'),
                 'proguard-rules.pro'
      }
   }
}
```

2. Create `android/app/proguard-rules.pro`, add the following lines:

```proguard
-keep class org.videolan.libvlc.** { *; }
```

<hr>

#### Android multi-window support

To enable multi-window support in your Android application, you need to make changes to `AndroidManifest.xml`, add the `android:resizeableActivity` key for the main activity, as well as the `android.allow_multiple_resumed_activities` metadata for application:

```xml
<manifest ...>
  <application ...>
    <activity ...
      android:resizeableActivity="true">
      ...
    </activity>
    ...
    <meta-data
      android:name="android.allow_multiple_resumed_activities"
      android:value="true" />
  </application>
</manifest>
```

## Using it

### With single video

```dart
import 'package:modern_player/modern_player.dart';

final modernPlayerWidget = SizedBox(
    height: 200,
    child: ModernPlayer.createPlayer(
      video: ModernPlayerVideo.single(ModernPlayerVideoData.network(
          label: "Default",
          url:
              "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"))),
  );
```

### With youtube video

```dart
import 'package:modern_player/modern_player.dart';

final modernPlayerWidget = SizedBox(
    height: 200,
    child: ModernPlayer.createPlayer(
      video:
          ModernPlayerVideo.youtubeWithId(id: 'EiiOYwqk3A0', fetchQualities: true)),
  );
```

### With multiple resolution/qualities video

```dart
import 'package:modern_player/modern_player.dart';

final modernPlayerWidget = SizedBox(
    height: 200,
    child: ModernPlayer.createPlayer(
      video: ModernPlayerVideo.multiple([
        ModernPlayerVideoData.network(
            label: "480p",
            url:
                "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"),
        ModernPlayerVideoData.network(
            label: "720p",
            url:
                "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4")
      ])),
  );
```

## Options

modern_player has some basic option to adjust video player.

To add options, you can add these lines to your [`modernPlayer`](#using-it)

```dart
  options: ModernPlayerOptions(
      controlVisibiltyPlay: true,
      videoStartAt: 5000 // in milliseconds
      allowScreenSleep: false
    )
```

### Controls Options

modern_player has some option to adjust and theme your controls. By default all button and features are enabled.

To enable disable button, you can add these lines to your [`modernPlayer`](#using-it)

```dart
  controlsOptions: ModernPlayerControlsOptions(
      showControls: true,
      doubleTapToSeek: true,
      showMenu: true,
      showMute: false,
      showBackbutton: false,
      enableVolumeSlider: true,
      enableBrightnessSlider: true,
      showBottomBar: true,)
```

### Custom Action Buttons

Empower your app's users with modern_player's customizable action buttons. Add custom buttons to control, navigate, or interact with your video content, and define the callbacks to handle these actions, offering a truly tailored video experience.

To add custom buttons, you can add these lines to your [`controlsOptions`](#controls-options)

```dart
  customActionButtons: [
      ModernPlayerCustomActionButton(
        icon: const Icon(
          Icons.info_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          // On Pressed
        },
      ),
    ]
```

### Theme Customization

Tailor your video playback experience to match your app's unique style with modern_player. Customize the theme of your controls, choosing colors, fonts, and layouts that seamlessly integrate with your app's design for a polished, cohesive look.

To customize theme or colors of your player, you can add these lines to your [`modernPlayer`](#using-it)

```dart
  themeOptions: ModernPlayerThemeOptions(
      backgroundColor: Colors.black,
      menuBackgroundColor: Colors.black,
      loadingColor: Colors.blue,
      menuIcon: const Icon(
        Icons.settings,
        color: Colors.white,
      ),
      volumeSlidertheme: ModernPlayerToastSliderThemeOption(
          sliderColor: Colors.blue, iconColor: Colors.white))
```

To customize theme of progress slider, you can add these lines to your [`controlsOptions`](#controls-options)

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

## Subtitles

modern_player simplifies your video viewing experience with auto-detected subtitles for supported formats. And for other formats, easily add subtitles from the internet or local files, ensuring that nothing gets lost in translation.

To add subtitles, you can add these lines to your [`modernPlayer`](#using-it)

```dart
  // For add subtitle from internet.
  subtitles: [
    ModernPlayerSubtitleOptions(
        source:
            "url_of_subtitle",
        sourceType: ModernPlayerSubtitleSourceType.network)
  ]

  // For add subtitle from local file.
  subtitles: [
    ModernPlayerSubtitleOptions(
        source:
            "path_of_subtitle",
        sourceType: ModernPlayerSubtitleSourceType.file)
  ]
```

## Audio Tracks

With modern_player, you're in control of your audio experience. Add custom audio tracks to your videos, switch between languages or audio sources on the fly, and enjoy a personalized listening experience like never before.

To add audio tracks, you can add these lines to your [`modernPlayer`](#using-it)

```dart
  // For add audio track from internet.
  audioTracks: [
    ModernPlayerAudioTrackOptions(
        source:
            "url_of_audio_track",
        sourceType: ModernPlayerAudioSourceType.network)
  ]

  // For add audio track from local file.
  audioTracks: [
    ModernPlayerAudioTrackOptions(
        source:
            "path_of_audio_track",
        sourceType: ModernPlayerAudioSourceType.file)
  ]
```

## Example

Please run the app in the `example/` folder to start playing!

## Description for Developers (Contributors)

### 🚀 Join the modern_player Development Team!

Are you passionate about enhancing the video playback experience in Flutter apps? Do you have a knack for creating polished, feature-rich, and highly customizable UI components? If so, we'd love to welcome you to the modern_player project!

### What is modern_player?

modern_player is a Flutter package designed to take the flutter_vlc_player to the next level. We're on a mission to provide users with an exceptional video playback experience, and we believe in the power of open-source collaboration to make it happen.

### Why Contribute to modern_player?

- **Cutting-Edge Features:** We've already implemented a range of impressive features like auto-hiding controls, double-tap seeking, video quality adjustment, and more.

- **Cross-Platform Support:** Our package works seamlessly on both Android and iOS devices, making it accessible to a wide audience.

- **Customization:** We empower users with a fully customizable UI, allowing them to tailor the video playback interface to their liking.

### How Can You Contribute?

- **Feature Development:** Whether you have an idea for a new feature or want to improve an existing one, your contributions are highly valuable.

- **Bug Fixes:** Help us keep modern_player running smoothly by identifying and fixing issues.

- **Documentation:** Clear and concise documentation is key. Contribute to documentation efforts to make it easier for others to use modern_player.

- **Testing:** Rigorous testing is crucial. Help ensure that modern_player is reliable and bug-free by testing its functionalities.

- **Design & UI:** If you have a knack for UI/UX design, we welcome your ideas and design improvements.

### Get Started:

Join our development team, and let's collectively take modern_player to new heights. Whether you're an experienced developer or just getting started, there's a place for you in our community.

GitHub Repository: https://github.com/itsSagarBro/modern_player

**Together, we can create the ultimate Flutter video playback package. Join us on this exciting journey!**

## Buy Me a Coffee

<a href="https://www.buymeacoffee.com/itssagarbro" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-yellow.png" alt="Buy Me A Coffee" height="41" width="174"></a>
