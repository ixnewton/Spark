/*
 *  SparkPreferences.m
 *  SparkKit
 *
 *  Created by Grayfox on 14/04/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPrivate.h>

/* Spark Core preferences */
#if defined(DEBUG)
static
CFStringRef const kSparkPreferencesIdentifier = CFSTR("org.shadowlab.Spark-debug");
static
CFStringRef const kSparkPreferencesService = CFSTR("org.shadowlab.spark.preferences.debug");

#else
static
CFStringRef const kSparkPreferencesIdentifier = CFSTR("org.shadowlab.Spark");
static
CFStringRef const kSparkPreferencesService = CFSTR("org.shadowlab.spark.preferences");
#endif

enum {
  kSparkPreferencesMessageID = 'SpPr',
};

static 
CFMutableDictionaryRef sSparkDaemonPreferences = NULL;
static 
CFMutableDictionaryRef sSparkFrameworkPreferences = NULL;

static
void SparkPreferencesNotifyObservers(NSString *key, id value, SparkPreferencesDomain domain);

@interface SparkLibrary (SparkPreferencesPrivate) 
- (id)preferenceValueForKey:(NSString *)key;
- (void)setPreferenceValue:(id)value forKey:(NSString *)key;
@end

#pragma mark -
static
CFDataRef _SparkPreferencesHandleMessage(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  if (kSparkPreferencesMessageID == msgid) {
    ShadowCTrace();
    NSDictionary *request = [NSPropertyListSerialization propertyListFromData:(id)data
                                                             mutabilityOption:NSPropertyListImmutable
                                                                       format:NULL errorDescription:NULL];
    if (request) {
      NSString *key = [request objectForKey:@"key"];
      SparkPreferencesDomain domain = SKIntegerValue([request objectForKey:@"domain"]);
      id value = [request objectForKey:@"value"];
      SparkPreferencesSetValue(key, value, domain);
    }
  }
  return NULL;
}

static 
void _SparkPreferencesStartServer(void) {
  static
  CFMessagePortRef sMachPort = NULL;
  if (!sMachPort) {
    sMachPort = CFMessagePortCreateLocal(kCFAllocatorDefault, kSparkPreferencesService,
                                         _SparkPreferencesHandleMessage, NULL, NULL);
    if (sMachPort) {
      CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, sMachPort, 0);
      if (source) {
        CFRunLoopRef rl = CFRunLoopGetCurrent();
        if (rl) {
          CFRunLoopAddSource(rl, source, kCFRunLoopCommonModes);
        } else {
          ECLog("Undefined error while getting current run loop");
        }
        CFRelease(source);
      }
    } else {
      ECLog("Undefined error while creating preference port");
      sMachPort = (CFMessagePortRef)kCFNull;
    }
  }
}

static
void _SparkPreferencesSetDaemonValue(NSString *key, id value, SparkPreferencesDomain domain) {
  if (SparkDaemonIsRunning()) {
    ShadowCTrace();
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
      key, @"key",
      SKInteger(domain), @"domain", 
      value, @"value", nil];
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:request
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                    errorDescription:NULL];
    if (data) {
      CFMessagePortRef port = CFMessagePortCreateRemote(kCFAllocatorDefault, kSparkPreferencesService);
      if (port) {
        if (kCFMessagePortSuccess != CFMessagePortSendRequest(port, kSparkPreferencesMessageID, (CFDataRef)data,
                                                              5, 0, NULL, NULL)) {
          WCLog("Error while sending preference message");
        }
        CFMessagePortInvalidate(port);
        CFRelease(port);
      }
    }
  }
}

#pragma mark -
#pragma mark API
static
CFMutableDictionaryRef _SparkPreferencesGetDictionary(SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      if (!sSparkDaemonPreferences)
        sSparkDaemonPreferences = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                            &kCFTypeDictionaryKeyCallBacks,
                                                            &kCFTypeDictionaryValueCallBacks);
      return sSparkDaemonPreferences;
    case SparkPreferencesFramework:
      if (!sSparkFrameworkPreferences)
        sSparkFrameworkPreferences = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                               &kCFTypeDictionaryKeyCallBacks,
                                                               &kCFTypeDictionaryValueCallBacks);
      return sSparkFrameworkPreferences;
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
  return nil;
}

