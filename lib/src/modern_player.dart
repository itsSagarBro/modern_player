import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:modern_player/src/modern_player_controls.dart';
import 'package:modern_player/src/modern_player_options.dart';
import 'package:modern_player/src/others/modern_players_enums.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Modern Player gives you a controller for flutter_vlc_player.
///
/// For displaying the video in Flutter, You can create video player widget by calling [createPlayer].
///
/// To customize video player controls or theme you can add [controlsOptions] and [themeOptions]
/// when calling [createPlayer]
class ModernPlayer extends StatefulWidget {
  const ModernPlayer._(
      {super.key,
      required this.video,
      required this.subtitles,
      required this.audioTracks,
      this.defaultSelectionOptions,
      this.options,
      this.controlsOptions,
      this.themeOptions,
      this.translationOptions,
      this.callbackOptions});

  /// Video quality options for multiple qualities. If you have only one quality video just add one in list.
  final ModernPlayerVideo video;

  /// Modern player can detect subtitle from the video on supported formats like .mkv.
  ///
  /// But if you wish to add subtitle from [file] or [network], you can use this [subtitles].
  final List<ModernPlayerSubtitleOptions> subtitles;

  /// If you wish to add audio from [file] or [network], you can use this [audioTracks].
  final List<ModernPlayerAudioTrackOptions> audioTracks;

  /// Default selection options for subtitles and audio tracks.
  final ModernPlayerDefaultSelectionOptions? defaultSelectionOptions;

  // Modern player options gives you some basic controls for video
  final ModernPlayerOptions? options;

  /// Modern player controls option.
  final ModernPlayerControlsOptions? controlsOptions;

  /// Control theme of controls.
  final ModernPlayerThemeOptions? themeOptions;

  /// With [translationOptions] option you can give translated text or custom to menu item.
  final ModernPlayerTranslationOptions? translationOptions;

  /// With [callbackOptions] option you can perform custom actions on callback.
  final ModernPlayerCallbackOptions? callbackOptions;

  /// Global key for accessing the player state
  static final GlobalKey<ModernPlayerState> _playerKey = GlobalKey<ModernPlayerState>();

  static ModernPlayer createPlayer(
      {required ModernPlayerVideo video,
      List<ModernPlayerSubtitleOptions>? subtitles,
      List<ModernPlayerAudioTrackOptions>? audioTracks,
      ModernPlayerDefaultSelectionOptions? defaultSelectionOptions,
      ModernPlayerOptions? options,
      ModernPlayerControlsOptions? controlsOptions,
      ModernPlayerThemeOptions? themeOptions,
      ModernPlayerTranslationOptions? translationOptions,
      ModernPlayerCallbackOptions? callbackOptions}) {
    return ModernPlayer._(
      key: _playerKey,
      video: video,
      subtitles: subtitles ?? [],
      audioTracks: audioTracks ?? [],
      options: options,
      controlsOptions: controlsOptions,
      defaultSelectionOptions: defaultSelectionOptions,
      themeOptions: themeOptions,
      translationOptions: translationOptions,
      callbackOptions: callbackOptions,
    );
  }

  /// Get the current playing position in milliseconds
  int getCurrentPosition() {
    return _playerKey.currentState?.getCurrentPosition() ?? 0;
  }

  @override
  State<ModernPlayer> createState() => ModernPlayerState();
}

class ModernPlayerState extends State<ModernPlayer> {
  late VlcPlayerController _playerController;
  bool _isControllerInitialized = false;

  bool isDisposed = false;
  bool canDisplayVideo = false;
  bool _isFullscreen = false;

  double visibilityFraction = 1;
  String? youtubeId;

  late ModernPlayerVideoData selectedQuality;

  List<ModernPlayerVideoData> videosData = List.empty(growable: true);

