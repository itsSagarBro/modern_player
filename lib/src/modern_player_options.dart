import 'package:flutter/material.dart';
import 'package:modern_player/src/others/modern_players_enums.dart';

/// [ModernPlayerVideo] has multiple type of player.
/// Enhance your video playback experience with modern_player.
/// A feature-rich Flutter package for flutter_vlc_player.
///
/// With [ModernPlayerVideo.single] you can create a singel video player.
///
/// Example usage:
/// ```dart
/// child: ModernPlayer.createPlayer(
///   video: ModernPlayerVideo.single(
///       source: source,
///       sourceType: ModernPlayerSourceType.youtube),
/// )
/// ```
///
/// With [ModernPlayerVideo.multiple] you can create a video player that contains multiple qualities and resolution.
///
/// Example usage:
/// ```dart
/// child: ModernPlayer.createPlayer(
///   video: ModernPlayerVideo.multiple([
///     ModernPlayerVideoData.network(label: label, url: url),
///     ModernPlayerVideoData.network(label: label, url: url),
///   ]),
/// )
/// ```
///
/// With [ModernPlayerVideo.youtubeWithUrl] you can create a yotube video player using video url with some extra and exclusive features.
///
/// Example usage:
/// ```dart
/// child: ModernPlayer.createPlayer(
///   video: ModernPlayerVideo.youtubeWithId(id: id),
/// )
/// ```
///
/// With [ModernPlayerVideo.youtubeWithId] you can create a yotube video player using video id with some extra and exclusive features.
///
/// Example usage:
/// ```dart
/// child: ModernPlayer.createPlayer(
///   video: ModernPlayerVideo.youtubeWithUrl(
///       url: url, fetchQualities: true),
/// )
/// ```
class ModernPlayerVideo {
  List<ModernPlayerVideoData> videosData = [];
  bool? fetchQualities;

  /// [ModernPlayerVideo.single] allow you to create a single video player, without any quality selection.
  ///
  /// Example usage:
  /// ```dart
  /// child: ModernPlayer.createPlayer(
  ///   video: ModernPlayerVideo.single(
  ///       source: source,
  ///       sourceType: ModernPlayerSourceType.youtube),
  /// )
  /// ```
  ModernPlayerVideo.single(
      {required String source, required ModernPlayerSourceType sourceType}) {
    late ModernPlayerVideoData videoData;

    switch (sourceType) {
      case ModernPlayerSourceType.file:
        videoData = ModernPlayerVideoData.file(label: 'Default', path: source);
        break;
      case ModernPlayerSourceType.asset:
        videoData = ModernPlayerVideoData.asset(label: 'Default', path: source);
        break;
      case ModernPlayerSourceType.youtube:
        videoData = source.contains('https') || source.contains('youtube')
            ? ModernPlayerVideoData.youtubeWithUrl(
                label: 'Default',
                url: source,
              )
            : ModernPlayerVideoData.youtubeWithId(
                label: 'Default',
                id: source,
              );
        break;
      default:
        videoData =
            ModernPlayerVideoData.network(label: 'Default', url: source);
        break;
    }

    videosData = [videoData];
  }

  /// [ModernPlayerVideo.multiple] allow you to create video player with abilty to switch between
  /// diffrente qualities/resoltuion or video tracks.
  ModernPlayerVideo.multiple(this.videosData);

  /// [ModernPlayerVideo.youtubeWithUrl] allow you to create a video player with youtube video url.
  ///
  /// It has an additional feature [fetchQualities], which can get different video quality/resoltuion
  /// from youtube and allow user to switch between those.
  ModernPlayerVideo.youtubeWithId({required String id, this.fetchQualities}) {
    videosData = [
      ModernPlayerVideoData.youtubeWithId(label: "Default", id: id)
    ];
  }

