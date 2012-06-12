//
//  ScTableViewCell.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScCachedEntity;

typedef enum {
    ScCellColourTypeBackground,
    ScCellColourTypeSelectedBackground,
    ScCellColourTypeEditableBackground,
    ScCellColourTypeLabel,
    ScCellColourTypeDetail,
    ScCellColourTypeSelectedLabel,
    ScCellColourTypeSelectedDetail,
} ScCellColourType;

typedef enum {
    ScCellFontTypeLabel,
    ScCellFontTypeDetail,
    ScCellFontTypeEditableDetail,
} ScCellFontType;

@interface ScTableViewCell : UITableViewCell {
@private
    BOOL isSelectable;
    
    CGFloat labelLineHeight;
    CGFloat detailLineHeight;
    
    NSMutableDictionary *labels;
    NSMutableDictionary *details;
    
    CGFloat verticalOffset;
}

+ (ScTableViewCell *)defaultCellForTableView:(UITableView *)tableView;
+ (ScTableViewCell *)entityCellForEntity:(ScCachedEntity *)entity tableView:(UITableView *)tableView;

+ (UIColor *)colourOfType:(ScCellColourType)colourType;
+ (UIFont *)fontOfType:(ScCellFontType)fontType;

- (void)addLabel:(NSString *)label withDetail:(NSString *)detail;
- (UITextField *)addLabel:(NSString *)label withEditableDetail:(NSString *)detail;

- (id)viewForLabel:(NSString *)label;

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity;
+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels;

@end
