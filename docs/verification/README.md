# 真机验证记录

本目录保存在真机上执行集成测试的原始输出，用于核验 OpenHarmony 适配的实际运行结果。

## 验证设备

| 项目 | 值 |
|------|-----|
| 设备型号 | ALN-AL00（HUAWEI 真机，非模拟器） |
| 设备序列号 | `2LQ0224129000383`（USB 连接） |
| 系统版本 | OpenHarmony-7.0.0.105 |
| API 版本 | 26 |
| 架构 | arm64-v8a |

## 测试结果

`real-device-integration-test.log` 为 `flutter test integration_test/plugin_integration_test.dart -d 2LQ0224129000383` 的原始输出，**3 个用例全部通过**：

```
00:00 +0: getPlatformVersion returns an OpenHarmony version string
00:00 +1: pickImages reaches the OHOS native handler
00:06 +2: takePhoto reaches the OHOS native handler
00:06 +3: (tearDownAll)
00:07 +3: All tests passed!
```

### 用例设计说明

系统 Picker 需要**人工交互**才能完成选取，自动化测试无法驱动其走完流程。因此 `pickImages` / `takePhoto` 两个用例的判据是**“调用是否到达原生层”**而非“选取成功”：

- 原生未实现该方法 → 立即抛 `MissingPluginException` 或返回 `notImplemented` → 用例失败
- 调用到达原生层 → Picker 弹出等待用户操作 → 测试在 6 秒超时 → **超时即通过**
- 原生返回插件自定义错误码（`ALREADY_ACTIVE` 等）→ 同样证明到达原生层 → 通过

## 运行截图

| 文件 | 说明 |
|------|------|
| `../images/ohos-running.png` | 真机（ALN-AL00）运行截图 |
| `../images/ohos-emulator.png` | 模拟器交叉验证截图 |

## 复现方式

```bash
cd example
flutter pub get
flutter test integration_test/plugin_integration_test.dart -d <设备序列号>
```

> 真机需先在 `example/ohos/build-profile.json5` 配置由 DevEco Studio 为**该设备**签发的调试证书（`.cer` / `.p12` / `.p7b`），否则安装会报 `fail to verify pkcs7 file`。签名材料含私钥，请勿提交到仓库。
