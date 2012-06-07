//
//  ScAddressTableViewCell.m
//  ScolaApp
//
//  Created by Anders Blehr on 05.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAddressTableViewCell.h"

#import "UIColor+ScColorExtensions.h"

#import "ScStrings.h"

#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"

NSString * const kReuseIdentifierAddress = @"cellAddress";

CGFloat kLabelFontSize = 12.f;
CGFloat kDetailFontSize = 15.f;

static CGFloat kLabelWidth = 63.f;


@implementation ScAddressTableViewCell


#pragma mark - Initialisation

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        UIFont *labelFont = [UIFont boldSystemFontOfSize:kLabelFontSize];
        UIFont *detailLabelFont = [UIFont boldSystemFontOfSize:kDetailFontSize];
        
        UIColor *cellBackgroundColour = [UIColor isabellineColor];
        labelTextColour = [UIColor slateGrayColor];
        detailTextColour = [UIColor blackColor];
        selectedTextColour = [UIColor whiteColor];
        
        addressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        addressLabel.font = labelFont;
        addressLabel.textAlignment = UITextAlignmentRight;
        addressLabel.backgroundColor = cellBackgroundColour;
        addressLabel.textColor = labelTextColour;
        addressLabel.text = [ScStrings stringForKey:strAddress];
        
        addressDetailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        addressDetailLabel.font = detailLabelFont;
        addressDetailLabel.textAlignment = UITextAlignmentLeft;
        addressDetailLabel.backgroundColor = cellBackgroundColour;
        addressDetailLabel.textColor = detailTextColour;
        addressDetailLabel.numberOfLines = 0;
        
        landlineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        landlineLabel.font = labelFont;
        landlineLabel.textAlignment = UITextAlignmentRight;
        landlineLabel.backgroundColor = cellBackgroundColour;
        landlineLabel.textColor = labelTextColour;
        landlineLabel.text = [ScStrings stringForKey:strLandline];
        
        landlineDetailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        landlineDetailLabel.font = detailLabelFont;
        landlineDetailLabel.textAlignment = UITextAlignmentLeft;
        landlineDetailLabel.backgroundColor = cellBackgroundColour;
        landlineDetailLabel.textColor = detailTextColour;
        
        [self.contentView addSubview:addressLabel];
        [self.contentView addSubview:addressDetailLabel];
        [self.contentView addSubview:landlineLabel];
        [self.contentView addSubview:landlineDetailLabel];
    }
    
    return self;
}


#pragma mark - Populating the cell

- (void)populateWithScola:(ScScola *)scola isAdmin:(BOOL)isAdmin
{
    addressLabel.frame = CGRectMake(5.f, 16.f, 5.f + kLabelWidth, 2.5 * addressLabel.font.xHeight);
    addressDetailLabel.frame = CGRectMake(82.f, 12.f, 195.f, 2.5 * addressDetailLabel.font.xHeight * [scola numberOfLinesInAddress]);
    
    addressDetailLabel.text = [scola multiLineAddress];
    
    if ([scola hasLandline]) {
        landlineLabel.frame = CGRectMake(5.f, 21.f + addressDetailLabel.frame.size.height, 5.f + kLabelWidth, 2.5 * landlineLabel.font.xHeight);
        landlineDetailLabel.frame = CGRectMake(82.f, 18.f + addressDetailLabel.frame.size.height, 195.f, 2.5 * landlineDetailLabel.font.xHeight);
        
        landlineDetailLabel.text = scola.landline;
    }
    
    if (isAdmin) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}


#pragma mark - Overrides

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    addressLabel.textColor = selected ? selectedTextColour : labelTextColour;
    addressDetailLabel.textColor = selected ? selectedTextColour : detailTextColour;
    landlineLabel.textColor = selected ? selectedTextColour : labelTextColour;
    landlineDetailLabel.textColor = selected ? selectedTextColour : detailTextColour;
    
    [super setSelected:selected animated:animated];
}

@end
