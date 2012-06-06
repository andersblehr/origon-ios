//
//  ScAddressTableViewCell.h
//  ScolaApp
//
//  Created by Anders Blehr on 05.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kReuseIdentifierAddress;

extern CGFloat kLabelFontSize;
extern CGFloat kDetailFontSize;

@class ScScola;

@interface ScAddressTableViewCell : UITableViewCell {
@private
    UIColor *labelTextColour;
    UIColor *detailTextColour;
    UIColor *selectedTextColour;
    
    UILabel *addressLabel;
    UILabel *addressDetailLabel;
    UILabel *landlineLabel;
    UILabel *landlineDetailLabel;
}

- (void)populateWithScola:(ScScola *)scola;

@end
