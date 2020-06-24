import 'package:flutter/material.dart';
import 'package:page_indicator/page_indicator.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FlyerDialog extends StatelessWidget {
  List<dynamic> _flyers;

  FlyerDialog(this._flyers);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          height: 500,
          padding: EdgeInsets.all(2),
          decoration: new BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: PageIndicatorContainer(
            pageView: PageView(
              children: <Widget>[]..addAll(_flyers.map((i) {
                  return getItem(i);
                })),
            ),
            length: _flyers.length,
            indicatorSelectorColor: Colors.grey.shade700,
          ),
        ),
        Positioned(
          child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
              }),
          right: 0,
        )
      ],
    );
  }

  Widget getItem(Map<String, dynamic> data) {
    if (data['media_type'] == 'video') {
      return YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: data['image'],
          flags: YoutubePlayerFlags(
            mute: false,
            autoPlay: true,
            disableDragSeek: true,
            enableCaption: false,
          ),
        ),
        showVideoProgressIndicator: true,
        onReady: () {
          //print('Player is ready.');
        },

      );
    } else {
      return Container(
        child: Image.network(
          data['image'],
          fit: BoxFit.contain,
        ),
        color: Colors.black,
      );
    }
  }
}
