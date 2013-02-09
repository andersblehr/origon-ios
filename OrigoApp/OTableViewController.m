//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OTableViewController

#pragma mark - Auxiliary methods

- (void)emphasiseInputField:(id)inputField
{
    if (self.state.actionIsDisplay) {
        [self toggleEditMode];
    }
    
    if ([_detailCell nextInputFieldFromTextField:inputField]) {
        self.navigationItem.rightBarButtonItem = _nextButton;
    } else {
        self.navigationItem.rightBarButtonItem = _doneButton;
    }
    
    _emphasisedField = inputField;
    
    [inputField setHasEmphasis:YES];
}


#pragma mark - Selector implementations

- (void)moveToNextInputField
{
    UIView *nextInputField = [_detailCell nextInputFieldFromTextField:_emphasisedField];
    
    if (nextInputField) {
        [nextInputField becomeFirstResponder];
    }
}


#pragma mark - Initialisation

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
            
            _lastSectionKey = [_sectionKeys lastObject];
            _didInitialise = YES;
        }
    }
}


#pragma mark - Section data management

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    if ([data isKindOfClass:NSSet.class]) {
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithArray:[[data allObjects] sortedArrayUsingSelector:@selector(compare:)]];
    } else {
        if (!data) {
            data = [NSNull null];
        }
        
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
        
        if (_entitySectionKey == NSNotFound) {
            _entitySectionKey = sectionKey;
            
            if ([data isKindOfClass:OReplicatedEntity.class]) {
                _entity = data;
            }
        }
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
    if (sectionKey == _entitySectionKey) {
        _entitySectionKey = NSNotFound;
        _entity = nil;
    }
    
    if ([data isKindOfClass:NSSet.class]) {
        [_sectionData[@(sectionKey)] addObjectsFromArray:[[data allObjects] sortedArrayUsingSelector:@selector(compare:)]];
    } else if (data) {
        [_sectionData[@(sectionKey)] addObject:data];
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


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return (sectionKey > 0);
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([self sectionNumberForSectionKey:sectionKey] == [self.tableView numberOfSections] - 1);
}


- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionCounts[@(sectionKey)] integerValue];
}


- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey
{
    return [_sectionKeys indexOfObject:@(sectionKey)];
}


- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber
{
    return [_sectionKeys[sectionNumber] integerValue];
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


#pragma mark - Utility methods

- (void)reflectState
{
    if (!_didInitialise) {
        [self initialise];
    } else {
        [[OState s] reflect:_state];
    }
}


- (void)toggleEditMode
{
    [_detailCell toggleEditMode];
    
    static UIBarButtonItem *rightButton = nil;
    static UIBarButtonItem *leftButton = nil;
    
    if (self.state.actionIsEdit) {
        rightButton = self.navigationItem.rightBarButtonItem;
        leftButton = self.navigationItem.leftBarButtonItem;
        
        if (!_cancelButton) {
            _cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
            _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
            _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        }
        
        self.navigationItem.leftBarButtonItem = _cancelButton;
    } else if (self.state.actionIsDisplay) {
        [self.view endEditing:YES];
        
        self.navigationItem.rightBarButtonItem = rightButton;
        self.navigationItem.leftBarButtonItem = leftButton;
        
        if ([[OMeta m].context needsReplication]) {
            [[OMeta m].context replicate];
            [self.observer reloadEntity];
        }
    }
    
    OLogState;
}


- (void)resumeFirstResponder
{
    [_emphasisedField becomeFirstResponder];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setBackground];
    
    NSString *viewControllerName = NSStringFromClass(self.class);
    _entityClass = NSClassFromString([viewControllerName substringToIndex:[viewControllerName rangeOfString:@"ViewController"].location]);
    _entitySectionKey = NSNotFound;
    _state = [[OState alloc] init];
    
    _canEdit = NO;
    _shouldDemphasiseOnEndEdit = YES;
    _modalImpliesRegistration = ([NSStringFromClass(self.class) rangeOfString:@"List"].location == NSNotFound);
    
    if (!self.navigationController || ([self.navigationController.viewControllers count] == 1)) {
        _isModal = (self.presentingViewController != nil);
    }
    
    _sectionKeys = [[NSMutableArray alloc] init];
    _sectionData = [[NSMutableDictionary alloc] init];
    _sectionCounts = [[NSMutableDictionary alloc] init];
    
    [self initialise];
    
    if (_state.actionIsRegister) {
        _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
        _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        
        self.navigationItem.leftBarButtonItem = [self cancelRegistrationButton];
        self.navigationItem.rightBarButtonItem = _nextButton;
    }
    
    _didJustLoad = YES;
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


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.state.actionIsRegister) {
        [[self.detailCell nextInputFieldFromTextField:nil] becomeFirstResponder];
    } else if (self.detailCell) {
        self.detailCell.editable = [self canEdit];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    _isHidden = (self.presentedViewController != nil);
    
    if (!_isHidden) {
        [[OMeta m].context replicateIfNeeded];
    }
}


