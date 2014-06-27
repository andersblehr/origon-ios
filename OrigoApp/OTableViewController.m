//
//  OTableViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTableViewController.h"

static NSString * const kViewControllerSuffixDefault = @"ViewController";
static NSString * const kViewControllerSuffixList = @"ListViewController";
static NSString * const kViewControllerSuffixPicker = @"PickerViewController";

static CGFloat const kEmptyFooterHeight = 14.f;
static CGFloat const kSectionSpacing = 28.f;

static NSInteger const kInputSectionKey = 0;
static NSInteger const kMinimumSectionIndexTitles = 13;

static BOOL _needsReinstantiateRootViewController;
static UIViewController * _reinstantiatedRootViewController;


@interface OTableViewController () <UITextFieldDelegate, UITextViewDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _didResurface;
    BOOL _isHidden;
    BOOL _shouldReloadOnModalDismissal;
    
    Class _entityClass;
    NSInteger _inputSectionKey;
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    NSMutableDictionary *_sectionHeaderLabels;
    NSMutableDictionary *_sectionFooterLabels;
    NSMutableArray *_sectionIndexTitles;
    NSMutableSet *_dirtySections;
    
    NSIndexPath *_selectedIndexPath;
    OActivityIndicator *_activityIndicator;
    
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_cancelButton;
    
    id<OTableViewController> _instance;
}

@end


@implementation OTableViewController

@synthesize identifier = _identifier;
@synthesize target = _target;
@synthesize returnData = _returnData;


#pragma mark - Comparison delegation

static NSInteger compareObjects(id object1, id object2, void *context)
{
    return [(__bridge id)context compareObject:object1 toObject:object2];
}


#pragma mark - Auxiliary methods

- (BOOL)isEntityViewController
{
    if (!_entityClass) {
        if (![self isListViewController] && ![self isPickerViewController]) {
            NSString *viewControllerName = NSStringFromClass([self class]);
            _entityClass = NSClassFromString([viewControllerName substringToIndex:[viewControllerName rangeOfString:kViewControllerSuffixDefault].location]);
        }
    }
    
    return _entityClass != NULL;
}


- (BOOL)isListViewController
{
    return [NSStringFromClass([self class]) hasSuffix:kViewControllerSuffixList];
}


- (BOOL)isPickerViewController
{
    return [NSStringFromClass([self class]) hasSuffix:kViewControllerSuffixPicker];
}


- (void)initialiseInstance
{
    if ([[OMeta m] userIsAllSet] || _isModal) {
        if ([self isEntityViewController]) {
            _state.action = _isModal ? kActionRegister : kActionDisplay;
        } else if ([self isListViewController]) {
            _state.action = kActionList;
        } else if ([self isPickerViewController]) {
            _state.action = kActionPick;
        }
        
        [_instance loadState];
        [_instance loadData];
        
        for (NSNumber *sectionKey in [_sectionData allKeys]) {
            _sectionCounts[sectionKey] = @([_sectionData[sectionKey] count]);
        }
        
        _didInitialise = YES;
    } else {
        _state.action = kActionLoad;
        _state.target = kTargetUser;
    }
}


- (NSArray *)sortedArrayWithData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    NSArray *unsortedArray = [data allObjects];
    NSArray *sortedArray = nil;
    
    BOOL instanceCanCompare = NO;
    
    if ([_instance respondsToSelector:@selector(canCompareObjectsInSectionWithKey:)]) {
        instanceCanCompare = [_instance canCompareObjectsInSectionWithKey:sectionKey];
    }
    
    if (instanceCanCompare) {
        sortedArray = [unsortedArray sortedArrayUsingFunction:compareObjects context:(__bridge void *)_instance];
    } else if ([_instance respondsToSelector:@selector(sortKeyForSectionWithKey:)]) {
        NSString *sortKey = [_instance sortKeyForSectionWithKey:sectionKey];
        
        if (sortKey) {
            sortedArray = [unsortedArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
        }
    }
    
    return sortedArray ? sortedArray : unsortedArray;
}


- (NSInteger)sectionKeyForSectionNumber:(NSInteger)sectionNumber
{
    return [_sectionKeys[sectionNumber] integerValue];
}


- (NSInteger)sectionNumberForSectionKey:(NSInteger)sectionKey
{
    return [_sectionKeys indexOfObject:@(sectionKey)];
}


