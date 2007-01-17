/*
 *  SEBuiltInPlugin.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEBuiltInPlugin.h"

@implementation SEInheritsPlugin

+ (Class)actionClass {
  return Nil;
}

+ (NSString *)plugInName {
  return @"Globals Setting";
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"applelogo"];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibPath {
  return [[NSBundle mainBundle] pathForResource:@"SEInheritsPlugin" ofType:@"nib"];
}

@end
