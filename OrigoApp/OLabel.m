//
//  OLabel.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OLabel.h"

@implementation OLabel

#pragma mark - Auxiliary methods

+ (CGFloat)widthWithKey:(NSString *)key keyPrefix:(NSString *)keyPrefix
{
    return [[OStrings stringForKey:key withKeyPrefix:keyPrefix] sizeWithFont:[UIFont detailFont] maxWidth:CGFLOAT_MAX].width;
}


#pragma mark - Width computation

+ (CGFloat)widthWithBlueprint:(OTableViewCellBlueprint *)blueprint
{
    CGFloat width = 0.f;
    
    for (NSString *key in blueprint.detailKeys) {
        width = MAX(width, [self widthWithKey:key keyPrefix:kKeyPrefixLabel]);
        
        if ([OValidator isAlternatingLabelKey:key]) {
            width = MAX(width, [self widthWithKey:key keyPrefix:kKeyPrefixAlternateLabel]);
        }
    }
    
    return width + 1.f;
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key centred:(BOOL)centred
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.text = [OStrings stringForKey:key withKeyPrefix:kKeyPrefixLabel];
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
            self.text = [OStrings stringForKey:_key withKeyPrefix:kKeyPrefixAlternateLabel];
        } else {
            self.text = [OStrings stringForKey:_key withKeyPrefix:kKeyPrefixLabel];
        }
    }
}

@end
