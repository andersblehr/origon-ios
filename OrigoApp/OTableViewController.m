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

static CGFloat const kInitialHeadroomHeight = 28.f;
static CGFloat const kPlainTableViewHeaderHeight = 22.f;
static CGFloat const kFooterHeadroom = 6.f;
static CGFloat const kEmptyHeaderHeight = 14.f;
static CGFloat const kEmptyFooterHeight = 14.f;

static NSInteger const kInputSectionKey = 0;

static BOOL _needsReinstantiateRootViewController;
static UIViewController * _reinstantiatedRootViewController;


@interface OTableViewController () <UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate> {
@private
    BOOL _didJustLoad;
    BOOL _didInitialise;
    BOOL _shouldReloadOnModalDismissal;
    BOOL _shouldDismissOnFinishEditingTitle;
    
    Class _entityClass;
    NSInteger _inputSectionKey;
    NSMutableArray *_sectionKeys;
    NSMutableDictionary *_sectionData;
    NSMutableDictionary *_sectionCounts;
    NSMutableDictionary *_sectionHeaderLabels;
    NSMutableDictionary *_sectionFooterLabels;
    NSMutableArray *_sectionIndexTitles;
    UITextField *_titleField;
    
    UISegmentedControl *_segments;
    NSMutableArray *_segmentTitles;
    
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
    NSArray *unsortedArray = [data isKindOfClass:[NSSet class]] ? [data allObjects] : data;
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


- (void)setEditingTitle:(BOOL)editing
{
    static UIBarButtonItem *leftBarButtonItem = nil;
    static NSArray *rightBarButtonItems = nil;
    
    if (editing) {
        leftBarButtonItem = self.navigationItem.leftBarButtonItem;
        rightBarButtonItems = self.navigationItem.rightBarButtonItems;
        
        if (!self.isModal || [_titleField.text hasValue]) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self action:@selector(didCancelEditingTitle)];
        }
        
        self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem doneButtonWithTitle:NSLocalizedString(@"Use", @"") target:self action:@selector(didFinishEditingTitle)]];
        
        [self.tableView dim];
    } else {
        self.navigationItem.leftBarButtonItem = leftBarButtonItem;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
        
        [self.tableView undim];
        
        if ([_titleField isFirstResponder]) {
            [_titleField resignFirstResponder];
        }
        
        if ([self actionIs:kActionRegister]) {
            [_inputCell resumeFirstResponder];
        }
    }
}


- (void)inputFieldDidBecomeFirstResponder:(OInputField *)inputField
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

