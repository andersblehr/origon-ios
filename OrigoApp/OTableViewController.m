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

NSInteger const kNoSection = -1;


@implementation OTableViewController

#pragma mark - State handling

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

- (void)setData:(id)data forSection:(NSInteger)section
{
    BOOL hasDataForSection = (_tableData[@(section)] != nil);
    
    if ([data isKindOfClass:OReplicatedEntity.class]) {
        if (!hasDataForSection) {
            _tableData[@(section)] = data;
            _sectionDeltas[@(section)] = @0;
        }
    } else if ([data count] > 0) {
        NSMutableArray *entities = [NSMutableArray arrayWithArray:[[data allObjects] sortedArrayUsingSelector:@selector(compare:)]];
        
        if (!hasDataForSection || ([entities count] != [_tableData[@(section)] count])) {
            if (hasDataForSection) {
                _sectionDeltas[@(section)] = @([_tableData[@(section)] count] - [entities count]);
            } else {
                _sectionDeltas[@(section)] = @0;
            }
            
            _tableData[@(section)] = entities;
        }
    }
}


- (void)addData:(id)data toSection:(NSInteger)section
{
    
}


- (id)entityForIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *sectionKey = [NSArray arrayWithArray:[[_tableData allKeys] sortedArrayUsingSelector:@selector(compare:)]][indexPath.section];
    
    return _tableData[sectionKey][indexPath.row];
}


- (void)reloadSectionsIfNeeded
{
    NSRange reloadRange = {0, 0};
    
    for (NSInteger section = 0; section < [_tableData count]; section++) {
        if (_sectionDeltas[@(section)] != @0) {
            reloadRange.location = reloadRange.length ? reloadRange.location : section;
            reloadRange.length = (section - reloadRange.location) + 1;
        }
    }
    
    if (reloadRange.length) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:reloadRange] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (NSInteger)sectionNumberForSection:(NSInteger)section
{
    NSInteger sectionNumber = kNoSection;
    NSArray *sortedSectionKeys = [NSArray arrayWithArray:[[_tableData allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    
    for (NSInteger i = 0; i < [sortedSectionKeys count]; i++) {
        NSNumber *sectionKey = sortedSectionKeys[i];
        
        if ([sectionKey integerValue] == section) {
            sectionNumber = i;
        }
    }
    
    return sectionNumber;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    _tableData = [[NSMutableDictionary alloc] init];
    _sectionDeltas = [[NSMutableDictionary alloc] init];
    
    _state = [[OState alloc] init];
    _modalImpliesRegistration = YES;
    
    [self initialise];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_didSetModal) {
        _isModal = (self.presentingViewController && ![self isMovingToParentViewController]);
        
        if (_isModal && _modalImpliesRegistration) {
            _state.actionIsRegister = YES;
        }
        
        _didSetModal = YES;
    }
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    
    _isPushed = [self isMovingToParentViewController];
    _isPopped = (!_isPushed && !_isModal && !_wasHidden);
    
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
    return [_tableData count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    NSNumber *sectionKey = [NSArray arrayWithArray:[[_tableData allKeys] sortedArrayUsingSelector:@selector(compare:)]][section];
    
    id sectionData = _tableData[sectionKey];
    
    if ([sectionData isKindOfClass:OReplicatedEntity.class]) {
        numberOfRows = 1;
    } else {
        numberOfRows = [sectionData count];
    }
    
    return numberOfRows;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSNumber *sectionKey = [NSArray arrayWithArray:[[_tableData allKeys] sortedArrayUsingSelector:@selector(compare:)]][indexPath.section];
        
        NSMutableArray *sectionData = _tableData[sectionKey];
        OReplicatedEntity *entity = sectionData[indexPath.row];
        
        [sectionData removeObjectAtIndex:indexPath.row];
        [[OMeta m].context deleteEntity:entity];
        
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
