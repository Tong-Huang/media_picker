#import "MediaPickerPlugin.h"
#import <media_picker/media_picker-Swift.h>

@implementation MediaPickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMediaPickerPlugin registerWithRegistrar:registrar];
}
@end
