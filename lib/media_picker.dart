import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:media_picker/helper/mutex.dart';

part './asset.dart';
part './asset_cache.dart';

class MediaPicker {
  static const MethodChannel _channel = const MethodChannel('media_picker');

  static Future<bool> requestPermission() async {
    final dynamic hasPermission =
        await _channel.invokeMethod('requestPermission');
    return hasPermission;
  }

  static List<Asset> getImagesFromCache() {
    return AssetCache.getData('images');
  }

  static Future<List<Asset>> getImages() async {
    final List<Asset> assets = [];
    final List<dynamic> images = await _channel.invokeMethod('getImages');
    for (var image in images) {
      assets.add(Asset.fromJson(image));
    }
    AssetCache.setData('images', assets);
    return assets;
  }

  static List<Asset> getVideosFromCache() {
    return AssetCache.getData('videos');
  }

  static Future<List<Asset>> getVideos() async {
    final List<Asset> assets = [];
    final List<dynamic> videos = await _channel.invokeMethod('getVideos');
    for (var video in videos) {
      assets.add(Asset.fromJson(video));
    }
    AssetCache.setData('videos', assets);
    return assets;
  }

  static Future<String> getAssetPath(String assetId) async {
    final String path =
        await _channel.invokeMethod('getAssetPath', {'id': assetId});
    return path;
  }

  static Future<Uint8List> getThumbData(String assetId,
      {int width, int height}) async {
    var assetCache = AssetCache.getData<Uint8List>(assetId);
    if (assetCache == null) {
      await Mutex.lock();
      assetCache = await _channel.invokeMethod('getThumbData', {
        'id': assetId,
        'height': height,
        'width': width,
      });
      await Mutex.unlock();
      AssetCache.setData(assetId, assetCache);
    }
    return assetCache;
  }
}
