import 'package:flutter/material.dart';
import 'package:modern_player/src/modern_players_enums.dart';

/// [ModernPlayerVideo] has multiple type of player.
///
/// With [ModernPlayerVideo.single] you can create a singel video player.
///
/// With [ModernPlayerVideo.multiple] you can create a video player that contains multiple qualities and resolution.
///
/// With [ModernPlayerVideo.youtube] you can create a yotube video player with some extra features.
class ModernPlayerVideo {
  List<ModernPlayerVideoData> videosData = [];
  bool? fetchQualities;

  /// [ModernPlayerVideo.single] allow you to create a single video player, without any quality selection.
  ModernPlayerVideo.single(ModernPlayerVideoData videoData) {
    videosData = [videoData];
  }

  /// [ModernPlayerVideo.multiple] allow you to create video player with abilty to switch between
  /// diffrente qualities/resoltuion or video tracks.
  ModernPlayerVideo.multiple(this.videosData);

  /// [ModernPlayerVideo.youtube] allow you to create a video player with youtube video id.
  ///
  /// It has an additional feature [fetchQualities], which can get different video quality/resoltuion
  /// from youtube and allow user to switch between those.
  ModernPlayerVideo.youtube({required String id, this.fetchQualities}) {
    videosData = [ModernPlayerVideoData.youtube(label: "Default", id: id)];
  }
}

/// [ModernPlayerVideoData] is a list item of video for Modern Player
///
/// This contains name and url of the video.
/// In [label] field you can add name of quality like Low/High.
/// In [source] field you can add url of the video and if your player is file then add path of video
class ModernPlayerVideoData {
  /// Name of quality, This will be displayed in video player quality selector menu.
  String label = "";

  /// Url or path of the video.
  String source = "";

  /// This can define type of data source of Modern Player.
  ModernPlayerSourceType sourceType = ModernPlayerSourceType.asset;

  ///Constructs a [ModernPlayerVideoData] playing a video from obtained from the network.
  ///
  ///The URL for the video is given by the [url] argument and must not be null.
  ///And the [label] is displayed on quality selection on menu.
  ModernPlayerVideoData.network({required this.label, required String url}) {
    source = url;
    sourceType = ModernPlayerSourceType.network;
  }

  ///Constructs a [ModernPlayerVideoData] playing a video from obtained from the local file.
  ///
  ///The Path for the video is given by the [path] argument and must not be null.
  ///And the [label] is displayed on quality selection on menu.
  ModernPlayerVideoData.file({required this.label, required String path}) {
    source = path;
    sourceType = ModernPlayerSourceType.file;
  }

  ///Constructs a [ModernPlayerVideoData] playing a video from obtained from the youtube.
  ///
  ///The Id of the youtube video is given by the [id] argument and must not be null.
  ///And the [label] is displayed on quality selection on menu.
  ModernPlayerVideoData.youtube({required this.label, required String id}) {
    source = id;
    sourceType = ModernPlayerSourceType.youtube;
  }

  ///Constructs a [ModernPlayerVideoData] playing a video from obtained from the assets.
  ///
  ///The Path for the video is given by the [path] argument and must not be null.
  ///And the [label] is displayed on quality selection on menu.
  ModernPlayerVideoData.asset({required this.label, required String path}) {
    source = path;
    sourceType = ModernPlayerSourceType.asset;
  }
}

/// Modern Player Option gies some basic controls for video.
class ModernPlayerOptions {
  /// When enabled, Video player will automatically gets paused when it is not visible and play when its visible.
  bool autoVisibilityPause;

  /// Set start time of video in milliseconds
  int? videoStartAt;

  ModernPlayerOptions({
    this.autoVisibilityPause = true,
    this.videoStartAt,
  });
}

/// Controls option for Modern Player
///
/// With this option you can customize controls of your player. Like showing or hiding specific button or changing colors etc.
class ModernPlayerControlsOptions {
  /// Toggle controls overlay visibilty.
  bool showControls;

  /// Toggle mute button visibilty.
  bool showMute;

  /// Toggle menu button visibilty.
  bool showMenu;

  /// Toggle bottom progress bar visibilty.
  bool showBottomBar;

  /// Toggle back button visibilty.
  bool showBackbutton;

  /// Toggle slide to control volume.
  bool enableVolumeSlider;

  /// Toggle slide to control brigthness.
  bool enableBrightnessSlider;

  /// Toggle double tap to seek.
  bool doubleTapToSeek;

  /// Time for auto hiding controls
  Duration? autoHideTime;

  /// With custom action button you can create your own button an get a callback on pressed, double tap, and long press.
  List<ModernPlayerCustomActionButton>? customActionButtons;

