//
//  OMapViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 18/01/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OMapViewController.h"

static NSInteger const kTitleSegmentStandard = 0;
static NSInteger const kTitleSegmentHybrid = 1;
static NSInteger const kTitleSegmentSatellite = 2;

static NSInteger const kActionSheetTagStartingPoint = 0;
static NSInteger const kButtonTagStartingPointCurrentLocation = 10;

static CGFloat const kMapRegionSpan = 1000.f;
static CGFloat const kMapEdgePadding = 50.f;

static NSString * const kIdentifierPinAnnotationView = @"pin";


@interface OMapViewController () <OTableViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIActionSheetDelegate> {
@private
    UISegmentedControl *_titleSegments;
    MKMapView *_mapView;
    MKPlacemark *_placemark;
    CLLocationManager *_locationManager;
    
    MKMapItem *_startItem;
    MKMapItem *_destinationItem;
    id<MKAnnotation> _startAnnotation;
}

@end


@implementation OMapViewController

#pragma mark - Auxiliary methods

- (void)overlayDirections
{
    _mapView.showsUserLocation = YES;
    
    if (_startAnnotation) {
        [_mapView addAnnotation:_startAnnotation];
    }
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    [request setSource:_startItem];
    [request setDestination:_destinationItem];
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (!error) {
            for (MKRoute *route in [response routes]) {
                [_mapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
                
                self.navigationItem.leftBarButtonItem = [UIBarButtonItem navigationButtonWithTarget:self];
            }
        } else {
            [self showAlertForError:error info:nil];
        }
    }];
}


- (MKPointAnnotation *)pointAnnotationWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = title;
    
    return annotation;
}


#pragma mark - Action sheets

- (void)presentStartingPointSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Select starting point for directions", @"") delegate:self tag:kActionSheetTagStartingPoint];
    
    for (id<OOrigo> address in [[OMeta m].user addresses]) {
        [actionSheet addButtonWithTitle:[address shortAddress]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Current location", @"") tag:kButtonTagStartingPointCurrentLocation];
    
    [actionSheet show];
}


#pragma mark - Alerts

- (void)showAlertForError:(NSError *)error info:(id)info
{
    if (error.domain == kCLErrorDomain && error.code == kCLErrorGeocodeFoundNoResult) {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Unknown address", @"") text:[NSString stringWithFormat:NSLocalizedString(@"No known address matches %@.", @""), info]];
    } else {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Error", @"") text:NSLocalizedString(@"An error occurred. Please try again another time.", @"")];
    }
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
}


- (void)showAmbiguousAddressAlertForOrigo:(id<OOrigo>)origo
{
    [OAlert showAlertWithTitle:NSLocalizedString(@"Unclear address", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The address %@ is unclear and could not be not found in the map.", @""), [origo singleLineAddress]]];
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
}


#pragma mark - Selector implementations

- (void)didSelectTitleSegment
{
    if (_titleSegments.selectedSegmentIndex == kTitleSegmentStandard) {
        _mapView.mapType = MKMapTypeStandard;
    } else if (_titleSegments.selectedSegmentIndex == kTitleSegmentHybrid) {
        _mapView.mapType = MKMapTypeHybrid;
    } else if  (_titleSegments.selectedSegmentIndex == kTitleSegmentSatellite) {
        _mapView.mapType = MKMapTypeSatellite;
    }
}


- (void)performDirectionsAction
{
    if ([CLLocationManager locationServicesEnabled]) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        
        if (status == kCLAuthorizationStatusNotDetermined) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            
            if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [_locationManager requestWhenInUseAuthorization];
            } else {
                [self presentStartingPointSheet];
            }
        } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [self presentStartingPointSheet];
        } else if (status == kCLAuthorizationStatusDenied) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Cannot give directions", @"") text:NSLocalizedString(@"Location services are disabled for Origo. Open Settings and go to Privacy > Location Services to enable location services for Origo.", @"")];
        }
    } else {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Cannot give directions", @"") text:NSLocalizedString(@"Open Settings, go to Privacy > Location Services and turn on location services in order to get directions.", @"")];
    }
}


