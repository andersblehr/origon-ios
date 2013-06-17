//
//  OLocator.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.04.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@protocol OLocatorDelegate;

@interface OLocator : NSObject<CLLocationManagerDelegate> {
@private
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
    UIAlertView *_blockingAlert;
    
    BOOL _blocking;
    BOOL _awaitingAuthorisation;
    BOOL _awaitingLocation;
    
    id<OLocatorDelegate> _delegate;
}

@property (weak, nonatomic, readonly) NSString *countryCode;

- (BOOL)isAuthorised;
- (BOOL)canLocate;
- (BOOL)didLocate;

- (void)locateBlocking:(BOOL)blocking;

@end
