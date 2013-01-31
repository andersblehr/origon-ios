//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OEntityObservingDelegate.h"
#import "OModalViewControllerDelegate.h"
#import "OTableViewControllerDelegate.h"

@class OState;
@class OReplicatedEntity;

@interface OTableViewController : UITableViewController<OTableViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, OModalViewControllerDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _isHidden;
    BOOL _needsReloadData;
    
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    NSNumber *_lastSectionKey;
}

@property (strong, nonatomic, readonly) OState *state;
@property (nonatomic) BOOL modalImpliesRegistration;

@property (strong, nonatomic) id data;
@property (strong, nonatomic) id<OModalViewControllerDelegate> delegate;
@property (strong, nonatomic) id<OEntityObservingDelegate>observer;

@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

- (void)reflectState;

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey;
- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey;
- (NSArray *)entitiesInSectionWithKey:(NSInteger)sectionKey;
- (id)entityForIndexPath:(NSIndexPath *)indexPath;

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey;
- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey;

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data;
- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data observer:(id)observer;
- (void)prepareForModalSegue:(UIStoryboardSegue *)segue data:(id)data delegate:(id)delegate;

@end
