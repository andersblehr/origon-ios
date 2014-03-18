//
//  OLabel.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLabel : UILabel {
@private
    NSString *_key;
}

@property (nonatomic) BOOL useAlternateText;

+ (CGFloat)widthWithBlueprint:(OTableViewCellBlueprint *)blueprint;

- (id)initWithKey:(NSString *)key centred:(BOOL)centred;

@end
