/*
 *  TISKeyMap.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
 @header KeyMap
 */

#import "HKKeyboardUtils.h"
#include <Carbon/Carbon.h>

struct __HKKeyMap {
  Boolean reverse;
  union {
    struct {
      KeyboardLayoutRef keyboard;
      KeyboardLayoutIdentifier identifier;
    } kl;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
    struct {
      TISInputSourceRef keyboard;
      CFStringRef identifier;
    } tis;
#endif
  };
  HKKeyMapContext ctxt;
};

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4

SK_INLINE
Boolean HKTISAvailable() {
  return TISInputSourceGetTypeID != NULL;
}

SK_PRIVATE
OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap);
SK_PRIVATE
void HKTISKeyMapDispose(HKKeyMapRef keyMap);

SK_PRIVATE
HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name, Boolean reverse);

SK_PRIVATE
HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(Boolean reverse);


SK_PRIVATE
Boolean HKTISKeyMapIsCurrent(HKKeyMapRef keyMap);

SK_PRIVATE
CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap);

SK_PRIVATE
CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap);

#else

SK_INLINE
Boolean HKTISAvailable() { return false; }

SK_INLINE
OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap) { return paramErr; }
SK_INLINE
void HKTISKeyMapDispose(HKKeyMapRef keyMap) {}

SK_INLINE
HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name, Boolean reverse) { return NULL; }

SK_INLINE
HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(Boolean reverse) { return NULL; }


SK_INLINE
Boolean HKTISKeyMapIsCurrent(HKKeyMapRef keyMap) { return true; }

SK_INLINE
CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap) { return NULL; }

SK_INLINE
CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap) { return NULL; }
#endif

/* Internal */
SK_PRIVATE
OSStatus _HKKeyMapInit(HKKeyMapRef keyMap);
