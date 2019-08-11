import Flutter
import UIKit

public class SwiftMediaPickerPlugin: NSObject, FlutterPlugin {
  var imageInfos = [AssetDict]()
  var imageDict = [String: PHAsset]()
  var videoInfos = [AssetDict]()
  var videoDict = [String: PHAsset]()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "media_picker", binaryMessenger: registrar.messenger())
    let instance = SwiftMediaPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  
  private func requestPermission(result: @escaping FlutterResult) {
    let status = PHPhotoLibrary.authorizationStatus()
    if status == .notDetermined || status == .denied || status == .restricted {
      PHPhotoLibrary.requestAuthorization({ (status) in
        if status == .authorized {
          result(true)
        } else if status == .denied || status == .restricted{
          result(false)
        }
      })
    } else {
      result(true)
    }
  }

  private func getImages() -> [AssetDict] {
    let assets = fetchAssets(mediaType: PHAssetMediaType.image)
    imageInfos = assets.infos
    imageDict = assets.dict
    return imageInfos
  }
  
  private func getVideos() -> [AssetDict] {
    let assets = fetchAssets(mediaType: PHAssetMediaType.video)
    videoInfos = assets.infos
    videoDict = assets.dict
    return videoInfos
  }
  
  private func fetchAssets(mediaType: PHAssetMediaType) -> (infos: [AssetDict], dict: [String: PHAsset]) {
    var assetkeys = [String]()
    var assetInfos = [AssetDict]()
    var assetDict = [String: PHAsset]()
    let fetchCollectionsOptions = PHFetchOptions()
    let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular,options: fetchCollectionsOptions)
    for i in 0..<collections.count{
      let fetchAssetsOptions = PHFetchOptions()
      fetchAssetsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchAssetsOptions.predicate = NSPredicate(format: "mediaType = %d", mediaType.rawValue)
      let collection = collections[i]
      let assets = PHAsset.fetchAssets(in: collection, options: fetchAssetsOptions)
      if assets.count > 0{
        for i in 0..<assets.count {
          let asset = assets[i]
          let id = asset.localIdentifier
          let assetInfo = [
            "id": id,
            "width": asset.pixelWidth,
            "height": asset.pixelHeight,
            "duration": Int(asset.duration * 1000),
            "type": mediaType == PHAssetMediaType.image ? "image" : "video"
            ] as [String : AnyObject]
          if !assetkeys.contains(id) {
            assetkeys.append(id)
            assetInfos.append(assetInfo as [String : AnyObject])
            assetDict[id] = asset
          }
        }
      }
    }
    return (assetInfos, assetDict)
  }
  
  private func getAssetPath(id: String, result: @escaping FlutterResult) {
    var asset: PHAsset? = nil
    
    if imageDict[id] != nil {
      asset = imageDict[id]!
      let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
      options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
        return true
      }
      asset!.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
        result(contentEditingInput!.fullSizeImageURL?.absoluteString)
      })
    } else if (videoDict[id] != nil) {
      asset = videoDict[id]!
      let options: PHVideoRequestOptions = PHVideoRequestOptions()
      options.version = .current
      options.isNetworkAccessAllowed = true
      PHImageManager.default().requestAVAsset(forVideo: asset!, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
        if let urlAsset = asset as? AVURLAsset {
          let localVideoUrl: URL = urlAsset.url as URL
          result(localVideoUrl.absoluteString)
        } else {
          result(nil)
        }
      })
    }
    
    if asset == nil {
      result(nil)
      return
    }
  }
  
  private func getThumbData(id: String, result: @escaping FlutterResult, width: Double?, height: Double?) {
    var asset: PHAsset? = nil
    
    if imageDict[id] != nil {
      asset = imageDict[id]!
    } else if (videoDict[id] != nil) {
      asset = videoDict[id]!
    }
    
    if asset == nil {
      result(nil)
      return
    }
    
    let w = width == nil ? asset!.pixelWidth : Int(width!)
    let h = height == nil ? asset!.pixelHeight : Int(height!)
    
    var targetSize = CGSize(width: w, height: h)
    let maxValue = max(asset!.pixelWidth, asset!.pixelHeight)
    if (maxValue > 512) {
      let scale = 512 / Double(maxValue)
      let width = scale * Double(asset!.pixelWidth)
      let height = scale * Double(asset!.pixelHeight)
      targetSize = CGSize(width: width, height: height)
    }

    let manager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = true
    requestOptions.resizeMode = .fast
    requestOptions.deliveryMode = .highQualityFormat;
    
    manager.requestImage(for: asset!, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, info) -> Void in
      result(UIImageJPEGRepresentation(image!, 1));
    })
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // TODO: it should request permission
    var arguments: AssetDict
    if call.arguments != nil {
      arguments = call.arguments as! AssetDict
    } else {
      arguments = AssetDict()
    }
    
    switch call.method {
    case "requestPermission":
      requestPermission(result: result)
    case "getImages":
      result(getImages())
    case "getVideos":
      result(getVideos())
    case "getAssetPath":
      let id: String = arguments["id"] as! String
      getAssetPath(id: id, result: result)
    case "getThumbData":
      let id: String = arguments["id"] as! String
      let width: Double? = arguments["width"] as? Double
      let height: Double? = arguments["height"] as? Double
      getThumbData(id: id, result: result, width: width, height: height);
    default:
      result(FlutterError(code: "404", message: "No such method", details: nil))
    }
  }
}
