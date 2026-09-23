<div style="text-align: center"><h1>adaptive_image_picker</h1></div>

本项目基于 [adaptive_image_picker](https://github.com/Karan8686/adaptive_image_picker) 开发。

## 简介

adaptive_image_picker 是一个面向 OpenHarmony 的自适应图片选择库，提供零权限的图片选取、纯 Dart 裁剪与二分压缩能力，并集成 OpenHarmony 系统图片选择器与相机选择器。

本库在 OpenHarmony 平台调用系统提供的 Picker 组件完成图片选取与拍照，应用无需申请媒体读写权限，也无需自行实现选择界面。

## 下载安装

在工程的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  adaptive_image_picker:
    git:
      url: https://github.com/jianguo888/adaptive_image_picker
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: 1.0.2-ohos-1.0.0-beta.1
```

执行以下命令获取依赖：

```bash
flutter pub get
```

### TAG 版本对应表

| Flutter 框架版本 | TAG 名称 | 分支名 |
|---|---|---|
| 3.47 | 1.0.2-ohos-1.0.0-beta.1 | main |

## 约束与限制

### 兼容性

1. Flutter: 3.47.4-ohos-1.0.4, DevEco Studio: 26.0.0 Release(26.0.0.821), SDK: 26.0.0(26), ROM: OpenHarmony-7.0.0.105;

### 权限要求

无。

本库调用 OpenHarmony 系统图片选择器（`photoAccessHelper.PhotoViewPicker`）与相机选择器（`cameraPicker`）完成媒体选取，二者均由系统以独立界面提供，应用仅获得用户明确选择的文件授权，因此无需在 `module.json5` 中声明媒体读写或相机权限。

## 使用示例

```dart
import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

// 从相册选取一张图片，无需申请权限
final AdaptiveFile? file = await AdaptiveImagePicker.pickImage();

if (file != null) {
  print('已选取 ${file.name}（${file.formattedSize}）');
}
```

完整的示例工程位于 [example](https://github.com/jianguo888/adaptive_image_picker/tree/main/example) 目录，包含相册浏览、拍摄、裁剪与压缩等场景。

## 使用说明

### 从相册选取单张图片

```dart
final AdaptiveFile? file = await AdaptiveImagePicker.pickImage(
  source: ImageSource.gallery,
);
```

### 调用相机拍照

```dart
final AdaptiveFile? photo = await AdaptiveImagePicker.pickImage(
  source: ImageSource.camera,
  preferredCameraDevice: CameraDevice.rear,
);
```

### 选取多张图片

```dart
final List<AdaptiveFile> files = await AdaptiveImagePicker.pickMultiple(
  maxCount: 5,
);
```

### 选取后自动裁剪与压缩

```dart
final AdaptiveFile? file = await AdaptiveImagePicker.pickImage(
  source: ImageSource.gallery,
  context: context,
  cropOptions: const CropOptions(
    title: '裁剪图片',
    aspectRatioPreset: CropAspectRatio.ratio16x9,
    lockAspectRatio: true,
  ),
  compressionOptions: const CompressionOptions(
    maxBytes: 350 * 1024,
    format: OutputFormat.webp,
  ),
);
```

### 弹出媒体来源选择面板

```dart
final AdaptiveFile? file = await AdaptiveImagePicker.showPickerModal(
  context: context,
  options: const PickerOptions(
    modalTitle: '选择图片来源',
    sources: [ImageSource.camera, ImageSource.gallery, ImageSource.url],
  ),
);
```

### 独立调用裁剪与压缩

```dart
final AdaptiveFile? cropped = await AdaptiveImagePicker.cropImage(
  file: file,
  context: context,
  options: const CropOptions(title: '裁剪图片'),
);

final AdaptiveFile compressed = await AdaptiveImagePicker.compressImage(
  file: file,
  options: const CompressionOptions(maxBytes: 500 * 1024),
);
```

### 从网络地址导入图片

```dart
final AdaptiveFile image = await AdaptiveImagePicker.fromUrl(
  'https://example.com/photo.jpg',
);
```

> 调用 `pickImage` 且 `source` 为 `ImageSource.url` 时，必须传入 `context`，否则抛出 `ArgumentError`。

> 选取与拍摄返回的 `AdaptiveFile.path` 指向应用沙箱内的缓存文件（`cacheDir/adaptive_picker`），应用重启后可能被系统清理，如需长期保存请调用 `saveTo` 转存。

## 接口说明

### API

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|-----|-----|---------|----------|---------|---------|-------------|
| getPlatformVersion | 获取平台版本信息 | 方法 | 无 | `Future<String?>` | 否 | 是 |
| pickImage | 从指定来源选取单张图片 | 方法 | `ImageSource source`、`CropOptions? cropOptions`、`CompressionOptions? compressionOptions`、`BuildContext? context`、`CameraDevice preferredCameraDevice`、`MediaType mediaType` | `Future<AdaptiveFile?>` | 否 | 是 |
| pickMultiple | 从相册选取多张图片 | 方法 | `int? maxCount`、`CompressionOptions? compressionOptions`、`MediaType mediaType` | `Future<List<AdaptiveFile>>` | 否 | 是 |
| cropImage | 打开交互式裁剪界面 | 方法 | `AdaptiveFile file`、`BuildContext context`、`CropOptions? options`、`CompressionOptions? compressionOptions` | `Future<AdaptiveFile?>` | 是 | 是 |
| compressImage | 按目标体积压缩图片 | 方法 | `AdaptiveFile file`、`CompressionOptions options` | `Future<AdaptiveFile>` | 是 | 是 |
| showPickerModal | 弹出媒体来源选择面板并进入对应流程 | 方法 | `BuildContext context`、`PickerOptions? options`、`CropOptions? cropOptions`、`CompressionOptions? compressionOptions` | `Future<AdaptiveFile?>` | 是 | 是 |
| fromUrl | 从网络地址下载图片 | 方法 | `String url`、`CompressionOptions? compressionOptions`、`CropOptions? cropOptions`、`BuildContext? context` | `Future<AdaptiveFile>` | 是 | 是 |
| fromNetwork | `fromUrl` 的别名 | 方法 | `String url` | `Future<AdaptiveFile>` | 是 | 是 |

### AdaptiveFile

| 名称 | 描述 | 类型 | OpenHarmony平台支持 |
|-----|-----|---------|-------------|
| path | 本地文件路径，内存或 Web 场景为 `null` | 属性 | 是 |
| name | 文件名（含扩展名） | 属性 | 是 |
| bytes | 内存中的字节数据 | 属性 | 是 |
| mimeType | MIME 类型 | 属性 | 是 |
| width | 图片宽度（像素） | 属性 | 是 |
| height | 图片高度（像素） | 属性 | 是 |
| size | 文件体积（字节） | 属性 | 是 |
| lastModified | 最后修改时间 | 属性 | 是 |
| formattedSize | 格式化后的体积字符串，如 `1.4 MB` | 属性 | 是 |
| readAsBytes | 读取文件字节 | 方法 | 是 |
| saveTo | 保存到指定路径 | 方法 | 是 |
| saveToDirectory | 保存到指定目录 | 方法 | 是 |
| delete | 删除本地文件 | 方法 | 是 |

### CropOptions

| 名称 | 描述 | 类型 | 必填 | OpenHarmony平台支持 |
|-----|-----|---------|--------|-------------|
| title | 裁剪界面标题 | 属性 | 否 | 是 |
| aspectRatioPreset | 预设宽高比 | 属性 | 否 | 是 |
| lockAspectRatio | 是否锁定宽高比 | 属性 | 否 | 是 |
| showGrid | 是否显示网格线 | 属性 | 否 | 是 |

### CompressionOptions

| 名称 | 描述 | 类型 | 必填 | OpenHarmony平台支持 |
|-----|-----|---------|--------|-------------|
| maxBytes | 目标体积上限（字节） | 属性 | 否 | 是 |
| maxWidth | 最大宽度（像素） | 属性 | 否 | 是 |
| quality | 压缩质量 | 属性 | 否 | 是 |
| format | 输出格式 | 属性 | 否 | 是 |

## 新增特性

### OpenHarmony 平台支持

- 新增 `ohos` 平台实现，插件类为 `AdaptiveImagePickerPlugin`。
- 相册选取基于 `@ohos.file.photoAccessHelper` 的 `PhotoViewPicker`，支持单选与多选，并可按 `MediaType` 过滤图片或视频。
- 拍照基于 `@ohos.multimedia.cameraPicker`，支持指定后置或前置摄像头。
- 选取结果自动转存至应用沙箱缓存目录 `cacheDir/adaptive_picker`，并返回文件名、体积、MIME 类型与修改时间。
- 无需申请媒体读写或相机权限。

## 遗留问题

无。

## 常见问题

### 选取的图片在应用重启后失效

`pickImage` 与 `takePhoto` 返回的文件已复制到应用缓存目录，系统可能在空间不足时清理该目录。如需长期保存，请调用 `saveTo` 或 `saveToDirectory` 转存到应用持久化目录。

### 调用拍照返回 null

用户在相机界面取消拍摄，或拍摄未产生有效文件时，`takePhoto` 返回 `null`。建议在使用前判空。

### 重复调用选取接口报错

同一时刻仅允许一个选取会话。若上一次选取尚未结束就再次调用，原生侧返回 `ALREADY_ACTIVE` 错误码。请在收到结果或确认用户已取消后再发起下一次调用。

## 目录结构

```text
adaptive_image_picker/
├── lib/                                      # Dart 层实现
│   ├── adaptive_image_picker.dart            # 对外 API 入口
│   ├── adaptive_image_picker_platform_interface.dart  # 平台接口定义
│   ├── adaptive_image_picker_method_channel.dart      # MethodChannel 实现
│   ├── adaptive_image_picker_desktop.dart    # 桌面平台实现
│   ├── adaptive_image_picker_web.dart        # Web 平台实现
│   └── src/                                  # 模型、处理逻辑与 UI 组件
├── ohos/                                     # OpenHarmony 平台实现
│   ├── index.ets                             # HAR 模块入口
│   ├── oh-package.json5                      # HAR 包配置
│   └── src/main/ets/components/plugin/
│       └── AdaptiveImagePickerPlugin.ets     # 插件主实现
├── android/                                  # Android 平台实现
├── ios/                                      # iOS 平台实现
├── example/                                  # 示例工程
│   └── ohos/                                 # OpenHarmony 示例工程
└── pubspec.yaml
```

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://github.com/jianguo888/adaptive_image_picker/issues) ，当然，也非常欢迎发 [PR](https://github.com/jianguo888/adaptive_image_picker/pulls) 共建。

## 开源协议

本项目基于 [MIT](https://github.com/Karan8686/adaptive_image_picker/blob/main/LICENSE) ，请自由地享受和参与开源。
