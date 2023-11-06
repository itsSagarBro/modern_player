import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:modern_player/modern_player.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ModernPlayerControls extends StatefulWidget {
  const ModernPlayerControls(
      {super.key,
      required this.player,
      required this.viewSize,
      required this.dataSourceType,
      required this.qualityOptions,
      required this.controlsOptions,
      required this.themeOptions,
      required this.onBackPressed});

  final VlcPlayerController player;
  final Size viewSize;
  final ModernPlayerSourceType dataSourceType;
  final List<ModernPlayerQualityOptions> qualityOptions;
  final ModernPlayerControlsOptions controlsOptions;
  final ModernPlayerThemeOptions themeOptions;
  final VoidCallback onBackPressed;

  @override
  State<ModernPlayerControls> createState() => _ModernPlayerControlsState();
}

class _ModernPlayerControlsState extends State<ModernPlayerControls> {
  VlcPlayerController get player => widget.player;

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
  late ModernPlayerQualityOptions _currentQuality;

  Timer? _hideTimer;
  bool _hideStuff = true;

  int _seekPos = 0;

  Map? _audioTracks;
  Map? _subtitleTracks;

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

    _currentQuality = widget.qualityOptions.last;

    _customActionButtons = widget.controlsOptions.customActionButtons ?? [];

    player.addListener(_listen);

