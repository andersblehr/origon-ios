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
#import "OTableViewCell.h"

#import "OReplicatedEntity.h"


@implementation OTableViewController

#pragma mark - Initialisation & state handling

- (void)initialise
{
    if (![OStrings hasStrings]) {
        [OState s].actionIsSetup = YES;
    } else {
        if ([self shouldInitialise]) {
            [self loadState];
            
            if (_isModal && self.modalImpliesRegistration) {
                _state.actionIsRegister = YES;
            }
            
            [self loadData];
            
            for (NSNumber *sectionKey in [_sectionData allKeys]) {
                _sectionCounts[sectionKey] = @([_sectionData[sectionKey] count]);
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
    
    if ([self.navigationController.viewControllers count] == 1) {
        _isModal = (self.presentingViewController != nil);
    }
    
    [self initialise];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    _isPushed = [self isMovingToParentViewController] || (_didJustLoad && !_isModal);
    _isPopped = (!_isPushed && !_isModal && !_wasHidden);
    _didJustLoad = NO;
    
    [self reflectState];
    
    if (_isPopped || _needsReloadData) {
        [self loadData];
        [self reloadSectionsIfNeeded];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _isHidden = (self.presentedViewController != nil);
}


#pragma mark - Segue handling

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data
{
    [self prepareForPushSegue:segue data:data observer:nil];
}


- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data observer:(id)observer
{
    OTableViewController *destinationViewController = segue.destinationViewController;
    destinationViewController.data = data;
    destinationViewController.observer = observer;
}


- (void)prepareForModalSegue:(UIStoryboardSegue *)segue data:(id)data delegate:(id)delegate
{
    OTableViewController *destinationViewController = nil;
    
    if ([segue.destinationViewController isKindOfClass:OTableViewController.class]) {
        destinationViewController = segue.destinationViewController;
    } else {
        UINavigationController *navigationController = segue.destinationViewController;
        destinationViewController = navigationController.viewControllers[0];
    }
    
    destinationViewController.data = data;
    destinationViewController.delegate = delegate;
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    // Override in subclass
}


- (void)loadData
{
    // Override in subclass
}


- (BOOL)shouldInitialise
{
    return YES;
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
    NSInteger numberOfRows = 0;
    
    if ([_sectionKeys count]) {
        numberOfRows = [self numberOfRowsInSectionWithKey:[_sectionKeys[section] integerValue]];
    }
    
    return numberOfRows;
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


#pragma mark - UITableViewDelegate conformance

- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        [cell willAppearTrailing:YES];
    } else {
        [cell willAppearTrailing:NO];
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissModalViewControllerWithIdentitifier:identitifier needsReloadData:YES];
}


- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier needsReloadData:(BOOL)needsReloadData
{
    _needsReloadData = needsReloadData;
    
    [self dismissViewControllerAnimated:YES completion:^{
        _needsReloadData = NO;
    }];
}

@end