- (void)reloadFooterForSectionPrecedingSection:(NSInteger)section
{
    NSInteger precedingSectionKey = [self sectionKeyForSectionNumber:section - 1];
    BOOL hasPrecedingFooter = NO;
    
    if ([_instance respondsToSelector:@selector(hasFooterForSectionWithKey:)]) {
        hasPrecedingFooter = [_instance hasFooterForSectionWithKey:precedingSectionKey];
    }
    
    if (hasPrecedingFooter) {
        [_sectionFooterLabels[@(precedingSectionKey)] setText:[_instance textForFooterInSectionWithKey:precedingSectionKey]];
    } else if ([_sectionFooterLabels[@(precedingSectionKey)] text]) {
        [_sectionFooterLabels[@(precedingSectionKey)] setText:nil];
    }
}


- (void)reloadHeaderForSectionFollowingSection:(NSInteger)section
{
    NSInteger followingSectionKey = [self sectionKeyForSectionNumber:section + 1];
    BOOL hasFollowingHeader = NO;
    
    if ([_instance respondsToSelector:@selector(hasHeaderForSectionWithKey:)]) {
        hasFollowingHeader = [_instance hasHeaderForSectionWithKey:followingSectionKey];
    } else {
        hasFollowingHeader = [self sectionNumberForSectionKey:followingSectionKey] > 0;
    }
    
    if (hasFollowingHeader) {
        [_sectionHeaderLabels[@(followingSectionKey)] setText:[_instance textForHeaderInSectionWithKey:followingSectionKey]];
    } else if ([_sectionHeaderLabels[@(followingSectionKey)] text]) {
        [_sectionHeaderLabels[@(followingSectionKey)] setText:nil];
    }
}


- (void)inputFieldDidBeginEditing:(OInputField *)inputField
{
    if ([self actionIs:kActionDisplay]) {
        [self toggleEditMode];
    }
    
    _inputCell.inputField = inputField;
    
    if ([_inputCell nextInputField]) {
        self.navigationItem.rightBarButtonItem = _nextButton;
        
        if (!inputField.supportsMultiLineText) {
            inputField.returnKeyType = UIReturnKeyNext;
        }
    } else {
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if (!inputField.supportsMultiLineText) {
            inputField.returnKeyType = UIReturnKeyDone;
        }
    }
}


- (void)preparePushDestinationViewController:(OTableViewController *)destinationViewController
{
    destinationViewController.target = [self dataAtIndexPath:_selectedIndexPath];
    destinationViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:_selectedIndexPath];
    
    if (destinationViewController.entity && _entity) {
        destinationViewController.entity.ancestor = _entity;
    }
}


#pragma mark - Header & footer handling & delegation

- (BOOL)instanceHasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = [self sectionNumberForSectionKey:sectionKey] > 0;
    
    if ([_instance respondsToSelector:@selector(hasHeaderForSectionWithKey:)]) {
        hasHeader = [_instance hasHeaderForSectionWithKey:sectionKey];
    }
    
    return hasHeader || _usesSectionIndexTitles;
}


- (BOOL)instanceHasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if ([_instance respondsToSelector:@selector(hasFooterForSectionWithKey:)]) {
        hasFooter = [_instance hasFooterForSectionWithKey:sectionKey];
    }
    
    return hasFooter;
}


- (NSString *)footerTextForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerText = nil;
    
    if ([_instance respondsToSelector:@selector(textForFooterInSectionWithKey:)]) {
        footerText = [_instance textForFooterInSectionWithKey:sectionKey];
    }
    
    return footerText;
}


#pragma mark - Selector implementations

- (void)didBeginEditing
{
    [self toggleEditMode];
}


- (void)didCancelEditing
{
    if ([self actionIs:kActionEdit]) {
        [_inputCell readData];
        [self toggleEditMode];
    } else {
        _didCancel = !_cancelImpliesSkip;
        
        if (_didCancel) {
            [_dismisser dismissModalViewController:self];
        } else {
            [_inputCell processInputShouldValidate:NO];
        }
    }
}


- (void)didFinishEditing
{
    if ([self actionIs:kActionInput]) {
        if (_isModal && [self isEntityViewController]) {
            _returnData = _entity;
        }
        
        [_inputCell processInputShouldValidate:YES];
    } else {
        [_dismisser dismissModalViewController:self];
    }
}


