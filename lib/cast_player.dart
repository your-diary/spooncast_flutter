import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'cast_info.dart';
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
            children: castFiles.l.map((CastInfo e) {
          final baseName = e.filePath!.replaceFirst(RegExp(".*/"), "");
          return Card(
              child: ListTile(
                  title: Text(e.title),
                  trailing: Text(e.author,
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  onTap: () {
                    final p = Provider.of<_Player>(context, listen: false);
                    p.player.setAudioSource(AudioSource.uri(
                        Uri.file(e.filePath!),
                        tag: MediaItem(title: e.title, id: e.id)));
                    p.setLastSetFile(e.filePath!);
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

class _PlayControllerState extends State<_PlayController>
    with AutomaticKeepAliveClientMixin {
  late final Timer timer;
  final updateIntervalSec = 1;

  //for `AutomaticKeepAliveClientMixin`
  @override
  bool wantKeepAlive = true;

  @override
  void initState() {
    this.timer =
        Timer.periodic(Duration(seconds: this.updateIntervalSec), (Timer t) {
      this.setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); //for `AutomaticKeepAliveClientMixin`

    final p = Provider.of<_Player>(context, listen: false);

    if (p.lastSetFile == null || p.player.duration == null) {
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

    final progressBarWidth = 350.0;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(p.lastSetFile!),
          SizedBox(height: 10),
          Container(
            width: progressBarWidth,
            height: 10,
            child: InkWell(
                child: LinearProgressIndicator(
                    value: cur.inMilliseconds / total.inMilliseconds),
                onTapDown: (tapUpDetails) {
                  final dx = tapUpDetails.localPosition.dx;
                  p.player.seek(Duration(
                      milliseconds:
                          (total.inMilliseconds * (dx / progressBarWidth))
                              .toInt()));
                  this.setState(() {});
                }),
          ),
          SizedBox(height: 10),
          Text("${_prettyPrintDuration(cur)} / ${_prettyPrintDuration(total)}"),
          SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: Opacity(
              opacity: (p.player.loopMode == LoopMode.off) ? 0.3 : 1.0,
              child: IconButton(
                  icon: Icon(Icons.loop),
                  onPressed: () async {
                    if (p.player.loopMode == LoopMode.off) {
                      await p.player.setLoopMode(LoopMode.one);
                    } else {
                      await p.player.setLoopMode(LoopMode.off);
                    }
                    this.setState(() {});
                  }),
            )),
            if (playerState == _PlayerState.playing)
              Expanded(
                child: IconButton(
                    icon: Icon(Icons.pause),
                    onPressed: () async {
                      await p.player.pause();
                      this.setState(() {});
                    }),
              )
            else if (playerState == _PlayerState.completed)
              Expanded(
                child: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () async {
                      p.player.seek(Duration.zero);
                      p.player.play();
                      this.setState(() {});
                    }),
              )
            else if (playerState == _PlayerState.paused)
              Expanded(
                child: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () async {
                      p.player.play();
                      this.setState(() {});
                    }),
              )
            else
              throw UnimplementedError(),
            Spacer(),
          ]),
        ],
      ),
    );
  }
}

/*-------------------------------------*/
