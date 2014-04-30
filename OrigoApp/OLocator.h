//
//  OLocator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLocator : NSObject<CLLocationManagerDelegate, UIAlertViewDelegate> {
@private
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
    
    BOOL _awaitingAuthorisation;
    BOOL _awaitingLocation;
    
    id<OLocatorDelegate> _delegate;
}

@property (nonatomic, readonly) BOOL blocking;

@property (weak, nonatomic, readonly) NSString *countryCode;

- (BOOL)isAuthorised;
- (BOOL)canLocate;
- (BOOL)didLocate;

- (void)locateBlocking:(BOOL)blocking;

@end