- (void)didCancelEditing
{
    if ([self actionIs:kActionEdit]) {
        [_inputCell readData];
        [self toggleEditMode];
    } else {
        _didCancel = !_cancelImpliesSkip;
        
        if (_didCancel) {
            [self.entity expire];
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


- (void)didCancelEditingTitle
{
    if ([self.title hasValue]) {
        _titleField.text = self.title;
        
        if ([_instance respondsToSelector:@selector(maySetViewTitle:)]) {
            [_instance maySetViewTitle:nil];
        }
        
        if (_shouldDismissOnFinishEditingTitle) {
            [self.dismisser dismissModalViewController:self];
        } else {
            [self setEditingTitle:NO];
        }
    }
}


- (void)didFinishEditingTitle
{
    if ([_titleField.text hasValue]) {
        if (!_shouldDismissOnFinishEditingTitle) {
            [self setEditingTitle:NO];
        }
        
        NSString *newTitle = ![_titleField.text isEqualToString:self.title] ? _titleField.text : nil;
        
        if ([_instance respondsToSelector:@selector(maySetViewTitle:)]) {
            [_instance maySetViewTitle:newTitle];
        }
        
        if (newTitle) {
            self.navigationItem.title = newTitle;
            self.title = newTitle;
        }
        
        if (_shouldDismissOnFinishEditingTitle) {
            [self.dismisser dismissModalViewController:self];
        }
    }
}


#pragma mark - Preceding view controller access

- (OTableViewController *)precedingViewController
{
    OTableViewController *precedingViewController = nil;
    
    if (self.navigationController) {
        precedingViewController = self.navigationController.viewControllers[[self.navigationController.viewControllers indexOfObject:self] - 1];
    }
    
    return precedingViewController;
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
    if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSSet class]]) {
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
        
        if (_usesSectionIndexTitles) {
            _usesSectionIndexTitles = ([data count] >= kSectionIndexMinimumDisplayRowCount);
        }
        
        if (_usesSectionIndexTitles) {
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
            
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:redundantSections] withRowAnimation:_rowAnimation];
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


- (NSInteger)numberOfRowsInSectionWithKey:(NSInteger)sectionKey
{
    return [_sectionCounts[@(sectionKey)] integerValue];
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
    
    [destinationViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    if (_presentStealthilyOnce) {
        self.view.window.rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        destinationViewController.view.alpha = 0.f;
        
        [self.navigationController presentViewController:destinationViewController animated:NO completion:^{
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                destinationViewController.view.alpha = 1.f;
            });
            
            self.view.window.rootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        }];
        
        _presentStealthilyOnce = NO;
    } else {
        [self.navigationController presentViewController:destinationViewController animated:YES completion:NULL];
    }
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
        if ([viewController respondsToSelector:@selector(viewWillBeDismissed)]) {
            [viewController viewWillBeDismissed];
        }
        
        if ([_instance respondsToSelector:@selector(willDismissModalViewController:)]) {
            [_instance willDismissModalViewController:viewController];
        }
        
        if ([[OMeta m] userIsSignedIn]) {
            _shouldReloadOnModalDismissal = !viewController.didCancel;
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            _shouldReloadOnModalDismissal = NO;
            
            if ([_instance respondsToSelector:@selector(didDismissModalViewController:)]) {
                [_instance didDismissModalViewController:viewController];
            }
        }];
    }
}


#pragma mark - Edit mode transitions

- (void)scrollToTopAndToggleEditMode
{
    if ([self actionIs:kActionDisplay]) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [self toggleEditMode];
        }];
        
        [self.tableView beginUpdates];
        [self.tableView setContentOffset:CGPointMake(0.f, 0.f - self.tableView.contentInset.top) animated:YES];
        [self.tableView endUpdates];
        
        [CATransaction commit];
    } else {
        [self toggleEditMode];
    }
}


- (void)toggleEditMode
{
    [_inputCell toggleEditMode];
    
    static UIBarButtonItem *leftBarButtonItem = nil;
    static NSArray *rightBarButtonItems = nil;
    
    if ([self actionIs:kActionEdit]) {
        leftBarButtonItem = self.navigationItem.leftBarButtonItem;
        rightBarButtonItems = self.navigationItem.rightBarButtonItems;
        
        if (!_cancelButton) {
            _cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
            _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
            _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        }
        
        self.navigationItem.leftBarButtonItem = _cancelButton;
        self.navigationItem.rightBarButtonItems = nil;
        
        if (_nextInputField) {
            [_nextInputField becomeFirstResponder];
            _nextInputField = nil;
        } else {
            [[_inputCell nextInputField] becomeFirstResponder];
        }
    } else if ([self actionIs:kActionDisplay]) {
        self.navigationItem.leftBarButtonItem = leftBarButtonItem;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
        
        if ([[OMeta m].replicator needsReplication]) {
            [[OMeta m].replicator replicate];
            [self.observer observeData];
        }
    }
    
    OLogState;
}


- (void)endEditing
{
    [self.view endEditing:YES];
    
    if ([self actionIs:kActionRegister]) {
        self.inputCell.editable = NO;
        self.navigationItem.rightBarButtonItems = @[_doneButton];
    }
}


#pragma mark - Custom title elements

