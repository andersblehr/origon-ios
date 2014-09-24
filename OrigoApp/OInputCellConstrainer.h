//
//  OInputCellConstrainer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OInputCellConstrainer : NSObject

@property (nonatomic, readonly) OInputCellBlueprint *blueprint;

@property (nonatomic, readonly) NSString *titleKey;
@property (nonatomic, readonly) NSArray *detailKeys;
@property (nonatomic, readonly) NSArray *inputKeys;

@property (nonatomic, assign, readonly) BOOL didConstrain;


- (instancetype)initWithCell:(OTableViewCell *)cell blueprint:(OInputCellBlueprint *)blueprint delegate:(id<OInputCellDelegate>)delegate;

- (NSDictionary *)constraintsWithAlignmentOptions;

- (CGFloat)labeledTextWidth;
- (CGFloat)heightOfInputCell;
+ (CGFloat)heightOfInputCellWithEntity:(id<OEntity>)entity delegate:(id)delegate;

- (OInputField *)inputFieldWithKey:(NSString *)key;

@end
