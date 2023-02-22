import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'cast_list.dart';

/*-------------------------------------*/

class _Player extends ChangeNotifier {
  final player = AudioPlayer();
  String? lastSetFile;

  void setLastSetFile(String s) {
    this.lastSetFile = s.replaceFirst(RegExp(r".*/"), "");
    notifyListeners();
  }
}

/*-------------------------------------*/

class CastPlayer extends StatelessWidget {
  CastPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _Player(),
      child: Column(
        children: [
          SizedBox(height: 10),
          Expanded(child: CastListView()),
          Expanded(
            child: _PlayController(),
          ),
        ],
      ),
    );
  }
}

/*-------------------------------------*/

class CastListView extends StatelessWidget {
  const CastListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CastList>(
      builder: (_context, castFiles, _child) {
        return ListView(
            children: castFiles.l.map((e) {
          return Card(
              child: ListTile(
                  title: Text(e.replaceFirst(RegExp(".*/"), "")),
                  onTap: () {
                    final p = Provider.of<_Player>(context, listen: false);
                    p.player.setFilePath(e);
                    p.setLastSetFile(e);
                    p.player.play();
                  }));
        }).toList());
      },
    );
  }
}

/*-------------------------------------*/

String _prettyPrintDuration(Duration d) {
  final s = d.inSeconds;
  final hours = s ~/ 3600;
  final minutes = (s - hours * 3600) ~/ 60;
  final seconds = s - hours * 3600 - minutes * 60;
  return hours.toString().padLeft(2, "0") +
      ":" +
      minutes.toString().padLeft(2, "0") +
      ":" +
      seconds.toString().padLeft(2, "0");
}

enum _PlayerState { noData, playing, paused, completed }

class _PlayController extends StatefulWidget {
  const _PlayController({
    super.key,
  });

  @override
  State<_PlayController> createState() => _PlayControllerState();
}

class _PlayControllerState extends State<_PlayController> {
  late final Timer timer;
  final updateIntervalSec = 1;

  @override
  void initState() {
    this.timer =
        Timer.periodic(Duration(seconds: this.updateIntervalSec), (Timer t) {
      this.setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<_Player>(context, listen: false);

    if (p.lastSetFile == null) {
      return Text("Not playing.");
    }

    final cur = p.player.position;
    final total = p.player.duration!;

    final _PlayerState playerState;
    if (!p.player.playing) {
      playerState = _PlayerState.paused;
    } else if (cur == total) {
      playerState = _PlayerState.completed;
    } else {
      playerState = _PlayerState.playing;
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(p.lastSetFile!),
          SizedBox(height: 10),
          LinearProgressIndicator(
              value: cur.inMilliseconds / total.inMilliseconds),
          SizedBox(height: 10),
          Text("${_prettyPrintDuration(cur)} / ${_prettyPrintDuration(total)}"),
          SizedBox(height: 10),
          if (playerState == _PlayerState.playing)
            IconButton(
                icon: Icon(Icons.pause),
                onPressed: () async {
                  await p.player.pause();
                  this.setState(() {});
                })
          else if (playerState == _PlayerState.completed)
            IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () async {
                  p.player.seek(Duration.zero);
                  p.player.play();
                  this.setState(() {});
                })
          else if (playerState == _PlayerState.paused)
            IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () async {
                  p.player.play();
                  this.setState(() {});
                })
          else
            throw UnimplementedError()
        ],
      ),
    );
  }
}

//bg再生
//volume
//loop
//seek

/*-------------------------------------*/