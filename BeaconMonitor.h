//
//  BeaconMonitor.h
//  WatchMyKids
//
//  Created by Daniele Rossetti on 27/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeaconMonitorDelegate.h"
#import "BeaconConstants.h"

@interface BeaconMonitor : NSObject

@property (nonatomic,weak) id<BeaconMonitorDelegate> delegate;
@property (nonatomic,readonly) NSArray* nearestRegions;

+ (instancetype)sharedMonitor;
- (void)addRegionWithIdentifier:(NSString *)name major:(NSUInteger)majorID minor:(NSUInteger)minorID;
- (void) startMonitoring;
- (void) stopMonitoring;
- (BOOL) saveState;
@end
