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

#import "OEntityReplicator.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"
#import "OTableViewCellBlueprint.h"

#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OTabBarController.h"

NSString * const kEmptyDetailCellPlaceholder = @"<empty>";


@interface OTableViewController ()

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end


@implementation OTableViewController


#pragma mark - Auxiliary methods

- (void)initialiseInstance
{
    if (([OStrings hasStrings] && [OMeta m].userIsAllSet) || _isModal) {
        _state = [[OState alloc] initForViewController:self];
        
        if (_isModal && self.modalImpliesRegistration) {
            _state.actionIsRegister = YES;
        }
        
        [_instance initialise];
        [[OState s] reflect:_state];
        [_instance populateDataSource];
        
        for (NSNumber *sectionKey in [_sectionData allKeys]) {
            _sectionCounts[sectionKey] = @([_sectionData[sectionKey] count]);
        }
        
        _lastSectionKey = [_sectionKeys lastObject];
        _didInitialise = YES;
    }
}


- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey
{
    return [_sectionKeys indexOfObject:@(sectionKey)];
}


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


#pragma mark - Setting & accessing section data

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    if ([data isKindOfClass:NSArray.class]) {
        _sectionData[@(sectionKey)] = data;
    } else if ([data isKindOfClass:NSSet.class]) {
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithArray:[[data allObjects] sortedArrayUsingSelector:@selector(compare:)]];
    } else if (data) {
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
        
        if (_entitySectionKey == NSNotFound) {
            _entitySectionKey = sectionKey;
            
            if ([data isKindOfClass:OReplicatedEntity.class]) {
                _entity = data;
                _entityClass = _entityClass ? _entityClass : _entity.class;
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


- (NSArray *)dataInSectionWithKey:(NSInteger)sectionKey
{
    return _sectionData[@(sectionKey)];
}


- (id)dataAtRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey
{
    return [self dataInSectionWithKey:sectionKey][row];
}


- (id)dataForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [_sectionKeys[indexPath.section] integerValue];
    
    return [self dataAtRow:indexPath.row inSectionWithKey:sectionKey];
}


#pragma mark - View layout

- (BOOL)hasSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionKeys containsObject:@(sectionKey)];
}


- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionCounts[@(sectionKey)] integerValue];
}


- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber
{
    return [_sectionKeys[sectionNumber] integerValue];
}


#pragma mark - Utility methods

- (void)reflectState
{
    if (!_didJustLoad) {
        if (!_didInitialise) {
            [self initialiseInstance];
        }
    
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
        
        if ([[OMeta m].replicator needsReplication]) {
            [[OMeta m].replicator replicate];
            [self.observer reloadEntity];
        }
    }
    
    OLogState;
}


- (void)reloadSectionsIfNeeded
{
    [_instance populateDataSource];
    
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


- (void)resumeFirstResponder
{
    [_emphasisedField becomeFirstResponder];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setBackground];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    NSString *viewControllerName = NSStringFromClass(self.class);
    _entityClass = NSClassFromString([viewControllerName substringToIndex:[viewControllerName rangeOfString:@"ViewController"].location]);
    _entitySectionKey = NSNotFound;
    _instance = self;
    
    _isListView = ([NSStringFromClass(self.class) rangeOfString:@"List"].location != NSNotFound);
    _canEdit = NO;
    _shouldDemphasiseOnEndEdit = YES;
    _modalImpliesRegistration = !_isListView;
    _cancelRegistrationImpliesSignOut = NO;
    
    if (!self.navigationController || ([self.navigationController.viewControllers count] == 1)) {
        _isModal = (self.presentingViewController != nil);
    }
    
    _sectionKeys = [[NSMutableArray alloc] init];
    _sectionData = [[NSMutableDictionary alloc] init];
    _sectionCounts = [[NSMutableDictionary alloc] init];
    
    [self initialiseInstance];
    
    if (_state.actionIsRegister) {
        _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
        _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        
        if (self.cancelRegistrationImpliesSignOut) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
        } else {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        }
        
        self.navigationItem.rightBarButtonItem = _nextButton;
    }
    
    _didJustLoad = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reflectState];
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    _isPushed = [self isMovingToParentViewController] || (_didJustLoad && !_isModal);
    _isPopped = (!_isPushed && !_isModal && !_wasHidden);
    _didJustLoad = NO;
    
    if (![OStrings hasStrings]) {
        [self.tabBarController.tabBar.items[kTabBarOrigo] setTitle:nil];
    }
    
    if (_isPopped || _needsReloadData) {
        [self reloadSectionsIfNeeded];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![OStrings hasStrings]) {
        [self.activityIndicator startAnimating];
        [[[OServerConnection alloc] init] fetchStrings:self];
    } else if (![OMeta m].userIsSignedIn) {
        [self presentModalViewWithIdentifier:kAuthView data:nil dismisser:self];
    } else if (self.state.actionIsRegister) {
        [[self.detailCell nextInputFieldFromTextField:nil] becomeFirstResponder];
    } else if (self.detailCell) {
        self.detailCell.editable = self.canEdit;
    }
    
    OLogState;
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    _isHidden = (self.presentedViewController != nil);
    
    if (!_isHidden) {
        [[OMeta m].replicator replicateIfNeeded];
    }
}


