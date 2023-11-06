import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:modern_player/src/modern_player_controls.dart';
import 'package:modern_player/src/modern_player_options.dart';
import 'package:modern_player/src/modern_players_enums.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Modern Player gives you a controller for flutter_vlc_player.
///
/// For displaying the video in Flutter, You can create video player widget by calling [createPlayer].
///
/// To customize video player controls or theme you can add [controlsOptions] and [themeOptions]
/// when calling [createPlayer]
class ModernPlayer extends StatefulWidget {
  const ModernPlayer._(
      {required this.qualityOptions,
      required this.sourceType,
      required this.subtitles,
      required this.audioTracks,
      this.options,
      this.controlsOptions,
      this.themeOptions,
      this.onBackPressed});

  /// Video quality options for multiple qualities. If you have only one quality video just add one in list.
  final List<ModernPlayerQualityOptions> qualityOptions;

  /// Type of player. It is network player or file player.
  final ModernPlayerSourceType sourceType;

  /// Modern player can detect subtitle from the video on supported formats like .mkv.
  ///
  /// But if you wish to add subtitle from [file] or [network], you can use this [subtitles].
  final List<ModernPlayerSubtitleOptions> subtitles;

  /// If you wish to add audio from [file] or [network], you can use this [audioTracks].
  final List<ModernPlayerAudioTrackOptions> audioTracks;

  // Modern player options gives you some basic controls for video
  final ModernPlayerOptions? options;

  /// Modern player controls option.
  final ModernPlayerControlsOptions? controlsOptions;

  /// Control theme of controls.
  final ModernPlayerThemeOptions? themeOptions;

  /// Callback when user pressed back button of controls.
  final VoidCallback? onBackPressed;

  static Widget createPlayer(
      {required List<ModernPlayerQualityOptions> qualityOptions,
      required ModernPlayerSourceType sourceType,
      List<ModernPlayerSubtitleOptions>? subtitles,
      List<ModernPlayerAudioTrackOptions>? audioTracks,
      ModernPlayerOptions? options,
      ModernPlayerControlsOptions? controlsOptions,
      ModernPlayerThemeOptions? themeOptions,
      VoidCallback? onBackPressed}) {
    return ModernPlayer._(
      qualityOptions: qualityOptions,
      sourceType: sourceType,
      subtitles: subtitles ?? [],
      audioTracks: audioTracks ?? [],
      options: options,
      controlsOptions: controlsOptions,
      themeOptions: themeOptions,
      onBackPressed: onBackPressed,
    );
  }

  @override
  State<ModernPlayer> createState() => _ModernPlayerState();
}

class _ModernPlayerState extends State<ModernPlayer> {
  late VlcPlayerController _playerController;

  bool isDisposed = false;

  double visibilityFraction = 1;

  @override
  void initState() {
    super.initState();

    if (widget.sourceType == ModernPlayerSourceType.network) {
      _playerController = VlcPlayerController.network(
          widget.qualityOptions.first.url,
          autoPlay: true,
          autoInitialize: true,
          hwAcc: HwAcc.full,
          options: VlcPlayerOptions(
            advanced:
                VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(120000)]),
          ));
    } else {
      _playerController = VlcPlayerController.file(
          File(widget.qualityOptions.first.url),
          autoPlay: true,
          autoInitialize: true,
          hwAcc: HwAcc.full);
    }

    _playerController.addOnInitListener(_onInitialize);
    _playerController.addListener(_checkVideoLoaded);
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

  @override
  void dispose() async {
    super.dispose();
    if (_playerController.value.isInitialized) {
      _playerController.dispose();
    }
    _playerController.removeListener(_checkVideoLoaded);
    _playerController.removeOnInitListener(_onInitialize);
    isDisposed = true;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        VisibilityDetector(
          key: const ValueKey<int>(0),
          onVisibilityChanged: (info) {
            if (widget.options?.controlVisibiltyPlay ?? true) {
              _onChangeVisibility(info.visibleFraction);
            }
          },
          child: VlcPlayer(
            controller: _playerController,
            aspectRatio: screenSize.width / screenSize.height,
          ),
        ),
        if (widget.controlsOptions?.showControls ?? true)
          ModernPlayerControls(
            player: _playerController,
            qualityOptions: widget.qualityOptions,
            dataSourceType: widget.sourceType,
            controlsOptions:
                widget.controlsOptions ?? ModernPlayerControlsOptions(),
            themeOptions: widget.themeOptions ?? ModernPlayerThemeOptions(),
            viewSize: Size(MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height),
            onBackPressed: () {
              if (widget.onBackPressed != null) {
                widget.onBackPressed!.call();
              }
            },
          )
      ],
    );
  }
}
