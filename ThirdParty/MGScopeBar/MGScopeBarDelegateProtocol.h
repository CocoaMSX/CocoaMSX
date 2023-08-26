//
//  MGScopeBarDelegateProtocol.h
//  MGScopeBar
//
//  Created by Matt Gemmell on 15/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Selection modes for the buttons within a group.
typedef NS_ENUM(NSInteger, MGScopeBarGroupSelectionMode) {
	/// Exactly one item in the group will be selected at a time (no more, and no less).
    MGRadioSelectionMode         = 0,
	/// Any number of items in the group (including none) may be selected at a time.
    MGMultipleSelectionMode      = 1
};


@class MGScopeBar;
@protocol MGScopeBarDelegate <NSObject>


// Methods used to configure the scope bar.
// Note: all groupNumber parameters are zero-based.

@required
- (NSInteger)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar;
- (nullable NSArray<NSObject<NSCopying>*> *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(NSInteger)groupNumber;
- (nullable NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(NSInteger)groupNumber; // return nil or an empty string for no label.
- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(NSInteger)groupNumber;
- (nullable NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(NSObject<NSCopying>*)identifier inGroup:(NSInteger)groupNumber;

@optional
// If the following method is not implemented, all groups except the first will have a separator before them.
- (BOOL)scopeBar:(MGScopeBar *)theScopeBar showSeparatorBeforeGroup:(NSInteger)groupNumber;
- (nullable NSImage *)scopeBar:(MGScopeBar *)theScopeBar imageForItem:(NSObject<NSCopying>*)identifier inGroup:(NSInteger)groupNumber; // default is no image. Will be shown at 16x16.
- (nullable NSView *)accessoryViewForScopeBar:(MGScopeBar *)theScopeBar; // default is no accessory view.


// Notification methods.

@optional
- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected forItem:(NSObject< NSCopying>*)identifier inGroup:(NSInteger)groupNumber;


@end

NS_ASSUME_NONNULL_END
