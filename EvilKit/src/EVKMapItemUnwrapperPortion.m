#import "EVKURLPortions.h"
#import "NSURL+ComponentAdditions.h"

@interface GEOMapItemStorage : NSObject
-(instancetype)initWithData:(NSData *)data;
-(NSDictionary *)addressDictionary;
@end

@implementation EVKMapItemUnwrapperPortion

- (NSString *)evaluateUnencodedWithURL:(NSURL *)url {
    NSData *b64 = [[NSData alloc] initWithBase64EncodedString:[url trimmedResourceSpecifier]
                                                      options:0];
    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:b64
                                                                    options:0
                                                                     format:nil
                                                                      error:nil];
    @try {
        NSData *d = plist[@"MKMapItemLaunchAdditionsMapItems"][0][@"MKMapItemGEOMapItem"];
        // Resolved purely at runtime: GeoServices cannot be linked from the
        // Xcode SDK, and a direct reference would emit an _OBJC_CLASS_$_
        // symbol that fails the link. On-device the class always exists.
        Class storageClass = NSClassFromString(@"GEOMapItemStorage");
        if(!storageClass) return nil;
        NSDictionary *addr = [[[storageClass alloc] initWithData:d] addressDictionary];

        return [NSString stringWithFormat:@"%@ %@ %@, %@ %@",
                addr[@"Name"] ? : @"",
                addr[@"Street"] ? : @"",
                addr[@"City"] ? : @"",
                addr[@"State"] ? : @"",
                addr[@"ZIP"] ? : @""
                         ];
    } @catch (NSException *ex) {
        return nil;
    }
}

- (NSString *)stringRepresentation { return @"Address unwrapper"; }

@end
