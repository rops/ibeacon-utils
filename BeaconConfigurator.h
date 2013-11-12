//
//  BeaconConfigurator.h
//  WatchMyKids
//
//  Created by Daniele Rossetti on 27/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeaconConfiguratorDelegate.h"

@interface BeaconConfigurator : NSObject
@property (nonatomic,weak) id<BeaconConfiguratorDelegate> delegate;

//designated initializer
- (BeaconConfigurator*) initWithDelegate:(id<BeaconConfiguratorDelegate>) delegate;
- (void) scan;
- (void) stopScan;
- (void) configureBeacon:(NSString*) identifier withMajor:(NSUInteger)major andMinor:(NSUInteger)minor;
@end
