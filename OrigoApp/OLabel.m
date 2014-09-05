//
//  OLabel.m
//  OrigoApp
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

#pragma mark - Width computation

#pragma mark - Initialisation

- (instancetype)initWithKey:(NSString *)key centred:(BOOL)centred
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.text = NSLocalizedString(key, kStringPrefixLabel);
        self.textAlignment = centred ? NSTextAlignmentCenter : NSTextAlignmentRight;
        self.textColor = [UIColor labelTextColour];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        _key = key;
        _useAlternateText = NO;
    }
    
    return self;
}


#pragma mark - Custom accessors

- (void)setUseAlternateText:(BOOL)useAlternateText
{
    _useAlternateText = useAlternateText;
    
    if ([OValidator isAlternatingLabelKey:_key]) {
        if (_useAlternateText) {
            self.text = NSLocalizedString(_key, kStringPrefixAlternateLabel);
        } else {
            self.text = NSLocalizedString(_key, kStringPrefixLabel);
        }
    }
}

@end
