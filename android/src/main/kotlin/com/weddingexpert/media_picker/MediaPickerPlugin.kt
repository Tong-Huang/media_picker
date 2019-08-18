package com.weddingexpert.media_picker

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ThumbnailUtils
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat;
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import net.kmxz.votive.Votive
import java.io.ByteArrayOutputStream
import java.io.IOException

const val REQUEST_CODE_MIN = 6910
const val REQUEST_CODE_MAX = 7910
typealias Asset = HashMap<String, Any>
typealias AssetsMap = HashMap<String, HashMap<String, Any>>
typealias AssetsList = ArrayList<HashMap<String, Any>>

class MediaPickerPlugin(val registrar: Registrar) : MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "media_picker")
      channel.setMethodCallHandler(MediaPickerPlugin(registrar))
    }
  }

  init {
    registrar.addRequestPermissionsResultListener { requestCode: Int, _: Array<out String>, grantResults: IntArray ->
      if (requestCode in REQUEST_CODE_MIN..REQUEST_CODE_MAX) {
        val callback = permissionCallbacks.remove(requestCode)
        if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
          callback?.first?.invoke(Unit)
        } else { // already removed anyway
          callback?.second?.invoke(Unit)
        }
      }
      false
    }
  }

  private val imageKeys = arrayOf(MediaStore.Images.Media.DISPLAY_NAME, // 显示的名字
    MediaStore.Images.Media.DATA, // 数据
    MediaStore.Images.Media.LONGITUDE, // 经度
    MediaStore.Images.Media._ID, // id
    MediaStore.Images.Media.MINI_THUMB_MAGIC, // id
    MediaStore.Images.Media.TITLE, // id
    MediaStore.Images.Media.BUCKET_ID, // dir id 目录
    MediaStore.Images.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
    MediaStore.Images.Media.WIDTH, // 宽
    MediaStore.Images.Media.HEIGHT, // 高
    MediaStore.Images.Media.DATE_TAKEN //日期
  )

  private val videoKeys = arrayOf(MediaStore.Video.Media.DISPLAY_NAME, // 显示的名字
    MediaStore.Video.Media.DATA, // 数据
    MediaStore.Video.Media.LONGITUDE, // 经度
    MediaStore.Video.Media._ID, // id
    MediaStore.Video.Media.MINI_THUMB_MAGIC, // id
    MediaStore.Video.Media.TITLE, // id
    MediaStore.Video.Media.BUCKET_ID, // dir id 目录
    MediaStore.Video.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
    MediaStore.Video.Media.DATE_TAKEN, //日期
    MediaStore.Video.Media.WIDTH, // 宽
    MediaStore.Video.Media.HEIGHT, // 高
    MediaStore.Video.Media.DURATION //时长
  )

  private val images = AssetsMap()
  private val videos = AssetsMap()
  private var lastRequestCode = REQUEST_CODE_MIN
  private var permissionCallbacks = mutableMapOf<Int, Pair<(Unit) -> Unit, ((Unit) -> Unit)>>()


  // check permission
  private fun requestPermission(result: Result) {
    withPermission(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE))
      .thenSimple {
        result.success(true)
      }
      .catchSimple {
        result.success(false)
      }
  }


  private fun withPermission(permissions: Array<String>) = Votive<Unit, Unit> { resolve, reject ->
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      var requirePermissions = arrayListOf<String>()
      for (permission in permissions) {
        if (ActivityCompat.checkSelfPermission(registrar.activity(), permission) != PackageManager.PERMISSION_GRANTED) {
          requirePermissions.add(permission)
        }
      }

      if (requirePermissions.isNotEmpty()) {
        val requestCode = lastRequestCode++
        if (lastRequestCode > REQUEST_CODE_MAX) {
          lastRequestCode = REQUEST_CODE_MIN
        }
        permissionCallbacks[requestCode] = Pair(resolve, reject)
        ActivityCompat.requestPermissions(registrar.activity(), permissions, requestCode)
      }
      resolve(Unit)
    } else {
      resolve(Unit)
    }
  }


  // thumbDataWithSize
  private fun getThumbData(id: String, width: Double?, height: Double?): ByteArray? {
    var bitmap: Bitmap?
    val bos = ByteArrayOutputStream()
    if (images.contains(id)) {
      var asset = images[id]
      bitmap = assetsToBitmap(asset!!["path"] as String)

      if (bitmap == null) {
        return null
      }
    } else {
      var asset = videos[id]
      bitmap = ThumbnailUtils.createVideoThumbnail(asset!!["path"] as String, MediaStore.Images.Thumbnails.MINI_KIND)
    }

    var w = width?.toInt()
    var h = height?.toInt()
    if (w == null || h == null) {
      w = bitmap!!.width
      h = bitmap!!.height
    } else {
      val scale = 1.0 * bitmap!!.width / bitmap!!.height
      h = Math.round(w / scale).toInt()
    }

    val max = Math.max(w, h)
    if (max > 512) {
      val scale = 512f / max
      w = Math.round(scale * w)
      h = Math.round(scale * h)
    }
    bitmap = Bitmap.createScaledBitmap(bitmap, w, h, true)
    bitmap?.compress(Bitmap.CompressFormat.JPEG, 100, bos)
    return bos.toByteArray()
  }

  private fun assetsToBitmap(filePath: String): Bitmap? {
    return try {
      BitmapFactory.decodeFile(filePath)
    } catch (e: IOException) {
      e.printStackTrace()
      null
    }
  }

  private fun getImages(): AssetsList {
    var assetsList = AssetsList()
    val assetsMap = AssetsMap()
    val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    val contentResolver = registrar.activity().contentResolver
    val cursor = MediaStore.Images.Media.query(contentResolver, imageUri, imageKeys, null, MediaStore.Images.Media.DATE_TAKEN)

    if (cursor.count == 0) {
      cursor.close()
      return assetsList
    }

    cursor.moveToLast()
    do {
      val id = cursor.getString(cursor.getColumnIndex(MediaStore.Images.Media._ID))
      val path = cursor.getString(cursor.getColumnIndex(MediaStore.Images.Media.DATA))
      val width = cursor.getInt(cursor.getColumnIndex(MediaStore.Images.Media.WIDTH))
      val height = cursor.getInt(cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT))
      var asset = Asset()
      asset["id"] = id
      asset["path"] = path
      asset["width"] = width
      asset["height"] = height
      asset["type"] = "image"
      assetsList.add(asset)
      assetsMap[id] = asset
    } while (cursor.moveToPrevious())
    cursor.close()


    images.clear()
    images.putAll(assetsMap)
    return assetsList
  }

  private fun getVideos(): AssetsList {
    var assetsList = AssetsList()
    val assetsMap = AssetsMap()
    val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
    val contentResolver = registrar.activity().contentResolver
    val cursor = MediaStore.Images.Media.query(contentResolver, videoUri, videoKeys, null, MediaStore.Video.Media.DATE_TAKEN)

    if (cursor.count == 0) {
      cursor.close()
      return assetsList
    }

    cursor.moveToLast()
    do {
      val id = cursor.getString(cursor.getColumnIndex(MediaStore.Video.Media._ID))
      val path = cursor.getString(cursor.getColumnIndex(MediaStore.Video.Media.DATA))
      val width = cursor.getInt(cursor.getColumnIndex(MediaStore.Video.Media.WIDTH))
      val height = cursor.getInt(cursor.getColumnIndex(MediaStore.Video.Media.HEIGHT))
      val duration = cursor.getLong(cursor.getColumnIndex(MediaStore.Video.Media.DURATION))
      var asset = Asset()
      asset["id"] = id
      asset["path"] = path
      asset["width"] = width
      asset["height"] = height
      asset["duration"] = duration
      asset["type"] = "video"
      assetsList.add(asset)
      assetsMap[id] = asset
    } while (cursor.moveToPrevious())
    cursor.close()

    videos.clear()
    videos.putAll(assetsMap)
    return assetsList
  }


  override fun onMethodCall(call: MethodCall, result: Result) {
    when {
      call.method == "requestPermission" -> {
        requestPermission(result)
      }
      call.method == "getImages" -> {
        val imageIds = getImages()
        result.success(imageIds)
      }
      call.method == "getVideos" -> {
        val videoIds = getVideos()
        result.success(videoIds)
      }
      call.method == "getAssetPath" -> {
        val id = call.argument<String>("id")
        var asset = images[id]
        if (asset == null) { asset = videos[id] }
        result.success(asset!!["path"] as String)
      }
      call.method == "getThumbData" -> {
        val id = call.argument<String>("id")
        val width = call.argument<Double>("width")
        val height = call.argument<Double>("height")
        result.success(getThumbData(id!!, width, height))
      }
      else -> result.notImplemented()
    }
  }
}
