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
              height: 200,
              child: ModernPlayer.createPlayer(
                  qualityOptions: [
                    ModernPlayerQualityOptions(
                        name: "new",
                        url:
                            "https://us-central-1.fybeobjects.com/0cacdc5a6e4b4c49822552f72d1463bd:cinevista/Trailers/Gold%20Theatrical%20Trailer%20_%20Akshay%20Kumar%20_%20Mouni%20_%20Kunal%20_%20Amit%20_%20Vineet%20_%20Sunny%20_%2015th%20August%202018.mp4")
                  ],
                  controlsOptions: ModernPlayerControlsOptions(
                      showControls: true,
                      doubleTapToSeek: false,
                      showMenu: true,
                      showMute: false,
                      showBackbutton: false,
                      enableVolumeSlider: true,
                      enableBrightnessSlider: true,
                      showBottomBar: true,
                      themeOptions: ModernPlayerThemeOptions(
                          backgroundColor: Colors.black,
                          menuBackgroundColor: Colors.black,
                          loadingColor: Colors.white,
                          menuIcon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          )),
                      progressSliderTheme: ModernPlayerProgressSliderTheme(
                          activeSliderColor: Colors.blue,
                          inactiveSliderColor: Colors.white70,
                          bufferSliderColor: Colors.black54,
                          thumbColor: Colors.white,
                          progressTextStyle: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              fontSize: 18)))),
            )
          ],
        ),
      ),
    );
  }
}
