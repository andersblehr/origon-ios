//
//  ScMessageBoard.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScMessageThread, ScScola;

@interface ScMessageBoard : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *messageThreads;
@property (nonatomic, retain) ScScola *scola;
@end

@interface ScMessageBoard (CoreDataGeneratedAccessors)

- (void)addMessageThreadsObject:(ScMessageThread *)value;
- (void)removeMessageThreadsObject:(ScMessageThread *)value;
- (void)addMessageThreads:(NSSet *)values;
- (void)removeMessageThreads:(NSSet *)values;

@end