- (void)moveToNextInputField
{
    [[_inputCell nextInputField] becomeFirstResponder];
}


#pragma mark - State introspection

- (BOOL)actionIs:(NSString *)action
{
    return [_state actionIs:action];
}


- (BOOL)targetIs:(NSString *)target
{
    return [_state targetIs:target];
}


- (BOOL)aspectIs:(NSString *)aspect
{
    return [_state aspectIs:aspect];
}


#pragma mark - Managing section data

- (void)setDataForInputSection
{
    [self setData:self.target forSectionWithKey:kInputSectionKey];
}


- (void)setData:(id)data forSectionWithKey:(NSInteger)sectionKey
{
    if ([data isKindOfClass:[NSArray class]]) {
        _sectionData[@(sectionKey)] = [data mutableCopy];
    } else if ([data isKindOfClass:[NSSet class]]) {
        _sectionData[@(sectionKey)] = [[self sortedArrayWithData:data forSectionWithKey:sectionKey] mutableCopy];
    } else if (data) {
        if (sectionKey == kInputSectionKey) {
            _inputSectionKey = sectionKey;
            
            if (_entity) {
                _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:_entity];
            } else {
                _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
            }
        } else {
            _sectionData[@(sectionKey)] = [NSMutableArray arrayWithObject:data];
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
    if (sectionKey == _inputSectionKey) {
        _inputSectionKey = NSNotFound;
        _entity = nil;
    }
    
    if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSSet class]]) {
        [_sectionData[@(sectionKey)] addObjectsFromArray:[self sortedArrayWithData:data forSectionWithKey:sectionKey]];
    } else if (data && ![_sectionData[@(sectionKey)] containsObject:data]) {
        [_sectionData[@(sectionKey)] addObject:data];
    }
}


- (void)setData:(NSArray *)data sectionIndexLabelKey:(NSString *)sectionIndexLabelKey
{
    static NSInteger sectionKey;
    static NSString *labelKey = nil;
    
    if (sectionIndexLabelKey) {
        sectionKey = 0;
        
        [_sectionIndexTitles removeAllObjects];
        [_dirtySections addObjectsFromArray:_sectionKeys];
        
        if (_usesPlainTableViewStyle && ([data count] > kMinimumSectionIndexTitles)) {
            _usesSectionIndexTitles = YES;
            labelKey = sectionIndexLabelKey;
            
            [self setData:data sectionIndexLabelKey:nil];
        } else {
            [self setData:data forSectionWithKey:sectionKey];
        }
    } else if (labelKey) {
        if ([data count]) {
            NSString *sectionLabelSample = [data[0] valueForKey:labelKey];
            NSString *sectionInitial = [sectionLabelSample substringWithRange:NSMakeRange(0, 1)];
            
            [_sectionIndexTitles addObject:[sectionInitial uppercaseString]];
            
            NSMutableArray *sectionData = [NSMutableArray array];
            NSArray *remainingData = nil;
            
            for (NSInteger i = 0; (i < [data count]) && !remainingData; i++) {
                NSString *label = [data[i] valueForKey:labelKey];
                
                if ([[label lowercaseString] hasPrefix:[sectionInitial lowercaseString]]) {
                    [sectionData addObject:data[i]];
                } else {
                    remainingData = [data subarrayWithRange:NSMakeRange(i, [data count] - i)];
                }
            }
            
            [self setData:sectionData forSectionWithKey:sectionKey++];
            [self setData:remainingData sectionIndexLabelKey:nil];
        } else if ([_sectionKeys count] > sectionKey) {
            NSRange redundantSections = NSMakeRange(sectionKey, [_sectionKeys count] - sectionKey);
            NSArray *redundantSectionKeys = [_sectionKeys subarrayWithRange:redundantSections];
            
            [_sectionKeys removeObjectsInRange:redundantSections];
            [_sectionData removeObjectsForKeys:redundantSectionKeys];
            [_sectionCounts removeObjectsForKeys:redundantSectionKeys];
            
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:redundantSections] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
    return _sectionData[@([self sectionKeyForIndexPath:indexPath])][indexPath.row];
}


#pragma mark - View layout

- (BOOL)isBottomSectionKey:(NSInteger)sectionKey
{
    return sectionKey == [[_sectionKeys lastObject] integerValue];
}


- (BOOL)hasSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionKeys containsObject:@(sectionKey)];
}