- (UISegmentedControl *)setTitleSegments:(NSArray *)segmentTitles
{
    if ([segmentTitles count]) {
        if (_segments) {
            NSString *selectedTitle = [_segments titleForSegmentAtIndex:_segments.selectedSegmentIndex];
            
            if (![segmentTitles containsObject:selectedTitle]) {
                selectedTitle = nil;
            }
            
            _segments.selectedSegmentIndex = -1;
            
            for (NSInteger i = 0; i < [_segmentTitles count]; i++) {
                NSString *segmentTitle = _segmentTitles[i];
                
                if (![segmentTitles containsObject:segmentTitle]) {
                    [_segments removeSegmentAtIndex:i animated:YES];
                    [_segmentTitles removeObjectAtIndex:i];
                }
            }
            
            for (NSInteger i = 0; i < [segmentTitles count]; i++) {
                NSString *segmentTitle = segmentTitles[i];
                
                if (![_segmentTitles containsObject:segmentTitle]) {
                    [_segments insertSegmentWithTitle:segmentTitle atIndex:i animated:YES];
                    [_segmentTitles insertObject:segmentTitle atIndex:i];
                }
                
                if (selectedTitle && [segmentTitle isEqualToString:selectedTitle]) {
                    _segments.selectedSegmentIndex = i;
                }
            }
            
            if (_segments.selectedSegmentIndex < 0) {
                _segments.selectedSegmentIndex = 0;
            }
        } else {
            self.tableView.contentInset = UIEdgeInsetsMake(kToolbarBarHeight, 0.f, 0.f, 0.f);
            
            _segmentTitles = [segmentTitles mutableCopy];
            _segments = [[UISegmentedControl alloc] initWithItems:segmentTitles];
            _segments.selectedSegmentIndex = 0;
            _segments.frame = CGRectMake(kContentInset, kContentInset / 2.f, [OMeta screenWidth] - 2 * kContentInset, _segments.frame.size.height);
            [_segments addTarget:_instance action:@selector(didSelectTitleSegment) forControlEvents:UIControlEventValueChanged];
            
            UIView *segmentsHairline = [[UIView alloc] initWithFrame:CGRectMake(0.f, kToolbarBarHeight, [OMeta screenWidth], kBorderWidth)];
            segmentsHairline.backgroundColor = [UIColor toolbarHairlineColour];
            
            UIView *segmentsView = [[UIView alloc] initWithFrame:CGRectMake(0.f, -kToolbarBarHeight, [OMeta screenWidth], kToolbarBarHeight)];
            segmentsView.backgroundColor = [UIColor toolbarColour];
            
            [segmentsView addSubview:_segments];
            [segmentsView addSubview:segmentsHairline];
            
            [self.tableView addSubview:segmentsView];
        }
    } else if (_segments) {
        self.tableView.contentInset = UIEdgeInsetsZero;
        
        [_segments.superview removeFromSuperview];
        _segments = nil;
    }
    
    return _segments;
}


- (UITextField *)setEditableTitle:(NSString *)title placeholder:(NSString *)placeholder
{
    _titleField = [self.navigationItem setTitle:title editable:YES withSubtitle:nil];
    _titleField.placeholder = placeholder;
    _titleField.delegate = self;
    
    self.title = title;
    
    return _titleField;
}


- (void)setSubtitle:(NSString *)subtitle
{
    _titleField = [self.navigationItem setTitle:self.title editable:_titleField.userInteractionEnabled withSubtitle:subtitle];
}


#pragma mark - Reloading sections and/or section elements

