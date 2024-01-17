#import "HyperWebviewFlutterPlugin.h"

@interface HyperWebviewFlutterPlugin()

@property (nonatomic, strong) FlutterMethodChannel* dartChannel;
@property (nonatomic, strong) FlutterMethodChannel* nativeChannel;

@end

const int OPENAPPS_REQUEST_CODE = 19;
const int GET_RESOURCE_NAME = 453;
const int CAN_OPEN_APP_CODE = 789;
@implementation HyperWebviewFlutterPlugin


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    HyperWebviewFlutterPlugin* instance = [[HyperWebviewFlutterPlugin alloc] init];
    instance.dartChannel=[FlutterMethodChannel methodChannelWithName:@"DartChannel" binaryMessenger:[registrar messenger]];
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"NativeChannel" binaryMessenger:[registrar messenger]];
    instance.nativeChannel=channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"openApp" isEqualToString:call.method]) {
      [self openApp:[call.arguments objectAtIndex:1]];
  } if ([@"getResourceByName" isEqualToString:call.method]) {
      NSString* resourceVal = [self getResourceByName:[call.arguments firstObject]];
      NSDictionary *resource = @{
          @"requestCode" : @(GET_RESOURCE_NAME),
          @"payload" : resourceVal
      };
      [self.dartChannel invokeMethod:@"onActivityResult" arguments:resource];
  } if ([@"canOpenApp" isEqualToString:call.method]) {
      [self canOpenApp:[call.arguments firstObject]];
  } else {
      result(FlutterMethodNotImplemented);
  }
    result(@"true");
}

/**
 To Check if an app can be opened by current app

 @param payload App URL
 */
- (void)canOpenApp:(NSString*)payload{
    //Note: canOpen will fail even if app is present in the device if app urls are not
    //added to info.plist under LSApplicationQueriesSchemes as an array of allowed urls.
    NSURL *appURL = [NSURL URLWithString:[HyperWebviewFlutterPlugin base64DecodedStringFromString:payload]];
    BOOL status = [[UIApplication sharedApplication] canOpenURL:appURL];
    NSString* resPayload = [NSString stringWithFormat:@"{\"result\":\"%@\",\"app\":\"%@\"}", status?@"1":@"0", appURL];
    NSDictionary *resp = @{
        @"requestCode" : @(CAN_OPEN_APP_CODE),
        @"payload" :resPayload
    };
    [self.dartChannel invokeMethod:@"onActivityResult" arguments:resp];
}

- (void)openApp:(NSString*)payload {
    NSURL *appURL = [NSURL URLWithString:[HyperWebviewFlutterPlugin base64DecodedStringFromString:payload]];
    NSDictionary *failedResp = @{
        @"requestCode" : @(OPENAPPS_REQUEST_CODE),
        @"payload" : @"false"
    };
    if (appURL && [[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSDictionary *successResp = @{
                    @"requestCode" : @(OPENAPPS_REQUEST_CODE),
                    @"payload" : @"true"
                };
                [self.dartChannel invokeMethod:@"onActivityResult" arguments:successResp];
            }else{
                [self.dartChannel invokeMethod:@"onActivityResult" arguments:failedResp];
            }
        }];
    }else{
        [self.dartChannel invokeMethod:@"onActivityResult" arguments:failedResp];
    }
}

- (NSString*)getResourceByName:(NSString *)resName {
    NSString *value;

    if ([resName isEqualToString:@"CFBundleVersion"]) {
        value = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"hyper_sdk_version"];
    } else {
        value = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:resName];
    }
    if (value == nil) {
        value = @"";
    }
    return value;
}

+ (NSString *)base64DecodedStringFromString:(NSString *)input {
    NSString *decodedString = @"";
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:input options:0];
    if (decodedData) {
        decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    }
    return decodedString;
}

@end
