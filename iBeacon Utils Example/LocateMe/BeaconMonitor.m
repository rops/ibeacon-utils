//
//  BeaconMonitor.m
//  WatchMyKids
//
//  Created by Daniele Rossetti on 27/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import "BeaconMonitor.h"
#import <CoreLocation/CoreLocation.h>

double const BEACON_ACCURACY_GRANULARITY = 1.00; //meters
int const MAJOR_MINOR_MAX =  65535;

@interface BeaconMonitor()<CLLocationManagerDelegate>
@property (nonatomic,strong) NSMutableDictionary *regions; //{NSString identifier:CLBeaconRegion region}
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong,nonatomic) NSMutableArray *distancesTracker;
@property (strong,nonatomic) NSMutableArray *distancesTrackerSupport;
@property (nonatomic,readwrite) NSArray* nearestRegions;
@end

@implementation BeaconMonitor

+ (instancetype)sharedMonitor {
    static BeaconMonitor *_sharedMonitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMonitor = [[BeaconMonitor alloc] init];
    });
    
    return _sharedMonitor;
}


#pragma mark Properties

- (NSArray*) nearestRegions{
    if (!_nearestRegions) _nearestRegions = [[NSArray alloc] init];
    return _nearestRegions;
}

- (NSMutableArray*) distancesTracker{
    if(!_distancesTracker) _distancesTracker = [[NSMutableArray alloc] init];
    return _distancesTracker;
}

- (CLLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}
- (NSMutableDictionary *)regions{
    if (!_regions){
        _regions = [[NSMutableDictionary alloc] init];
        NSArray *regionsMetadata = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:[self regionsFileURL]]];
        if(regionsMetadata){
            for(NSDictionary *metadata in regionsMetadata){
                NSUInteger major = [metadata[BEACON_MAJOR_KEY] intValue];
                NSUInteger minor = [metadata[BEACON_MINOR_KEY] intValue];
                NSString* identifier = metadata[BEACON_IDENTIFIER_KEY];
                CLBeaconRegion *newRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:MY_UUID]
                                                                                   major:major
                                                                                   minor:minor
                                                                              identifier:identifier];
                [_regions setObject:newRegion forKey:identifier];
            }
        }
    }
    return _regions;
}
#pragma mark Public methods

- (BOOL) saveState{
    NSMutableArray *regionsMetadata = [[NSMutableArray alloc] init];
    for(NSString *identifier in self.regions){
        NSDictionary *metadata = @{BEACON_IDENTIFIER_KEY:identifier,
                                   BEACON_MAJOR_KEY:((CLBeaconRegion*)self.regions[identifier]).major,
                                   BEACON_MINOR_KEY:((CLBeaconRegion*)self.regions[identifier]).minor};
        [regionsMetadata addObject:metadata];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:regionsMetadata];
    return [data writeToURL:[self regionsFileURL] atomically:YES];
}

- (void)addRegionWithIdentifier:(NSString *)name major:(NSUInteger)majorID minor:(NSUInteger)minorID{
    CLBeaconRegion *newRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:MY_UUID]
                                                                       major:majorID
                                                                       minor:minorID
                                                                   identifier:name];
//    newRegion.notifyEntryStateOnDisplay = YES;
    [self.regions setObject:newRegion forKey:name];
    //if is already monitoring
    if([[self.locationManager rangedRegions] count]>0){
        [self startMonitoringRegion:newRegion];
    }
    
}
- (void) startMonitoring{
    if(![CLLocationManager isRangingAvailable]){
        [self.delegate regionMonitoringUnsupported];
        return;
    }

    if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied){
        [self.delegate regionMonitoringUnauthorized];
        return;
    }else{
        for(NSString *identifier in self.regions){
            [self startMonitoringRegion:self.regions[identifier]];
        }
    }
}

