/*
 *  SparkPlugInView.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

@class SparkActionPlugIn;
@interface SparkPlugInView : NSViewController {
@private
  IBOutlet NSView *uiTrap;
  IBOutlet NSView *uiView;
  IBOutlet NSImageView *uiIcon;
  IBOutlet NSTextField *uiName;
}

- (void)setPlugIn:(SparkActionPlugIn *)aPlugin;
- (void)setPlugInView:(NSView *)aView;

- (NSView *)trapPlaceholder;

@end