  ModernPlayerControlsOptions(
      {this.showControls = true,
      this.showMenu = true,
      this.showMute = true,
      this.showBackbutton = true,
      this.showBottomBar = true,
      this.enableVolumeSlider = true,
      this.enableBrightnessSlider = true,
      this.doubleTapToSeek = true,
      this.customActionButtons,
      this.autoHideTime});
}

/// Theme option for Modern Player
///
/// With theme option, you can change color of specific widget and change icon of buttons.
class ModernPlayerThemeOptions {
  /// Background color of icons and bottom bar.
  Color? backgroundColor;

  /// Background color of menu.
  Color? menuBackgroundColor;

  /// Color of loading circle.
  Color? loadingColor;

  /// Icon for menu button.
  Icon? menuIcon;

  /// Icon for mute button.
  Icon? muteIcon;

  /// Icon for unmute button.
  Icon? unmuteIcon;

  /// Icon for back button.
  Icon? backIcon;

  /// Customize theme of progress slider theme.
  ModernPlayerProgressSliderTheme? progressSliderTheme;

  /// Customize theme of brightness slider.
  ModernPlayerToastSliderThemeOption? brightnessSlidertheme;

  /// Customize theme of volume slider.
  ModernPlayerToastSliderThemeOption? volumeSlidertheme;

  ModernPlayerThemeOptions(
      {this.backgroundColor,
      this.menuBackgroundColor,
      this.loadingColor,
      this.menuIcon,
      this.muteIcon,
      this.unmuteIcon,
      this.backIcon,
      this.progressSliderTheme,
      this.brightnessSlidertheme,
      this.volumeSlidertheme});
}

/// Proggress slider theme option for Modern Player
///
/// With proggress slider theme option, you can change color of specific progress slider and change style of text.
class ModernPlayerProgressSliderTheme {
  /// Set color for played part of video.
  Color? activeSliderColor;

  /// Set color of slider.
  Color? inactiveSliderColor;

  /// Set color for loaded part of video.
  Color? bufferSliderColor;

  /// Set color for thumb of slider.
  Color? thumbColor;

  /// Text style for progress text.
  TextStyle? progressTextStyle;

  ModernPlayerProgressSliderTheme(
      {this.activeSliderColor,
      this.inactiveSliderColor,
      this.bufferSliderColor,
      this.thumbColor,
      this.progressTextStyle});
}

/// Toast slider theme option for Modern Player
///
/// With toast slider theme option, you can customize brightness and volume slider in player.
class ModernPlayerToastSliderThemeOption {
  /// Give slider color.
  Color sliderColor;

  /// Give slider color.
  Color? iconColor;

  /// Give toast background color.
  Color? backgroundColor;

  /// This icon active when slider value is 0%.
  IconData? unfilledIcon;

  /// This icon active when slider value is 50%.
  IconData? halfFilledIcon;

  /// This icon active when slider value is 1000%.
  IconData? filledIcon;

  ModernPlayerToastSliderThemeOption(
      {required this.sliderColor,
      this.iconColor,
      this.backgroundColor,
      this.unfilledIcon,
      this.halfFilledIcon,
      this.filledIcon});
}

/// Custom action button for Modern Player
///
/// With custom action button you can create your own button an get a callback on pressed, double tap, and long press.
class ModernPlayerCustomActionButton {
  /// This icon used for action button icon.
  Icon icon;

  /// You received a callback whenever user press this button.
  VoidCallback? onPressed;

  /// You received a callback whenever user double tap on this button.
  VoidCallback? onLongPress;

  /// You received a callback whenever user long press this button.
  VoidCallback? onDoubleTap;

  ModernPlayerCustomActionButton(
      {required this.icon, this.onPressed, this.onDoubleTap, this.onLongPress});
}

/// Subtitle Option for Modern Player
///
/// With subtitle option you can add subtitle in video from other sources.
class ModernPlayerSubtitleOptions {
  /// Url or Path for subtitle source
  String source;

  /// Source type for loading subtitle.
  ///
  /// [sourceType.network] is load subtitle from internet.
  ///
  /// [sourceType.file] is load subtitle from local file.
  ModernPlayerSubtitleSourceType sourceType;

  /// When enables, it gets selected when added
  bool? isSelected;

  ModernPlayerSubtitleOptions(
      {required this.source, required this.sourceType, this.isSelected});
}

/// Audio Option for Modern Player
///
/// With audio option you can add audio in video from other sources.
class ModernPlayerAudioTrackOptions {
  /// Url or Path for audio source
  String source;

  /// Source type for loading audio.
  ///
  /// [sourceType.network] is load audio from internet.
  ///
  /// [sourceType.file] is load audio from local file.
  ModernPlayerAudioSourceType sourceType;

  /// When enables, it gets selected when added
  bool? isSelected;

  ModernPlayerAudioTrackOptions(
      {required this.source, required this.sourceType, this.isSelected});
}