- (NSInteger)sectionKeyForIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionKeyForSectionNumber:indexPath.section];
}


#pragma mark - Modal view controller handling

- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target
{
    [self presentModalViewControllerWithIdentifier:identifier target:target meta:nil];
}


- (void)presentModalViewControllerWithIdentifier:(NSString *)identifier target:(id)target meta:(id)meta
{
    OTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    
    viewController->_isModal = YES;
    viewController.target = target;
    
    if (viewController.entity && _entity) {
        viewController.entity.ancestor = _entity;
    }
    
    if ([meta isKindOfClass:[OTableViewController class]]) {
        viewController.dismisser = meta;
    } else {
        viewController.meta = meta;
        viewController.dismisser = self;
    }
    
    UIViewController *destinationViewController = nil;
    
    if ([identifier isEqualToString:kIdentifierAuth]) {
        destinationViewController = viewController;
    } else {
        destinationViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    }
    
    destinationViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:destinationViewController animated:YES completion:NULL];
}


- (void)dismissModalViewController:(OTableViewController *)viewController
{
    BOOL shouldRelayDismissal = NO;
    
    if (_isModal) {
        if ([_instance respondsToSelector:@selector(shouldRelayDismissalOfModalViewController:)]) {
            shouldRelayDismissal = [_instance shouldRelayDismissalOfModalViewController:viewController];
        }
    }
    
    if (shouldRelayDismissal) {
        [_dismisser dismissModalViewController:self];
    } else {
        if ([_instance respondsToSelector:@selector(willDismissModalViewController:)]) {
            [_instance willDismissModalViewController:viewController];
        }
        
        if ([[OMeta m] userIsSignedIn]) {
            _shouldReloadOnModalDismissal = !viewController.didCancel;
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            _shouldReloadOnModalDismissal = NO;
        }];
        
        if ([_instance respondsToSelector:@selector(didDismissModalViewController:)]) {
            [_instance didDismissModalViewController:viewController];
        }
    }
}


#pragma mark - Edit mode transitions

- (void)toggleEditMode
{
    [_inputCell toggleEditMode];
    
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
        
        if (_nextInputField) {
            [_nextInputField becomeFirstResponder];
            _nextInputField = nil;
        } else {
            [[_inputCell nextInputField] becomeFirstResponder];
        }
    } else if ([self actionIs:kActionDisplay]) {
        self.navigationItem.rightBarButtonItem = rightButton;
        self.navigationItem.leftBarButtonItem = leftButton;
        
        if ([[OMeta m].replicator needsReplication]) {
            [[OMeta m].replicator replicate];
            [self.observer observeEntity];
        }
    }
    
    OLogState;
}


- (void)endEditing
{
    [self.view endEditing:YES];
    
    if ([self actionIs:kActionRegister]) {
        self.inputCell.editable = NO;
        self.navigationItem.rightBarButtonItem = _doneButton;
    }
}


#pragma mark - Reloading sections and/or section elements

