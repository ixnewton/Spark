/*
 *  SparkLibrary.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>

SPARK_EXPORT
NSPropertyListFormat SparkLibraryFileFormat;

SPARK_EXPORT
NSString * const kSparkLibraryFileExtension;

SPARK_EXPORT
NSString * const kSparkLibraryDefaultFileName;

SPARK_EXPORT
NSString *SparkLibraryDefaultFolder(void);

enum {
  kSparkLibraryReserved = 0xff
};

#pragma mark -
@class SparkLibrary, SparkObjectSet, SparkEntryManager;

SPARK_EXPORT
SparkLibrary *SparkActiveLibrary(void);
SPARK_EXPORT
BOOL SparkSetActiveLibrary(SparkLibrary *library);

#pragma mark -
@class SparkApplication, SparkEntryManager;
@interface SparkLibrary : NSObject {
  @private
  NSString *sp_file;
  CFUUIDRef sp_uuid;
  
  SparkObjectSet *sp_objects[4];
  SparkEntryManager *sp_relations;
  
  struct _sp_slFlags {
    unsigned int loaded:1;
    unsigned int reserved:31;
  } sp_slFlags;
  
  /* Model synchronization */
  NSUndoManager *sp_undo;
  NSNotificationCenter *sp_center;
}

- (id)initWithPath:(NSString *)path;

- (CFUUIDRef)uuid;

- (NSString *)path;
- (void)setPath:(NSString *)file;

- (NSUndoManager *)undoManager;
- (void)setUndoManager:(NSUndoManager *)aManager;

- (NSNotificationCenter *)notificationCenter;

- (BOOL)isLoaded;
- (BOOL)readLibrary:(NSError **)error;

- (SparkObjectSet *)listSet;
- (SparkObjectSet *)actionSet;
- (SparkObjectSet *)triggerSet;
- (SparkObjectSet *)applicationSet;

- (SparkEntryManager *)entryManager;
   
- (BOOL)synchronize;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

@end

#pragma mark Debugger
SPARK_EXPORT
void SparkDumpTriggers(SparkLibrary *aLibrary);
