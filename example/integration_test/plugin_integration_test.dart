import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

/// On-device verification for the OHOS implementation.
///
/// Goal: prove all three methods reach the native ArkTS handler on a real
/// device. Dispatch is proven by *which* error comes back, not by a successful
/// pick — the system picker requires human interaction, so it cannot be driven
/// to completion from an automated test.
///
/// - `getPlatformVersion` returns a real string  -> channel + registration OK.
/// - `pickImages` / `takePhoto` must NOT raise `MissingPluginException` and
///   must NOT return `notImplemented`; any error carrying one of the plugin's
///   own codes (`ALREADY_ACTIVE`, `PICK_FAILED`, `CAMERA_FAILED`,
///   `NO_ACTIVITY`) or a timeout proves the call reached native code.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('adaptive_image_picker');

  /// The plugin's own error codes, i.e. errors raised by our ArkTS handler.
  const Set<String> pluginOwnCodes = <String>{
    'ALREADY_ACTIVE',
    'PICK_FAILED',
    'CAMERA_FAILED',
    'NO_ACTIVITY',
  };

  /// Invokes [method] and asserts the call reached the native handler.
  Future<void> expectReachesNative(String method, Map<String, Object?> args) async {
    Object? thrown;
    try {
      await channel
          .invokeMethod<dynamic>(method, args)
          .timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // The native picker opened and is waiting for the user: dispatch proven.
      return;
    } catch (e) {
      thrown = e;
    }

    if (thrown is MissingPluginException) {
      fail('$method did not reach native code: $thrown');
    }
    if (thrown is PlatformException) {
      if (thrown.code == 'channel-error' &&
          (thrown.message ?? '').toLowerCase().contains('not implemented')) {
        fail('$method fell through to notImplemented on native side: $thrown');
      }
      expect(pluginOwnCodes.contains(thrown.code), true,
          reason: '$method returned an unexpected error code: ${thrown.code}');
      return;
    }
    if (thrown != null) {
      fail('$method raised an unexpected error: $thrown');
    }
  }

  testWidgets('getPlatformVersion returns an OpenHarmony version string',
      (WidgetTester tester) async {
    final String? version = await AdaptiveImagePicker.getPlatformVersion();
    expect(version, isNotNull);
    expect(version!.isNotEmpty, true);
    expect(version.startsWith('OpenHarmony'), true,
        reason: 'unexpected platform string: $version');
  });

  testWidgets('pickImages reaches the OHOS native handler',
      (WidgetTester tester) async {
    await expectReachesNative('pickImages', <String, Object?>{
      'mediaType': 'image',
      'maxCount': 1,
      'isMultiple': false,
    });
  });

  testWidgets('takePhoto reaches the OHOS native handler',
      (WidgetTester tester) async {
    await expectReachesNative('takePhoto', <String, Object?>{
      'preferredCameraDevice': 'rear',
    });
  });
}
