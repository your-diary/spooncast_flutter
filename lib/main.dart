import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

Future<String> getCastID(String shortenURL) async {
  final client = Client();

  final uri = Uri.parse(shortenURL);

  var req = Request("GET", uri);
  req.followRedirects = false;

  final res = await client.send(req);
  client.close();
  assert(res.isRedirect);
  assert(res.headers.containsKey("location"));

  return RegExp(r"https://spooncast.net/jp/cast/(\d+)")
      .firstMatch(res.headers["location"]!)!
      .group(1)!;
}

class CastInfo {
  final String id;
  final String author;
  final String title;
  final String voiceURL;
  final String fileExtension;

  CastInfo({
    required this.id,
    required this.author,
    required this.title,
    required this.voiceURL,
    required this.fileExtension,
  });

  @override
  String toString() {
    return "CastInfo(id = ${this.id}, author = ${this.author}, title = ${this.title}, voiceURL = ${this.voiceURL}, fileExtension = ${this.fileExtension})";
  }
}

Future<CastInfo> getCastInfo(String castID) async {
  final uri = Uri.parse("https://jp-api.spooncast.net/casts/${castID}/");
  final res = await get(uri);
  assert(res.statusCode == 200);
  final m = jsonDecode(utf8.decode(res.bodyBytes));
  return CastInfo(
    id: castID,
    author: m["results"][0]["author"]["nickname"],
    title: m["results"][0]["title"],
    voiceURL: m["results"][0]["voice_url"],
    fileExtension:
        m["results"][0]["voice_url"].replaceFirst(RegExp(r".*\."), ""),
  );
}

Future<void> downloadCast(CastInfo castInfo) async {
  final uri = Uri.parse(castInfo.voiceURL);
  final res = await get(uri);
  assert(res.statusCode == 200);
  final appDocDir = (await getApplicationDocumentsDirectory()).path;
  await File("${appDocDir}/${castInfo.id}.${castInfo.fileExtension}")
      .writeAsBytes(res.bodyBytes);
}

//The argument is a shorten URL like "https://u8kv3.app.goo.gl/Q4izq".
Future<CastInfo> f(String shortenURL) async {
  final castID = await getCastID(shortenURL);
  print(castID);

  final castInfo = await getCastInfo(castID);
  print(castInfo);

  await downloadCast(castInfo);

  return castInfo;
}

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
      create: (_context) => CastFiles(),
      child: DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 30,
            title: Text("title"),
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.cloud_outlined),
                ),
                Tab(
                  icon: Icon(Icons.beach_access_sharp),
                ),
                Tab(
                  icon: Icon(Icons.brightness_5_sharp),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Tab1(),
              Tab2(),
              Tab3(),
            ],
          ),
        ),
      ),
    );
  }
}

class CastFiles extends ChangeNotifier {
  List<String> l = [];

  CastFiles() {
    this.update();
  }

  Future<void> update() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    this.l = appDocDir.listSync().map((e) => e.path).toList();
    notifyListeners();
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
        Expanded(child: Consumer<CastFiles>(
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

class Tab2 extends StatefulWidget {
  const Tab2({
    super.key,
  });

  @override
  State<Tab2> createState() => _Tab2State();
}

enum DownloadProgress { notInProgress, inProgress, completed, failed }

class _Tab2State extends State<Tab2> {
  DownloadProgress isDownloading = DownloadProgress.notInProgress;
  String input = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                      maxLines: null, onChanged: (s) => this.input = s.trim())),
              SizedBox(width: 20),
              OutlinedButton(
                  child: Text("Download"),
                  onPressed: (this.isDownloading == DownloadProgress.inProgress)
                      ? null
                      : () async {
                          this.setState(() =>
                              this.isDownloading = DownloadProgress.inProgress);
                          try {
                            await f(this.input);
                            await Provider.of<CastFiles>(context, listen: false)
                                .update();
                            this.setState(() => this.isDownloading =
                                DownloadProgress.completed);
                          } catch (e) {
                            debugPrint(e.toString());
                            this.setState(() =>
                                this.isDownloading = DownloadProgress.failed);
                          }
                        }),
            ],
          ),
        ),
        if (this.isDownloading == DownloadProgress.inProgress)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Downloading..."),
            ],
          ),
        if (this.isDownloading == DownloadProgress.completed) Text("Done."),
        if (this.isDownloading == DownloadProgress.failed) Text("Failed."),
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