- (void)reloadSections
{
    [_instance loadData];
    
    NSMutableIndexSet *affectedSections = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToInsert = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToReload = [NSMutableIndexSet indexSet];
    
    [self.tableView beginUpdates];
    
    for (NSNumber *sectionKey in [_sectionData allKeys]) {
        NSInteger section = [self sectionNumberForSectionKey:[sectionKey integerValue]];
        NSInteger oldCount = [_sectionCounts[sectionKey] integerValue];
        NSInteger newCount = [_sectionData[sectionKey] count];
        
        if (oldCount) {
            if (newCount) {
                if ((newCount != oldCount) || [_dirtySections containsObject:@(section)]) {
                    [sectionsToReload addIndex:section];
                }
            } else {
                [affectedSections addIndex:section];
                [_sectionKeys removeObject:sectionKey];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else if (newCount) {
            [sectionsToInsert addIndex:section];
        }
        
        _sectionCounts[sectionKey] = @(newCount);
    }
    
    if ([sectionsToInsert count]) {
        [self.tableView insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    if ([sectionsToReload count]) {
        [self.tableView reloadSections:sectionsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView endUpdates];
    [_dirtySections removeAllObjects];
    
    [affectedSections addIndexes:sectionsToInsert];
    [affectedSections addIndexes:sectionsToReload];
    
    NSInteger topmostAffectedSection = [affectedSections firstIndex];
    NSInteger bottomAffectedSection = [affectedSections lastIndex];
    NSInteger bottomSection = [self sectionNumberForSectionKey:[[_sectionKeys lastObject] integerValue]];
    
    if (topmostAffectedSection != NSNotFound) {
        if (topmostAffectedSection > 0) {
            [self reloadFooterForSectionPrecedingSection:topmostAffectedSection];
        }
        
        if (bottomAffectedSection < bottomSection) {
            [self reloadHeaderForSectionFollowingSection:bottomAffectedSection];
        }
    }
}


- (void)reloadSectionWithKey:(NSInteger)sectionKey
{
    [_instance loadData];
    
    BOOL sectionExists = [_sectionCounts[@(sectionKey)] integerValue] > 0;
    BOOL sectionIsEmpty = ![_sectionData[@(sectionKey)] count];
    
    if (sectionExists || !sectionIsEmpty) {
        _sectionCounts[@(sectionKey)] = @([_sectionData[@(sectionKey)] count]);
        
        NSInteger section = [self sectionNumberForSectionKey:sectionKey];
        NSInteger bottomSection = [self sectionNumberForSectionKey:[[_sectionKeys lastObject] integerValue]];
        
        if (section == 0 && section < bottomSection) {
            [self reloadHeaderForSectionFollowingSection:section];
        } else if (section < bottomSection) {
            [self reloadFooterForSectionPrecedingSection:section];
            [self reloadHeaderForSectionFollowingSection:section];
        } else if (section > 0) {
            [self reloadFooterForSectionPrecedingSection:section];
        }
        
        if (sectionExists && !sectionIsEmpty) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (!sectionExists && !sectionIsEmpty) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (sectionExists && sectionIsEmpty) {
            [_sectionKeys removeObject:@(sectionKey)];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([OMeta systemIs_iOS6x]) {
        self.tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.tableView.backgroundColor = [UIColor tableViewBackgroundColour];
    }
    
    _identifier = self.restorationIdentifier;
    _sectionKeys = [NSMutableArray array];
    _sectionData = [NSMutableDictionary dictionary];
    _sectionCounts = [NSMutableDictionary dictionary];
    _sectionHeaderLabels = [NSMutableDictionary dictionary];
    _sectionFooterLabels = [NSMutableDictionary dictionary];
    _sectionIndexTitles = [NSMutableArray array];
    _dirtySections = [NSMutableSet set];
    _inputSectionKey = NSNotFound;
    _instance = self;
    _state = [[OState alloc] initWithViewController:self];
    
    [self initialiseInstance];
    
    if (_usesPlainTableViewStyle) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    if ([self actionIs:kActionRegister]) {
        _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
        _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        
        if (_isModal) {
            if ([[OMeta m].user isActive]) {
                if (_cancelImpliesSkip) {
                    self.navigationItem.leftBarButtonItem = [UIBarButtonItem skipButtonWithTarget:self];
                } else {
                    self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
                }
            } else {
                self.navigationItem.leftBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:[OMeta m]];
            }
        }
        
        [self.navigationItem appendRightBarButtonItem:_nextButton];
    }
    
    _didJustLoad = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    if (!_didJustLoad) {
        if (!_didInitialise && self.target) {
            [self initialiseInstance];
        }
        
        [_state makeActive];
    }
    
    [super viewWillAppear:animated];
    
    _wasHidden = _isHidden;
    _isHidden = NO;
    _isPushed = [self isMovingToParentViewController] || (_didJustLoad && !_isModal);
    _didResurface = !_isPushed && !_wasHidden && (!_isModal || !_didJustLoad);
    _didJustLoad = NO;
    
    if ([_instance respondsToSelector:@selector(toolbarButtons)]) {
        if (!_isModal && (!self.toolbarItems || _didResurface || _wasHidden)) {
            self.toolbarItems = [_instance toolbarButtons];
        }
    }
    
    [self.navigationController setToolbarHidden:(!self.toolbarItems) animated:YES];
    
    if (![self actionIs:kActionInput] && (_didResurface || _shouldReloadOnModalDismissal)) {
        [self reloadSections];
    } else if ([self actionIs:kActionInput] && _didResurface) {
        [self.inputCell resumeFirstResponder];
    }
}


- (void)viewDidLayoutSubviews
{
    if (_inputCell) {
        [_inputCell didLayoutSubviews];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    OLogState;
    
    if ([[OMeta m] userIsSignedIn]) {
        if (_inputCell && !_didResurface && !_isHidden) {
            [_inputCell prepareForInput];
            
            if ([self actionIs:kActionRegister] && !_wasHidden) {
                if (![_inputCell nextInvalidInputField]) {
                    [[_inputCell nextInputField] becomeFirstResponder];
                }
            }
        }
    } else if (![_identifier isEqualToString:kIdentifierAuth]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetUser];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self.observer observeEntity];
    }
    
	[super viewWillDisappear:animated];
    
    _isHidden = self.presentedViewController ? YES : NO;
    
    [[OMeta m].replicator replicateIfNeeded];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_needsReinstantiateRootViewController) {
        [self.navigationController setViewControllers:@[_reinstantiatedRootViewController]];
        _needsReinstantiateRootViewController = NO;
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([OMeta systemIs_iOS6x]) {
        for (OTableViewCell *cell in [self.tableView visibleCells]) {
            [cell redrawSeparatorsForTableViewCell];
        }
    }
}


#pragma mark - Custom accessors

- (void)setTarget:(id)target
{
    _target = target;
    
    id ancestor = _entity.ancestor;
    
    if ([target conformsToProtocol:@protocol(OEntity)]) {
        _entity = [target proxy];
    } else if ([self isEntityViewController]) {
        _entity = [[_entityClass proxyClass] proxyForEntityOfClass:_entityClass meta:target];
    }
    
    if (_entity) {
        _target = _entity;
        _entity.ancestor = ancestor;
    }
    
    if (_state) {
        _state.target = _target;
    }
}


- (id)target
{
    if (!_target && [_instance respondsToSelector:@selector(defaultTarget)]) {
        self.target = [_instance defaultTarget];
    }
    
    return _target;
}


- (void)setUsesSectionIndexTitles:(BOOL)usesSectionIndexTitles
{
    _usesSectionIndexTitles = usesSectionIndexTitles;
    
    if (_usesSectionIndexTitles) {
        _usesPlainTableViewStyle = YES;
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self preparePushDestinationViewController:segue.destinationViewController];
}


#pragma mark - OTableViewController conformance

- (void)loadState
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)loadData
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)didSignOut
{
    _needsReinstantiateRootViewController = YES;
    _reinstantiatedRootViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierOrigoList];
    
    [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetUser meta:_reinstantiatedRootViewController];
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_sectionKeys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sectionCounts[@([_sectionKeys[section] integerValue])] integerValue];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kDefaultCellHeight;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_inputSectionKey]) {
        if (_inputCell) {
            height = [_inputCell.constrainer heightOfInputCell];
        } else {
            height = [OInputCellConstrainer heightOfInputCellWithEntity:_entity delegate:_instance];
        }
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    if (indexPath.section == [self sectionNumberForSectionKey:_inputSectionKey]) {
        NSString *reuseIdentifier = nil;
        
        if ([_instance respondsToSelector:@selector(reuseIdentifierForInputSection)]) {
            reuseIdentifier = [_instance reuseIdentifierForInputSection];
        }
        
        if (reuseIdentifier) {
            cell = [tableView inputCellWithReuseIdentifier:reuseIdentifier delegate:_instance];
        } else {
            cell = [tableView inputCellWithEntity:_entity delegate:_instance];
            cell.observer = self.observer;
        }
        
        _inputCell = cell;
    } else {
        UITableViewCellStyle style = UITableViewCellStyleSubtitle;
        
        if ([_instance respondsToSelector:@selector(styleForListCellAtIndexPath:)]) {
            style = [_instance styleForListCellAtIndexPath:indexPath];
        }
        
        cell = [tableView listCellWithStyle:style data:[self dataAtIndexPath:indexPath] delegate:_instance];
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteCell = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] != _inputSectionKey) {
        if ([_instance respondsToSelector:@selector(canDeleteCellAtIndexPath:)]) {
            canDeleteCell = [_instance canDeleteCellAtIndexPath:indexPath];
        }
    }
    
    return canDeleteCell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSNumber *sectionKey = _sectionKeys[indexPath.section];
        NSMutableArray *sectionData = _sectionData[sectionKey];
        id entity = sectionData[indexPath.row];
        
        _sectionCounts[sectionKey] = @([_sectionCounts[sectionKey] integerValue] - 1);
        [sectionData removeObjectAtIndex:indexPath.row];
        
        if ([_entity instance] && [entity instance]) {
            [[[_entity instance] relationshipToEntity:[entity instance]] expire];
            [[OMeta m].replicator replicateIfNeeded];
        }
        
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _sectionIndexTitles;
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = _usesPlainTableViewStyle ? 0.f : kSectionSpacing;
    
    if ([self instanceHasHeaderForSectionWithKey:[self sectionKeyForSectionNumber:section]]) {
        height = [tableView headerHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = _usesPlainTableViewStyle ? 0.f : kEmptyFooterHeight;
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    
    if ([self instanceHasFooterForSectionWithKey:sectionKey]) {
        height = [tableView footerHeightWithText:[self footerTextForSectionWithKey:sectionKey]];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = nil;
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];

    if (_usesSectionIndexTitles) {
        view = [tableView headerViewWithText:_sectionIndexTitles[section]];
    } else if ([self instanceHasHeaderForSectionWithKey:sectionKey]) {
        view = [tableView headerViewWithText:[_instance textForHeaderInSectionWithKey:sectionKey]];
        
        if (view) {
            [_sectionHeaderLabels setObject:view.subviews[0] forKey:@(sectionKey)];
        }
    }
    
    return view;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = nil;
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    
    if ([self instanceHasFooterForSectionWithKey:sectionKey]) {
        view = [tableView footerViewWithText:[self footerTextForSectionWithKey:sectionKey]];
    }
    
    if (view) {
        [_sectionFooterLabels setObject:view.subviews[0] forKey:@(sectionKey)];
    }
    
    return view;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (cell == _inputCell) {
        if ([_instance respondsToSelector:@selector(willDisplayInputCell:)]) {
            [_instance willDisplayInputCell:cell];
        }
    } else {
        [_instance loadListCell:cell atIndexPath:indexPath];
    }
    
    if ([OMeta systemIs_iOS6x] && !_usesPlainTableViewStyle) {
        [cell.backgroundView addSeparatorsForTableViewCell];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.destinationId) {
        if (![self actionIs:kActionInput] || cell.selectableDuringInput) {
            _selectedIndexPath = indexPath;
            
            if (![_identifier isEqualToString:cell.destinationId]) {
                [self performSegueWithIdentifier:[_identifier stringByAppendingString:cell.destinationId separator:kSeparatorColon] sender:self];
            } else {
                OTableViewController *destinationViewController = [self.storyboard instantiateViewControllerWithIdentifier:cell.destinationId];
                
                [self preparePushDestinationViewController:destinationViewController];
                [self.navigationController pushViewController:destinationViewController animated:YES];
            }
        } else {
            cell.selected = NO;
        }
    } else if (cell.selectable) {
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


- (BOOL)textFieldShouldReturn:(OTextField *)textField
{
    if ([_inputCell nextInputField]) {
        [self moveToNextInputField];
    } else {
        [self performSelector:@selector(didFinishEditing)];
    }
    
    return NO;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    _inputCell.inputField = nil;
}


#pragma mark - UITextViewDelegate conformance

- (void)textViewDidBeginEditing:(OTextView *)textView
{
    [self inputFieldDidBeginEditing:textView];
}


- (void)textViewDidChange:(OTextView *)textView
{
    [_inputCell redrawIfNeeded];
}


- (void)textViewDidEndEditing:(OTextView *)textView
{
    _inputCell.inputField = nil;
}


#pragma mark - OConnectionDelegate conformance

- (void)willSendRequest:(NSURLRequest *)request
{
    if (_requiresSynchronousServerCalls) {
        [[OMeta m].activityIndicator startAnimating];
    }
}


- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if ([OMeta m].activityIndicator.isAnimating) {
        [[OMeta m].activityIndicator stopAnimating];
    }
}


- (void)didFailWithError:(NSError *)error
{
    if ([OMeta m].activityIndicator.isAnimating) {
        [[OMeta m].activityIndicator stopAnimating];
    }
    
    // TODO: Handle errors (-1001: Timeout, and others)
}

@end
