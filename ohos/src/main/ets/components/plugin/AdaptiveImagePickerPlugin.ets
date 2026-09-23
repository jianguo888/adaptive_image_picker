import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  AbilityAware,
  AbilityPluginBinding,
} from '@ohos/flutter_ohos';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import cameraPicker from '@ohos.multimedia.cameraPicker';
import camera from '@ohos.multimedia.camera';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import deviceInfo from '@ohos.deviceInfo';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

/** AdaptiveImagePickerPlugin **/
export default class AdaptiveImagePickerPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private pending: boolean = false;

  constructor() {
  }

  getUniqueClassName(): string {
    return "AdaptiveImagePickerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "adaptive_image_picker");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
      this.channel = null
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context as common.UIAbilityContext
  }

  onDetachedFromAbility(): void {
    this.context = null
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "getPlatformVersion") {
      result.success("OpenHarmony " + deviceInfo.osFullName)
    } else if (call.method == "pickImages") {
      this.handlePickImages(call, result)
    } else if (call.method == "takePhoto") {
      this.handleTakePhoto(call, result)
    } else {
      result.notImplemented()
    }
  }

  // MARK: - pickImages

  private handlePickImages(call: MethodCall, result: MethodResult): void {
    if (this.pending) {
      result.error("ALREADY_ACTIVE", "An image picking session is already in progress.", null)
      return
    }
    if (this.context == null) {
      result.error("NO_ACTIVITY", "Ability is not available to pick images.", null)
      return
    }

    const isMultiple: boolean = call.argument("isMultiple") ?? false
    const maxCount: number = call.argument("maxCount") ?? 1
    const mediaType: string = call.argument("mediaType") ?? "image"

    this.pending = true

    try {
      const options = new photoAccessHelper.PhotoSelectOptions()
      switch (mediaType) {
        case "video":
          options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE
          break
        case "all":
          options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE
          break
        default:
          options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
          break
      }
      options.maxSelectNumber = (isMultiple && maxCount > 1) ? maxCount : 1

      const picker = new photoAccessHelper.PhotoViewPicker()
      picker.select(options)
        .then((selectResult: photoAccessHelper.PhotoSelectResult) => {
          const uris: Array<string> = selectResult.photoUris ?? []
          if (uris.length == 0) {
            this.pending = false
            result.success([])
            return
          }
          const fileList: Array<Record<string, Object>> = []
          for (let i = 0; i < uris.length; i++) {
            const info = this.copyUriToCache(uris[i])
            if (info != null) {
              fileList.push(info)
            }
          }
          this.pending = false
          result.success(fileList)
        })
        .catch((err: BusinessError) => {
          this.pending = false
          result.error("PICK_FAILED", `Failed to launch photo picker: ${err.message}`, null)
        })
    } catch (err) {
      this.pending = false
      result.error("PICK_FAILED", `Failed to launch photo picker: ${(err as BusinessError).message}`, null)
    }
  }

  // MARK: - takePhoto

  private handleTakePhoto(call: MethodCall, result: MethodResult): void {
    if (this.pending) {
      result.error("ALREADY_ACTIVE", "A media session is already in progress.", null)
      return
    }
    if (this.context == null) {
      result.error("NO_ACTIVITY", "Ability is not available to take photo.", null)
      return
    }

    const preferredCamera: string = call.argument("preferredCameraDevice") ?? "rear"
    const cameraPosition: camera.CameraPosition =
      preferredCamera == "front" ? camera.CameraPosition.CAMERA_POSITION_FRONT : camera.CameraPosition.CAMERA_POSITION_BACK

    this.pending = true

    try {
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: cameraPosition,
      }
      cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.PHOTO], profile)
        .then((pickerResult: cameraPicker.PickerResult) => {
          this.pending = false
          if (pickerResult.resultCode != 0 || pickerResult.resultUri == null || pickerResult.resultUri.length == 0) {
            // User cancelled or capture failed
            result.success(null)
            return
          }
          const info = this.copyUriToCache(pickerResult.resultUri)
          result.success(info)
        })
        .catch((err: BusinessError) => {
          this.pending = false
          result.error("CAMERA_FAILED", `Failed to launch camera: ${err.message}`, null)
        })
    } catch (err) {
      this.pending = false
      result.error("CAMERA_FAILED", `Failed to launch camera: ${(err as BusinessError).message}`, null)
    }
  }

  // MARK: - Helpers

  /**
   * Copies the picked media URI into the application cache directory and
   * returns a metadata map consistent with the Android/iOS implementations.
   */
  private copyUriToCache(uri: string): Record<string, Object> | null {
    if (this.context == null) {
      return null
    }
    let srcFile: fs.File | null = null
    try {
      const name: string = this.extractFileName(uri)
      const mimeType: string = this.inferMimeType(name)

      const cacheDir: string = `${this.context.cacheDir}/adaptive_picker`
      if (!fs.accessSync(cacheDir)) {
        fs.mkdirSync(cacheDir, true)
      }
      const destPath: string = `${cacheDir}/${name}`

      srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      const stat = fs.statSync(srcFile.fd)
      const size: number = stat.size
      const lastModified: number = stat.mtime * 1000

      // Remove the previous file if it exists so the copy always reflects the latest pick.
      if (fs.accessSync(destPath)) {
        fs.unlinkSync(destPath)
      }
      fs.copyFileSync(srcFile.fd, destPath)

      const info: Record<string, Object> = {
        "path": destPath,
        "name": name,
        "size": size,
        "mimeType": mimeType,
        "lastModified": lastModified,
      }
      return info
    } catch (err) {
      return null
    } finally {
      if (srcFile != null) {
        try {
          fs.closeSync(srcFile)
        } catch (closeErr) {
          // ignore
        }
      }
    }
  }

  private extractFileName(uri: string): string {
    let path: string = uri
    try {
      path = new fileUri.FileUri(uri).path
    } catch (err) {
      path = uri
    }
    const normalized: string = path.replace(/\\/g, '/')
    const idx: number = normalized.lastIndexOf('/')
    const raw: string = idx >= 0 ? normalized.substring(idx + 1) : normalized
    if (raw.length > 0 && raw.indexOf('.') > 0) {
      return raw
    }
    return `picked_image_${Date.now()}.jpg`
  }

  private inferMimeType(fileName: string): string {
    const idx: number = fileName.lastIndexOf('.')
    const ext: string = idx >= 0 ? fileName.substring(idx + 1).toLowerCase() : ''
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg'
      case 'png':
        return 'image/png'
      case 'webp':
        return 'image/webp'
      case 'gif':
        return 'image/gif'
      case 'bmp':
        return 'image/bmp'
      case 'heic':
        return 'image/heic'
      case 'heif':
        return 'image/heif'
      case 'mp4':
        return 'video/mp4'
      case 'mov':
        return 'video/quicktime'
      case 'avi':
        return 'video/x-msvideo'
      default:
        return 'application/octet-stream'
    }
  }
}
