//
//  OMapViewController.m
//  Origon
//
//  Created by Anders Blehr on 18/01/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OMapViewController.h"

static NSInteger const kTitleSegmentStandard = 0;
static NSInteger const kTitleSegmentHybrid = 1;
static NSInteger const kTitleSegmentSatellite = 2;

static CGFloat const kMapRegionSpan = 1000.f;
static CGFloat const kMapEdgePadding = 50.f;

static NSString * const kIdentifierPinAnnotationView = @"pin";


@interface OMapViewController () <OTableViewController, CLLocationManagerDelegate, MKMapViewDelegate> {
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
                [self->_mapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
                
                self.navigationItem.leftBarButtonItem = [UIBarButtonItem navigationButtonWithTarget:self];
            }
        } else {
            [self showAlertForError:error info:nil];
        }
    }];
}


#pragma mark - Action sheets

- (void)presentStartingPointSheet
{
    OActionSheet *actionSheet =
            [[OActionSheet alloc] initWithPrompt:OLocalizedString(@"Select starting point for directions", @"")];
    
    for (id<OOrigo> address in [[OMeta m].user addresses]) {
        [actionSheet addButtonWithTitle:[address shortAddress] action:^{
            self->_destinationItem = [[MKMapItem alloc] initWithPlacemark:self->_placemark];
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            [geocoder geocodeAddressString:address.address completionHandler:^(NSArray *placemarks, NSError *error) {
                if (!error) {
                    if (placemarks.count == 1) {
                        MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:placemarks[0]];
                        self->_startItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                        self->_startAnnotation = placemark;
                        [self overlayDirections];
                    } else {
                        [self showAmbiguousAddressAlertForOrigo:address];
                    }
                } else {
                    [self showAlertForError:error info:[address singleLineAddress]];
                }
            }];
        }];
    }
    
    [actionSheet addButtonWithTitle:OLocalizedString(@"Current location", @"") action:^{
        self->_destinationItem = [[MKMapItem alloc] initWithPlacemark:self->_placemark];
        self->_startItem = [MKMapItem mapItemForCurrentLocation];
        [self overlayDirections];
    }];
    
    [actionSheet show];
}


#pragma mark - Alerts

- (void)showAlertForError:(NSError *)error info:(id)info
{
    if (error.domain == kCLErrorDomain && error.code == kCLErrorGeocodeFoundNoResult) {
        [OAlert showAlertWithTitle:OLocalizedString(@"Unknown address", @"") message:[NSString stringWithFormat:OLocalizedString(@"No known address matches %@.", @""), info]];
    } else {
        [OAlert showAlertWithTitle:OLocalizedString(@"Error", @"") message:OLocalizedString(@"An error has occurred. Please try again another time.", @"")];
    }
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
}


- (void)showAmbiguousAddressAlertForOrigo:(id<OOrigo>)origo
{
    [OAlert showAlertWithTitle:OLocalizedString(@"Unclear address", @"") message:[NSString stringWithFormat:OLocalizedString(@"The address %@ is unclear and could not be not found in the map.", @""), [origo singleLineAddress]]];
    
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
            [OAlert showAlertWithTitle:OLocalizedString(@"Cannot give directions", @"") message:OLocalizedString(@"Location services are disabled for Origon. Open Settings and go to Privacy > Location Services to enable location services for Origon.", @"")];
        }
    } else {
        [OAlert showAlertWithTitle:OLocalizedString(@"Cannot give directions", @"") message:OLocalizedString(@"Open Settings, go to Privacy > Location Services and turn on location services in order to get directions.", @"")];
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
    
    _titleSegments = [self titleSegmentsWithTitles:@[OLocalizedString(@"Standard", @""), OLocalizedString(@"Hybrid", @""), OLocalizedString(@"Satellite", @"")]];
    _titleSegments.selectedSegmentIndex = kTitleSegmentStandard;

    id<OOrigo> origo = self.target;
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:origo.address completionHandler:^(NSArray* placemarks, NSError* error) {
        if (!error) {
            if (placemarks.count == 1) {
                self->_placemark = [[MKPlacemark alloc] initWithPlacemark:placemarks[0]];
                MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self->_placemark.coordinate, kMapRegionSpan, kMapRegionSpan);
                
                [self->_mapView setRegion:region animated:YES];
                [self->_mapView addAnnotation:self->_placemark];
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
            pinAnnotationView.pinTintColor = [UIColor greenColor];
        } else {
            pinAnnotationView.pinTintColor = [UIColor redColor];
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

@end
