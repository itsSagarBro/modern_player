import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:modern_player/modern_player.dart';
import 'package:modern_player/src/modern_player_options.dart';
import 'package:modern_player/src/others/modern_player_utils.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'widgets/modern_player_menus.dart';

class ModernPlayerControls extends StatefulWidget {
  const ModernPlayerControls(
      {super.key,
      required this.player,
      required this.viewSize,
      required this.videos,
      required this.controlsOptions,
      required this.defaultSelectionOptions,
      required this.themeOptions,
      required this.translationOptions,
      required this.callbackOptions,
      required this.selectedQuality});

  final VlcPlayerController player;
  final Size viewSize;
  final List<ModernPlayerVideoData> videos;
  final ModernPlayerControlsOptions controlsOptions;
  final ModernPlayerDefaultSelectionOptions defaultSelectionOptions;
  final ModernPlayerThemeOptions themeOptions;
  final ModernPlayerTranslationOptions translationOptions;
  final ModernPlayerCallbackOptions callbackOptions;
  final ModernPlayerVideoData selectedQuality;

  @override
  State<ModernPlayerControls> createState() => _ModernPlayerControlsState();
}

class _ModernPlayerControlsState extends State<ModernPlayerControls> {
  VlcPlayerController get player => widget.player;
  ModernPlayerTranslationOptions get translationOptions =>
      widget.translationOptions;

  Timer? _statelessTimer;

  Duration _duration = const Duration();
  Duration _currentPos = const Duration();

  bool _dragLeft = false;
  bool _dragRight = false;

  bool _isLoading = true;
  bool _isDisposed = false;

  double? _brightness;
  double? _volume;
  double? _slidingValue;

  late StreamController<double> _valController;
  late ModernPlayerVideoData _currentVideoData;

  /// Auto hide controls timer
  Timer? _hideTimer;

  /// Check controls is hidden or not
  bool _hideStuff = true;

  /// Offline seek position
  int _seekPos = 0;

  /// List of audio tracks
  Map<int, String>? _audioTracks;

  /// List of subtitle tracks
  Map<int, String>? _subtitleTracks;

