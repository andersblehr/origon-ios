//
//  OTableViewCellConstrainer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTableViewCellConstrainer : NSObject {
@private
    OTableViewCellBlueprint *_blueprint;
    OTableViewCell *_cell;
    
    CGFloat _labelWidth;
}

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (strong, nonatomic, readonly) NSArray *inputKeys;

- (instancetype)initWithCell:(OTableViewCell *)cell blueprint:(OTableViewCellBlueprint *)blueprint;

- (NSDictionary *)constraintsWithAlignmentOptions;

- (CGFloat)heightOfCell;
+ (CGFloat)heightOfCellWithReuseIdentifier:(NSString *)reuseIdentifier entity:(id<OEntity>)entity delegate:(id)delegate;

@end
