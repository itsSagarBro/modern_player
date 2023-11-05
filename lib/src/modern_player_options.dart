import 'package:flutter/material.dart';

/// List of video for Modern Player
///
/// This contains name and url of the video quality.
/// In name field you can add name of quality like Low/High.
/// In url field you can add url of the video and if your player is file then add path of video
class ModernPlayerQualityOptions {
  /// Name of quality, This will be displayed in video player quality selector menu.
  String name;

  /// Url or path of the video.
  String url;

  ModernPlayerQualityOptions({required this.name, required this.url});
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

  /// When enabled, Video player will automatically gets paused when it is not visible and play when its visible.
  bool controlVisibiltyPlay;

  /// Set start time of video in milliseconds
  int? videoStartAt;

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
      this.controlVisibiltyPlay = true,
      this.videoStartAt,
      this.customActionButtons});
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

  /// Control theme of progress slider theme.
  ModernPlayerProgressSliderTheme? progressSliderTheme;

  ModernPlayerThemeOptions(
      {this.backgroundColor,
      this.menuBackgroundColor,
      this.loadingColor,
      this.menuIcon,
      this.muteIcon,
      this.unmuteIcon,
      this.backIcon,
      this.progressSliderTheme});
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
