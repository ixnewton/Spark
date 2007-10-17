/*
 *  SparkIconManagerPrivate.h
 *  SparkKit
 *
 *  Created by Grayfox on 24/02/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkIconManager.h>

@class SparkObjectSet;
SK_EXPORT
SparkObjectSet *_SparkObjectSetForType(SparkLibrary *library, UInt8 type);

@interface _SparkIconEntry : NSObject {
  BOOL sp_clean;
  BOOL sp_loaded;
  
  @private
    NSImage *sp_icon;
  NSString *sp_path;
  NSImage *sp_ondisk;
}

- (BOOL)loaded;
- (BOOL)hasChanged;
- (void)applyChange;

- (id)initWithObject:(SparkObject *)object;

- (NSString *)path;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)anImage;

- (void)setCachedIcon:(NSImage *)anImage;

@end

@interface SparkIconManager (SparkPrivate)

- (_SparkIconEntry *)entryForObject:(SparkObject *)anObject;

@end
