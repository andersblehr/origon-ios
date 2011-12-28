//
//  ScMessageBoard.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScMessageThread, ScScola;

@interface ScMessageBoard : NSManagedObject

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSSet *messageThreads;
@property (nonatomic, strong) ScScola *scola;
@end

@interface ScMessageBoard (CoreDataGeneratedAccessors)

- (void)addMessageThreadsObject:(ScMessageThread *)value;
- (void)removeMessageThreadsObject:(ScMessageThread *)value;
- (void)addMessageThreads:(NSSet *)values;
- (void)removeMessageThreads:(NSSet *)values;

@end