  /// List of playback speeds
  final List<double> _playbackSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2
  ];

  List<ModernPlayerCustomActionButton> _customActionButtons = [];

  @override
  void initState() {
    _valController = StreamController.broadcast();

    _duration = player.value.duration;
    _currentPos = player.value.position;

    _currentVideoData = widget.selectedQuality;
    _customActionButtons = widget.controlsOptions.customActionButtons ?? [];

    player.addListener(_listen);
    super.initState();
  }

  /// Add listners
  void _listen() async {
    if (!_isDisposed) {
      if (_hideStuff == false) {
        if (_currentPos != player.value.position ||
            player.value.playingState == PlayingState.paused) {
          setState(() {
            _currentPos = player.value.position;
            _duration = player.value.duration;
          });
        }
      } else {
        _currentPos = player.value.position;
        _duration = player.value.duration;
      }

      if (player.value.playingState == PlayingState.playing &&
          _isLoading &&
          player.value.playingState != PlayingState.initializing &&
          player.value.bufferPercent >= 100) {
        if (_audioTracks == null && _subtitleTracks == null) {
          _getTracks();
        }

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get audio and subtitle tracks
  void _getTracks() async {
    // Run in parallel - they don't depend on each other.
    final tracksFutures = Future.wait([
      player.getAudioTracks(),
      player.getSpuTracks(),
    ]);

    final results = await tracksFutures;
    _audioTracks = results[0];
    _subtitleTracks = results[1];

    await Future.wait([
      _setDefaultSubtitleTrack(_subtitleTracks),
      _setDefaultAudioTrack(_audioTracks),
    ]);
  }

  /// Helper function to set default track for subtitle, audio, etc
  Future<void> _setDefaultTrack(
      {required List<DefaultSelector>? selectors,
      required Map<int, String>? trackEntries,
      required Function(int) setTrackFunction}) async {
    if (selectors == null || trackEntries == null || trackEntries.isEmpty) {
      return;
    }

    for (final selector in selectors) {
      switch (selector) {
        case DefaultSelectorCustom():
          int? defaultIndex;
          for (final entry in trackEntries.entries) {
            if (selector.shouldUseTrack(entry.key, entry.value)) {
              defaultIndex = entry.key;
              break;
            }
          }

          if (defaultIndex != null) {
            setTrackFunction(defaultIndex);
            return;
            // Else, if no track is found, loop to the next selector
          }
        case DefaultSelectorOff():
          setTrackFunction(-1);
          return;
      }
    }
  }

  /// Set default subtitle track
  Future<void> _setDefaultSubtitleTrack(Map<int, String>? tracks) async {
    await _setDefaultTrack(
      selectors: widget.defaultSelectionOptions.defaultSubtitleSelectors,
      trackEntries: tracks,
      setTrackFunction: player.setSpuTrack,
    );
  }

  /// Set default audio track
  Future<void> _setDefaultAudioTrack(Map<int, String>? tracks) async {
    await _setDefaultTrack(
      selectors: widget.defaultSelectionOptions.defaultAudioSelectors,
      trackEntries: tracks,
      setTrackFunction: player.setAudioTrack,
    );
  }

  /// Toggle between play and pause
  void _playOrPause() async {
    if (await player.isPlaying() ?? false) {
      setState(() {
        player.pause();
      });

      widget.callbackOptions.onPause?.call();
    } else {
      setState(() {
        player.play();
      });

      widget.callbackOptions.onPlay?.call();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(
        widget.controlsOptions.autoHideTime ?? const Duration(seconds: 5), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _startHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  void _changeVideoQuality(ModernPlayerVideoData videoData) async {
    Duration lastPosition = player.value.position;

    await player.pause().then((value) async {
      setState(() {
        _isLoading = true;
      });

      if (videoData.sourceType == ModernPlayerSourceType.network) {
        await player
            .setMediaFromNetwork(videoData.source,
                autoPlay: true, hwAcc: HwAcc.full)
            .whenComplete(() async {
          if (videoData is ModernPlayerVideoDataYoutube) {
            await player.seekTo(lastPosition).then((value) async {
              await player.addAudioFromNetwork(videoData.audioOverride!,
                  isSelected: true);
              _getTracks();
              player.play();
              setState(() {
                _currentPos = lastPosition;
                _currentVideoData = videoData;
              });
            });
          } else {
            _getTracks();
            player.play();
            setState(() {
              _currentPos = lastPosition;
              _currentVideoData = videoData;
            });
          }
        });
      } else if (videoData.sourceType == ModernPlayerSourceType.file) {
        await player
            .setMediaFromFile(File(videoData.source),
                autoPlay: true, hwAcc: HwAcc.full)
            .whenComplete(() async {
          await player.seekTo(lastPosition).then((value) {
            player.play();
            setState(() {
              _currentPos = lastPosition;
              _currentVideoData = videoData;
            });
          });
        });
      } else if (widget.videos.first.sourceType ==
          ModernPlayerSourceType.youtube) {
        var yt = YoutubeExplode();
        StreamManifest manifest =
            await yt.videos.streamsClient.getManifest(videoData.source);

        VideoStreamInfo streamInfo = manifest.muxed.withHighestBitrate();

        await player
            .setMediaFromNetwork(streamInfo.url.toString(),
                autoPlay: true, hwAcc: HwAcc.full)
            .whenComplete(() async {
          await player.seekTo(lastPosition).then((value) {
            player.play();
            setState(() {
              _currentPos = lastPosition;
              _currentVideoData = videoData;
            });
          });
        });

        yt.close();
      } else {
        await player
            .setMediaFromAsset(videoData.source,
                autoPlay: true, hwAcc: HwAcc.full)
            .whenComplete(() async {
          await player.seekTo(lastPosition).then((value) {
            player.play();
            setState(() {
              _currentPos = lastPosition;
              _currentVideoData = videoData;
            });
          });
        });
      }
    });

    widget.callbackOptions.onChangedQuality
        ?.call(videoData.label, videoData.source);

    // Refresh subtitle and audio tracks
    _getTracks();
  }

  void _changeSubtitleTrack(MapEntry subtitle) async {
    await player.setSpuTrack(subtitle.key);
    widget.callbackOptions.onChangedSubtitle?.call(subtitle.key);
  }

  void _changeAudioTrack(MapEntry subtitle) async {
    await player.setAudioTrack(subtitle.key);
    widget.callbackOptions.onChangedAudio?.call(subtitle.key);
  }

  void _seekTo(Duration position) async {
    await player.pause().then((value) async {
      setState(() {
        _isLoading = true;
      });

      await player.seekTo(position).then((value) {
        player.play();
        setState(() {
          _currentPos = position;
          _seekPos = 0;
        });

        widget.callbackOptions.onSeek?.call(position.inMilliseconds);
      });
    });
  }

  void _seekForward() async {
    int positionInSeconds = player.value.position.inSeconds + 10;

    await player.pause().then((value) async {
      setState(() {
        _isLoading = true;
      });

      await player.seekTo(Duration(seconds: positionInSeconds)).then((value) {
        player.play();
        setState(() {
          _currentPos = Duration(seconds: positionInSeconds);
          _seekPos = 0;
        });

        widget.callbackOptions.onSeekForward?.call();
      });
    });
  }

  void _seekBackward() async {
    int positionInSeconds = player.value.position.inSeconds - 10;

    await player.pause().then((value) async {
      setState(() {
        _isLoading = true;
      });

      await player.seekTo(Duration(seconds: positionInSeconds)).then((value) {
        player.play();
        setState(() {
          _currentPos = Duration(seconds: positionInSeconds);
          _seekPos = 0;
        });

        widget.callbackOptions.onSeekBackward?.call();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _isDisposed = true;
    player.removeListener(_listen);
    _hideTimer?.cancel();
    _statelessTimer?.cancel();
    ScreenBrightness().resetScreenBrightness();
  }

  void _onDoubleTap(TapDownDetails details) {
    if (widget.controlsOptions.doubleTapToSeek) {
      if (details.localPosition.dx > widget.viewSize.width / 2) {
        _seekForward();
      } else {
        _seekBackward();
      }
    }
  }

  void onVerticalDragStartFun(DragStartDetails d) {
    _dragLeft = false;
    _dragRight = false;

    if (d.localPosition.dx >
        (widget.viewSize.width / 3 + (widget.viewSize.width / 3))) {
      // right, volume
      if (widget.controlsOptions.enableVolumeSlider) {
        _dragRight = true;
        double volume = _volume ?? (player.value.volume / 100).toDouble();
        setState(() {
          _slidingValue = volume;
          _volume = volume;
          _valController.add(volume);
        });
      }
    } else if (d.localPosition.dx < widget.viewSize.width / 3) {
      // left, brightness
      if (widget.controlsOptions.enableBrightnessSlider) {
        _dragLeft = true;
        ScreenBrightness().current.then((v) {
          setState(() {
            _slidingValue = v;
            _brightness = v;
            _valController.add(v);
          });
        });
      }
    }

    _statelessTimer?.cancel();
    _statelessTimer = Timer(const Duration(milliseconds: 2000), () {
      setState(() {});
    });
  }

  void onVerticalDragUpdateFun(DragUpdateDetails d) {
    double delta = d.primaryDelta! / widget.viewSize.height;
    delta = -delta.clamp(-1.0, 1.0);
    if (_dragRight == true) {
      var volume = _volume ?? 1;
      volume += delta;
      volume = volume.clamp(0.0, 1.0);
      player.setVolume((volume * 100).toInt());
      setState(() {
        _slidingValue = volume;
        _volume = volume;
        _valController.add(volume);
      });
    } else if (_dragLeft == true) {
      var brightness = _brightness;
      if (brightness != null) {
        brightness += delta;
        brightness = brightness.clamp(0.0, 1.0);
        _brightness = brightness;
        ScreenBrightness().setScreenBrightness(brightness);
        setState(() {
          _slidingValue = brightness;
          _valController.add(brightness!);
        });
      }
    }
  }

  void onVerticalDragEndFun(DragEndDetails e) {
    _slidingValue = null;
    _brightness = null;
    _statelessTimer?.cancel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 400),
          child: !_hideStuff
              ? Stack(
                  key: const ValueKey<int>(0),
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: _cancelAndRestartTimer,
                      onDoubleTapDown: _onDoubleTap,
                      onVerticalDragStart: onVerticalDragStartFun,
                      onVerticalDragUpdate: onVerticalDragUpdateFun,
                      onVerticalDragEnd: onVerticalDragEndFun,
                      onHorizontalDragStart: (details) {},
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (widget.controlsOptions.showBackbutton)
                                  // Back Button
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: InkWell(
                                      onTap: () {
                                        widget.callbackOptions.onBackPressed
                                            ?.call();
                                      },
                                      child: Card(
                                        color: getIconsBackgroundColor(),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: widget.themeOptions.backIcon ??
                                            const Icon(
                                              Icons.arrow_back_ios_new_rounded,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                // Custom Buttons
                                ..._customActionButtons.map(
                                  (e) => SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: InkWell(
                                      onTap: () {
                                        if (e.onPressed != null) {
                                          e.onPressed!.call();
                                        }
                                      },
                                      onDoubleTap: () {
                                        if (e.onDoubleTap != null) {
                                          e.onDoubleTap!.call();
                                        }
                                      },
                                      onLongPress: () {
                                        if (e.onLongPress != null) {
                                          e.onLongPress!.call();
                                        }
                                      },
                                      child: Card(
                                        color: getIconsBackgroundColor(),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: e.icon,
                                      ),
                                    ),
                                  ),
                                ),
                                // Mute/Unmute
                                if (widget.controlsOptions.showMute)
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _startHideTimer();
                                          if (player.value.volume > 0) {
                                            player.setVolume(0);
                                          } else {
                                            _volume = 100;
                                            player.setVolume(100);
                                          }
                                        });

                                        widget.callbackOptions.onMutePressed
                                            ?.call();
                                      },
                                      child: Card(
                                        color: getIconsBackgroundColor(),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: player.value.volume > 0
                                            ? widget.themeOptions.muteIcon ??
                                                const Icon(
                                                  Icons.volume_up_rounded,
                                                  color: Colors.white,
                                                )
                                            : widget.themeOptions.unmuteIcon ??
                                                const Icon(
                                                  Icons.volume_off_rounded,
                                                  color: Colors.white,
                                                ),
                                      ),
                                    ),
                                  ),
                                // Settings/Menu
                                if (widget.controlsOptions.showMenu)
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: InkWell(
                                      onTap: () {
                                        _startHideTimer();
                                        showOptions(context);

                                        widget.callbackOptions.onMenuPressed
                                            ?.call();
                                      },
                                      child: Card(
                                        color: getIconsBackgroundColor(),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: widget.themeOptions.menuIcon ??
                                            const Icon(
                                              Icons.settings_rounded,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    if (widget.controlsOptions.showBottomBar)
                      _bottomBar(context),
                  ],
                )
              : GestureDetector(
                  onTap: _cancelAndRestartTimer,
                  onDoubleTapDown: _onDoubleTap,
                  onVerticalDragStart: onVerticalDragStartFun,
                  onVerticalDragUpdate: onVerticalDragUpdateFun,
                  onVerticalDragEnd: onVerticalDragEndFun,
                  onHorizontalDragStart: (details) {},
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: (_slidingValue != null)
                                ? IgnorePointer(
                                    child: _brightness != null
                                        ? _VideoControlsSliderToast(
                                            _brightness!,
                                            1,
                                            _valController.stream,
                                            widget.themeOptions
                                                    .brightnessSlidertheme ??
                                                ModernPlayerToastSliderThemeOption(
                                                    sliderColor: Colors.blue),
                                            widget.themeOptions
                                                    .volumeSlidertheme ??
                                                ModernPlayerToastSliderThemeOption(
                                                    sliderColor: Colors.blue))
                                        : _VideoControlsSliderToast(
                                            _volume!,
                                            0,
                                            _valController.stream,
                                            widget.themeOptions
                                                    .brightnessSlidertheme ??
                                                ModernPlayerToastSliderThemeOption(
                                                    sliderColor: Colors.blue),
                                            widget.themeOptions
                                                    .volumeSlidertheme ??
                                                ModernPlayerToastSliderThemeOption(
                                                    sliderColor: Colors.blue)),
                                  )
                                : const SizedBox.shrink())
                      ],
                    ),
                  ),
                ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Center(
              child: widget.themeOptions.customLoadingWidget ??
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      color: widget.themeOptions.loadingColor ??
                          Colors.greenAccent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
            ),
          )
      ],
    ));
  }

  Widget _bottomBar(BuildContext context) {
    int duration = _duration.inSeconds;

    int currentValue = _seekPos > 0 ? _seekPos : _currentPos.inSeconds;
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);

    Duration remaining = _duration - _currentPos;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: getIconsBackgroundColor(),
            borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: IconButton(
                onPressed: () {
                  _startHideTimer();
                  _seekBackward();
                },
                icon: const Icon(
                  Icons.replay_10_rounded,
                  size: 20,
                ),
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 40,
              child: GestureDetector(
                onTap: () {
                  _startHideTimer();
                  _playOrPause();
                },
                child: Icon(
                  player.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                onPressed: () {
                  _startHideTimer();
                  _seekForward();
                },
                icon: const Icon(
                  Icons.forward_10_rounded,
                  size: 20,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              getFormattedDuration(
                  _seekPos > 0 ? Duration(seconds: _seekPos) : _currentPos),
              style:
                  widget.themeOptions.progressSliderTheme?.progressTextStyle ??
                      const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                child: SliderTheme(
              data: SliderThemeData(
                  trackShape: VideoSliderTrackShape(),
                  activeTrackColor: widget.themeOptions.progressSliderTheme
                          ?.activeSliderColor ??
                      Colors.greenAccent,
                  secondaryActiveTrackColor: widget.themeOptions
                          .progressSliderTheme?.bufferSliderColor ??
                      Colors.white,
                  thumbColor:
                      widget.themeOptions.progressSliderTheme?.thumbColor ??
                          Colors.white,
                  inactiveTrackColor: widget.themeOptions.progressSliderTheme
                          ?.inactiveSliderColor ??
                      Colors.white60,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7, pressedElevation: 10)),
              child: Slider(
                value: currentValue.toDouble(),
                min: 0,
                max: duration.toDouble(),
                onChanged: (value) {
                  _startHideTimer();
                  setState(() {
                    _seekPos = value.toInt();
                  });
                },
                onChangeEnd: (value) {
                  _seekTo(Duration(seconds: value.toInt()));
                },
              ),
            )),
            const SizedBox(
              width: 10,
            ),
            Text(
              "-${getFormattedDuration(_seekPos > 0 ? Duration(seconds: duration - _seekPos) : remaining)}",
              style:
                  widget.themeOptions.progressSliderTheme?.progressTextStyle ??
                      const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        ),
      ),
    );
  }

  void showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: getMenuBackgroundColor(),
      constraints: const BoxConstraints(maxWidth: 400),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ModernPlayerMenus().showQualityOptions(context,
                      menuColor: getMenuBackgroundColor(),
                      currentData: _currentVideoData,
                      allData: widget.videos,
                      onChangedQuality: _changeVideoQuality);
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(
                      "${translationOptions.qualityHeaderText ?? "Quality"}  ◉  ",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      _currentVideoData.label,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 16),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ModernPlayerMenus().showPlabackSpeedOptions(context,
                      menuColor: getMenuBackgroundColor(),
                      text: translationOptions.defaultPlaybackSpeedText ??
                          "Normal",
                      currentSpeed: player.value.playbackSpeed,
                      allSpeeds: _playbackSpeeds, onChnagedSpeed: (speed) {
                    player.setPlaybackSpeed(speed);
                    widget.callbackOptions.onChangedPlaybackSpeed?.call(speed);
                  });
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(
                      "${translationOptions.playbackSpeedText ?? "Plaback speed"}  ◉  ",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      player.value.playbackSpeed == 1
                          ? translationOptions.defaultPlaybackSpeedText ??
                              "Normal"
                          : "${player.value.playbackSpeed.toStringAsFixed(2)}x",
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 16),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              _subtitleRowWidget(context),
              const SizedBox(
                height: 30,
              ),
              _audioRowWidget(context),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subtitleRowWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_subtitleTracks != null) {
          if (_subtitleTracks!.entries.isNotEmpty) {
            Navigator.pop(context);
            ModernPlayerMenus().showSubtitleOptions(context,
                menuColor: getMenuBackgroundColor(),
                activeTrack: player.value.activeSpuTrack,
                allTracks: _subtitleTracks!,
                onChangedSubtitle: _changeSubtitleTrack);
          }
        }
      },
      child: _subtitleTracks != null
          ? _subtitleTracks!.entries.isNotEmpty
              ? Row(
                  children: [
                    const Icon(
                      Icons.closed_caption_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(
                      "${translationOptions.subtitleText ?? "Subtitles"}  ◉  ",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      _subtitleTracks!.entries.isNotEmpty
                          ? _subtitleTracks![player.value.activeSpuTrack] ??
                              translationOptions.noneSubtitleText ??
                              "None"
                          : translationOptions.unavailableSubtitleText ??
                              "Unavailable",
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 16),
                    )
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.closed_caption_outlined,
                      color: Colors.white38,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(
                      "${translationOptions.subtitleText ?? "Subtitles"}  ◉  ",
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                    Text(
                      translationOptions.unavailableSubtitleText ??
                          "Unavailable",
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 16),
                    )
                  ],
                )
          : Row(
              children: [
                const Icon(
                  Icons.closed_caption_outlined,
                  color: Colors.white38,
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  "${translationOptions.subtitleText ?? "Subtitles"}  ◉  ",
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                ),
                Text(
                  translationOptions.unavailableSubtitleText ?? "Unavailable",
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                )
              ],
            ),
    );
  }

  Widget _audioRowWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_audioTracks != null) {
          if (_audioTracks![player.value.activeAudioTrack] != null) {
            Navigator.pop(context);
            ModernPlayerMenus().showAudioOptions(context,
                menuColor: getMenuBackgroundColor(),
                activeTrack: player.value.activeAudioTrack,
                allTracks: _audioTracks!,
                onChangedAudio: _changeAudioTrack);
          }
        }
      },
      child: _audioTracks![player.value.activeAudioTrack] != null
          ? Row(
              children: [
                const Icon(
                  Icons.speaker_group_outlined,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  "${translationOptions.audioHeaderText ?? "Audio"}  ◉  ",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  _audioTracks == null
                      ? translationOptions.loadingAudioText ?? "Loading"
                      : _audioTracks![player.value.activeAudioTrack]!,
                  style: const TextStyle(color: Colors.white60, fontSize: 16),
                )
              ],
            )
          : Row(
              children: [
                const Icon(
                  Icons.closed_caption_outlined,
                  color: Colors.white38,
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  "${translationOptions.audioHeaderText ?? "Audio"}  ◉  ",
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                ),
                Text(
                  translationOptions.unavailableAudioText ?? "Default",
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                )
              ],
            ),
    );
  }

  Color getMenuBackgroundColor() {
    return widget.themeOptions.menuBackgroundColor ??
        const Color.fromARGB(255, 20, 20, 20);
  }

  Color getIconsBackgroundColor() {
    Color? color =
        widget.themeOptions.backgroundColor ?? Colors.black.withOpacity(.75);
    return color;
  }
}

class VideoSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class _VideoControlsSliderToast extends StatefulWidget {
  final Stream<double> emitter;
  final double initial;

  // type 0 volume
  // type 1 screen brightness
  final int type;
  final ModernPlayerToastSliderThemeOption volumeSliderTheme;
  final ModernPlayerToastSliderThemeOption brightnessSliderTheme;

  const _VideoControlsSliderToast(this.initial, this.type, this.emitter,
      this.brightnessSliderTheme, this.volumeSliderTheme);

  @override
  _VideoControlsSliderToastState createState() =>
      _VideoControlsSliderToastState();
}

class _VideoControlsSliderToastState extends State<_VideoControlsSliderToast> {
  double value = 0;
  StreamSubscription? subs;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
    subs = widget.emitter.listen((v) {
      setState(() {
        value = v;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    subs?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    if (type == 0) {
      // Volume
      IconData iconData;
      if (value <= 0) {
        iconData = widget.volumeSliderTheme.unfilledIcon ?? Icons.volume_mute;
      } else if (value < 0.5) {
        iconData = widget.volumeSliderTheme.halfFilledIcon ?? Icons.volume_down;
      } else {
        iconData = widget.volumeSliderTheme.filledIcon ?? Icons.volume_up;
      }

      return Align(
        alignment: const Alignment(0, -0.4),
        child: Card(
          color: widget.volumeSliderTheme.backgroundColor ??
              Colors.black.withOpacity(.5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  iconData,
                  color: widget.volumeSliderTheme.iconColor ?? Colors.white,
                ),
                const SizedBox(
                  width: 4,
                ),
                SizedBox(
                  width: 100,
                  height: 1.5,
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white60,
                    valueColor: AlwaysStoppedAnimation(
                        widget.volumeSliderTheme.sliderColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Brightness
      IconData iconData;
      if (value <= 0) {
        iconData =
            widget.brightnessSliderTheme.unfilledIcon ?? Icons.brightness_low;
      } else if (value < 0.5) {
        iconData = widget.brightnessSliderTheme.halfFilledIcon ??
            Icons.brightness_medium;
      } else {
        iconData =
            widget.brightnessSliderTheme.filledIcon ?? Icons.brightness_high;
      }

      return Align(
        alignment: const Alignment(0, -0.4),
        child: Card(
          color: widget.brightnessSliderTheme.backgroundColor ??
              Colors.black.withOpacity(.5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  iconData,
                  color: widget.brightnessSliderTheme.iconColor ?? Colors.white,
                ),
                const SizedBox(
                  width: 4,
                ),
                SizedBox(
                  width: 100,
                  height: 1.5,
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white60,
                    valueColor: AlwaysStoppedAnimation(
                        widget.brightnessSliderTheme.sliderColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
