//
//  OTableViewCellBlueprint.h
//  OrigoApp
//
//  Created by Anders Blehr on 22.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTableViewCellBlueprint : NSObject

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (weak, nonatomic, readonly) NSArray *allKeys;
@property (nonatomic, readonly) BOOL hasPhoto;

- (id)initForReuseIdentifier:(NSString *)reuseIdentifier;
- (id)initForEntityClass:(Class)entityClass;

- (BOOL)keyRepresentsMultiLineProperty:(NSString *)propertyKey;

@end
