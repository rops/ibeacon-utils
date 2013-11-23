//
//  BeaconMonitorDelegate.h
//  WatchMyKids
//
//  Created by Daniele Rossetti on 27/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol BeaconMonitorDelegate <NSObject>
- (void) regionMonitoringUnsupported;
- (void) regionMonitoringUnauthorized;
- (void) nearestRegionsDidChange:(NSArray*)regionsIdentifier; //array of regions(identifiers) sorted by distance
- (void) didEnterRegion:(NSString*) identifier;
- (void) didExitRegion:(NSString*) identifier;
@end