#pragma mark - Segue handling

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue
{
    [self prepareForPushSegue:segue data:[self dataForIndexPath:_selectedIndexPath]];
}


- (void)prepareForPushSegue:(UIStoryboardSegue *)segue data:(id)data
{
    OTableViewController *destinationViewController = segue.destinationViewController;
    destinationViewController.data = data;
    destinationViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:_selectedIndexPath];
}


#pragma mark - Presenting modal view controllers

- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data
{
    [self presentModalViewWithIdentifier:identifier data:data meta:nil];
}


- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data meta:(id)meta
{
    OTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    
    viewController.data = data;
    
    if ([meta isKindOfClass:OTableViewController.class]) {
        viewController.dismisser = meta;
    } else {
        viewController.meta = meta;
        viewController.dismisser = self;
    }
    
    UIViewController *destinationViewController = nil;
    
    if ([identifier isEqualToString:kAuthView]) {
        destinationViewController = viewController;
        destinationViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    } else {
        destinationViewController = [[UINavigationController alloc] initWithRootViewController:viewController];;
        destinationViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    
    [self.navigationController presentViewController:destinationViewController animated:YES completion:NULL];
}


- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data dismisser:(id)dismisser
{
    [self presentModalViewWithIdentifier:identifier data:data meta:dismisser];
}


#pragma mark - Custom property accessors

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [self.tableView addActivityIndicator];
    }
    
    return _activityIndicator;
}


- (void)setAspectCarrier:(id)aspectCarrier
{
    [_state setAspectForCarrier:aspectCarrier];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    // Override in subclass
}


- (void)populateDataSource
{
    // Override in subclass
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return ([self sectionNumberForSectionKey:sectionKey] > 0);
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    NSInteger sectionNumber = [self sectionNumberForSectionKey:sectionKey];
    
    return ((sectionNumber == [self.tableView numberOfSections] - 1) && !_state.actionIsRegister);
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_sectionKeys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfRowsInSectionWithKey:[_sectionKeys[section] integerValue]];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kDefaultTableViewCellHeight;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_entitySectionKey]) {
        height = [OTableViewCellBlueprint cell:_detailCell heightForEntityClass:_entityClass entity:_entity];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_entitySectionKey]) {
        _detailCell = [tableView cellForEntityClass:_entityClass entity:_entity delegate:self];
        _detailCell.observer = self.observer;
        
        cell = _detailCell;
    } else {
        cell = [tableView listCellForIndexPath:indexPath delegate:self];
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self.tableView cellForRowAtIndexPath:indexPath] != _detailCell);
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSNumber *sectionKey = _sectionKeys[indexPath.section];
        NSMutableArray *sectionData = _sectionData[sectionKey];
        OReplicatedEntity *entity = sectionData[indexPath.row];
        
        _sectionCounts[sectionKey] = @([_sectionCounts[sectionKey] integerValue] - 1);
        [sectionData removeObjectAtIndex:indexPath.row];
        [entity expire];
        
        [[OMeta m].replicator replicateIfNeeded];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultCellPadding;
    
    if ([_instance hasHeaderForSectionWithKey:[self sectionKeyForSectionNumber:section]]) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultCellPadding;
    
    if ([_instance hasFooterForSectionWithKey:[self sectionKeyForSectionNumber:section]]) {
        height = [tableView standardFooterHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *view = nil;

    if ([_instance hasHeaderForSectionWithKey:sectionKey]) {
        view = [tableView headerViewWithText:[self textForHeaderInSectionWithKey:sectionKey]];
    }
    
    return view;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *view = nil;
    
    if ([_instance hasFooterForSectionWithKey:sectionKey]) {
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
    OTableViewCell *cell = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.selectable) {
        _selectedIndexPath = indexPath;
        
        [_instance didSelectRow:indexPath.row inSectionWithKey:[self sectionKeyForSectionNumber:indexPath.section]];
    }
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


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewWithIdentitifier:(NSString *)identitifier
{
    [self dismissModalViewWithIdentitifier:identitifier needsReloadData:YES];
}


- (void)dismissModalViewWithIdentitifier:(NSString *)identitifier needsReloadData:(BOOL)needsReloadData
{
    _needsReloadData = [OMeta m].userIsSignedIn ? needsReloadData : NO;
    
    [self dismissViewControllerAnimated:YES completion:^{
        _needsReloadData = NO;
    }];
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if ([OState s].actionIsSetup) {
        [self.activityIndicator stopAnimating];
        
        [OStrings.class didCompleteWithResponse:response data:data];
        [[OMeta m] setGlobalDefault:[NSDate date] forKey:kDefaultsKeyStringDate];
        [(OTabBarController *)self.tabBarController setTabBarTitles];
        
        [self presentModalViewWithIdentifier:kAuthView data:nil dismisser:self];
    }
}


- (void)didFailWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    
    // TODO: Handle errors (-1001: Timeout, and others)
}

@end
