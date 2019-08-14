part of './media_picker.dart';

enum AssetType { image, video }

final assetTypeValues =
    EnumValues({'image': AssetType.image, 'video': AssetType.video});

class Asset {
  String id;
  int width;
  int height;
  int duration;
  AssetType type;

  Asset({
    this.id,
    this.width,
    this.height,
    this.duration,
    this.type,
  });

  Uint8List get thumbData {
    return AssetCache.getData(id);
  }

  factory Asset.fromJson(Map<dynamic, dynamic> json) => Asset(
        id: json['id'] == null ? null : json['id'],
        width: json['width'] == null ? null : json['width'],
        height: json['height'] == null ? null : json['height'],
        duration: json['duration'] == null ? null : json['duration'],
        type: json['type'] == null ? null : assetTypeValues.map[json['type']],
      );
}

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap ??= map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
