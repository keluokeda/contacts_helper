#import "ContactsHelperPlugin.h"
#import <contacts_helper/contacts_helper-Swift.h>

@implementation ContactsHelperPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftContactsHelperPlugin registerWithRegistrar:registrar];
}
@end
