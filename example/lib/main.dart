import 'package:flutter/material.dart';
import 'package:modern_player/modern_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Player Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Modern Player Example'),
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
  // Theme option for modern_player
  var themeOptions = ModernPlayerThemeOptions(
      backgroundColor: Colors.black,
      menuBackgroundColor: Colors.black,
      loadingColor: Colors.blue,
      menuIcon: const Icon(
        Icons.settings,
        color: Colors.white,
      ),
      volumeSlidertheme: ModernPlayerToastSliderThemeOption(
          sliderColor: Colors.blue, iconColor: Colors.white),
      progressSliderTheme: ModernPlayerProgressSliderTheme(
          activeSliderColor: Colors.blue,
          inactiveSliderColor: Colors.white70,
          bufferSliderColor: Colors.black54,
          thumbColor: Colors.white,
          progressTextStyle: const TextStyle(
              fontWeight: FontWeight.w400, color: Colors.white, fontSize: 18)));

  // Controls option for modern_player
  var controlsOptions = ModernPlayerControlsOptions(
      showControls: true,
      doubleTapToSeek: true,
      showMenu: true,
      showMute: false,
      showBackbutton: false,
      enableVolumeSlider: true,
      enableBrightnessSlider: true,
      showBottomBar: true,
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
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 250,
              child: ModernPlayer.createPlayer(
                defaultSelectionOptions: ModernPlayerDefaultSelectionOptions(
                    defaultQualitySelectors: [DefaultSelectorLabel('360p')]),
                video: ModernPlayerVideo.youtubeWithUrl(
                    url:
                        'https://www.youtube.com/watch?v=vEHeI_wBzu0&ab_channel=UntitledStudio',
                    fetchQualities: true),
              ),
            )
          ],
        ),
      ),
    );
  }
}
