import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_picker/media_picker.dart';
import 'package:media_picker_example/media_preview_page.dart';

class MediaItem extends StatelessWidget {
  final Asset asset;
  final Size size;

  MediaItem({this.asset, this.size});

  Future<void> _previewAssetDetail(BuildContext context) async {
    final String path = await MediaPicker.getAssetPath(this.asset.id);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MediaPreviewPage(type: this.asset.type, path: path),
        ));
  }

  @override
  Widget build(BuildContext context) {
    String text = '';
    if (this.asset.type == AssetType.video) {
      double duration = this.asset.duration.toDouble() ?? 0.0;
      duration /= 1000; //convert to seconds
      int minutes = (duration / 60).round();
      int seconds = (duration % 60).round();
      String minutesTxt = minutes > 10 ? "$minutes" : "0$minutes";
      String secondsTxt = seconds > 10 ? "$seconds" : "0$seconds";
      text = '$minutesTxt:$secondsTxt';
    }
    return FutureBuilder<Uint8List>(
      future: MediaPicker.getThumbData(this.asset.id,
          width: size.width, height: size.height),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return InkWell(
            onTap: () => _previewAssetDetail(context), // preview later
            child: Stack(
              children: <Widget>[
                Image.memory(
                  snapshot.data,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                IgnorePointer(
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '$text',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
