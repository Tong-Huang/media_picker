import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/services.dart';

part './asset.dart';
part './asset_cache.dart';

class MediaPicker {
  static const MethodChannel _channel = const MethodChannel('media_picker');

  static Future<bool> requestPermission() async {
    final dynamic hasPermission =
        await _channel.invokeMethod('requestPermission');
    return hasPermission;
  }

  static Future<List<Asset>> getImages() async {
    final List<Asset> assets = [];
    final List<dynamic> images = await _channel.invokeMethod('getImages');
    for (var image in images) {
      assets.add(Asset.fromJson(image));
    }
    return assets;
  }

  static Future<List<Asset>> getVideos() async {
    final List<Asset> assets = [];
    final List<dynamic> videos = await _channel.invokeMethod('getVideos');
    for (var video in videos) {
      assets.add(Asset.fromJson(video));
    }
    return assets;
  }

  static Future<String> getAssetPath(String assetId) async {
    final String path =
        await _channel.invokeMethod('getAssetPath', {'id': assetId});
    return path;
  }

  static Future<Uint8List> getThumbData(String assetId,
      {double width, double height}) async {
    Uint8List assetCache = AssetCache.getData(assetId);
    if (assetCache == null) {
      assetCache = await _channel.invokeMethod('getThumbData', {
        'id': assetId,
        'height': height,
        'width': width,
      });
      AssetCache.setData(assetId, assetCache);
    }
    return assetCache;
  }
}
