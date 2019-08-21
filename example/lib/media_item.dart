import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_picker/media_picker.dart';
import 'package:media_picker_example/media_preview_page.dart';

class MediaItem extends StatelessWidget {
  final Asset asset;
  final Size size;

  MediaItem({this.asset, this.size});

  Future<void> _previewAssetDetail(BuildContext context) async {
    final String path = await MediaPicker.getAssetPath(asset.id);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewPage(type: asset.type, path: path),
        ));
  }

  @override
  Widget build(BuildContext context) {
    String text = '';
    if (asset.type == AssetType.video) {
      double duration = asset.duration.toDouble() ?? 0.0;
      duration /= 1000; //convert to seconds
      int minutes = (duration / 60).round();
      int seconds = (duration % 60).round();
      String minutesTxt = minutes > 10 ? "$minutes" : "0$minutes";
      String secondsTxt = seconds > 10 ? "$seconds" : "0$seconds";
      text = '$minutesTxt:$secondsTxt';
    }
    if (asset.thumbData != null) {
      return _buildItem(context, asset.thumbData, text);
    }
    return FutureBuilder<Uint8List>(
      future: MediaPicker.getThumbData(asset.id, width: 256, height: 256),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return _buildItem(context, snapshot.data, text);
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  InkWell _buildItem(BuildContext context, Uint8List thumbData, String text) {
    return InkWell(
      onTap: () => _previewAssetDetail(context), // preview later
      child: Stack(
        children: <Widget>[
          Image.memory(
            thumbData,
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
}