- (void) stopMonitoring{
    for(NSString *identifier in self.regions){
        [self stopMonitoringRegion:self.regions[identifier]];
    }
    self.distancesTracker = nil;
    self.nearestRegions = nil;
    [self notifyDelegateAboutOrderChange];
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    if ([beacons count] > 0){

        CLBeacon *nearestExhibit = [beacons firstObject];
        NSLog(@"%@",nearestExhibit);
        [self updateBeaconDistance:nearestExhibit identifier:region.identifier];

    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if ([[self.locationManager rangedRegions] count]>0 && status==kCLAuthorizationStatusDenied){
        [self.delegate regionMonitoringUnauthorized];
        return;
    }
}
- (void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    [self.delegate didEnterRegion:region.identifier];
}
- (void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    [self.delegate didExitRegion:region.identifier];
}
#pragma mark Internal methods

- (void) startMonitoringRegion:(CLBeaconRegion*)region{
    [self.locationManager startRangingBeaconsInRegion:region];
    [self.locationManager startMonitoringForRegion:region];
}
- (void) stopMonitoringRegion:(CLBeaconRegion*)region{
    [self.locationManager stopRangingBeaconsInRegion:region];
    [self.locationManager stopMonitoringForRegion:region];
}

- (NSUInteger) indexOfMetadataDistanceFromIdentifier:(NSString*) identifier{
    return [self.distancesTracker indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj[BEACON_IDENTIFIER_KEY] isEqualToString:identifier]){
            *stop = YES;
            return YES;
        }
        return NO;
    }];
}
- (void) updateBeaconDistance:(CLBeacon*)beacon identifier:(NSString*)identifier{
    CLProximity newProximity = beacon.proximity;
    CLLocationAccuracy newAccuracy = beacon.accuracy;
    NSDictionary *newData = @{BEACON_IDENTIFIER_KEY:identifier,BEACON_PROXIMITY_KEY:@(newProximity),BEACON_ACCURACY_KEY:@(newAccuracy)};
    
    NSUInteger index = [self indexOfMetadataDistanceFromIdentifier:identifier];
    
    if (index == NSNotFound && newProximity == CLProximityUnknown) return;
    
    if (index == NSNotFound && newProximity != CLProximityUnknown){
        [self.distancesTracker addObject:newData];
        [self updateDistancesTrackerWithForcedNotification:YES];

        return;
    }
    NSDictionary* distanceData = self.distancesTracker[index];
    CLProximity oldProximity = [distanceData[BEACON_PROXIMITY_KEY] intValue];
    CLLocationAccuracy oldAccuracy = [distanceData[BEACON_ACCURACY_KEY] floatValue];
    
    
    if (newProximity == CLProximityUnknown){
        [self.distancesTracker removeObjectAtIndex:index];
        [self updateDistancesTrackerWithForcedNotification:YES];
        return;
    }
    
    if (oldProximity != newProximity || ABS(oldAccuracy-newAccuracy)>BEACON_ACCURACY_GRANULARITY){
        self.distancesTracker[index] = newData;
        [self updateDistancesTrackerWithForcedNotification:NO];
    }
}
- (void) updateDistancesTrackerWithForcedNotification:(BOOL)notify{
    if(notify){
        [self.distancesTracker sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:BEACON_PROXIMITY_KEY ascending:YES],
                                                      [NSSortDescriptor sortDescriptorWithKey:BEACON_ACCURACY_KEY ascending:YES]]];
        [self notifyDelegateAboutOrderChange];
    }else{
        NSArray *old = [self.distancesTracker copy];
        [self.distancesTracker sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:BEACON_PROXIMITY_KEY ascending:YES],
                                                      [NSSortDescriptor sortDescriptorWithKey:BEACON_ACCURACY_KEY ascending:YES]]];
        BOOL changed = NO;
        for(int i=0;i<[old count]&&!changed;i++){
            if (![old[i][BEACON_IDENTIFIER_KEY] isEqualToString:self.distancesTracker[i][BEACON_IDENTIFIER_KEY]]){
                changed = YES;
            }
        }
        if(changed){
           [self notifyDelegateAboutOrderChange]; 
        }
        
    }
    
    
}
- (void) notifyDelegateAboutOrderChange{
    [self.delegate nearestRegionsDidChange:[self.distancesTracker copy]];
}

- (NSURL*) regionsFileURL{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [url URLByAppendingPathComponent:@"MonitoredRegionsMetaData"];
}


@end