- (void)reloadSections
{
    [_instance loadData];
    
    NSMutableIndexSet *affectedSections = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToInsert = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToReload = [NSMutableIndexSet indexSet];
    
    for (NSNumber *sectionKey in [_sectionData allKeys]) {
        NSInteger section = [self sectionNumberForSectionKey:[sectionKey integerValue]];
        NSInteger oldCount = [_sectionCounts[sectionKey] integerValue];
        NSInteger newCount = [_sectionData[sectionKey] count];
        
        if (oldCount) {
            if (newCount) {
                if (newCount != oldCount) {
                    [sectionsToReload addIndex:section];
                }
            } else {
                [affectedSections addIndex:section];
                [_sectionKeys removeObject:sectionKey];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:_rowAnimation];
            }
        } else if (newCount) {
            [sectionsToInsert addIndex:section];
        }
        
        _sectionCounts[sectionKey] = @(newCount);
    }
    
    if ([sectionsToInsert count]) {
        [self.tableView insertSections:sectionsToInsert withRowAnimation:_rowAnimation];
    }
    
    if ([sectionsToReload count]) {
        [self.tableView reloadSections:sectionsToReload withRowAnimation:_rowAnimation];
    }
    
    if ([_sectionKeys count]) {
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
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:_rowAnimation];
        } else if (!sectionExists && !sectionIsEmpty) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:_rowAnimation];
        } else if (sectionExists && sectionIsEmpty) {
            [_sectionKeys removeObject:@(sectionKey)];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:_rowAnimation];
        }
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _identifier = self.restorationIdentifier;
    _sectionKeys = [NSMutableArray array];
    _sectionData = [NSMutableDictionary dictionary];
    _sectionCounts = [NSMutableDictionary dictionary];
    _sectionHeaderLabels = [NSMutableDictionary dictionary];
    _sectionFooterLabels = [NSMutableDictionary dictionary];
    _sectionIndexTitles = [NSMutableArray array];
    _inputSectionKey = NSNotFound;
    _instance = self;
    _state = [[OState alloc] initWithViewController:self];
    _rowAnimation = UITableViewRowAnimationAutomatic;
    
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
        
        [self.navigationItem insertRightBarButtonItem:_nextButton atIndex:0];
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
    
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
    
    [self.navigationController setToolbarHidden:(!self.toolbarItems) animated:YES];
    
    if (self.navigationController.navigationBar.translucent) {
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.navigationBar.barTintColor = [UIColor toolbarColour];
    }
    
    if (_usesSectionIndexTitles) {
        self.tableView.sectionIndexMinimumDisplayRowCount = kSectionIndexMinimumDisplayRowCount;
    }
    
    if (_segments) {
        [self.navigationController.navigationBar setHairlinesHidden:YES];
    }
    
    if (![self actionIs:kActionInput] && _shouldReloadOnModalDismissal) {
        [self reloadSections];
    } else if ([self actionIs:kActionInput] && _didResurface) {
        [self.inputCell resumeFirstResponder];
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
        
        if (_titleField && _isModal && !_wasHidden) {
            [_titleField becomeFirstResponder];
            
            _shouldDismissOnFinishEditingTitle = [_titleField.text hasValue];
        }
    } else if (![_identifier isEqualToString:kIdentifierAuth]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetUser];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self.observer observeData];
    }
    
	[super viewWillDisappear:animated];
    
    _isHidden = self.presentedViewController ? YES : NO;
    
    if (!_isHidden) {
        [[OMeta m].replicator replicateIfNeeded];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_segments) {
        [self.navigationController.navigationBar setHairlinesHidden:NO];
    }
    
    if (_needsReinstantiateRootViewController) {
        self.navigationController.viewControllers = @[_reinstantiatedRootViewController];
        _needsReinstantiateRootViewController = NO;
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Custom accessors

- (void)setUsesSectionIndexTitles:(BOOL)usesSectionIndexTitles
{
    _usesSectionIndexTitles = usesSectionIndexTitles;
    
    if (_usesSectionIndexTitles) {
        _usesPlainTableViewStyle = YES;
    }
}


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
        _state.target = target;
    }
}


