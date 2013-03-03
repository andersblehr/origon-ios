//
//  OTableViewCellConstrainer.h
//  OrigoApp
//
//  Created by Anders Blehr on 18.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTableViewCell, OTableViewCellBlueprint;

@interface OTableViewCellConstrainer : NSObject {
@private
    OTableViewCellBlueprint *_blueprint;
    OTableViewCell *_cell;
}

- (id)initWithBlueprint:(OTableViewCellBlueprint *)blueprint cell:(OTableViewCell *)cell;

- (NSDictionary *)constraintsWithAlignmentOptions;

@end
