/*
 *  KeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>

#import "KeyMap.h"
#import "HKKeyMap.h"
#import "HKKeyboardUtils.h"

#pragma mark Structure Definition
struct __HKKeyMap {
  Boolean reverse;
  KeyboardLayoutRef keyboard;
  KeyboardLayoutIdentifier identifier;
  HKKeyMapContext ctxt;
};

#pragma mark -
#pragma mark Statics Functions
HK_INLINE
UInt32 __CurrentKCHRId(void) {
  UInt32 uid = 0;
  KeyboardLayoutRef ref;
  KLGetCurrentKeyboardLayout(&ref);
  KLGetKeyboardLayoutProperty(ref, kKLIdentifier, (void *)&uid);
  return uid;
}

static
OSStatus _HKKeyMapInit(HKKeyMapRef keyMap) {
  /* find the current layout resource ID */
  KeyboardLayoutKind kind = 0;
  KeyboardLayoutPropertyTag tag = 0;
  KLGetKeyboardLayoutProperty(keyMap->keyboard, kKLIdentifier, (void *)&(keyMap->identifier));
  
  OSStatus err = KLGetKeyboardLayoutProperty(keyMap->keyboard, kKLKind, (void *)&kind);
  if (noErr == err) {
    switch (kind) {
      case kKLuchrKind:
      case kKLKCHRuchrKind:
        // Load uchr data
        tag = kKLuchrData;
        break;
      case kKLKCHRKind:
        // load kchr data
        tag = kKLKCHRData;
        break;
    }
  }
  const void *data = NULL;
  if (noErr == err) {
    err = KLGetKeyboardLayoutProperty(keyMap->keyboard, tag, (void *)&data);
  }
  if (noErr == err) {
    switch (kind) {
      case kKLuchrKind:
      case kKLKCHRuchrKind:
        // Load uchr data
        err = HKKeyMapContextWithUchrData(data, keyMap->reverse, &keyMap->ctxt);
        break;
      case kKLKCHRKind:
        // load kchr data
        err = HKKeyMapContextWithKCHRData(data, keyMap->reverse, &keyMap->ctxt);
        break;
    }
  }
  return err;
}

static
void _HKKeyMapDispose(HKKeyMapRef keyMap) {
  keyMap->keyboard = NULL;
  if (keyMap->ctxt.dealloc) {
    keyMap->ctxt.dealloc(&keyMap->ctxt);
    bzero(&keyMap->ctxt, sizeof(keyMap->ctxt));
  }
}

#pragma mark -
#pragma mark Creation/Destruction functions.
static
HKKeyMapRef HKKeyMapCreateWithKeyboardLayout(KeyboardLayoutRef layout, Boolean reverse) {
  HKKeyMapRef keymap = NSZoneCalloc(nil, 1, sizeof(struct __HKKeyMap));
  if (keymap) {
    keymap->reverse = reverse;
    keymap->keyboard = layout;
    if (noErr != _HKKeyMapInit(keymap)) {
      HKKeyMapRelease(keymap);
      keymap = nil;
    }
  }
  return keymap;
}

HKKeyMapRef HKKeyMapCreateWithName(CFStringRef name, Boolean reverse) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetKeyboardLayoutWithName(name, &ref)) {
    return HKKeyMapCreateWithKeyboardLayout(ref, reverse);
  }
  return NULL;
}

HKKeyMapRef HKKeyMapCreateWithIdentifier(SInt32 identifier, Boolean reverse) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetKeyboardLayoutWithIdentifier(identifier, &ref)) {
    return HKKeyMapCreateWithKeyboardLayout(ref, reverse);
  }
  return NULL;  
}

HKKeyMapRef HKKeyMapCreateWithCurrentLayout(Boolean reverse) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetCurrentKeyboardLayout(&ref)) {
    return HKKeyMapCreateWithKeyboardLayout(ref, reverse);
  }
  return NULL;
}

void HKKeyMapRelease(HKKeyMapRef keymap) {
  _HKKeyMapDispose(keymap);
  NSZoneFree(nil, keymap);
}

#pragma mark -
#pragma mark Public Functions Definition.
OSStatus HKKeyMapCheckCurrentMap(HKKeyMapRef keyMap, Boolean *wasChanged) {
  SInt32 theID = __CurrentKCHRId();
  if (theID != keyMap->identifier) {
    if (wasChanged)
      *wasChanged = YES;
    _HKKeyMapDispose(keyMap);
    return _HKKeyMapInit(keyMap);
  }
  else {
    if (wasChanged)
      *wasChanged = NO;
    return noErr;
  }
}

UInt32 HKKeyMapGetKeycodesForUnichar(HKKeyMapRef keyMap, UniChar character, UInt32 *keys, UInt32 *modifiers, UInt32 maxsize) {
  UInt32 count = 0;
  if (keyMap->reverse && keyMap->ctxt.reverseMap) {
    count = keyMap->ctxt.reverseMap(keyMap->ctxt.data, character, keys, modifiers, maxsize);
  }
  return count;
}

UniChar HKKeyMapGetUnicharForKeycode(HKKeyMapRef keyMap, UInt32 virtualKeyCode) {
  UniChar result = kHKNilUnichar;
  if (keyMap->ctxt.baseMap) {
    result = keyMap->ctxt.baseMap(keyMap->ctxt.data, virtualKeyCode);
  }
  return result;
}

UniChar HKKeyMapGetUnicharForKeycodeAndModifier(HKKeyMapRef keyMap, UInt32 virtualKeyCode, UInt32 modifiers) {
  UniChar result = kHKNilUnichar;
  if (keyMap->ctxt.fullMap) {
    result = keyMap->ctxt.fullMap(keyMap->ctxt.data, virtualKeyCode, modifiers);
  }
  return result;
}

CFStringRef HKKeyMapGetName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  KLGetKeyboardLayoutProperty(keymap->keyboard, kKLName, (void *)&str);
  return str;
}

CFStringRef HKKeyMapGetLocalizedName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  KLGetKeyboardLayoutProperty(keymap->keyboard, kKLLocalizedName, (void *)&str);
  return str;
}

