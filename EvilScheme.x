#import <EvilKit/EvilKit.h>
#import "PrivateFrameworks.h"

#define appInstalled(app)  [[LSApplicationWorkspace defaultWorkspace] applicationIsInstalled:app]

// Preference retrieval {{{
static NSDictionary<NSString *, EVKAppAlternative *> *prefs() {
    NSString *path = @"/var/mobile/Library/Preferences/EvilScheme/alternatives_v0.plist";
    NSData *data = [NSData dataWithContentsOfFile:path];
    if(!data) return @{};

    NSError *err = nil;
    NSKeyedUnarchiver *u = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&err];
    if(!u) {
        if(err) NSLog(@"[EVS] Error loading prefs: %@", [err localizedDescription]);
        return @{};
    }
    [u setRequiresSecureCoding:NO];
    NSDictionary *ret = [u decodeObjectForKey:NSKeyedArchiveRootObjectKey];

    return ret ? : @{};
}

static NSSet *blacklist() {
    NSSet *fallback = [NSSet setWithObject:@"com.apple.siri"];

    NSString *path = @"/var/mobile/Library/Preferences/EvilScheme/blacklist_v0.plist";
    NSData *data = [NSData dataWithContentsOfFile:path];
    if(!data) return fallback;

    NSError *err = nil;
    NSSet *types = [NSSet setWithObjects:[NSOrderedSet class], [NSString class], nil];
    NSOrderedSet *ret = [NSKeyedUnarchiver unarchivedObjectOfClasses:types
                                                            fromData:data
                                                               error:&err];
    if(err) NSLog(@"[EVS] Error loading blacklist: %@", [err localizedDescription]);
    if(!ret) return fallback;
    return [[ret set] setByAddingObject:@"com.apple.siri"];
}
// }}}

// Logging {{{
static NSDictionary *logDict() {
    NSString *path = @"file:/var/mobile/Library/Preferences/EvilScheme/log_v0.plist";

    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]
                                         options:0
                                           error:&err];
    if(!data) return nil;

    NSSet *types = [NSSet setWithObjects:[NSDictionary class],
                                         [NSArray class],
                                         [NSString class],
                                         [NSNumber class], nil];

    NSDictionary *ret = [NSKeyedUnarchiver unarchivedObjectOfClasses:types
                                                            fromData:data
                                                               error:&err];

    if(err) NSLog(@"[EVS] Error reading log: %@", [err localizedDescription]);

    return ret;
}

static void setLogDict(NSDictionary *dict) {
    if(!dict) return;
    NSError *err = nil;

    NSString *dir = @"/var/mobile/Library/Preferences/EvilScheme/";
    // Ensure dir exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir
                                              isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&err];
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict
                                         requiringSecureCoding:NO
                                                         error:&err];
    if(err || !data) {
        if(err) NSLog(@"[EVS] Error writing to log: %@", [err localizedDescription]);
        return;
    }

    NSString *path = @"file:/var/mobile/Library/Preferences/EvilScheme/log_v0.plist";
    [data writeToURL:[NSURL URLWithString:path]
             options:0
               error:&err];

    if(err) NSLog(@"[EVS] Error writing to log: %@", [err localizedDescription]);
}

static void logString(NSString *lString) {
    NSLog(@"[EVS] %@", lString);
    NSMutableDictionary *ld = [logDict() ? : @{} mutableCopy];
    if([ld[@"enabled"] boolValue]) {
        NSMutableArray *arr = [ld[@"data"] ? : @[] mutableCopy];
        [arr addObject:lString];
        ld[@"data"] = arr;
        setLogDict(ld);
    }
}
// }}}

// Spelunk into actions as a last resort to find URL
static NSURL *urlFromActions(NSArray *actions) {
    __block NSURL *ret;
    if(![actions isKindOfClass:[NSArray class]]) return nil;
    for(id candidate in actions) {
        if(![candidate isKindOfClass:[BSAction class]]) continue;
        BSAction *action = candidate;
        NSIndexSet *settings = [[action info] allSettings];
        if(!settings) continue;
        [settings enumerateIndexesUsingBlock:^ (NSUInteger idx, BOOL *stop) {
            id obj = [[action info] objectForSetting:idx];
            if([obj isKindOfClass:[NSData class]]) {
                ret = [[NSKeyedUnarchiver unarchivedObjectOfClass:[UAUserActivityInfo class]
                                                         fromData:obj
                                                            error:nil] webpageURL];
            }
        }];
    }
    return [ret isKindOfClass:[NSURL class]] ? ret : nil;
}

%hook FBSystemService

- (void)openApplication:(NSString *)bundleID
            withOptions:(FBSOpenApplicationOptions *)options
             originator:(BSProcessHandle *)source
              requestID:(NSUInteger)req
             completion:(id)completion {

    EVKAppAlternative *app = prefs()[bundleID];
    NSMutableString *lString = [NSMutableString new];
    // Never pass nil into -containsObject: (throws) or into
    // -applicationIsInstalled: (private API, may assert on iOS 16+).
    NSString *sourceID = [source bundleIdentifier] ? : @"";
    if(!app
    || [blacklist() containsObject:sourceID]
    || !appInstalled([app substituteBundleID])) {
        [lString appendFormat:@"Ignored: %@\n%@\n", bundleID, options];
    }
    else {
        [lString appendFormat:@"From: %@\n%@\n", bundleID, options];
        NSURL *url = [options dictionary][@"__PayloadURL"];
        if(![url isKindOfClass:[NSURL class]]) {
            url = nil;
            id appLink = [options dictionary][@"__AppLink4LS"];
            if([appLink respondsToSelector:@selector(URL)]) {
                NSURL *u = [appLink URL];
                if([u isKindOfClass:[NSURL class]]) url = u;
            }
            if(!url) url = urlFromActions([options dictionary][@"__Actions"]);
        }
        if(url) {
            [lString appendFormat:@"%@\n", [url absoluteString]];
            NSURL *newURL = [app transformURL:url];
            if(newURL) {
                // Craft new request, preserving all original keys:
                // frontboardd on iOS 16+ expects more than just
                // __PayloadURL/__PayloadOptions to activate the app.
                bundleID = [app substituteBundleID];
                NSMutableDictionary *opts = [[options dictionary] mutableCopy];
                if(!opts) opts = [NSMutableDictionary new];
                opts[@"__PayloadURL"] = newURL;
                [options setDictionary:opts];
            }
        }
        [lString appendFormat:@"\nTo: %@\n%@\n", bundleID, options];
    }

    logString(lString);
    %orig;
}

%end
