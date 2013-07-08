//
//  OTableViewCellConstrainer.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OTableViewCellConstrainer : NSObject {
@private
    OTableViewCellBlueprint *_blueprint;
    OTableViewCell *_cell;
}

- (id)initWithBlueprint:(OTableViewCellBlueprint *)blueprint cell:(OTableViewCell *)cell;

- (NSDictionary *)constraintsWithAlignmentOptions;

@end
