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

static CGFloat kLabelFontSize = 12.f;
static CGFloat kDetailFontSize = 14.f;

static CGFloat kLabelOriginX = 5.f;
static CGFloat kDetailOriginX = 82.f;
static CGFloat kLabelWidth = 63.f;
static CGFloat kDetailWidth = 113.f;

static CGFloat kBezelSpace = 12.f;
static CGFloat kLabelFontVerticalOffset = 3.f;
static CGFloat kLineSpacing = 5.f;

static UIColor *backgroundColour = nil;
static UIColor *selectedBackgroundColour = nil;
static UIColor *editableBackgroundColour = nil;
static UIColor *labelColour = nil;
static UIColor *detailColour = nil;
static UIColor *selectedLabelColour = nil;
static UIColor *selectedDetailColour = nil;

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


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        isSelectable = YES;
        
        backgroundColour = [ScTableViewCell colourOfType:ScCellColourTypeBackground];
        selectedBackgroundColour = [ScTableViewCell colourOfType:ScCellColourTypeSelectedBackground];
        editableBackgroundColour = [ScTableViewCell colourOfType:ScCellColourTypeEditableBackground];
        labelColour = [ScTableViewCell colourOfType:ScCellColourTypeLabel];
        detailColour = [ScTableViewCell colourOfType:ScCellColourTypeDetail];
        selectedLabelColour = [ScTableViewCell colourOfType:ScCellColourTypeSelectedLabel];
        selectedDetailColour = [ScTableViewCell colourOfType:ScCellColourTypeSelectedDetail];
        
        labelFont = [ScTableViewCell fontOfType:ScCellFontTypeLabel];
        detailFont = [ScTableViewCell fontOfType:ScCellFontTypeDetail];
        editableDetailFont = [ScTableViewCell fontOfType:ScCellFontTypeEditableDetail];
        
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


#pragma mark - Preconfigured colours and fonts

+ (UIColor *)colourOfType:(ScCellColourType)colourType
{
    UIColor *colour = nil;
    
    switch (colourType) {
        case ScCellColourTypeBackground:
            if (!backgroundColour) {
                backgroundColour = [UIColor isabellineColor];
            }
            
            colour = backgroundColour;
            
            break;
            
        case ScCellColourTypeSelectedBackground:
            if (!selectedBackgroundColour) {
                selectedBackgroundColour = [UIColor ashGrayColor];
            }
            
            colour = selectedBackgroundColour;
            
            break;
            
        case ScCellColourTypeEditableBackground:
            if (!editableBackgroundColour) {
                editableBackgroundColour = [UIColor ghostWhiteColor];
            }
            
            colour = editableBackgroundColour;
            
            break;
            
        case ScCellColourTypeLabel:
            if (!labelColour) {
                labelColour = [UIColor slateGrayColor];
            }
            
            colour = labelColour;
            
            break;
            
        case ScCellColourTypeDetail:
            if (!detailColour) {
                detailColour = [UIColor blackColor];
            }
            
            colour = detailColour;
            
            break;
            
        case ScCellColourTypeSelectedLabel:
            if (!selectedLabelColour) {
                selectedLabelColour = [UIColor lightTextColor];
            }
            
            colour = selectedLabelColour;
            
            break;
            
        case ScCellColourTypeSelectedDetail:
            if (!selectedDetailColour) {
                selectedDetailColour = [UIColor whiteColor];
            }
            
            colour = selectedDetailColour;
            
            break;
            
        default:
            break;
    }
    
    return colour;
}


+ (UIFont *)fontOfType:(ScCellFontType)fontType
{
    UIFont *font;
    
    switch (fontType) {
        case ScCellFontTypeLabel:
            if (!labelFont) {
                labelFont = [UIFont boldSystemFontOfSize:kLabelFontSize];
            }
            
            font = labelFont;
            
            break;
            
        case ScCellFontTypeDetail:
            if (!detailFont) {
                detailFont = [UIFont boldSystemFontOfSize:kDetailFontSize];
            }
            
            font = detailFont;
            
            break;
            
        case ScCellFontTypeEditableDetail:
            if (!editableDetailFont) {
                editableDetailFont = [UIFont systemFontOfSize:kDetailFontSize];
            }
            
            font = editableDetailFont;
            
            break;
            
        default:
            break;
    }

    return font;
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
        detailField.backgroundColor = editableBackgroundColour;
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
