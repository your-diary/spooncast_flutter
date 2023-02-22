import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'cast_info.dart';
import 'cast_list.dart';

/*-------------------------------------*/

Future<String> _getCastID(String shortenURL) async {
  final client = Client();

  final uri = Uri.parse(shortenURL);

  var req = Request("GET", uri);
  req.followRedirects = false;

  final res = await client.send(req);
  client.close();
  assert(res.isRedirect);
  assert(res.headers.containsKey("location"));

  return RegExp(r"spooncast.net/jp/cast/(\d+)")
      .firstMatch(res.headers["location"]!)!
      .group(1)!;
}

Future<CastInfo> _getCastInfo(String castID) async {
  final uri = Uri.parse("https://jp-api.spooncast.net/casts/${castID}/");
  final res = await get(uri);
  assert(res.statusCode == 200);
  final m = jsonDecode(utf8.decode(res.bodyBytes));
  return CastInfo(
    id: castID,
    author: m["results"][0]["author"]["nickname"],
    title: m["results"][0]["title"],
    voiceURL: m["results"][0]["voice_url"],
    imgURL: m["results"][0]["img_url"],
    downloadedDate: DateTime.now(),
  );
}

Future<String> _downloadCast(CastInfo castInfo) async {
  final uri = Uri.parse(castInfo.voiceURL);
  final res = await get(uri);
  assert(res.statusCode == 200);
  final appDocDir = (await getApplicationDocumentsDirectory()).path;
  final path = "${appDocDir}/${castInfo.id}.${extension(castInfo.voiceURL)}";
  await File(path).writeAsBytes(res.bodyBytes);
  return path;
}

Future<String> _downloadImg(CastInfo castInfo) async {
  final uri = Uri.parse(castInfo.imgURL);
  final res = await get(uri);
  assert(res.statusCode == 200);
  final appDocDir = (await getApplicationDocumentsDirectory()).path;
  final path = "${appDocDir}/${castInfo.id}.${extension(castInfo.imgURL)}";
  await File(path).writeAsBytes(res.bodyBytes);
  return path;
}

//The argument is a shorten URL like "https://u8kv3.app.goo.gl/Q4izq".
Future<CastInfo> _downloadCastFromURL(String shortenURL) async {
  if (!shortenURL.startsWith("https://u8kv3.app.goo.gl/")) {
    throw ArgumentError("Invalid URL.");
  }

  final castID = await _getCastID(shortenURL);
  debugPrint(castID);

  final castInfo = await _getCastInfo(castID);
  debugPrint(castInfo.toString());

  castInfo.filePath = await _downloadCast(castInfo);
  castInfo.imgPath = await _downloadImg(castInfo);

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
  String failureReason = "";

  final textEditingContoller = TextEditingController();

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
                controller: this.textEditingContoller,
                keyboardType: TextInputType.url,
                maxLines: null,
                onChanged: (s) => this.setState(() {
                  //Why splits and takes the last?
                  //The reason is when you copy a shorten URL from iOS app rather than web version, the copied content consists of a trailing explanation and a URL.
                  //Let user manually extract a URL is tedious, so we automate it.
                  this.input = s.trim();
                  if (this.input.isNotEmpty) {
                    this.input = this.input.split(RegExp(r"\s")).last;
                  }
                }),
                decoration: InputDecoration(
                  hintText: 'URL',
                  suffixIcon: IconButton(
                    onPressed: () {
                      this.textEditingContoller.clear();
                      this.setState(() {
                        this.input = "";
                      });
                    },
                    icon: Icon(Icons.clear),
                  ),
                ),
              )),
              SizedBox(width: 20),
              OutlinedButton(
                  child: Text("Download"),
                  onPressed: (this.input.isEmpty ||
                          (this.isDownloading == _DownloadProgress.inProgress))
                      ? null
                      : () async {
                          this.setState(() => this.isDownloading =
                              _DownloadProgress.inProgress);
                          try {
                            final castInfo =
                                await _downloadCastFromURL(this.input);
                            if (context.mounted) {
                              await Provider.of<CastList>(context,
                                      listen: false)
                                  .insert(castInfo);
                            }
                            this.setState(() => this.isDownloading =
                                _DownloadProgress.completed);
                          } catch (e) {
                            debugPrint(e.toString());
                            this.setState(() {
                              this.isDownloading = _DownloadProgress.failed;
                              this.failureReason = e.toString();
                            });
                          }
                        }),
            ],
          ),
          SizedBox(height: 20),
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
          if (this.isDownloading == _DownloadProgress.failed)
            Text("Failed: ${this.failureReason}"),
        ],
      ),
    );
  }
}