#pragma mark - Segue handling

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue
{
    [self prepareForPushSegue:segue data:[self entityForIndexPath:_selectedIndexPath]];
}


- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data
{
    OTableViewController *destinationViewController = segue.destinationViewController;
    destinationViewController.data = data;
    destinationViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:_selectedIndexPath];
}


- (void)prepareForModalSegue:(UIStoryboardSegue *)segue data:(id)data
{
    [self prepareForModalSegue:segue data:data meta:nil];
}


- (void)prepareForModalSegue:(UIStoryboardSegue *)segue data:(id)data meta:(id)meta
{
    OTableViewController *destinationViewController = nil;
    
    if ([segue.destinationViewController isKindOfClass:OTableViewController.class]) {
        destinationViewController = segue.destinationViewController;
    } else {
        UINavigationController *navigationController = segue.destinationViewController;
        destinationViewController = navigationController.viewControllers[0];
    }
    
    destinationViewController.data = data;
    
    if ([meta isKindOfClass:OTableViewController.class]) {
        destinationViewController.delegate = meta;
    } else {
        destinationViewController.meta = meta;
        destinationViewController.delegate = self;
    }
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


- (UIBarButtonItem *)cancelRegistrationButton
{
    return nil;
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    return nil;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return nil;
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [OState s].actionIsSetup ? 0 : [_sectionKeys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfRowsInSectionWithKey:[_sectionKeys[section] integerValue]];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kDefaultTableViewCellHeight;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_entitySectionKey]) {
        height = _entity ? [_entity cellHeight] : [_entityClass defaultCellHeight];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_entitySectionKey]) {
        if (_entity) {
            _detailCell = [tableView cellForEntity:_entity delegate:self];
        } else {
            _detailCell = [tableView cellForEntityClass:_entityClass delegate:self];
        }
        
        if (self.state.actionIsList) {
            _detailCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        _detailCell.observer = self.observer;
        
        cell = _detailCell;
    } else {
        cell = [tableView listCellForEntity:[self entityForIndexPath:indexPath]];
    }
    
    return cell;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if ([self hasHeaderForSectionWithKey:[self sectionKeyForSectionNumber:section]]) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if ([self hasFooterForSectionWithKey:[self sectionKeyForSectionNumber:section]]) {
        height = [tableView standardFooterHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *view = nil;

    if ([self hasHeaderForSectionWithKey:sectionKey]) {
        view = [tableView headerViewWithText:[self textForHeaderInSectionWithKey:sectionKey]];
    }
    
    return view;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *view = nil;
    
    if ([self hasFooterForSectionWithKey:sectionKey]) {
        view = [tableView footerViewWithText:[self textForFooterInSectionWithKey:sectionKey]];
    }
    
    return view;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        [cell willAppearTrailing:YES];
    } else {
        [cell willAppearTrailing:NO];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (((OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath]).selectable) {
        _selectedIndexPath = indexPath;
        
        [self didSelectRowAtIndexPath:indexPath];
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


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    [self emphasiseInputField:textField];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([_detailCell nextInputFieldFromTextField:textField]) {
        [self moveToNextInputField];
    } else {
        [self performSelector:@selector(didFinishEditing)];
    }
    
    return YES;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    if (_shouldDemphasiseOnEndEdit) {
        textField.hasEmphasis = NO;
    }
}


#pragma mark - UITextViewDelegate conformance

- (void)textViewDidBeginEditing:(OTextView *)textView
{
    [self emphasiseInputField:textView];
}


- (void)textViewDidChange:(OTextView *)textView
{
    [self.detailCell redrawIfNeeded];
}


- (void)textViewDidEndEditing:(OTextView *)textView
{
    if (_shouldDemphasiseOnEndEdit) {
        textView.hasEmphasis = NO;
    }
}

@end
