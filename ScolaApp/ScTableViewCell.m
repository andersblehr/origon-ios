//
//  ScTableViewCell.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTableViewCell.h"

#import "UIColor+ScColorExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScStrings.h"

#import "ScCachedEntity.h"
#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"


static NSString * const kDefaultCell = @"cellDefault";

static CGFloat const kLabelFontSize = 12.f;
static CGFloat const kDetailFontSize = 14.f;

static CGFloat const kLabelOriginX = 5.f;
static CGFloat const kDetailOriginX = 82.f;
static CGFloat const kLabelWidth = 63.f;
static CGFloat const kDetailWidth = 113.f;

static CGFloat const kBezelSpace = 12.f;
static CGFloat const kLabelFontVerticalOffset = 3.f;
static CGFloat const kLineSpacing = 5.f;

static UIColor *backgroundColour = nil;
static UIColor *selectedBackgroundColour = nil;
static UIColor *labelColour = nil;
static UIColor *detailColour = nil;
static UIColor *selectedLabelColour = nil;
static UIColor *selectedDetailColour = nil;
static UIColor *editableFieldBackgroundColour = nil;

static UIFont *labelFont = nil;
static UIFont *detailFont = nil;
static UIFont *editableDetailFont = nil;



@implementation ScTableViewCell


#pragma mark - Auxiliary methods

- (void)populateWithEntity:(ScCachedEntity *)entity
{
    if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        NSString *addressLabel = [ScStrings stringForKey:strAddress];
        
        [self addLabel:addressLabel withDetail:[scola multiLineAddress]];
        
        if ([scola hasLandline]) {
            NSString *landlineLabel = [ScStrings stringForKey:strLandline];
            
            [self addLabel:landlineLabel withDetail:scola.landline];
        }
        
        verticalOffset = kBezelSpace;
    }
}


#pragma mark - Table view cell colours

+ (UIColor *)backgroundColour
{
    if (!backgroundColour) {
        backgroundColour = [UIColor isabellineColor];
    }
    
    return backgroundColour;
}


+ (UIColor *)labelColour
{
    if (!labelColour) {
        labelColour = [UIColor slateGrayColor];
    }
    
    return labelColour;
}


+ (UIColor *)detailColour
{
    if (!detailColour) {
        detailColour = [UIColor blackColor];
    }
    
    return detailColour;
}


+ (UIColor *)selectedBackgroundColour
{
    if (!selectedBackgroundColour) {
        selectedBackgroundColour = [UIColor ashGrayColor];
    }
    
    return selectedBackgroundColour;
}


+ (UIColor *)selectedLabelColour
{
    if (!selectedLabelColour) {
        selectedLabelColour = [UIColor lightTextColor];
    }
    
    return selectedLabelColour;
}


+ (UIColor *)selectedDetailColour
{
    if (!selectedDetailColour) {
        selectedDetailColour = [UIColor whiteColor];
    }
    
    return selectedDetailColour;
}


+ (UIColor *)editableFieldBackgroundColour
{
    if (!editableFieldBackgroundColour) {
        editableFieldBackgroundColour = [UIColor ghostWhiteColor];
    }
    
    return editableFieldBackgroundColour;
}


#pragma mark - Table view cell fonts

+ (UIFont *)labelFont
{
    if (!labelFont) {
        labelFont = [UIFont boldSystemFontOfSize:kLabelFontSize];
    }
    
    return labelFont;
}


+ (UIFont *)detailFont
{
    if (!detailFont) {
        detailFont = [UIFont boldSystemFontOfSize:kDetailFontSize];
    }
    
    return detailFont;
}


+ (UIFont *)editableDetailFont
{
    if (!editableDetailFont) {
        editableDetailFont = [UIFont systemFontOfSize:kDetailFontSize];
    }
    
    return editableDetailFont;
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        isSelectable = YES;
        
        backgroundColour = [ScTableViewCell backgroundColour];
        selectedBackgroundColour = [ScTableViewCell selectedBackgroundColour];
        labelColour = [ScTableViewCell labelColour];
        detailColour = [ScTableViewCell detailColour];
        selectedLabelColour = [ScTableViewCell selectedLabelColour];
        selectedDetailColour = [ScTableViewCell selectedDetailColour];
        editableFieldBackgroundColour = [ScTableViewCell editableFieldBackgroundColour];
        
        labelFont = [ScTableViewCell labelFont];
        detailFont = [ScTableViewCell detailFont];
        editableDetailFont = [ScTableViewCell editableDetailFont];
        
        labelLineHeight = 2.5 * labelFont.xHeight;
        detailLineHeight = 2.5 * detailFont.xHeight;
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.backgroundView.backgroundColor = backgroundColour;
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        self.selectedBackgroundView.backgroundColor = selectedBackgroundColour;
        
        self.textLabel.backgroundColor = backgroundColour;
        self.detailTextLabel.backgroundColor = backgroundColour;
        
        verticalOffset = kBezelSpace;
    }
    
    return self;
}


