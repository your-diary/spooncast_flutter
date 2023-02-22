import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'cast_downloader.dart';
import 'cast_list.dart';

void main() {
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
      create: (_context) => CastList(),
      child: DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            // title: Text("title"),
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.playlist_play),
                ),
                Tab(
                  icon: Icon(Icons.download),
                ),
                Tab(
                  icon: Icon(Icons.play_arrow),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Tab1(),
              CastDownloader(),
              Tab3(),
            ],
          ),
        ),
      ),
    );
  }
}

class Tab1 extends StatelessWidget {
  final player = AudioPlayer();

  Tab1({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Consumer<CastList>(
          builder: (_context, castFiles, _child) {
            return ListView(
                children: castFiles.l.map((e) {
              return Card(
                  child: ListTile(
                      title: Text(e.replaceFirst(RegExp(".*/"), "")),
                      onTap: () {
                        this.player.setFilePath(e);
                        this.player.play();
                      }));
            }).toList());
          },
        )),
        Expanded(
          child: TextButton(
              child: Text("stop"), onPressed: () => this.player.stop()),
        ),
      ],
    );
  }
}

class Tab3 extends StatelessWidget {
  const Tab3({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("settings"),
    );
  }
}
