#import "AFXLocalization.h"

NSNotificationName const AFXLanguageDidChangeNotification = @"AFXLanguageDidChange";
NSString * const AFXLanguageSystem = @"system";
NSString * const AFXLanguagePreferenceKey = @"AFXLanguage";

static NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *AFXStringTables(void)
{
    static NSMutableDictionary *tables;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        tables = [NSMutableDictionary dictionary];
    });
    return tables;
}

NSArray<NSString *> *AFXAvailableLanguageCodes(void)
{
    NSMutableArray<NSString *> *codes = [NSMutableArray array];
    NSArray<NSString *> *paths = [NSBundle.mainBundle pathsForResourcesOfType:@"lproj" inDirectory:nil];
    for (NSString *path in paths) {
        NSString *code = path.lastPathComponent.stringByDeletingPathExtension;
        if (code.length == 0 || [code isEqualToString:@"Base"]) continue;
        NSString *strings = [path stringByAppendingPathComponent:@"Localizable.strings"];
        if ([NSFileManager.defaultManager fileExistsAtPath:strings]) {
            [codes addObject:code];
        }
    }
    [codes sortUsingSelector:@selector(compare:)];
    return codes;
}

static NSDictionary<NSString *, NSString *> *AFXTableForLanguage(NSString *code)
{
    if (code.length == 0) return @{};
    NSMutableDictionary *tables = AFXStringTables();
    NSDictionary *cached = tables[code];
    if (cached) return cached;

    NSString *path = [NSBundle.mainBundle pathForResource:@"Localizable"
                                                    ofType:@"strings"
                                               inDirectory:nil
                                           forLocalization:code];
    NSDictionary *loaded = path ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
    if (![loaded isKindOfClass:NSDictionary.class]) loaded = @{};
    tables[code] = loaded;
    return loaded;
}

static NSString *AFXResolvedLanguageCode(void)
{
    NSArray<NSString *> *available = AFXAvailableLanguageCodes();
    NSString *stored = [NSUserDefaults.standardUserDefaults stringForKey:AFXLanguagePreferenceKey];
    if (stored.length > 0 && ![stored isEqualToString:AFXLanguageSystem] && [available containsObject:stored]) {
        return stored;
    }

    for (NSString *preferred in NSBundle.mainBundle.preferredLocalizations) {
        if ([available containsObject:preferred]) return preferred;
        for (NSString *code in available) {
            if ([preferred hasPrefix:[code stringByAppendingString:@"-"]]) return code;
        }
    }
    if ([available containsObject:@"en"]) return @"en";
    return available.firstObject ?: @"en";
}

NSString *AFXPreferredLanguageCode(void)
{
    NSString *stored = [NSUserDefaults.standardUserDefaults stringForKey:AFXLanguagePreferenceKey];
    if (stored.length == 0 || [stored isEqualToString:AFXLanguageSystem]) return AFXLanguageSystem;
    if ([AFXAvailableLanguageCodes() containsObject:stored]) return stored;
    return AFXLanguageSystem;
}

void AFXSetPreferredLanguageCode(NSString *code)
{
    if (code.length == 0 || [code isEqualToString:AFXLanguageSystem] ||
        ![AFXAvailableLanguageCodes() containsObject:code]) {
        code = AFXLanguageSystem;
    }
    [NSUserDefaults.standardUserDefaults setObject:code forKey:AFXLanguagePreferenceKey];
    [NSNotificationCenter.defaultCenter postNotificationName:AFXLanguageDidChangeNotification
                                                      object:code];
}

NSString *AFXLanguageDisplayName(NSString *code)
{
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:code];
    NSString *name = [locale displayNameForKey:NSLocaleIdentifier value:code];
    return name.length > 0 ? name : code;
}

NSString *AFXLocalized(NSString *key)
{
    if (key.length == 0) return @"";
    NSString *value = AFXTableForLanguage(AFXResolvedLanguageCode())[key];
    if ([value isKindOfClass:NSString.class] && value.length > 0) return value;
    if (![AFXResolvedLanguageCode() isEqualToString:@"en"]) {
        value = AFXTableForLanguage(@"en")[key];
        if ([value isKindOfClass:NSString.class] && value.length > 0) return value;
    }
    return key;
}

NSString *AFXLocalizedFormat(NSString *key, ...)
{
    va_list args;
    va_start(args, key);
    NSString *result = [[NSString alloc] initWithFormat:AFXLocalized(key) arguments:args];
    va_end(args);
    return result;
}
