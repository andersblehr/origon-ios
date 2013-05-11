//
//  OLocator.m
//  OrigoApp
//
//  Created by Anders Blehr on 29.04.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OLocator.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "OMeta.h"
#import "OSettings.h"
#import "OState.h"
#import "OStrings.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OTableViewControllerInstance.h"


@implementation OLocator

#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self && [self canUseLocationServices]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return self;
}


#pragma mark - Updating location info

- (BOOL)canUseLocationServices
{
    BOOL canUseLocationServices = [CLLocationManager locationServicesEnabled];
    
    if (canUseLocationServices) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        
        canUseLocationServices =
        ((authorizationStatus == kCLAuthorizationStatusNotDetermined) ||
         (authorizationStatus == kCLAuthorizationStatusAuthorized));
    }
    
    return canUseLocationServices;
}


- (void)locate
{
    if ([self canUseLocationServices]) {
        [_locationManager startUpdatingLocation];
    }
}


#pragma mark - Custom property accessors

- (NSString *)countryCode
{
    NSString *countryCode = _placemark ? _placemark.ISOcountryCode : [OMeta m].settings.countryCode;
    
    if (!countryCode) {
        CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        countryCode = [networkInfo subscriberCellularProvider].isoCountryCode;
        
        if (!countryCode) {
            countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        }
    }
    
    return countryCode;
}


- (NSString *)country
{
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self.countryCode];
}


#pragma mark - CLLocationManagerDelegate conformance

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
    
    [[[CLGeocoder alloc] init] reverseGeocodeLocation:manager.location completionHandler:^(NSArray *placemarks, NSError *error) {
        _placemark = placemarks[0];
        
        if ([[OState s].activeViewController respondsToSelector:@selector(locatorDidLocate)]) {
            [[OState s].activeViewController locatorDidLocate];
        }
    }];
}

@end
