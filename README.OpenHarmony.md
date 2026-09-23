<div style="text-align: center"><h1>adaptive_image_picker</h1></div>

This project is developed based on [adaptive_image_picker](https://github.com/Karan8686/adaptive_image_picker).

## Introduction

adaptive_image_picker is an adaptive image picker for OpenHarmony, providing zero-permission image selection, pure-Dart cropping and binary-search compression, and integrating the OpenHarmony system photo picker and camera picker.

On the OpenHarmony platform, this library invokes the system-provided picker components to select images and take photos. The application does not need to request media read/write permissions, nor does it need to implement a selection UI itself.

## Download and Installation

Add the dependency to your project's `pubspec.yaml`:

```yaml
dependencies:
  adaptive_image_picker:
    git:
      url: https://github.com/jianguo888/adaptive_image_picker
      # ref: Select the TAG version that matches your Flutter framework version from the table below
      ref: 1.0.2-ohos-1.0.0-beta.1
```

Run the following command to fetch the dependency:

```bash
flutter pub get
```

### TAG Version Mapping

| Flutter Framework Version | TAG Name | Branch |
|---|---|---|
| 3.47 | 1.0.2-ohos-1.0.0-beta.1 | main |

## Constraints and Limitations

### Compatibility

1. Flutter: 3.47.4-ohos-1.0.4, DevEco Studio: 26.0.0 Release(26.0.0.821), SDK: 26.0.0(26), ROM: OpenHarmony-7.0.0.105;

### Permission Requirements

None.

This library invokes the OpenHarmony system photo picker (`photoAccessHelper.PhotoViewPicker`) and camera picker (`cameraPicker`) to select media. Both are presented by the system as standalone interfaces, and the application only receives authorization for the files the user explicitly selects. Therefore, there is no need to declare media read/write or camera permissions in `module.json5`.

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

// Pick an image from the gallery with zero permissions
final AdaptiveFile? file = await AdaptiveImagePicker.pickImage();

if (file != null) {
  print('Picked ${file.name} (${file.formattedSize})');
}
```

The complete example project is located in the [example](https://github.com/jianguo888/adaptive_image_picker/tree/main/example) directory, covering gallery browsing, capture, cropping and compression scenarios.

## Usage Instructions

### Pick a single image from the gallery

```dart
final AdaptiveFile? file = await AdaptiveImagePicker.pickImage(
  source: ImageSource.gallery,
);
```

### Take a photo with the camera

```dart
final AdaptiveFile? photo = await AdaptiveImagePicker.pickImage(
  source: ImageSource.camera,
  preferredCameraDevice: CameraDevice.rear,
);
```

### Pick multiple images

```dart
final List<AdaptiveFile> files = await AdaptiveImagePicker.pickMultiple(
  maxCount: 5,
);
```

### Crop and compress automatically after picking

```dart
final AdaptiveFile? file = await AdaptiveImagePicker.pickImage(
  source: ImageSource.gallery,
  context: context,
  cropOptions: const CropOptions(
    title: 'Crop Image',
    aspectRatioPreset: CropAspectRatio.ratio16x9,
    lockAspectRatio: true,
  ),
  compressionOptions: const CompressionOptions(
    maxBytes: 350 * 1024,
    format: OutputFormat.webp,
  ),
);
```

### Show the media source selection sheet

```dart
final AdaptiveFile? file = await AdaptiveImagePicker.showPickerModal(
  context: context,
  options: const PickerOptions(
    modalTitle: 'Select Media Source',
    sources: [ImageSource.camera, ImageSource.gallery, ImageSource.url],
  ),
);
```

### Call cropping and compression separately

```dart
final AdaptiveFile? cropped = await AdaptiveImagePicker.cropImage(
  file: file,
  context: context,
  options: const CropOptions(title: 'Crop Image'),
);

final AdaptiveFile compressed = await AdaptiveImagePicker.compressImage(
  file: file,
  options: const CompressionOptions(maxBytes: 500 * 1024),
);
```

### Import an image from a remote URL

```dart
final AdaptiveFile image = await AdaptiveImagePicker.fromUrl(
  'https://example.com/photo.jpg',
);
```

> When calling `pickImage` with `source` set to `ImageSource.url`, you must pass `context`, otherwise an `ArgumentError` is thrown.

> The `AdaptiveFile.path` returned by picking and capture points to a cache file inside the application sandbox (`cacheDir/adaptive_picker`). It may be cleared by the system after the application restarts. Call `saveTo` to persist it if you need long-term storage.

## API Reference

### API

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Platform Support |
|-----|-----|---------|----------|---------|---------|-------------|
| getPlatformVersion | Gets the platform version information | Method | None | `Future<String?>` | No | Yes |
| pickImage | Picks a single image from the specified source | Method | `ImageSource source`, `CropOptions? cropOptions`, `CompressionOptions? compressionOptions`, `BuildContext? context`, `CameraDevice preferredCameraDevice`, `MediaType mediaType` | `Future<AdaptiveFile?>` | No | Yes |
| pickMultiple | Picks multiple images from the gallery | Method | `int? maxCount`, `CompressionOptions? compressionOptions`, `MediaType mediaType` | `Future<List<AdaptiveFile>>` | No | Yes |
| cropImage | Opens the interactive cropping interface | Method | `AdaptiveFile file`, `BuildContext context`, `CropOptions? options`, `CompressionOptions? compressionOptions` | `Future<AdaptiveFile?>` | Yes | Yes |
| compressImage | Compresses an image to a target size | Method | `AdaptiveFile file`, `CompressionOptions options` | `Future<AdaptiveFile>` | Yes | Yes |
| showPickerModal | Shows the media source selection sheet and enters the corresponding flow | Method | `BuildContext context`, `PickerOptions? options`, `CropOptions? cropOptions`, `CompressionOptions? compressionOptions` | `Future<AdaptiveFile?>` | Yes | Yes |
| fromUrl | Downloads an image from a remote URL | Method | `String url`, `CompressionOptions? compressionOptions`, `CropOptions? cropOptions`, `BuildContext? context` | `Future<AdaptiveFile>` | Yes | Yes |
| fromNetwork | Alias of `fromUrl` | Method | `String url` | `Future<AdaptiveFile>` | Yes | Yes |

### AdaptiveFile

| Name | Description | Type | OpenHarmony Platform Support |
|-----|-----|---------|-------------|
| path | Local file path, `null` for in-memory or web scenarios | Property | Yes |
| name | File name including extension | Property | Yes |
| bytes | Byte data in memory | Property | Yes |
| mimeType | MIME type | Property | Yes |
| width | Image width in pixels | Property | Yes |
| height | Image height in pixels | Property | Yes |
| size | File size in bytes | Property | Yes |
| lastModified | Last modified time | Property | Yes |
| formattedSize | Formatted size string, such as `1.4 MB` | Property | Yes |
| readAsBytes | Reads the file bytes | Method | Yes |
| saveTo | Saves the file to the specified path | Method | Yes |
| saveToDirectory | Saves the file to the specified directory | Method | Yes |
| delete | Deletes the local file | Method | Yes |

### CropOptions

| Name | Description | Type | Required | OpenHarmony Platform Support |
|-----|-----|---------|--------|-------------|
| title | Title of the cropping interface | Property | No | Yes |
| aspectRatioPreset | Preset aspect ratio | Property | No | Yes |
| lockAspectRatio | Whether to lock the aspect ratio | Property | No | Yes |
| showGrid | Whether to show the grid lines | Property | No | Yes |

### CompressionOptions

| Name | Description | Type | Required | OpenHarmony Platform Support |
|-----|-----|---------|--------|-------------|
| maxBytes | Target size limit in bytes | Property | No | Yes |
| maxWidth | Maximum width in pixels | Property | No | Yes |
| quality | Compression quality | Property | No | Yes |
| format | Output format | Property | No | Yes |

## New Features

### OpenHarmony Platform Support

- Added the `ohos` platform implementation, with the plugin class `AdaptiveImagePickerPlugin`.
- Gallery selection is based on `PhotoViewPicker` from `@ohos.file.photoAccessHelper`, supporting single and multiple selection, and filtering images or videos by `MediaType`.
- Capture is based on `@ohos.multimedia.cameraPicker`, supporting the rear or front camera.
- Picked results are automatically copied to the application sandbox cache directory `cacheDir/adaptive_picker`, returning the file name, size, MIME type and modification time.
- No media read/write or camera permissions are required.

## Known Issues

None.

## FAQ

### The picked image becomes invalid after the application restarts

The files returned by `pickImage` and `takePhoto` are copied into the application cache directory, which the system may clear when storage is low. For long-term storage, call `saveTo` or `saveToDirectory` to move them to a persistent application directory.

### Capture returns null

When the user cancels in the camera interface, or the capture produces no valid file, `takePhoto` returns `null`. Check for null before use.

### Repeated calls to the picker report an error

Only one picking session is allowed at a time. If the picker is invoked again before the previous session finishes, the native side returns the `ALREADY_ACTIVE` error code. Start the next call only after receiving a result or confirming the user has cancelled.

## Directory Structure

```text
adaptive_image_picker/
├── lib/                                      # Dart layer implementation
│   ├── adaptive_image_picker.dart            # Public API entry
│   ├── adaptive_image_picker_platform_interface.dart  # Platform interface definition
│   ├── adaptive_image_picker_method_channel.dart      # MethodChannel implementation
│   ├── adaptive_image_picker_desktop.dart    # Desktop platform implementation
│   ├── adaptive_image_picker_web.dart        # Web platform implementation
│   └── src/                                  # Models, processing logic and UI widgets
├── ohos/                                     # OpenHarmony platform implementation
│   ├── index.ets                             # HAR module entry
│   ├── oh-package.json5                      # HAR package configuration
│   └── src/main/ets/components/plugin/
│       └── AdaptiveImagePickerPlugin.ets     # Main plugin implementation
├── android/                                  # Android platform implementation
├── ios/                                      # iOS platform implementation
├── example/                                  # Example project
│   └── ohos/                                 # OpenHarmony example project
└── pubspec.yaml
```

## Contributing

If you find any issues during use, feel free to submit an [Issue](https://github.com/jianguo888/adaptive_image_picker/issues). Contributions via [PR](https://github.com/jianguo888/adaptive_image_picker/pulls) are also very welcome.

## License

This project is licensed under [MIT](https://github.com/Karan8686/adaptive_image_picker/blob/main/LICENSE), feel free to enjoy and participate in open source.