- (void)performNavigationAction
{
    [MKMapItem openMapsWithItems:@[_startItem, _destinationItem] launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving}];
}


#pragma mark - OTableViewController conformance

- (void)loadState
{
    self.usesTableView = NO;
    
    _mapView = [[MKMapView alloc] initWithFrame:self.view.frame];
    _mapView.mapType = MKMapTypeStandard;
    _mapView.delegate = self;
    
    [self.view addSubview:_mapView];
    
    _titleSegments = [self titleSegmentsWithTitles:@[NSLocalizedString(@"Standard", @""), NSLocalizedString(@"Hybrid", @""), NSLocalizedString(@"Satellite", @"")]];
    _titleSegments.selectedSegmentIndex = kTitleSegmentStandard;

    id<OOrigo> origo = self.target;
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:origo.address completionHandler:^(NSArray* placemarks, NSError* error) {
        if (!error) {
            if (placemarks.count == 1) {
                _placemark = [[MKPlacemark alloc] initWithPlacemark:placemarks[0]];
                MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_placemark.coordinate, kMapRegionSpan, kMapRegionSpan);
                
                [_mapView setRegion:region animated:YES];
                [_mapView addAnnotation:_placemark];
            } else {
                [self showAmbiguousAddressAlertForOrigo:origo];
            }
        } else {
            [self showAlertForError:error info:[origo singleLineAddress]];
        }
    }];
    
    self.title = [origo shortAddress];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem directionsButtonWithTarget:self];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem closeButtonWithTarget:self];
}


- (void)loadData
{
    // No table view data.
}


#pragma mark - CLLocationManagerDelegate conformance

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self presentStartingPointSheet];
    }
}


#pragma mark - MKMapViewDelegate conformance

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pinAnnotationView = nil;
    
    if (annotation != _mapView.userLocation) {
        pinAnnotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kIdentifierPinAnnotationView];
        
        if (!pinAnnotationView) {
            pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kIdentifierPinAnnotationView];
            pinAnnotationView.canShowCallout = YES;
            pinAnnotationView.animatesDrop = YES;
        }
        
        if (annotation == _startAnnotation) {
            pinAnnotationView.pinColor = MKPinAnnotationColorGreen;
        } else {
            pinAnnotationView.pinColor = MKPinAnnotationColorRed;
        }
    }
    
    return pinAnnotationView;
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = nil;
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        [_mapView setVisibleMapRect:[overlay boundingMapRect] edgePadding:UIEdgeInsetsMake(kMapEdgePadding, kMapEdgePadding, kMapEdgePadding, kMapEdgePadding) animated:YES];
        
        renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        [renderer setStrokeColor:[UIColor globalTintColour]];
        [renderer setLineWidth:5.0];
    }
    
    return renderer;
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kActionSheetTagStartingPoint:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                _destinationItem = [[MKMapItem alloc] initWithPlacemark:_placemark];
                
                NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
                
                if (buttonTag == kButtonTagStartingPointCurrentLocation) {
                    _startItem = [MKMapItem mapItemForCurrentLocation];
                    
                    [self overlayDirections];
                } else {
                    id<OOrigo> address = [[OMeta m].user addresses][buttonIndex];
                    
                    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
                    [geocoder geocodeAddressString:address.address completionHandler:^(NSArray *placemarks, NSError *error) {
                        if (!error) {
                            if (placemarks.count == 1) {
                                MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:placemarks[0]];
                                
                                _startItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                                _startAnnotation = placemark;
                                
                                [self overlayDirections];
                            } else {
                                [self showAmbiguousAddressAlertForOrigo:address];
                            }
                        } else {
                            [self showAlertForError:error info:[address singleLineAddress]];
                        }
                    }];
                }
            }
            
            break;
            
        default:
            break;
    }
}

@end
