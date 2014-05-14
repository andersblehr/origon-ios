//
//  OTableViewCellConstrainer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTableViewCellConstrainer : NSObject

@property (nonatomic, readonly) NSString *titleKey;
@property (nonatomic, readonly) NSArray *detailKeys;
@property (nonatomic, readonly) NSArray *inputKeys;

- (instancetype)initWithCell:(OTableViewCell *)cell blueprint:(OTableViewCellBlueprint *)blueprint;

- (NSDictionary *)constraintsWithAlignmentOptions;

- (CGFloat)heightOfCell;
+ (CGFloat)heightOfCellWithReuseIdentifier:(NSString *)reuseIdentifier entity:(id<OEntity>)entity delegate:(id)delegate;

@end
