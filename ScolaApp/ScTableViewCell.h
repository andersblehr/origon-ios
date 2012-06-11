//
//  ScTableViewCell.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScCachedEntity;

@interface ScTableViewCell : UITableViewCell {
@private
    BOOL isSelectable;
    
    UIColor *backgroundColour;
    UIColor *editableDetailBackgroundColour;
    UIColor *labelColour;
    UIColor *detailColour;
    UIColor *selectedLabelColour;
    UIColor *selectedDetailColour;
    
    UIFont *labelFont;
    UIFont *detailFont;
    UIFont *editableDetailFont;
    
    CGFloat labelLineHeight;
    CGFloat detailLineHeight;
    
    NSMutableDictionary *labels;
    NSMutableDictionary *details;
    
    CGFloat verticalOffset;
}

+ (ScTableViewCell *)defaultCellForTableView:(UITableView *)tableView;
+ (ScTableViewCell *)entityCellForEntity:(ScCachedEntity *)entity tableView:(UITableView *)tableView;

- (void)addLabel:(NSString *)label withDetail:(NSString *)detail;
- (UITextField *)addLabel:(NSString *)label withEditableDetail:(NSString *)detail;

- (id)viewForLabel:(NSString *)label;

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity;
+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels;

@end