#pragma mark Getter
id SparkPreferencesGetValue(NSString *key, SparkPreferencesDomain domain) {
  /* If daemon context, register preferences port */
  if (SparkGetCurrentContext() != kSparkEditorContext) {
    _SparkPreferencesStartServer();
  }
  
  switch (domain) {
    case SparkPreferencesDaemon:
    case SparkPreferencesFramework: {
      id value = nil;
      /* If daemon context, try to get value from memory cache*/
      if (SparkGetCurrentContext() != kSparkEditorContext) {
        CFMutableDictionaryRef dict = _SparkPreferencesGetDictionary(domain);
        NSCAssert(dict != NULL, @"Invalid preferences dictionary");
        value = (id)CFDictionaryGetValue(dict, key);
      }
      /* If editor context or memory cache return NULL, get system preference */
      if (!value) {
        value = (id)CFPreferencesCopyValue((CFStringRef)key, kSparkPreferencesIdentifier, 
                                           kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        [value autorelease];
      }
      return value;
    }
    case SparkPreferencesLibrary:
      return [SparkActiveLibrary() preferenceValueForKey:key];
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
  return nil;
}
BOOL SparkPreferencesGetBooleanValue(NSString *key, SparkPreferencesDomain domain) {
  return [SparkPreferencesGetValue(key, domain) boolValue];
}
NSInteger SparkPreferencesGetIntegerValue(NSString *key, SparkPreferencesDomain domain) {
  return SKIntegerValue(SparkPreferencesGetValue(key, domain));
}

#pragma mark Setter
void SparkPreferencesSetValue(NSString *key, id value, SparkPreferencesDomain domain) {
  DLog(@"SparkPreferencesSetValue(%@, %@, %i)", key, value, domain);
  /* If daemon context, register preferences port */
  if (SparkGetCurrentContext() != kSparkEditorContext) {
    _SparkPreferencesStartServer();
  }
  
  switch (domain) {
    case SparkPreferencesDaemon:
    case SparkPreferencesFramework: {
      if (SparkGetCurrentContext() == kSparkEditorContext) {
        CFPreferencesSetValue((CFStringRef)key, (CFPropertyListRef)value, 
                              kSparkPreferencesIdentifier,
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      } else {
        CFMutableDictionaryRef dict = _SparkPreferencesGetDictionary(domain);
        NSCAssert(dict != NULL, @"Invalid preferences dictionary");
        if (value) {
          CFDictionarySetValue(dict, key, value);
        } else {
          CFDictionaryRemoveValue(dict, key);
        }
      }
    }
      break;
    case SparkPreferencesLibrary:
      [SparkActiveLibrary() setPreferenceValue:value forKey:key];
      break;
    default:
      [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
      break;
  }
  SparkPreferencesNotifyObservers(key, value, domain);
  if (SparkGetCurrentContext() == kSparkEditorContext) {
    /* Sync daemon */
    _SparkPreferencesSetDaemonValue(key, value, domain);
  }
}
void SparkPreferencesSetBooleanValue(NSString *key, BOOL value, SparkPreferencesDomain domain) {
  SparkPreferencesSetValue(key, SKBool(value), domain);
}
void SparkPreferencesSetIntegerValue(NSString *key, NSInteger value, SparkPreferencesDomain domain) {
  SparkPreferencesSetValue(key, SKInteger(value), domain);
}

#pragma mark Synchronize
Boolean SparkPreferencesSynchronize(SparkPreferencesDomain domain) {
  if (SparkGetCurrentContext() != kSparkEditorContext) {
    WLog(@"Try to synchronize preferences but not in editor context");
    return false;
  }
  switch (domain) {
    case SparkPreferencesDaemon:
      return CFPreferencesSynchronize(kSparkPreferencesIdentifier,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    case SparkPreferencesLibrary:
      return SparkLibraryPreferencesSynchronize();
    case SparkPreferencesFramework:
      return CFPreferencesSynchronize(kSparkPreferencesIdentifier,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
  return false;
}

#pragma mark -
#pragma mark Observers
@interface _SparkPreferencesObserver : NSObject {
  id sp_target;
  SEL sp_action;
}

- (id)initWithTarget:(id)target action:(SEL)action;

- (id)target;

- (void)notifyValueChange:(id)value forKey:(NSString *)key;

@end

static NSMapTable *sDaemonObservers = NULL;
static NSMapTable *sLibraryObservers = NULL;
static NSMapTable *sFrameworkObservers = NULL;

static NSString * const kSparkPreferencesWildcard = @"__****__";

static
NSMapTable *_SparkPreferencesGetObservers(SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      return sDaemonObservers;
    case SparkPreferencesLibrary:
      return sLibraryObservers;
    case SparkPreferencesFramework:
      return sFrameworkObservers;
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %li", domain];
  return NULL;
}

static
void _SparkPreferencesSetObservers(NSMapTable *observers, SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      sDaemonObservers = observers;
      break;
    case SparkPreferencesLibrary:
      sLibraryObservers = observers;
      break;
    case SparkPreferencesFramework:
      sFrameworkObservers = observers;
      break;
    default:
      [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %li", domain];
  }
}

SK_INLINE
void __SparkPreferencesNotifyObservers(NSHashTable *observers, NSString *key, id value) {
  if (observers) {
    _SparkPreferencesObserver *observer;
    NSHashTable *copy = NSCopyHashTableWithZone(observers, NULL);
    NSHashEnumerator items = NSEnumerateHashTable(copy);
    while (observer = NSNextHashEnumeratorItem(&items)) {
      if ([observer target]) {
        [observer notifyValueChange:value forKey:key];
      } else {
        NSHashRemove(observers, observer);
      }
    }
    NSEndHashTableEnumeration(&items);
  }  
}

static
void SparkPreferencesNotifyObservers(NSString *key, id value, SparkPreferencesDomain domain) {
  NSCParameterAssert(key);
  NSMapTable *table = _SparkPreferencesGetObservers(domain);
  if (table) {
    __SparkPreferencesNotifyObservers(NSMapGet(table, key), key, value);
    __SparkPreferencesNotifyObservers(NSMapGet(table, kSparkPreferencesWildcard), key, value);
  }
}

void SparkPreferencesRegisterObserver(id object, SEL callback, NSString *key, SparkPreferencesDomain domain) {
  NSMapTable *table = _SparkPreferencesGetObservers(domain);
  if (!table) {
    table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
    _SparkPreferencesSetObservers(table, domain);
  }
  if (!key) key = kSparkPreferencesWildcard;
  NSHashTable *observers = NSMapGet(table, key);
  if (!observers) {
    observers = NSCreateHashTable(NSObjectHashCallBacks, 0);
    NSMapInsert(table, key, observers);
  }
  _SparkPreferencesObserver *observer = [[_SparkPreferencesObserver alloc] initWithTarget:object action:callback];
  NSHashInsert(observers, observer);
  [observer release];
}

SK_INLINE
void __SparkPreferencesRemoveObserver(NSMapTable *table, NSHashTable *observers, id observer, NSString *key) {
  if (observers) {
    NSHashRemove(observers, observer);
    /* Cleanup */
    if (!NSCountHashTable(observers)) {
      NSMapRemove(table, key);
      NSFreeHashTable(observers);
    }
  }
}

void SparkPreferencesUnregisterObserver(id observer, NSString *key, SparkPreferencesDomain domain) {
  NSMapTable *table = _SparkPreferencesGetObservers(domain);
  if (table) {
    /* If key is null, remove observer for all entries */
    if (!key) {
      NSHashTable *observers;
      NSMapTable *copy = NSCopyMapTableWithZone(table, NULL);
      NSMapEnumerator iter = NSEnumerateMapTable(copy);
      while (NSNextMapEnumeratorPair(&iter, (void **)&key, (void **)&observers)) {
        __SparkPreferencesRemoveObserver(table, observers, observer, key);
      }
      NSEndMapTableEnumeration(&iter);
      NSFreeMapTable(copy);
    } else {
      __SparkPreferencesRemoveObserver(table, NSMapGet(table, key), observer, key);
    }
    /* Cleanup */
    if (!NSCountMapTable(table)) {
      NSFreeMapTable(table);
      _SparkPreferencesSetObservers(NULL, domain);
    }
  }
}

@implementation _SparkPreferencesObserver

- (id)initWithTarget:(id)target action:(SEL)action {
  if (self = [super init]) {
    sp_target = target;
    sp_action = action;
  }
  return self;
}

- (NSUInteger)hash {
  return [sp_target hash];
}

- (BOOL)isEqual:(id)object {
  return [sp_target isEqual:object];
}

- (id)target {
  return sp_target;
}

- (void)notifyValueChange:(id)value forKey:(NSString *)key {
  @try {
    [sp_target performSelector:sp_action withObject:value withObject:key];
  } @catch (id exception) {
    SKLogException(exception);
  }
}

@end

#pragma mark -
@implementation SparkLibrary (SparkPreferences)

- (NSMutableDictionary *)preferences {
  return sp_prefs ? : SparkLibraryGetPreferences(self);
}
- (void)setPreferences:(NSDictionary *)preferences {
  SKSetterMutableCopy(sp_prefs, preferences);
}

@end

@implementation SparkLibrary (SparkPreferencesPrivate)

- (id)preferenceValueForKey:(NSString *)key {
  return [[self preferences] objectForKey:key];
}

- (void)setPreferenceValue:(id)value forKey:(NSString *)key {
  if (value) {
    [[self preferences] setObject:value forKey:key];
  } else {
    [[self preferences] removeObjectForKey:key];
  }
}

@end

