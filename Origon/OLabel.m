//
//  OLabel.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OLabel.h"


@interface OLabel () {
@private
    NSString *_key;
}

@end


@implementation OLabel

#pragma mark - Initialisation

- (instancetype)initWithKey:(NSString *)key centred:(BOOL)centred
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.text = OLocalizedString(key, kStringPrefixLabel);
        self.textAlignment = centred ? NSTextAlignmentCenter : NSTextAlignmentRight;
        self.textColor = [UIColor labelTextColour];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        _key = key;
        _useAlternateText = NO;
    }
    
    return self;
}


#pragma mark - Static, reusable labels

+ (UILabel *)genericLabelWithText:(NSString *)text
{
    UIFont *labelFont = [UIFont detailFont];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, [text sizeWithFont:labelFont maxWidth:CGFLOAT_MAX].width, [labelFont lineHeight])];
    label.backgroundColor = [UIColor clearColor];
    label.font = labelFont;
    label.textColor = [UIColor textColour];
    label.text = text;
    
    return label;
}


#pragma mark - Custom accessors

- (void)setUseAlternateText:(BOOL)useAlternateText
{
    _useAlternateText = useAlternateText;
    
    if ([OValidator isAlternatingLabelKey:_key]) {
        if (_useAlternateText) {
            self.text = OLocalizedString(_key, kStringPrefixAlternateLabel);
        } else {
            self.text = OLocalizedString(_key, kStringPrefixLabel);
        }
    }
}

@end
