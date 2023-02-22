import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'cast_list.dart';

class CastPlayer extends StatelessWidget {
  final player = AudioPlayer();

  CastPlayer({
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
