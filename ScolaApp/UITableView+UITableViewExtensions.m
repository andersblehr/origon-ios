//
//  UITableView+UITableViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UITableView+UITableViewExtensions.h"

#import "UIView+ScViewExtensions.h"


@implementation UITableView (UITableViewExtensions)

- (void)insertCellForRow:(NSInteger)row inSection:(NSInteger)section;
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self beginUpdates];
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self endUpdates];
    
    BOOL isLastRowInSection = ([self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row + 1 inSection:section]] == nil);
    
    if (isLastRowInSection) {
        UITableViewCell *precedingCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row - 1 inSection:section]];
        
        [precedingCell.backgroundView addShadowForMiddleOrTopTableViewCell];
    }
}

@end
