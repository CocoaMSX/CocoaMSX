//
//  MGScopeBar.h
//  MGScopeBar
//
//  Created by Matt Gemmell on 15/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import <Cocoa/Cocoa.h>
#import "MGScopeBarDelegateProtocol.h"

@interface MGScopeBar : NSView {
@private
    /// weak ref.
	__weak id <MGScopeBarDelegate> delegate;
	/// x-coords of separators, indexed by their group-number.
	NSMutableArray *_separatorPositions;
	/// groups of items.
	NSMutableArray *_groups;
	/// weak ref since it's a subview.
	__weak NSView *_accessoryView;
	/// map of identifiers to items.
	NSMutableDictionary<NSObject<NSCopying>*,id> *_identifiers;
	/// all selected items in all groups; see note below.
	NSMutableArray<NSMutableArray<NSObject<NSCopying>*>*> *_selectedItems;
	/// previous width of view from when we last resized.
	CGFloat _lastWidth;
	/// index of first group collapsed into a popup.
	NSInteger _firstCollapsedGroup;
	/// total width needed to show all groups expanded (excluding padding and accessory).
	CGFloat _totalGroupsWidthForPopups;
	/// total width needed to show all groups as native-width popups (excluding padding and accessory).
	CGFloat _totalGroupsWidth;
	/// whether to do our clever collapsing/expanding of buttons when resizing (Smart Resizing).
	BOOL _smartResizeEnabled;
}

/// should implement the MGScopeBarDelegate protocol.
@property (nonatomic, weak) IBOutlet id<MGScopeBarDelegate> delegate;

/// causes the scope-bar to reload all groups/items from its delegate.
- (void)reloadData;
/// only resizes vertically to optimum height; does not affect width.
- (void)sizeToFit;
/// performs Smart Resizing if enabled. You should only need to call this yourself if you change the width of the accessoryView.
- (void)adjustSubviews;

/// Smart Resize is the intelligent conversion of button-groups into NSPopUpButtons and vice-versa, based on available space.
/// This functionality is enabled (YES) by default. Changing this setting will automatically call -reloadData.
@property (nonatomic) BOOL smartResizeEnabled;
- (void)setSmartResizeEnabled:(BOOL)enabled;

// The following method must be used to manage selections in the scope-bar; do not attempt to manipulate buttons etc directly.
- (void)setSelected:(BOOL)selected forItem:(NSObject<NSCopying>*)identifier inGroup:(NSInteger)groupNumber;
- (NSArray<NSArray<NSObject<NSCopying>*>*> *)selectedItems;

/*
 Note:	The -selectedItems method returns an array of arrays.
		Each index in the returned array represents the group of items at that index.
		The contents of each sub-array are the identifiers of each selected item in that group.
		Sub-arrays may be empty, but will always be present (i.e. you will always find an NSArray).
		Depending on the group's selection-mode, sub-arrays may contain zero, one or many identifiers.
		The identifiers in each sub-array are not in any particular order.
 */

@end
