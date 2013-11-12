//
//  BeaconConfiguratorDelegate.h
//  WatchMyKids
//
//  Created by Daniele Rossetti on 28/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BeaconConfiguratorDelegate <NSObject>
- (void) didDiscoverdBeacons:(NSArray*)discoveredBeacons;//identifiers of beacons
- (void) beaconDidConfigure:(NSString*)identifier withMajor:(NSUInteger) major minor:(NSUInteger)minor;
- (void) beaconDidFailConfiguring;
- (void) deviceUnsupported;

@end
