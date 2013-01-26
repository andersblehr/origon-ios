//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OReplicatedEntity.h"


@implementation OTableViewController

#pragma mark - Initialisation & state handling

- (void)initialise
{
    if (![OStrings hasStrings]) {
        [OState s].actionIsSetup = YES;
    } else {
        if ([self shouldInitialise]) {
            if ([self respondsToSelector:@selector(setPrerequisites)]) {
                [self setPrerequisites];
            }
            
            [self setState];
            
            if ([self respondsToSelector:@selector(loadData)]) {
                [self loadData];
            }
            
            _didInitialise = YES;
        }
    }
}


- (void)reflectState
{
    if (!_didInitialise) {
        [self initialise];
    } else {
        [[OState s] reflect:_state];
    }
}


#pragma mark - Section data management

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    if ([data isKindOfClass:OReplicatedEntity.class]) {
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
    } else {
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithArray:[[data allObjects] sortedArrayUsingSelector:@selector(compare:)]];
    }
    
    if ([_sectionData[@(sectionKey)] count]) {
        if (![_sectionKeys containsObject:@(sectionKey)]) {
            [_sectionKeys addObject:@(sectionKey)];
            [_sectionKeys sortUsingSelector:@selector(compare:)];
        }
    } else if (!_sectionCounts[@(sectionKey)]) {
        _sectionCounts[@(sectionKey)] = @0;
    }
}


- (void)appendData:(id)data toSectionWithKey:(NSInteger)sectionKey
{
    NSMutableArray *mergedData = _sectionData[@(sectionKey)];
    
    if ([data isKindOfClass:OReplicatedEntity.class]) {
        [mergedData addObject:data];
    } else {
        [mergedData addObjectsFromArray:[[data allObjects] sortedArrayUsingSelector:@selector(compare:)]];
    }
}


- (NSArray *)entitiesInSectionWithKey:(NSInteger)sectionKey
{
    return _sectionData[@(sectionKey)];
}


- (id)entityForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [_sectionKeys[indexPath.section] integerValue];
    
    return [self entitiesInSectionWithKey:sectionKey][indexPath.row];
}


#pragma mark - Section handling

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionKeys containsObject:@(sectionKey)];
}


- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey
{
    if (!_sectionCounts[@(sectionKey)]) {
        _sectionCounts[@(sectionKey)] = @([_sectionData[@(sectionKey)] count]);
    }
    
    return [_sectionCounts[@(sectionKey)] integerValue];
}


- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey
{
    return [_sectionKeys indexOfObject:@(sectionKey)];
}


- (void)reloadSectionsIfNeeded
{
    NSMutableIndexSet *sectionsToInsert = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToReload = [NSMutableIndexSet indexSet];

    for (NSNumber *sectionKey in [_sectionData allKeys]) {
        NSInteger section = [self sectionNumberForSectionKey:[sectionKey integerValue]];
        NSInteger oldSectionCount = [_sectionCounts[sectionKey] integerValue];
        NSInteger newSectionCount = [_sectionData[sectionKey] count];
        
        if (oldSectionCount) {
            if (newSectionCount && (newSectionCount != oldSectionCount)) {
                [sectionsToReload addIndex:section];
            } else if (!newSectionCount) {
                [_sectionKeys removeObject:sectionKey];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else if (newSectionCount) {
            [sectionsToInsert addIndex:section];
        }
        
        _sectionCounts[sectionKey] = @(newSectionCount);
    }

    if (![_lastSectionKey isEqualToNumber:[_sectionKeys lastObject]]) {
        if ([_sectionKeys containsObject:_lastSectionKey]) {
            [sectionsToReload addIndex:[self sectionNumberForSectionKey:[_lastSectionKey integerValue]]];
        }
        
        _lastSectionKey = [_sectionKeys lastObject];
    }
    
    if ([sectionsToInsert count]) {
        [self.tableView insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    if ([sectionsToReload count]) {
        [self.tableView reloadSections:sectionsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    _sectionKeys = [[NSMutableArray alloc] init];
    _sectionData = [[NSMutableDictionary alloc] init];
    _sectionCounts = [[NSMutableDictionary alloc] init];
    
    _state = [[OState alloc] init];
    _modalImpliesRegistration = YES;
    _didJustLoad = YES;
    
    [self initialise];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_didJustLoad) {
        _isModal = (self.presentingViewController && ![self isMovingToParentViewController]);
        
        if (_isModal && _modalImpliesRegistration) {
            _state.actionIsRegister = YES;
        }
    }
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    
    _isPushed = [self isMovingToParentViewController];
    _isPopped = (!_isPushed && !_isModal && !_wasHidden && !_didJustLoad);
    _didJustLoad = NO;
    
    [self reflectState];
    
    if ([self respondsToSelector:@selector(loadData)] && (_isPopped || _wasHidden)) {
        [self loadData];
        [self reloadSectionsIfNeeded];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _isHidden = (self.presentedViewController != nil);
}


#pragma mark - OTableViewControllerDelegate conformance

- (BOOL)shouldInitialise
{
    return YES;
}


- (void)setState
{
    // Override in subclass
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!_lastSectionKey) {
        _lastSectionKey = [_sectionKeys lastObject];
    }
    
    return [_sectionKeys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfRowsInSectionWithKey:[_sectionKeys[section] integerValue]];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSNumber *sectionKey = _sectionKeys[indexPath.section];
        
        NSMutableArray *sectionData = _sectionData[sectionKey];
        OReplicatedEntity *entity = sectionData[indexPath.row];
        
        [sectionData removeObjectAtIndex:indexPath.row];
        _sectionCounts[sectionKey] = @([_sectionCounts[sectionKey] integerValue] - 1);
        [[OMeta m].context deleteEntity:entity];
        
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
