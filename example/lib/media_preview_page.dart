import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker/media_picker.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewPage extends StatefulWidget {
  final AssetType type;
  final String path;

  MediaPreviewPage({this.type, this.path});

  @override
  _MediaPreviewPageState createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.type == AssetType.video) {
      _controller = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MediaPreviewPage'),
      ),
      body: Center(
          child: widget.type == AssetType.image
              ? Image.file(File(widget.path))
              : _controller.value.initialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Container()),
      floatingActionButton: widget.type == AssetType.video
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
