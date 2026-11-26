#import <Foundation/Foundation.h>

/// Posted on the main thread after the in-app language override changes.
/// The menu rebuilds from this; the process does not need to relaunch.
extern NSNotificationName const AFXLanguageDidChangeNotification;

/// Stored preference value that means "use the language macOS chose for this launch".
extern NSString * const AFXLanguageSystem;

/// Preference key. The value is AFXLanguageSystem or an lproj name such as @"zh-Hans".
extern NSString * const AFXLanguagePreferenceKey;

/// Translation for `key`, or `key` itself when a language has no entry.
/// English strings are the keys, so a missing translation stays readable.
FOUNDATION_EXPORT NSString *AFXLocalized(NSString *key);

/// `stringWithFormat:` using the translated format. Placeholders must match the English key.
FOUNDATION_EXPORT NSString *AFXLocalizedFormat(NSString *key, ...) NS_FORMAT_FUNCTION(1, 2);

/// @"system", or an lproj code that is actually in the bundle.
FOUNDATION_EXPORT NSString *AFXPreferredLanguageCode(void);
FOUNDATION_EXPORT void AFXSetPreferredLanguageCode(NSString *code);

/// lproj names that contain Localizable.strings, excluding Base.
/// A new language appears here once its .lproj is copied into the app.
FOUNDATION_EXPORT NSArray<NSString *> *AFXAvailableLanguageCodes(void);

/// The language's own name, for example "English" or "简体中文".
FOUNDATION_EXPORT NSString *AFXLanguageDisplayName(NSString *code);
