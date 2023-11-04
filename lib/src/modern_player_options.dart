import 'package:flutter/material.dart';

class ModernPlayerQualityOptions {
  String name;
  String url;

  ModernPlayerQualityOptions({required this.name, required this.url});
}

class ModernPlayerControlsOptions {
  bool showControls;
  bool showFloating;
  bool showMute;
  bool showMenu;
  bool showBottomBar;
  bool showBackbutton;
  bool enableVolumeSlider;
  bool enableBrigthnessSlider;
  bool doubleTapToSeek;
  ModernPlayerThemeOptions? themeOptions;
  ModernPlayerProgressSliderTheme? progressSliderTheme;

  ModernPlayerControlsOptions(
      {this.showControls = true,
      this.showMenu = true,
      this.showMute = true,
      this.showFloating = true,
      this.showBackbutton = true,
      this.showBottomBar = true,
      this.enableVolumeSlider = true,
      this.enableBrigthnessSlider = true,
      this.doubleTapToSeek = true,
      this.themeOptions,
      this.progressSliderTheme});
}

class ModernPlayerThemeOptions {
  Color? backgroundColor;
  Color? menuBackgroundColor;
  Color? loadingColor;
  Icon? menuIcon;
  Icon? floatingIcon;
  Icon? muteIcon;
  Icon? unmuteIcon;
  Icon? backIcon;

  ModernPlayerThemeOptions(
      {this.backgroundColor,
      this.menuBackgroundColor,
      this.loadingColor,
      this.menuIcon,
      this.floatingIcon,
      this.muteIcon,
      this.unmuteIcon,
      this.backIcon});
}

class ModernPlayerProgressSliderTheme {
  Color? textColor;
  Color? activeSliderColor;
  Color? inactiveSliderColor;
  Color? bufferSliderColor;
  Color? thumbColor;

  ModernPlayerProgressSliderTheme(
      {this.textColor,
      this.activeSliderColor,
      this.inactiveSliderColor,
      this.bufferSliderColor,
      this.thumbColor});
}