    super.initState();
  }

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
          _getAudioTracks();
        }

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _getAudioTracks() async {
    _audioTracks = await player.getAudioTracks();
    _subtitleTracks = await player.getSpuTracks();
  }

  void _playOrPause() async {
    if (await player.isPlaying() ?? false) {
      setState(() {
        player.pause();
      });
    } else {
      setState(() {
        player.play();
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
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

  void _changeVideoQuality(ModernPlayerQualityOptions qualityOptions) async {
    Duration lastPosition = player.value.position;

    await player.pause().then((value) async {
      setState(() {
        _isLoading = true;
      });

      if (widget.dataSourceType == ModernPlayerSourceType.network) {
        await player
            .setMediaFromNetwork(qualityOptions.url,
                autoPlay: true, hwAcc: HwAcc.full)
            .whenComplete(() async {
          await player.seekTo(lastPosition).then((value) {
            player.play();
            setState(() {
              _currentPos = lastPosition;
              _currentQuality = qualityOptions;
            });
          });
        });
      } else {
        await player
            .setMediaFromFile(File(qualityOptions.url),
                autoPlay: true, hwAcc: HwAcc.full)
            .whenComplete(() async {
          await player.seekTo(lastPosition).then((value) {
            player.play();
            setState(() {
              _currentPos = lastPosition;
              _currentQuality = qualityOptions;
            });
          });
        });
      }
    });
  }

  void _changeSubtitleTrack(MapEntry subtitle) async {
    await player.setSpuTrack(subtitle.key);
  }

  void _changeAudioTrack(MapEntry subtitle) async {
    await player.setAudioTrack(subtitle.key);
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
        double volume = _volume ?? (player.value.volume / 200).toDouble();
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
      player.setVolume((volume * 200).toInt());
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

  String getFormattedDuration(Duration duration) {
    return "${duration.inHours > 0 ? "${(duration.inHours % 24).toString().padLeft(2, '0')}:" : ""}${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
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
                                        widget.onBackPressed.call();
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
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 75,
                width: 75,
                child: CircularProgressIndicator(
                  color: widget.themeOptions.loadingColor ?? Colors.greenAccent,
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
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                showQualityOptions();
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
                  const Text(
                    "Quality  ◉  ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    _currentQuality.name,
                    style: const TextStyle(color: Colors.white60, fontSize: 16),
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
                showPlabackSpeedOptions();
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
                  const Text(
                    "Plaback speed  ◉  ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    player.value.playbackSpeed == 1
                        ? "Normal"
                        : "${player.value.playbackSpeed.toStringAsFixed(2)}x",
                    style: const TextStyle(color: Colors.white60, fontSize: 16),
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
            GestureDetector(
              onTap: () {
                if (_audioTracks != null) {
                  Navigator.pop(context);
                  showAudioOptions();
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.speaker_group_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  const Text(
                    "Audio  ◉  ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    _audioTracks == null
                        ? "Loading"
                        : _audioTracks![player.value.activeAudioTrack],
                    style: const TextStyle(color: Colors.white60, fontSize: 16),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector _subtitleRowWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_subtitleTracks != null) {
          if (_subtitleTracks!.entries.isNotEmpty) {
            Navigator.pop(context);
            showSubtitleOptions();
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
                    const Text(
                      "Subtitles  ◉  ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      _subtitleTracks!.entries.isNotEmpty
                          ? _subtitleTracks![player.value.activeSpuTrack]
                          : "Unavailable",
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 16),
                    )
                  ],
                )
              : const Row(
                  children: [
                    Icon(
                      Icons.closed_caption_outlined,
                      color: Colors.white38,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      "Subtitles  ◉  ",
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                    Text(
                      "Unavailable",
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    )
                  ],
                )
          : const Row(
              children: [
                Icon(
                  Icons.closed_caption_outlined,
                  color: Colors.white38,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  "Subtitles  ◉  ",
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
                Text(
                  "Unavailable",
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                )
              ],
            ),
    );
  }

  void showQualityOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: getMenuBackgroundColor(),
      constraints: const BoxConstraints(maxWidth: 400),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.qualityOptions.map(
              (e) => InkWell(
                onTap: () {
                  if (e.name != _currentQuality.name) {
                    Navigator.pop(context);
                    _changeVideoQuality(e);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      if (e.name == _currentQuality.name)
                        const SizedBox(
                          width: 15,
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                          ),
                        ),
                      SizedBox(
                        width: e.name == _currentQuality.name ? 20 : 35,
                      ),
                      Text(
                        e.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }

  void showPlabackSpeedOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: getMenuBackgroundColor(),
      constraints: const BoxConstraints(maxWidth: 400),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._playbackSpeeds.map(
              (e) => InkWell(
                onTap: () {
                  if (e != player.value.playbackSpeed) {
                    player.setPlaybackSpeed(e);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      if (e == player.value.playbackSpeed)
                        const SizedBox(
                          width: 15,
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                          ),
                        ),
                      SizedBox(
                        width: e == player.value.playbackSpeed ? 20 : 35,
                      ),
                      Text(
                        e == 1 ? "Normal" : "${e.toStringAsFixed(2)}x",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }

  void showSubtitleOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: getMenuBackgroundColor(),
      constraints: const BoxConstraints(maxWidth: 400),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _subtitleListItelWidget(const MapEntry(-1, "None"), context),
              ..._subtitleTracks!.entries.map(
                (e) => _subtitleListItelWidget(e, context),
              )
            ],
          ),
        ),
      ),
    );
  }

  InkWell _subtitleListItelWidget(
      MapEntry<dynamic, dynamic> e, BuildContext context) {
    return InkWell(
      onTap: () {
        if (e.key != player.value.activeSpuTrack) {
          Navigator.pop(context);
          _changeSubtitleTrack(e);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (e.value == _subtitleTracks![player.value.activeSpuTrack] ||
                e.key == -1 &&
                    _subtitleTracks![player.value.activeSpuTrack] == null)
              const SizedBox(
                width: 15,
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                ),
              ),
            SizedBox(
              width: e.value == _subtitleTracks![player.value.activeSpuTrack] ||
                      e.key == -1 &&
                          _subtitleTracks![player.value.activeSpuTrack] == null
                  ? 20
                  : 35,
            ),
            Text(
              e.value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void showAudioOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: getMenuBackgroundColor(),
      constraints: const BoxConstraints(maxWidth: 400),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._audioTracks!.entries.map(
                (e) => InkWell(
                  onTap: () {
                    if (e.key != player.value.activeAudioTrack) {
                      Navigator.pop(context);
                      _changeAudioTrack(e);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (e.value ==
                            _audioTracks![player.value.activeAudioTrack])
                          const SizedBox(
                            width: 15,
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                            ),
                          ),
                        SizedBox(
                          width: e.value ==
                                  _audioTracks![player.value.activeAudioTrack]
                              ? 20
                              : 35,
                        ),
                        Text(
                          e.value,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
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