- (id)target
{
    if (!_target && [_instance respondsToSelector:@selector(defaultTarget)]) {
        self.target = [_instance defaultTarget];
    }
    
    return _state && [_target isKindOfClass:[NSDictionary class]] ? [_target allKeys][0] : _target;
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
        
        if ([_instance respondsToSelector:@selector(listCellStyleForSectionWithKey:)]) {
            style = [_instance listCellStyleForSectionWithKey:[self sectionKeyForIndexPath:indexPath]];
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
        if ([_instance respondsToSelector:@selector(willDeleteCellAtIndexPath:)]) {
            [_instance willDeleteCellAtIndexPath:indexPath];
        }
        
        NSNumber *sectionKey = _sectionKeys[indexPath.section];
        NSMutableArray *sectionData = _sectionData[sectionKey];
        
        _sectionCounts[sectionKey] = @([_sectionCounts[sectionKey] integerValue] - 1);
        [sectionData removeObjectAtIndex:indexPath.row];
        
        [[OMeta m].replicator replicateIfNeeded];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:_rowAnimation];
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
    CGFloat height = 0.f;
    
    if (_usesPlainTableViewStyle) {
        height = [_sectionIndexTitles count] ? kPlainTableViewHeaderHeight : 0.f;
    } else {
        if ([self instanceHasHeaderForSectionWithKey:[self sectionKeyForSectionNumber:section]]) {
            if (_usesPlainTableViewStyle) {
                height = [UIFont plainHeaderFont].lineHeight;
            } else {
                height = kLineToHeaderHeightFactor * [UIFont headerFont].lineHeight;
            }
        } else if (section == 0) {
            height = kInitialHeadroomHeight;
        } else {
            height = kEmptyHeaderHeight;
        }
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = _usesPlainTableViewStyle ? 0.f : kEmptyFooterHeight;
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    
    if ([self instanceHasFooterForSectionWithKey:sectionKey]) {
        UIFont *footerFont = [UIFont footerFont];
        NSString *footerText = [self footerTextForSectionWithKey:sectionKey];
        CGFloat textHeight = [footerText lineCountWithFont:footerFont maxWidth:[OMeta screenWidth] - 2 * kContentInset] * footerFont.lineHeight;
        
        height = textHeight + 2 * kDefaultCellPadding;
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    NSString *headerText = nil;
    UIView *headerView = nil;
    
    if (_usesSectionIndexTitles) {
        headerText = _sectionIndexTitles[section];
    } else if ([self instanceHasHeaderForSectionWithKey:sectionKey]) {
        headerText = [_instance textForHeaderInSectionWithKey:sectionKey];
    }
    
    if (headerText) {
        CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:section];
        CGRect headerFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], headerHeight);
        headerView = [[UIView alloc] initWithFrame:headerFrame];

        CGRect labelFrame = CGRectMake(kContentInset, 0.f, [OMeta screenWidth] - 2 * kContentInset, headerHeight);
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:labelFrame];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor headerTextColour];
        
        if (_usesPlainTableViewStyle) {
            headerView.backgroundColor = [UIColor tableViewBackgroundColour];
            headerView.alpha = 0.99f;
            headerLabel.font = [UIFont listTextFont];
        } else {
            headerLabel.font = [UIFont headerFont];
        }
        
        headerLabel.text = headerText;
        headerLabel.textAlignment = NSTextAlignmentLeft;
        
        [headerView addSubview:headerLabel];
        
        if (headerView) {
            [_sectionHeaderLabels setObject:headerView.subviews[0] forKey:@(sectionKey)];
        }
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSInteger sectionKey = [self sectionKeyForSectionNumber:section];
    UIView *footerView = nil;
    
    if ([self instanceHasFooterForSectionWithKey:sectionKey]) {
        CGFloat footerHeight = [self tableView:tableView heightForFooterInSection:section];
        CGRect footerFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], footerHeight);
        CGRect labelFrame = CGRectMake(kContentInset, 0.f, [OMeta screenWidth] - 2 * kContentInset, footerHeight + kFooterHeadroom);
        
        footerView = [[UIView alloc] initWithFrame:footerFrame];
        UILabel *footerLabel = [[UILabel alloc] initWithFrame:labelFrame];
        
        footerLabel.backgroundColor = [UIColor clearColor];
        footerLabel.font = [UIFont footerFont];
        footerLabel.numberOfLines = 0;
        footerLabel.text = [self footerTextForSectionWithKey:sectionKey];
        footerLabel.textAlignment = NSTextAlignmentCenter;
        footerLabel.textColor = [UIColor footerTextColour];
        
        [footerView addSubview:footerLabel];
        
        if (footerView) {
            [_sectionFooterLabels setObject:footerView.subviews[0] forKey:@(sectionKey)];
        }
    }
    
    return footerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (cell == _inputCell) {
        [_inputCell prepareForDisplay];
        
        if ([_instance respondsToSelector:@selector(willDisplayInputCell:)]) {
            [_instance willDisplayInputCell:cell];
        }
    } else {
        [_instance loadListCell:cell atIndexPath:indexPath];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.destinationId) {
        if (![self actionIs:kActionInput] || cell.selectableDuringInput) {
            id target = nil;
            
            if ([_instance respondsToSelector:@selector(destinationTargetForIndexPath:)]) {
                target = [_instance destinationTargetForIndexPath:indexPath];
            }
            
            if (!target) {
                target = [self dataAtIndexPath:indexPath];
            }
            
            OTableViewController *destinationViewController = [self.storyboard instantiateViewControllerWithIdentifier:cell.destinationId];
            destinationViewController.target = target;
            destinationViewController.meta = cell.destinationMeta;
            destinationViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
            if (destinationViewController.entity && _entity) {
                destinationViewController.entity.ancestor = _entity;
            }
            
            [self.navigationController pushViewController:destinationViewController animated:YES];
            
            _selectedIndexPath = indexPath;
        } else {
            cell.selected = NO;
        }
    } else if (cell.selectable) {
        if ([_instance respondsToSelector:@selector(didSelectCell:atIndexPath:)]) {
            [_instance didSelectCell:cell atIndexPath:indexPath];
        }
        
        _selectedIndexPath = indexPath;
    }
}