  /// [ModernPlayerVideo.youtubeWithUrl] allow you to create a video player with youtube video url.
  ///
  /// It has an additional feature [fetchQualities], which can get different video quality/resoltuion
  /// from youtube and allow user to switch between those.
  ModernPlayerVideo.youtubeWithUrl({required String url, this.fetchQualities}) {
    videosData = [
      ModernPlayerVideoData.youtubeWithUrl(label: "Default", url: url)
    ];
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
  ///The URL for the video is given by the [url] argument and must not be null
  ///and the [label] is displayed on quality selection on menu.
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
  ///The url of the youtube video is given by the [url] argument and must not be null.
  ///And the [label] is displayed on quality selection on menu.
  ModernPlayerVideoData.youtubeWithUrl(
      {required this.label, required String url}) {
    String? videoId = _youtubeParser(url);

    if (videoId == null) {
      throw Exception("Cannot get video from url. Please try with ID");
    }

    source = videoId;
    sourceType = ModernPlayerSourceType.youtube;
  }

  ///Constructs a [ModernPlayerVideoData] playing a video from obtained from the youtube.
  ///
  ///The Id of the youtube video is given by the [id] argument and must not be null.
  ///And the [label] is displayed on quality selection on menu.
  ModernPlayerVideoData.youtubeWithId(
      {required this.label, required String id}) {
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

  // Get youtube video id from url
  String? _youtubeParser(String url) {
    final regExp = RegExp(
        r'^.*((youtu.be/)|(v/)|(\/u/\w/)|(embed/)|(watch\?))\??v?=?([^#&?]*).*');
    final match = regExp.firstMatch(url);
    return (match != null && match.group(7)!.length == 11)
        ? match.group(7)
        : null;
  }
}

/// ModernPlayerVideoDataYoutube is an internal class which used for accessing all qualities of video from youtube and merging an audio
class ModernPlayerVideoDataYoutube extends ModernPlayerVideoData {
  /// Url of audio for override [For youtube obly]
  String? audioOverride;

  ModernPlayerVideoDataYoutube.network(
      {required super.label, required super.url, required this.audioOverride})
      : super.network();
}

/// Modern Player Option gies some basic controls for video.
class ModernPlayerOptions {
  /// When enabled, Video player will automatically gets paused when it is not visible and play when its visible.
  bool autoVisibilityPause;

  /// Set start time of video in milliseconds
  int? videoStartAt;

  /// When enabled, screen can go on sleep during the video is playing
  bool? allowScreenSleep;

  ModernPlayerOptions(
      {this.autoVisibilityPause = true,
      this.videoStartAt,
      this.allowScreenSleep});
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

  /// This widget replace default ModernPlayer loading widget.
  Widget? customLoadingWidget;

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
      this.customLoadingWidget,
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

/// The top level type which defines the strategies for selecting tracks
sealed class DefaultSelector {}

/// Will default to disabling this track
class DefaultSelectorOff extends DefaultSelector {}

/// Provide custom logic for selecting a track
/// It will pick the first track that returns true
class DefaultSelectorCustom extends DefaultSelector {
  final bool Function(int index, String label) shouldUseTrack;

  DefaultSelectorCustom(this.shouldUseTrack);
}

/// A [DefaultSelectorCustom] that gets initialized with a string
/// and selects the first track with a label that contains the string.
///
/// Example usage:
/// ```dart
/// defaultSubtitleSelectors: [
///       // Matches "English", "english", "ENG", "eng", etc.
///       DefaultSelectorLabel("Eng"),
///       // Falls back to [DefaultSelectorOff] if no other track matches
///       DefaultSelectorOff(),
///     ],
/// ```
class DefaultSelectorLabel extends DefaultSelectorCustom {
  DefaultSelectorLabel(String labelSubstring)
      : super((index, label) =>
            label.toLowerCase().contains(labelSubstring.toLowerCase()));
}

/// [ModernPlayerDefaultSelectionOptions] provides you ability to select default subtitle, audio and video quality.
class ModernPlayerDefaultSelectionOptions {
  List<DefaultSelector>? defaultSubtitleSelectors;
  List<DefaultSelector>? defaultAudioSelectors;
  List<DefaultSelector>? defaultQualitySelectors;

  ModernPlayerDefaultSelectionOptions(
      {this.defaultSubtitleSelectors,
      this.defaultAudioSelectors,
      this.defaultQualitySelectors});
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

/// Translation Option for Modern Player
///
/// With [ModernPlayerTranslationOptions] option you can give translated text or custom to menu item.
class ModernPlayerTranslationOptions {
  /// [qualityHeaderText] displayed on menu quality section in left side.
  String? qualityHeaderText;

  /// [playbackSpeedText] displayed on menu playback speed section in left side.
  String? playbackSpeedText;

  /// [defaultPlaybackSpeedText] displayed on 1x playback speed.
  String? defaultPlaybackSpeedText;

  /// [subtitleText] displayed on menu subtitle section in left side.
  String? subtitleText;

  /// [noneSubtitleText] displayed user seleted none.
  String? noneSubtitleText;

  /// [unavailableSubtitleText] displayed when subtitle in unavailabel.
  String? unavailableSubtitleText;

  /// [audioHeaderText] displayed on menu audio text in left side.
  String? audioHeaderText;

  /// [loadingAudioText] displayed when subtitle in unavailabel.
  String? loadingAudioText;

  /// [unavailableAudioText] displayed when subtitle in unavailabel.
  String? unavailableAudioText;

  /// [defaultAudioText] displayed on default selected audio text.
  String? defaultAudioText;

  ModernPlayerTranslationOptions.menu(
      {this.qualityHeaderText,
      this.playbackSpeedText,
      this.defaultPlaybackSpeedText,
      this.subtitleText,
      this.unavailableSubtitleText,
      this.audioHeaderText,
      this.loadingAudioText,
      this.defaultAudioText,
      this.unavailableAudioText});
}

/// Callbacks Option for Modern Player
///
/// With [ModernPlayerCallbackOptions] option you can perform custom fuction on callback.
class ModernPlayerCallbackOptions {
  /// [onPlay] calls when video state changed from pause to play.
  Function? onPlay;

  /// [onPause] calls when video state changed from play to pause.
  Function? onPause;

  /// [onSeek] calls when user seek the video.
  /// It also has [int] which return where the video is seeked in milliseconds.
  Function(int milliseconds)? onSeek;

  /// [onSeekForward] calls when user seek the video forward (10 sec).
  Function? onSeekForward;

  /// [onSeekBackward] calls when user seek the video backward (10 sec).
  Function? onSeekBackward;

  /// [onChangedQuality] calls when user changed the quality of video.
  Function(String title, String source)? onChangedQuality;

  /// [onChangedSubtitle] calls when user changed the subtitle track.
  Function(int selectedSubtitle)? onChangedSubtitle;

  /// [onChangedAudio] calls when user changed the audio track.
  Function(int selectedAudio)? onChangedAudio;

  /// [onChangedPlaybackSpeed] calls when user changed the playback speed.
  /// It also has [double] which return where selected speed.
  Function(double selectedSpeed)? onChangedPlaybackSpeed;

  /// [onBackPressed] calls when user clicked back button.
  Function? onBackPressed;

  /// [onMenuPressed] calls when user clicked menu button.
  Function? onMenuPressed;

  /// [onMutePressed] calls when user clicked mute button.
  Function? onMutePressed;

  ModernPlayerCallbackOptions(
      {this.onPlay,
      this.onPause,
      this.onSeek,
      this.onSeekForward,
      this.onSeekBackward,
      this.onChangedQuality,
      this.onChangedSubtitle,
      this.onChangedAudio,
      this.onChangedPlaybackSpeed,
      this.onBackPressed,
      this.onMenuPressed,
      this.onMutePressed});
}
