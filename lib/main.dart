import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'cast_downloader.dart';
import 'cast_list.dart';
import 'cast_player.dart';

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme:
          ThemeData(brightness: Brightness.dark, primaryColor: Colors.blueGrey),
      home: W(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class W extends StatelessWidget {
  const W({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CastList("main.db"),
      child: DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            // title: Text("title"),
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.play_arrow),
                ),
                Tab(
                  icon: Icon(Icons.download),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              CastPlayer(),
              CastDownloader(),
            ],
          ),
        ),
      ),
    );
  }
}
