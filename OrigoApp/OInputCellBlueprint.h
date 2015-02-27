//
//  OInputCellBlueprint.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kDefaultCellHeight;
extern CGFloat const kDefaultCellPadding;
extern CGFloat const kMinimumCellPadding;
extern CGFloat const kPhotoFrameWidth;

@interface OInputCellBlueprint : NSObject

@property (nonatomic, assign) BOOL hasPhoto;
@property (nonatomic, assign) BOOL fieldsAreLabeled;
@property (nonatomic, assign) BOOL fieldsShouldDeemphasiseOnEndEdit;
@property (nonatomic, assign) BOOL isInlineBlueprint;

@property (nonatomic) NSString *titleKey;
@property (nonatomic) NSArray *detailKeys;
@property (nonatomic) NSArray *inputKeys;
@property (nonatomic) NSArray *multiLineKeys;
@property (nonatomic) NSArray *buttonKeys;

+ (OInputCellBlueprint *)inlineCellBlueprint;

@end
