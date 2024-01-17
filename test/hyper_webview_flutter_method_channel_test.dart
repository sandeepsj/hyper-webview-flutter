import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_webview_flutter/hyper_webview_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelHyperWebviewFlutter platform = MethodChannelHyperWebviewFlutter();
  const MethodChannel channel = MethodChannel('hyper_webview_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
