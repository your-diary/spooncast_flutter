import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'cast_list.dart';

/*-------------------------------------*/

class _CastInfo {
  final String id;
  final String author;
  final String title;
  final String voiceURL;
  final String fileExtension;

  _CastInfo({
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

Future<String> _getCastID(String shortenURL) async {
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

Future<_CastInfo> _getCastInfo(String castID) async {
  final uri = Uri.parse("https://jp-api.spooncast.net/casts/${castID}/");
  final res = await get(uri);
  assert(res.statusCode == 200);
  final m = jsonDecode(utf8.decode(res.bodyBytes));
  return _CastInfo(
    id: castID,
    author: m["results"][0]["author"]["nickname"],
    title: m["results"][0]["title"],
    voiceURL: m["results"][0]["voice_url"],
    fileExtension:
        m["results"][0]["voice_url"].replaceFirst(RegExp(r".*\."), ""),
  );
}

Future<void> _downloadCast(_CastInfo castInfo) async {
  final uri = Uri.parse(castInfo.voiceURL);
  final res = await get(uri);
  assert(res.statusCode == 200);
  final appDocDir = (await getApplicationDocumentsDirectory()).path;
  await File("${appDocDir}/${castInfo.id}.${castInfo.fileExtension}")
      .writeAsBytes(res.bodyBytes);
}

//The argument is a shorten URL like "https://u8kv3.app.goo.gl/Q4izq".
Future<_CastInfo> _downloadCastFromURL(String shortenURL) async {
  final castID = await _getCastID(shortenURL);
  debugPrint(castID);

  final castInfo = await _getCastInfo(castID);
  debugPrint(castInfo.toString());

  await _downloadCast(castInfo);

  return castInfo;
}

/*-------------------------------------*/

class CastDownloader extends StatefulWidget {
  const CastDownloader({
    super.key,
  });

  @override
  State<CastDownloader> createState() => _CastDownloaderState();
}

enum _DownloadProgress { notInProgress, inProgress, completed, failed }

class _CastDownloaderState extends State<CastDownloader> {
  _DownloadProgress isDownloading = _DownloadProgress.notInProgress;
  String input = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Input a share-URL like `https://u8kv3.app.goo.gl/abcde` and tap `Download` to download a cast.',
                      style: TextStyle(color: Colors.grey))),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      maxLines: null, onChanged: (s) => this.input = s.trim())),
              SizedBox(width: 20),
              OutlinedButton(
                  child: Text("Download"),
                  onPressed: (this.isDownloading ==
                          _DownloadProgress.inProgress)
                      ? null
                      : () async {
                          this.setState(() => this.isDownloading =
                              _DownloadProgress.inProgress);
                          try {
                            await _downloadCastFromURL(this.input);
                            await Provider.of<CastList>(context, listen: false)
                                .update();
                            this.setState(() => this.isDownloading =
                                _DownloadProgress.completed);
                          } catch (e) {
                            debugPrint(e.toString());
                            this.setState(() =>
                                this.isDownloading = _DownloadProgress.failed);
                          }
                        }),
            ],
          ),
          if (this.isDownloading == _DownloadProgress.inProgress)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Downloading..."),
              ],
            ),
          if (this.isDownloading == _DownloadProgress.completed) Text("Done."),
          if (this.isDownloading == _DownloadProgress.failed) Text("Failed."),
        ],
      ),
    );
  }
}