  @override
  void initState() {
    super.initState();

    if (widget.options?.allowScreenSleep ?? false == false) {
      WakelockPlus.enable();
    }

    videosData = widget.video.videosData;
    _setPlayer();

    // Listen to orientation changes if auto-fullscreen is enabled
    if (widget.controlsOptions?.enableAutoFullscreen ?? true) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _setPlayer() async {
    ModernPlayerVideoData defaultSource = videosData.length > 1
        ? _getDefaultTrackSource(
                selectors:
                    widget.defaultSelectionOptions?.defaultQualitySelectors,
                trackEntries: videosData) ??
            videosData.first
        : videosData.first;

    selectedQuality = defaultSource;

    try {
    // Network
    if (defaultSource.sourceType == ModernPlayerSourceType.network) {
      _playerController = VlcPlayerController.network(defaultSource.source,
          autoPlay: true,
          autoInitialize: true,
          hwAcc: HwAcc.auto,
          options: VlcPlayerOptions(
            subtitle: VlcSubtitleOptions(
                [VlcSubtitleOptions.color(VlcSubtitleColor.white)]),
          ));
    }
    // File
    else if (defaultSource.sourceType == ModernPlayerSourceType.file) {
      _playerController = VlcPlayerController.file(File(defaultSource.source),
          autoPlay: true, autoInitialize: true, hwAcc: HwAcc.auto);
    }
    // Youtube
    else if (defaultSource.sourceType == ModernPlayerSourceType.youtube) {
      var yt = YoutubeExplode();
      youtubeId = defaultSource.source;
      StreamManifest manifest =
          await yt.videos.streamsClient.getManifest(youtubeId);

      if (widget.video.fetchQualities ?? false) {
        List<ModernPlayerVideoData> ytVideos = List.empty(growable: true);

        for (var element in manifest.videoOnly) {
          ModernPlayerVideoData videoData =
              ModernPlayerVideoDataYoutube.network(
                  label: element.qualityLabel,
                  url: element.url.toString(),
                  audioOverride:
                      manifest.audioOnly.withHighestBitrate().url.toString());

          if (ytVideos
              .where((element) => element.label == videoData.label)
              .isEmpty) {
            ytVideos.insert(0, videoData);
          }
        }

        videosData = ytVideos;

        widget.audioTracks.add(ModernPlayerAudioTrackOptions(
            source: manifest.audioOnly.withHighestBitrate().url.toString(),
            sourceType: ModernPlayerAudioSourceType.network));

        ModernPlayerVideoData? defaultSourceYt = _getDefaultTrackSource(
            selectors: widget.defaultSelectionOptions?.defaultQualitySelectors,
            trackEntries: ytVideos);

        selectedQuality = defaultSourceYt ?? defaultSource;

        _playerController = VlcPlayerController.network(
            defaultSourceYt?.source ?? ytVideos.first.source,
            autoPlay: true,
            autoInitialize: true,
            hwAcc: HwAcc.auto);
      } else {
        _playerController = VlcPlayerController.network(
            manifest.muxed.withHighestBitrate().url.toString(),
            autoPlay: true,
            autoInitialize: true,
            hwAcc: HwAcc.auto);
      }

      yt.close();
    }
    // Asset
    else {
      _playerController = VlcPlayerController.asset(defaultSource.source,
          autoPlay: true, autoInitialize: true, hwAcc: HwAcc.full);
    }

    _playerController.addOnInitListener(_onInitialize);
    _playerController.addListener(_checkVideoLoaded);

    setState(() {
        _isControllerInitialized = true;
      canDisplayVideo = true;
    });
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        canDisplayVideo = false;
      });
    }
  }

  /// Helper function to set default track for subtitle, audio, etc
  ModernPlayerVideoData? _getDefaultTrackSource(
      {required List<DefaultSelector>? selectors,
      required List<ModernPlayerVideoData>? trackEntries}) {
    if (selectors == null || trackEntries == null || trackEntries.isEmpty) {
      return null;
    }

    for (final selector in selectors) {
      switch (selector) {
        case DefaultSelectorCustom():
          ModernPlayerVideoData? selected;
          for (int i = 0; i < trackEntries.length; i++) {
            if (selector.shouldUseTrack(i, trackEntries[i].label)) {
              selected = trackEntries[i];
              break;
            }
          }

          if (selected != null) {
            return selected;
            // Else, if no track is found, loop to the next selector
          }
        case DefaultSelectorOff():
          return null;
      }
    }
    return null;
  }

  void _onInitialize() async {
    _videoStartAt();
    _addSubtitles();
    _addAudioTracks();
  }

  void _videoStartAt() async {
    if (widget.options?.videoStartAt != null) {
      do {
        await Future.delayed(const Duration(milliseconds: 100));
      } while (_playerController.value.playingState != PlayingState.playing);

      await _playerController
          .seekTo(Duration(milliseconds: widget.options!.videoStartAt!));
    }
  }

  void _addSubtitles() async {
    for (var subtitle in widget.subtitles) {
      if (subtitle.sourceType == ModernPlayerSubtitleSourceType.file) {
        if (await File(subtitle.source).exists()) {
          _playerController.addSubtitleFromFile(File(subtitle.source),
              isSelected: subtitle.isSelected);
        } else {
          throw Exception("${subtitle.source} is not exist in local file.");
        }
      } else {
        _playerController.addSubtitleFromNetwork(subtitle.source,
            isSelected: subtitle.isSelected);
      }
    }
  }

  void _addAudioTracks() async {
    for (var audio in widget.audioTracks) {
      if (audio.sourceType == ModernPlayerAudioSourceType.file) {
        if (await File(audio.source).exists()) {
          _playerController.addAudioFromFile(File(audio.source),
              isSelected: audio.isSelected);
        } else {
          throw Exception("${audio.source} is not exist in local file.");
        }
      } else {
        _playerController.addAudioFromNetwork(audio.source,
            isSelected: audio.isSelected);
      }
    }
  }

  void _checkVideoLoaded() {
    if (_playerController.value.isPlaying) {
      setState(() {});
    }
  }

  void _onChangeVisibility(double visibility) {
    visibilityFraction = visibility;
    _checkPlayPause();
  }

  void _checkPlayPause() {
    if (visibilityFraction == 0) {
      if (_playerController.value.isInitialized && !isDisposed) {
        _playerController.pause();
      }
    } else {
      if (_playerController.value.isInitialized && !isDisposed) {
        _playerController.play();
      }
    }
  }

  /// Enter fullscreen mode
  void enterFullscreen() async {
    if (!_isFullscreen) {
      // Store current playback state and pause immediately
      final wasPlaying = _playerController.value.isPlaying;
      final currentPosition = _playerController.value.position;
      await _playerController.pause();
      
      setState(() {
        _isFullscreen = true;
      });
      
      // Lock to landscape orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Hide system UI completely
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [],
      );

      // Wait for the transition to complete before restoring playback
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && wasPlaying) {
        await _playerController.seekTo(currentPosition);
        await _playerController.play();
      }
      
      widget.callbackOptions?.onEnterFullscreen?.call();
    }
  }

  /// Exit fullscreen mode
  void exitFullscreen() async {
    if (_isFullscreen) {
      // Store current playback state and pause immediately
      final wasPlaying = _playerController.value.isPlaying;
      final currentPosition = _playerController.value.position;
      await _playerController.pause();
      
      setState(() {
        _isFullscreen = false;
      });
      
      // Return to portrait orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      
      // Restore system UI
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // Wait for the transition to complete before restoring playback
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && wasPlaying) {
        await _playerController.seekTo(currentPosition);
        await _playerController.play();
      }
      
      widget.callbackOptions?.onExitFullscreen?.call();
    }
  }

  /// Toggle fullscreen mode
  void toggleFullscreen() {
    if (_isFullscreen) {
      exitFullscreen();
    } else {
      enterFullscreen();
    }
  }

  @override
  void dispose() {
    // Ensure player is stopped before disposal
    if (_playerController.value.isInitialized && _playerController.value.isPlaying) {
      _playerController.pause();
    }
    super.dispose();
    if (_playerController.value.isInitialized) {
      _playerController.dispose();
    }

    _playerController.removeListener(_checkVideoLoaded);
    _playerController.removeOnInitListener(_onInitialize);

    if (widget.options?.allowScreenSleep ?? false == false) {
      WakelockPlus.disable();
    }

    // Reset system UI and orientation
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    isDisposed = true;
  }

  @override
  Widget build(BuildContext context) {
    // Use a single player instance
    final player = KeyedSubtree(
      key: const ValueKey('player_instance'),
      child: _buildPlayer(),
    );
    
    return WillPopScope(
      onWillPop: () async {
        if (_isFullscreen) {
          exitFullscreen();
          return false;
        }
        return true;
      },
      child: _isFullscreen
          ? Container(
              color: Colors.black,
              child: player,
            )
          : player,
    );
  }

  Widget _buildPlayer() {
    return canDisplayVideo
        ? Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: VisibilityDetector(
                  key: const ValueKey<int>(0),
                  onVisibilityChanged: (info) {
                    if (widget.options?.autoVisibilityPause ?? true) {
                      _onChangeVisibility(info.visibleFraction);
                    }
                  },
                  child: VlcPlayer(
                    controller: _playerController,
                    aspectRatio: _isFullscreen 
                        ? MediaQuery.of(context).size.width / MediaQuery.of(context).size.height
                        : _playerController.value.aspectRatio,
                  ),
                ),
              ),
              if (widget.controlsOptions?.showControls ?? true)
                ModernPlayerControls(
                  player: _playerController,
                  videos: videosData,
                  controlsOptions:
                      widget.controlsOptions ?? ModernPlayerControlsOptions(),
                  defaultSelectionOptions: widget.defaultSelectionOptions ??
                      ModernPlayerDefaultSelectionOptions(),
                  themeOptions:
                      widget.themeOptions ?? ModernPlayerThemeOptions(),
                  translationOptions: widget.translationOptions ??
                      ModernPlayerTranslationOptions.menu(),
                  viewSize: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  callbackOptions:
                      widget.callbackOptions ?? ModernPlayerCallbackOptions(),
                  selectedQuality: selectedQuality,
                  isFullscreen: _isFullscreen,
                  onToggleFullscreen: toggleFullscreen,
                )
            ],
          )
        : Center(
            child: SizedBox(
              height: 50,
              width: 50,
              child: widget.themeOptions?.customLoadingWidget ??
                  CircularProgressIndicator(
                    color:
                        widget.themeOptions?.loadingColor ?? Colors.greenAccent,
                    strokeCap: StrokeCap.round,
                  ),
            ),
          );
  }

  /// Get the current playing position in milliseconds
  int getCurrentPosition() {
    if (!_isControllerInitialized || !_playerController.value.isInitialized) {
      return 0;
    }
    return _playerController.value.position.inMilliseconds;
  }
}