+ (ScTableViewCell *)defaultCellForTableView:(UITableView *)tableView
{
    ScTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCell];
    
    if (!cell) {
        cell = [[ScTableViewCell alloc] initWithReuseIdentifier:kDefaultCell];
    }
    
    return cell;
}


+ (ScTableViewCell *)entityCellForEntity:(ScCachedEntity *)entity tableView:(UITableView *)tableView
{
    NSString *entityClass = NSStringFromClass(entity.class);
    ScTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:entityClass];
    
    if (!cell) {
        if ([entity isKindOfClass:ScScola.class]) {
            cell = [[ScTableViewCell alloc] initWithReuseIdentifier:entityClass];
            
            [cell populateWithEntity:entity];
        }
    }
    
    return cell;
}


#pragma mark - Cell population

- (void)addLabel:(NSString *)label withDetail:(NSString *)detail
{
    [self addLabel:label withDetail:detail editable:NO];
}


- (UITextField *)addLabel:(NSString *)label withEditableDetail:(NSString *)detail
{
    isSelectable = NO;
    
    return [self addLabel:label withDetail:detail editable:YES];
}


- (id)addLabel:(NSString *)label withDetail:(NSString *)detail editable:(BOOL)editable
{
    NSUInteger numberOfLinesInDetail = 1;
    
    if (detail && !editable) {
        numberOfLinesInDetail = [[NSMutableString stringWithString:detail] replaceOccurrencesOfString:@"\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, detail.length)] + 1;
    }
    
    CGRect labelFrame = CGRectMake(kLabelOriginX, verticalOffset + kLabelFontVerticalOffset, kLabelOriginX + kLabelWidth, labelLineHeight);
    CGRect detailFrame = CGRectMake(kDetailOriginX, verticalOffset, kDetailOriginX + kDetailWidth, detailLineHeight * numberOfLinesInDetail);
    
    verticalOffset += detailLineHeight * numberOfLinesInDetail + kLineSpacing;
    
    if (!labels) {
        labels = [[NSMutableDictionary alloc] init];
        details = [[NSMutableDictionary alloc] init];
    }

    UILabel *labelView = [[UILabel alloc] initWithFrame:labelFrame];
    
    labelView.font = labelFont;
    labelView.textAlignment = UITextAlignmentRight;
    labelView.backgroundColor = backgroundColour;
    labelView.textColor = labelColour;
    labelView.text = label;
    
    UIView *detailView = nil;
    
    if (editable) {
        UITextField *detailField = [[UITextField alloc] initWithFrame:detailFrame];
        detailField.font = editableDetailFont;
        detailField.textAlignment = UITextAlignmentLeft;
        detailField.backgroundColor = editableFieldBackgroundColour;
        detailField.textColor = detailColour;
        detailField.text = detail;
        
        detailView = detailField;
    } else {
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:detailFrame];
        detailLabel.font = detailFont;
        detailLabel.textAlignment = UITextAlignmentLeft;
        detailLabel.backgroundColor = backgroundColour;
        detailLabel.textColor = detailColour;
        detailLabel.numberOfLines = 0;
        detailLabel.text = detail;
        
        detailView = detailLabel;
    }
    
    [self.contentView addSubview:labelView];
    [self.contentView addSubview:detailView];
    
    [labels setObject:labelView forKey:label];
    [details setObject:detailView forKey:label];
    
    return detailView;
}


#pragma mark - Accessing internals

- (id)viewForLabel:(NSString *)label
{
    return [details objectForKey:label];
}


#pragma mark - Metadata

+ (CGFloat)heightForEntity:(ScCachedEntity *)entity
{
    CGFloat height = 0.f;
    
    if ([entity isKindOfClass:ScScola.class]) {
        ScScola *scola = (ScScola *)entity;
        CGFloat lineHeight = 2.5 * [UIFont systemFontOfSize:kDetailFontSize].xHeight;
        
        height += kBezelSpace;
        height += lineHeight * [scola numberOfLinesInAddress];
        
        if ([scola hasLandline]) {
            height += kLineSpacing;
            height += lineHeight;
        }
        
        height += kBezelSpace;
    }
    
    return height;
}


+ (CGFloat)heightForNumberOfLabels:(NSInteger)numberOfLabels
{
    CGFloat lineHeight = 2.5 * [UIFont systemFontOfSize:kDetailFontSize].xHeight;
    CGFloat height = 0.f;
    
    height += kBezelSpace * 2;
    height += lineHeight * numberOfLabels;
    height += kLineSpacing * (numberOfLabels - 1);
    
    return height;
}


#pragma mark - Overrides

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (isSelectable) {
        for (NSString *label in labels.allKeys) {
            UILabel *labelView = [labels objectForKey:label];
            UILabel *detailView = [details objectForKey:label];
            
            labelView.textColor = selected ? selectedLabelColour : labelColour;
            detailView.textColor = selected ? selectedDetailColour : detailColour;
        }
        
        [super setSelected:selected animated:animated];
    }
}

@end
