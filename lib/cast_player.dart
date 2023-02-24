import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'cast_info.dart';
import 'cast_list.dart';

/*-------------------------------------*/

class _Player extends ChangeNotifier {
  final player = AudioPlayer();
  CastInfo? lastSetFile;

  void setLastSetFile(CastInfo castInfo) {
    this.lastSetFile = castInfo;
    notifyListeners();
  }
}

/*-------------------------------------*/

class CastPlayer extends StatelessWidget {
  const CastPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _Player(),
      child: Column(
        children: [
          SizedBox(height: 10),
          Expanded(child: _CastListView()),
          Divider(),
          _PlayController(),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

/*-------------------------------------*/

//ignore: must_be_immutable
class _CastListView extends StatelessWidget {
  TapDownDetails? tapDownDetails;

  _CastListView();

  void deleteHandler(
      BuildContext context, CastList castList, CastInfo castInfo) {
    //HACK: This use of `Future` is a hack.
    //ref: |https://stackoverflow.com/questions/69568862/flutter-showdialog-is-not-shown-on-popupmenuitem-tap|
    Future.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (context) => Dialog(
                    child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          "Do you really want to delete `${castInfo.title} / ${castInfo.author}`?"),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          SizedBox(width: 20),
                          OutlinedButton(
                            child: Text('Yes'),
                            onPressed: () {
                              castList.deleteById(castInfo.id);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ))));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CastList>(
      builder: (context, castList, child) {
        return ListView(
            children: castList.l.map((CastInfo e) {
          return InkWell(
              child: Card(
                  child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipRRect(child: Image.file(File(e.imgPath!))),
                ),
                title: Text(e.title),
                trailing: Text(e.author,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )),
              onTap: () {
                final p = Provider.of<_Player>(context, listen: false);
                p.player.setAudioSource(AudioSource.uri(Uri.file(e.filePath!),
                    tag: MediaItem(
                        title: e.title,
                        id: e.id,
                        artUri: Uri.file(e.imgPath!))));
                p.setLastSetFile(e);
                p.player.play();
              },
              onTapDown: (details) => this.tapDownDetails = details,
              onLongPress: () async {
                final dx = this.tapDownDetails!.globalPosition.dx;
                final dy = this.tapDownDetails!.globalPosition.dy;
                await showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(dx, dy, dx, dy),
                    color: Color.fromRGBO(90, 90, 90, 1),
                    items: [
                      PopupMenuItem(
                          child: Text("Delete"),
                          onTap: () => deleteHandler(context, castList, e)),
                      PopupMenuItem(child: Text("Cancel")),
                    ]);
              });
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

enum _PlayerState { playing, paused, completed }

class _PlayController extends StatefulWidget {
  const _PlayController();

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
    super.initState();
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

    const progressBarWidth = 350.0;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
              width: progressBarWidth * 0.7,
              height: progressBarWidth * 0.7,
              child: Image.file(File(p.lastSetFile!.imgPath!))),
          SizedBox(height: 10),
          Text(p.lastSetFile!.title),
          Text(p.lastSetFile!.author),
          SizedBox(height: 10),
          SizedBox(
            width: progressBarWidth,
            height: 10,
            child: InkWell(
                child: LinearProgressIndicator(
                  value: cur.inMilliseconds / total.inMilliseconds,
                  color: Color.fromRGBO(200, 200, 200, 1),
                ),
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
