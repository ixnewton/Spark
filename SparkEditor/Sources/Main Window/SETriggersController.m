/*
 *  SETriggersController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SETriggersController.h"
#import "SELibraryDocument.h"
#import "SELibraryWindow.h"
#import "SESparkEntrySet.h"
#import "SETriggerTable.h"
#import "SEPreferences.h"
#import "SEEntryEditor.h"
#import "Spark.h"

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkEntryManager.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKImageAndTextCell.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
BOOL _SEEntryFilter(NSString *search, SparkEntry *entry, void *ctxt) {
  /* Hide unplugged if needed */
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kSEPreferencesHideDisabled] && ![entry isPlugged]) return NO;
  
  if (!search) return YES;
  
  if ([[entry name] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  if ([[entry actionDescription] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  if ([[entry categorie] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  return NO;
}

typedef struct _SETriggerStyle {
  BOOL bold;
  BOOL strike;
  NSColor *standard, *selected;
} SETriggerStyle;

static
SETriggerStyle styles[6];

static 
NSString * sSEHiddenPluggedObserverKey = nil;

@implementation SETriggersController

+ (void)initialize {
  if ([SETriggersController class] == self) {
    /* Standard (global) */
    styles[0] = (SETriggerStyle){NO, NO,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Global overrided */
    styles[1] = (SETriggerStyle){YES, NO,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Inherits */
    styles[2] = (SETriggerStyle){NO, NO,
      [[NSColor darkGrayColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Override */
    styles[3] = (SETriggerStyle){YES, NO,
      [[NSColor colorWithCalibratedRed:.067f green:.357f blue:.420f alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.886f green:.914f blue:.996f alpha:1] retain]};
    /* Specifics */
    styles[4] = (SETriggerStyle){NO, NO,
      [[NSColor orangeColor] retain],
      [[NSColor colorWithCalibratedRed:.992f green:.875f blue:.749f alpha:1] retain]};
    /* Weak Override */
    styles[5] = (SETriggerStyle){NO, YES,
      [[NSColor colorWithCalibratedRed:.463f green:.016f blue:.314f alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.984f green:.890f blue:1.00f alpha:1] retain]};
    
    sSEHiddenPluggedObserverKey = [[@"values." stringByAppendingString:kSEPreferencesHideDisabled] retain];
  }
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:sSEHiddenPluggedObserverKey
                                                                 options:NSKeyValueObservingOptionNew
                                                                 context:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self
                                                               forKeyPath:sSEHiddenPluggedObserverKey];
  [super dealloc];
}

#pragma mark -
- (SparkLibrary *)library {
  return [ibWindow library];
}
- (SparkApplication *)application {
  return [ibWindow application];
}

- (void)awakeFromNib {
  [self setFilterFunction:_SEEntryFilter context:nil];
  
  [uiTable setTarget:self];
  [uiTable setDoubleAction:@selector(doubleAction:)];
  
  [uiTable setSortDescriptors:gSortByNameDescriptors];
  
  [uiTable setAutosaveName:@"SparkTriggerTable"];
  [uiTable setAutosaveTableColumns:YES];
  
  [uiTable setVerticalMotionCanBeginDrag:YES];
  [uiTable setContinueEditing:NO];
}

- (NSView *)tableView {
  return uiTable;
}

- (void)setListEnabled:(BOOL)flag {
  SparkUID app = [[self application] uid];
  NSUInteger idx = [self count];
  SparkEntryManager *manager = [[self library] entryManager];
  SEL method = flag ? @selector(enableEntry:) : @selector(disableEntry:);
  while (idx-- > 0) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([[entry application] uid] == app) {
      if (XOR([entry isEnabled], flag)) {
        [manager performSelector:method withObject:entry];
      }
    }
  }
  [uiTable reloadData];
}

- (IBAction)search:(id)sender {
  [self setSearchString:[sender stringValue]];
}

- (IBAction)doubleAction:(id)sender {
  /* Does not support multi-edition */
  if ([[self selectedObjects] count] != 1) {
    NSBeep();
    return;
  }
  
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([entry isPlugged]) {
      [[ibWindow document] editEntry:entry];
    } else {
      NSBeep();
    }
  }
}

#pragma mark -
#pragma mark Data Source
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
  /* Should not allow all columns */
  return [[tableColumn identifier] isEqualToString:@"__item__"] || [[tableColumn identifier] isEqualToString:@"active"];
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {

}

- (IBAction)selectAll:(id)sender {
  ShadowTrace();
}

#pragma mark Delegate
- (void)spaceDownInTableView:(SETriggerTable *)aTable {
  NSUInteger idx = 0;
  SparkEntryManager *manager = [[self library] entryManager];
  SKIndexEnumerator *idexes = [[self selectionIndexes] indexEnumerator];
  while ((idx = [idexes nextIndex]) != NSNotFound) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([entry isPlugged]) {
      if ([entry isEnabled])
        [manager disableEntry:entry];
      else
        [manager enableEntry:entry];
    }
  }
}

- (BOOL)tableView:(SETriggerTable *)aTable shouldHandleOptionClick:(NSEvent *)anEvent {
  NSPoint point = [aTable convertPoint:[anEvent locationInWindow] fromView:nil];
  NSInteger row = [aTable rowAtPoint:point];
  NSInteger column = [aTable columnAtPoint:point];
  if (row != -1 && column != -1) {
    if ([[[[aTable tableColumns] objectAtIndex:column] identifier] isEqualToString:@"active"]) {
      SparkEntry *entry = [self objectAtIndex:row];
      [self setListEnabled:![entry isEnabled]];
      return NO;
    }
  }
  return YES;
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  NSArray *items = [self selectedObjects];
  if (items && [items count]) {
    if ([[ibWindow selectedList] isEditable]) {
      // User list
      [[ibWindow selectedList] removeEntries:items];
    } else {
      [[ibWindow document] removeEntries:items];
    }
  }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  SparkEntry *entry = [self objectAtIndex:rowIndex];
  
  /* Text field cell */
  if ([aCell respondsToSelector:@selector(setTextColor:)]) {  
    SparkApplication *application = [self application];
    
    SInt32 idx = -1;
    if (0 == [application uid]) {
      /* Global key */
      if ([[[self library] entryManager] containsOverwriteEntryForTrigger:[[entry trigger] uid]]) {
        idx = 1;
      } else {
        idx = 0;
      }
    } else {
      switch ([entry type]) {
        case kSparkEntryTypeDefault:
          /* Inherits */
          idx = 2;
          break;
        case kSparkEntryTypeOverWrite:
          idx = 3;
          break;
        case kSparkEntryTypeSpecific: 
          /* Is only defined for a specific application */
          idx = 4;
          break;
        case kSparkEntryTypeWeakOverWrite:
          idx = 5;
          break;
      }
    }
    if (idx >= 0) {
      NSWindow *window = [aTableView window];
      BOOL selected = ([window isKeyWindow] && [window firstResponder] == aTableView) && [aTableView isRowSelected:rowIndex];
      if ([entry isPlugged]) {
        [aCell setTextColor:selected ? styles[idx].selected : styles[idx].standard];
      } else {
        /* handle case where plugin is disabled */
        [aCell setTextColor:selected ? [NSColor selectedControlTextColor] : [NSColor disabledControlTextColor]];
      }
      /* Set Line status */
      if ([aCell respondsToSelector:@selector(setDrawsLineOver:)])
        [aCell setDrawsLineOver:styles[idx].strike && ![entry isEnabled]];
      
      CGFloat size = [NSFont smallSystemFontSize];
      [aCell setFont:styles[idx].bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
    }
  }
}

#pragma mark Drag & Drop
- (BOOL)tableView:(NSTableView *)aTableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  NSMutableIndexSet *idxes = [NSMutableIndexSet indexSet];
  NSUInteger count = [rows count];
  while (count-- > 0) {
    [idxes addIndex:[[rows objectAtIndex:count] unsignedIntValue]];
  }
  return [self tableView:aTableView writeRowsWithIndexes:idxes toPasteboard:pboard];
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  if (![rowIndexes count])
    return NO;
  
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  CFUUIDBytes bytes = CFUUIDGetUUIDBytes([[self library] uuid]);
  [plist setObject:[NSData dataWithBytes:&bytes length:sizeof(bytes)] forKey:@"uuid"];
  [pboard declareTypes:[NSArray arrayWithObject:SparkEntriesPboardType] owner:self];
  
  NSUInteger idx = 0;
  NSMutableArray *triggers = [[NSMutableArray alloc] init];
  SKIndexEnumerator *indexes = [rowIndexes indexEnumerator];
  while ((idx = [indexes nextIndex]) != NSNotFound) {
    SparkTrigger *trigger = [[self objectAtIndex:idx] trigger];
    [triggers addObject:SKUInt([trigger uid])];
  }
  [plist setObject:triggers forKey:@"triggers"];
  [triggers release];
  
  [pboard setPropertyList:plist forType:SparkEntriesPboardType];
  [plist release];
  return YES;
}

#pragma mark Context Menu
- (NSMenu *)tableView:(NSTableView *)aTableView menuForRow:(NSInteger)row {
  if (row >= 0) {
    SparkEntry *entry = [self objectAtIndex:row];
    SparkEntryManager *manager = [[self library] entryManager];
    if ([manager containsOverwriteEntryForTrigger:[[entry trigger] uid]]) {
      NSMenu *ctxt = [[NSMenu alloc] initWithTitle:@"Action Menu"];
      NSMenuItem *item = [ctxt addItemWithTitle:@"Show in Application..." action:nil keyEquivalent:@""];
      NSArray *entries = [manager entriesForTrigger:[[entry trigger] uid]];
      NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Submenu"];
      for (NSUInteger idx = 0; idx < [entries count]; idx++) {
        SparkApplication *app = [[entries objectAtIndex:idx] application];
        NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:[app name] 
                                                         action:@selector(revealInApplication:) keyEquivalent:@""];
        [appItem setRepresentedObject:[entries objectAtIndex:idx]];
        NSImage *icon = [[app icon] copy];
        [icon setSize:NSMakeSize(16, 16)];
        [appItem setImage:icon];
        [icon release];
        
        [submenu addItem:appItem];
        [appItem release];
      }
      [item setSubmenu:submenu];
      [submenu release];
      
      return [ctxt autorelease];
    }
  }
  return nil;
}

#pragma mark Notifications
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  [self rearrangeObjects];
}

@end

#pragma mark -
@implementation SparkEntry (SETriggerSort)

+ (void)load {
  if ([SparkEntry class] == self) {
    SKExchangeInstanceMethods(self, @selector(setEnabled:), @selector(se_setEnabled:));
  }
}

- (NSUInteger)triggerValue {
  return [[self trigger] character] << 16 | [[self trigger] modifier] & 0xff;
}

- (void)setActive:(BOOL)active {
  SELibraryDocument *document = SEGetDocumentForLibrary([[self action] library]);
  if (document) {
    SparkEntry *entry = self;
    SparkApplication *application = [document application];
    if ([application uid] != 0 && kSparkEntryTypeDefault == [self type]) {
      /* Inherits: should create an new entry */
      entry = [[self copy] autorelease];
      [entry setApplication:application];
      [[[document library] entryManager] addEntry:entry];
      [[document mainWindowController] revealEntry:entry];
    }
    if (active) {
      [[[document library] entryManager] enableEntry:entry];
    } else {
      [[[document library] entryManager] disableEntry:entry];
    }
  }
}

- (void)se_setEnabled:(BOOL)enabled {
  if ([self type] == kSparkEntryTypeWeakOverWrite) [self willChangeValueForKey:@"representation"];
  [self willChangeValueForKey:@"active"];
  [self se_setEnabled:enabled];
  [self didChangeValueForKey:@"active"];
  if ([self type] == kSparkEntryTypeWeakOverWrite) [self didChangeValueForKey:@"representation"];
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)name {
  if (name && [name length]) {
    SparkAction *act = [self action];
    if (act) {
      [[[act library] undoManager] registerUndoWithTarget:self
                                                 selector:@selector(setRepresentation:)
                                                   object:[act name]];
      [act setName:name];
    }
  } else {
    NSBeep();
  }
}

@end
