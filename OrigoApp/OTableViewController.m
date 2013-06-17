//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
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
#import "OUtil.h"

#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OTabBarController.h"

NSString * const kCustomCell = @"custom";

static NSString * const kListViewSuffix = @"ListViewController";
static NSString * const kDetailViewSuffix = @"ViewController";


@interface OTableViewController ()

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end


@implementation OTableViewController

#pragma mark - Auxiliary methods

- (BOOL)isListView
{
    return [NSStringFromClass(self.class) containsString:kListViewSuffix];
}


- (void)initialiseInstance
{
    if ([OStrings hasStrings]) {
        if ([OMeta m].userIsAllSet || _isModal) {
            if (_isModal && self.modalImpliesRegistration) {
                _action = kActionRegister;
            } else if ([self isListView]) {
                _action = kActionList;
            } else {
                _action = kActionDisplay;
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
    } else {
        _action = kActionSetup;
    }
}


- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey
{
    return [_sectionKeys indexOfObject:@(sectionKey)];
}


- (void)inputFieldDidBeginEditing:(id)inputField
{
    if ([self actionIs:kActionDisplay]) {
        [self toggleEditMode];
    }

    _detailCell.inputField = inputField;
    
    if ([_detailCell nextInputField]) {
        self.navigationItem.rightBarButtonItem = _nextButton;
    } else {
        self.navigationItem.rightBarButtonItem = _doneButton;
    }
}


- (void)resetViewControllerAtTabIndex:(NSInteger)tabIndex reauthenticate:(BOOL)reauthenticate
{
    NSString *viewControllerId = nil;
    
    if (tabIndex == kTabIndexOrigo) {
        viewControllerId = kViewIdOrigoList;
    } else if (tabIndex == kTabIndexCalendar) {
        viewControllerId = kViewIdCalendar;
    } else if (tabIndex == kTabIndexTasks) {
        viewControllerId = kViewIdTaskList;
    } else if (tabIndex == kTabIndexMessages) {
        viewControllerId = kViewIdMessageList;
    } else if (tabIndex == kTabIndexSettings) {
        viewControllerId = kViewIdSettingList;
    }
    
    UINavigationController *navigationController = self.tabBarController.viewControllers[tabIndex];
    [navigationController setViewControllers:[NSArray arrayWithObject:[self.storyboard instantiateViewControllerWithIdentifier:viewControllerId]]];
    
    if (reauthenticate) {
        [[OMeta m] userDidSignOut];
        
        [self presentModalViewWithIdentifier:kViewIdAuth data:nil dismisser:navigationController.viewControllers[0]];
        
        _reauthenticationLandingTabIndex = tabIndex;
    }
}


#pragma mark - Selector implementations

- (void)moveToNextInputField
{
    [[_detailCell nextInputField] becomeFirstResponder];
}


- (void)didCancelEditing
{
    if ([self actionIs:kActionRegister]) {
        [_dismisser dismissModalViewControllerNeedsReloadData:NO];
    } else if ([self actionIs:kActionEdit]) {
        [_detailCell readEntity];
        [self toggleEditMode];
    }
}


- (void)didFinishEditing
{
    if ([self isListView]) {
        [_dismisser dismissModalViewController];
    } else {
        if ([_instance inputIsValid]) {
            if ([self actionIs:kActionRegister]) {
                [self.view endEditing:YES];
            }
            
            [_instance processInput];
        } else {
            [_detailCell shakeCellVibrate:NO];
        }
    }
}


- (void)signOut
{
    [self resetViewControllerAtTabIndex:kTabIndexOrigo reauthenticate:YES];
}


#pragma mark - Setting & accessing section data

- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    if ([data isKindOfClass:NSArray.class]) {
        _sectionData[@(sectionKey)] = [NSMutableArray arrayWithArray:data];
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
    
    if ([_data isKindOfClass:NSArray.class] || [data isKindOfClass:NSSet.class]) {
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


- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
    return [self dataAtRow:indexPath.row inSectionWithKey:[self sectionKeyForIndexPath:indexPath]];
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


- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionKeyForSectionNumber:indexPath.section];
}


#pragma mark - Segue handling

- (void)prepareForPushSegue:(UIStoryboardSegue *)segue
{
    [self prepareForPushSegue:segue data:[self dataAtIndexPath:_selectedIndexPath]];
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
    
    if ([identifier isEqualToString:kViewIdAuth]) {
        destinationViewController = viewController;
        destinationViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    } else {
        destinationViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        destinationViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    
    [self.navigationController presentViewController:destinationViewController animated:YES completion:NULL];
}


- (void)presentModalViewWithIdentifier:(NSString *)identifier data:(id)data dismisser:(id)dismisser
{
    [self presentModalViewWithIdentifier:identifier data:data meta:dismisser];
}


#pragma mark - State inspection

- (BOOL)actionIs:(NSString *)action
{
    return [_action isEqualToString:action];
}


- (BOOL)targetIs:(NSString *)target
{
    return [_target isEqualToString:target];
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
    [self.state toggleEditState];
    [_detailCell toggleEditMode];
    
    static UIBarButtonItem *rightButton = nil;
    static UIBarButtonItem *leftButton = nil;
    
    if ([self actionIs:kActionEdit]) {
        rightButton = self.navigationItem.rightBarButtonItem;
        leftButton = self.navigationItem.leftBarButtonItem;
        
        if (!_cancelButton) {
            _cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
            _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
            _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        }
        
        self.navigationItem.leftBarButtonItem = _cancelButton;
    } else if ([self actionIs:kActionDisplay]) {
        [self.view endEditing:YES];
        
        self.navigationItem.rightBarButtonItem = rightButton;
        self.navigationItem.leftBarButtonItem = leftButton;
        
        if ([[OMeta m].replicator needsReplication]) {
            [[OMeta m].replicator replicate];
            [self.observer entityDidChange];
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


- (void)reloadSectionWithKey:(NSInteger)sectionKey
{
    [_instance populateDataSource];
    
    _sectionCounts[@(sectionKey)] = @([_sectionData[@(sectionKey)] count]);
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[self sectionNumberForSectionKey:sectionKey]] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)resumeFirstResponder
{
    [_detailCell.inputField becomeFirstResponder];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    NSString *longName = NSStringFromClass(self.class);
    NSString *shortName = [longName substringFromIndex:1];
    NSString *viewSuffix = [self isListView] ? kListViewSuffix : kDetailViewSuffix;
    _viewId = [[shortName substringToIndex:[shortName rangeOfString:viewSuffix].location] lowercaseString];
    
    if ([self isListView]) {
        _modalImpliesRegistration = NO;
        _viewId = [_viewId stringByAppendingString:@"s"];
    } else {
        _modalImpliesRegistration = YES;
        _entityClass = NSClassFromString([longName substringToIndex:[longName rangeOfString:kDetailViewSuffix].location]);
    }
    
    if (!self.navigationController || ([self.navigationController.viewControllers count] == 1)) {
        _isModal = (self.presentingViewController != nil);
    }
    
    _entitySectionKey = NSNotFound;
    _sectionKeys = [[NSMutableArray alloc] init];
    _sectionData = [[NSMutableDictionary alloc] init];
    _sectionCounts = [[NSMutableDictionary alloc] init];
    _reauthenticationLandingTabIndex = NSNotFound;
    _instance = self;
    
    _state = [[OState alloc] initWithViewController:self];
    _canEdit = NO;
    _cancelRegistrationImpliesSignOut = NO;
    
    [self initialiseInstance];
    
    if ([self actionIs:kActionRegister]) {
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
        [self.tabBarController.tabBar.items[kTabIndexOrigo] setTitle:nil];
    }
    
    if (_isPopped || _needsReloadSections) {
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
        [self presentModalViewWithIdentifier:kViewIdAuth data:nil dismisser:self];
    } else if ([self actionIs:kActionRegister]) {
        [[self.detailCell nextInputField] becomeFirstResponder];
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


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_reauthenticationLandingTabIndex != NSNotFound) {
        NSInteger leftmostTabIndex = kTabIndexOrigo;
        NSInteger rightmostTabIndex = kTabIndexSettings;
        
        self.tabBarController.selectedIndex = _reauthenticationLandingTabIndex;
        
        for (NSInteger tabIndex = leftmostTabIndex; tabIndex <= rightmostTabIndex; tabIndex++) {
            if (tabIndex != _reauthenticationLandingTabIndex) {
                [self resetViewControllerAtTabIndex:tabIndex reauthenticate:NO];
            }
        }
        
        _reauthenticationLandingTabIndex = NSNotFound;
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Custom property accessors

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [self.tableView addActivityIndicator];
    }
    
    return _activityIndicator;
}


- (void)setTarget:(id)target
{
    if ([target isKindOfClass:OReplicatedEntity.class]) {
        _target = [target asTarget];
    } else if ([target isKindOfClass:NSString.class]) {
        _target = [OUtil stringHoldsValidEmailAddress:target] ? kTargetEmail : target;
    }
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
    
    return ((sectionNumber == [self.tableView numberOfSections] - 1) && ![self actionIs:kActionRegister]);
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
        _detailCell = [tableView cellForEntityClass:_entityClass entity:_entity];
        _detailCell.observer = self.observer;
        
        cell = _detailCell;
    } else {
        cell = [tableView listCellForIndexPath:indexPath value:[self dataAtIndexPath:indexPath]];
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
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    CGFloat height = kDefaultCellPadding;
    
    if ([_instance hasFooterForSectionWithKey:sectionKey]) {
        height = [tableView heightForFooterWithText:[_instance textForFooterInSectionWithKey:sectionKey]];
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
    
    if ([_instance respondsToSelector:@selector(willDisplayCell:atIndexPath:)]) {
        [_instance willDisplayCell:cell atIndexPath:indexPath];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.selectable) {
        _selectedIndexPath = indexPath;
        
        if ([_instance respondsToSelector:@selector(didSelectCell:atIndexPath:)]) {
            [_instance didSelectCell:cell atIndexPath:indexPath];
        }
    }
}


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    [self inputFieldDidBeginEditing:textField];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([_detailCell nextInputField]) {
        [self moveToNextInputField];
    } else {
        [self performSelector:@selector(didFinishEditing)];
    }
    
    return YES;
}


#pragma mark - UITextViewDelegate conformance

- (void)textViewDidBeginEditing:(OTextView *)textView
{
    [self inputFieldDidBeginEditing:textView];
}


- (void)textViewDidChange:(OTextView *)textView
{
    [self.detailCell redrawIfNeeded];
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewController
{
    [self dismissModalViewControllerWithIdentifier:_viewId];
}


- (void)dismissModalViewControllerWithIdentifier:(NSString *)identifier
{
    [self dismissModalViewControllerWithIdentifier:identifier needsReloadData:YES];
}


- (void)dismissModalViewControllerNeedsReloadData:(BOOL)needsReloadData
{
    [self dismissModalViewControllerWithIdentifier:_viewId needsReloadData:needsReloadData];
}


- (void)dismissModalViewControllerWithIdentifier:(NSString *)identifier needsReloadData:(BOOL)needsReloadData
{
    _needsReloadSections = [OMeta m].userIsSignedIn ? needsReloadData : NO;
    
    [self dismissViewControllerAnimated:YES completion:^{
        _needsReloadSections = NO;
    }];
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if ([self actionIs:kActionSetup]) {
        [self.activityIndicator stopAnimating];
        
        [OStrings.class didCompleteWithResponse:response data:data];
        [[OMeta m] setGlobalDefault:[NSDate date] forKey:kDefaultsKeyStringDate];
        [(OTabBarController *)self.tabBarController setTabBarTitles];
        
        [self presentModalViewWithIdentifier:kViewIdAuth data:nil dismisser:self];
    }
}


- (void)didFailWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    
    // TODO: Handle errors (-1001: Timeout, and others)
}

@end
