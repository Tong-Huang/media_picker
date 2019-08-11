import 'package:flutter/material.dart';
import 'package:media_picker/media_picker.dart';

import 'media_item.dart';

class MediasPage extends StatefulWidget {
  final AssetType assetType;

  MediasPage({this.assetType = AssetType.image});

  @override
  _MediasPageState createState() => _MediasPageState();
}

class _MediasPageState extends State<MediasPage> {
  List<Asset> assets = <Asset>[];
  bool granted = false;

  @override
  void initState() {
    super.initState();
    MediaPicker.requestPermission().then((hasPermission) {
      if (hasPermission) {
        granted = true;
        if (widget.assetType == AssetType.image) {
          initImages();
        } else {
          initVideos();
        }
      }
    });
  }

  Future<void> initImages() async {
    try {
      List<Asset> images = await MediaPicker.getImages();
      setState(() {
        assets = images;
      });
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  Future<void> initVideos() async {
    try {
      List<Asset> videos = await MediaPicker.getVideos();
      setState(() {
        assets = videos;
      });
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: const Text('Videos Page')),
      body: granted
          ? GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (BuildContext context, int index) =>
                  MediaItem(asset: assets[index], size: size),
              itemCount: assets.length,
            )
          : Center(child: Text('No permission')),
    );
  }
}
