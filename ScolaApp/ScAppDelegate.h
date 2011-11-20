//
//  ScAppDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Facebook.h"
#import "Reachability.h"

@interface ScAppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) Facebook *facebook;

@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)logInWithFacebook;
- (void)logInWithGoogle;
- (void)logOut;

- (NSURL *)applicationDocumentsDirectory;

@end
