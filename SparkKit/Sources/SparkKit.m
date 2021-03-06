/*
 *  SparkKit.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
/* MUST be include for SparkDaemonStatusKey */
#import <SparkKit/SparkAppleScriptSuite.h>

#import <SparkKit/SparkPreferences.h>

#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBLSFunctions.h>

NSString * const kSparkErrorDomain = @"com.xenonium.SparkErrorDomain";

NSString * const kSparkFolderName = @"Spark";

NSString * const kSparkKitBundleIdentifier = @"com.xenonium.SparkKit";

NSString * const kSparkEditorBundleIdentifier = @"com.xenonium.Spark";
NSString * const kSparkDaemonBundleIdentifier = @"com.xenonium.Spark.daemon";

#pragma mark Distributed Notifications
NSString * const SparkDaemonStatusKey = @"SparkDaemonStatusKey";
NSString * const SparkDaemonStatusDidChangeNotification = @"SparkDaemonStatusDidChange";

const OSType kSparkEditorSignature = 'Sprk';
const OSType kSparkDaemonSignature = 'SprS';

NSString * kSparkFinderBundleIdentifier = @"com.apple.finder";

static __attribute__((constructor)) 
void __SparkInitializeLibrary(void) {
  NSString *str = SparkPreferencesGetValue(@"SparkFinderBundleIdentifier", SparkPreferencesFramework);
  if (str) {
    if (![str isKindOfClass:[NSString class]]) {
      SparkPreferencesSetValue(@"SparkFinderBundleIdentifier", NULL, SparkPreferencesFramework);
    } else {
      if (WBLSCopyApplicationURLForBundleIdentifier(SPXNSToCFString(str)))
        kSparkFinderBundleIdentifier = str;
    }
  }
}