#pragma mark - UIScrollViewDelegate conformance

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_segments) {
        CGRect tableViewBounds = self.tableView.bounds;
        CGRect segmentsViewFrame = _segments.superview.frame;
        
        _segments.superview.frame = CGRectMake(tableViewBounds.origin.x, tableViewBounds.origin.y, segmentsViewFrame.size.width, segmentsViewFrame.size.height);
    }
}


#pragma mark - UITextFieldDelegate conformance

- (BOOL)textFieldShouldBeginEditing:(OTextField *)textField
{
    return (textField == _titleField) ? !self.tableView.isDecelerating : YES;
}


- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    if (textField == _titleField) {
        if ([_titleField.text hasValue]) {
            _titleField.selectedTextRange = [_titleField textRangeFromPosition:_titleField.beginningOfDocument toPosition:_titleField.endOfDocument];
        }
        
        [self setEditingTitle:YES];
    } else {
        [self inputFieldDidBecomeFirstResponder:textField];
    }
}


- (BOOL)textFieldShouldReturn:(OTextField *)textField
{
    if (textField == _titleField) {
        if ([_titleField.text hasValue]) {
            [_titleField resignFirstResponder];
        }
    } else {
        if ([_inputCell nextInputField]) {
            [self moveToNextInputField];
        } else {
            [self didFinishEditing];
        }
    }
    
    return NO;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    if (textField == _titleField) {
        if (_didCancel) {
            _didCancel = NO;
        } else {
            [self didFinishEditingTitle];
        }
    } else {
        _inputCell.inputField = nil;
    }
}


#pragma mark - UITextViewDelegate conformance

- (void)textViewDidBeginEditing:(OTextView *)textView
{
    [self inputFieldDidBecomeFirstResponder:textView];
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
