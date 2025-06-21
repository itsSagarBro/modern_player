import 'package:flutter/material.dart';
import 'package:modern_player/modern_player.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Player Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Modern Player Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ModernPlayer _player;
  String _currentPosition = '0:00';
  bool _isFullscreen = false;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _player = ModernPlayer.createPlayer(
      defaultSelectionOptions: ModernPlayerDefaultSelectionOptions(
        defaultQualitySelectors: [DefaultSelectorLabel('360p')],
      ),
      video: ModernPlayerVideo.youtubeWithUrl(
        url: 'https://www.youtube.com/watch?v=lZWaDmUlRJo',
        fetchQualities: true,
      ),
      controlsOptions: ModernPlayerControlsOptions(
        showFullscreen: true,
        enableAutoFullscreen: true,
        autoHideTime: const Duration(seconds: 3),
      ),
      callbackOptions: ModernPlayerCallbackOptions(
        onEnterFullscreen: () {
          setState(() {
            _isFullscreen = true;
          });
        },
        onExitFullscreen: () {
          setState(() {
            _isFullscreen = false;
          });
        },
      ),
    );

    // Update position every second
    _updatePosition();
  }

  void _updatePosition() {
    if (mounted) {
      final position = _player.getCurrentPosition();
      final minutes = (position / 60000).floor();
      final seconds = ((position % 60000) / 1000).floor();
      setState(() {
        _currentPosition = '$minutes:${seconds.toString().padLeft(2, '0')}';
      });
      _positionTimer?.cancel();
      _positionTimer = Timer(const Duration(seconds: 1), _updatePosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a single player instance
    final playerWidget = _player;

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: playerWidget,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: playerWidget,
            ),
            const SizedBox(height: 16),
            Text(
              'Current Position: $_currentPosition',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }
}
