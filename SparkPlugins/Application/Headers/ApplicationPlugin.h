/*
 *  ApplicationActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

#import "ApplicationAction.h"

@class SKImageView;
@interface ApplicationActionPlugin : SparkActionPlugIn {
  IBOutlet NSView *ibAppView;
  IBOutlet NSButton *ibOptions;
  IBOutlet NSTextField *ibApplication;
  
  IBOutlet NSTabView *ibTab;
  IBOutlet NSTextField *ibName;
  IBOutlet SKImageView *ibIcon;
  @private
    NSImage *aa_icon;
  NSString *aa_name;
  NSString *aa_path;
  LSLaunchFlags aa_flags;
  ApplicationVisualSetting aa_settings;
}

- (IBAction)back:(id)sender;
- (IBAction)options:(id)sender;
- (IBAction)chooseApplication:(id)sender;

- (ApplicationActionType)action;
- (void)setAction:(ApplicationActionType)anAction;

- (int)visual;
- (void)setVisual:(int)visual;

- (BOOL)notifyLaunch;
- (BOOL)notifyActivation;

- (void)setPath:(NSString *)path;
- (void)setFlags:(LSLaunchFlags)value;

- (BOOL)dontSwitch;
- (void)setDontSwitch:(BOOL)dontSwitch;
- (BOOL)newInstance;
- (void)setNewInstance:(BOOL)newInstance;
- (BOOL)hide;
- (void)setHide:(BOOL)hide;
- (BOOL)hideOthers;
- (void)setHideOthers:(BOOL)hideOthers;

@end