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
    
    CGFloat labelLineHeight;
    CGFloat detailLineHeight;
    
    NSMutableDictionary *labels;
    NSMutableDictionary *details;
    
    CGFloat verticalOffset;
}

+ (UIColor *)backgroundColour;
+ (UIColor *)labelColour;
+ (UIColor *)detailColour;
+ (UIColor *)selectedBackgroundColour;
+ (UIColor *)selectedLabelColour;
+ (UIColor *)selectedDetailColour;
+ (UIColor *)editableFieldBackgroundColour;

+ (UIFont *)labelFont;
+ (UIFont *)detailFont;
+ (UIFont *)editableDetailFont;

+ (ScTableViewCell *)defaultCellForTableView:(UITableView *)tableView;
+ (ScTableViewCell *)entityCellForEntity:(ScCachedEntity *)entity tableView:(UITableView *)tableView;

- (void)addLabel:(NSString *)label withDetail:(NSString *)detail;
- (UITextField *)addLabel:(NSString *)label withEditableDetail:(NSString *)detail;

- (id)viewForLabel:(NSString *)label;

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity;
+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels;

@end
