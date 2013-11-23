## iBeacon Utilits

Set of classes to handle configuration and monitoring of iBeacons

- BeaconConfigurator
- BeaconConfigurator Delegate
- BeaconMonitor
- BeaconMonitor Delegate


## Beacon Configurator
Warning: It works only with RBL BLEMini device (http://blemini/) but you can simply adapt it to any device by changing the service UUID in BeaconConfigurator.m

``` objc
#import "BeaconConfigurator.h"
...
// Initialize the configurator
BeaconConfigurator* configurator = [[BeaconConfigurator alloc] initWithDelegate:self];

// Start scanning for beacons
[configurator scan];

....

// Configure Beacon
// Check BeaconConfiguratorDelegate.h to see how to obtain the beacon identifiers
[configurator configureBeacon:beaconIdentifier identifier withMajor:major andMinor:minor;]

....

//Stop scanning for beacons 
[configurator stopScan];
....

```

## Beacon Configurator Delegate

The method `didDiscoverdBeacons:(NSArray*)discoveredBeacons` gets called on the delegate each time the configurator discover new beacons. The `discoveredBeacons` array contains the identifiers of the discovered beacons. It's a good place to configure the discovered beacons with `configureBeacon:identifier:withMajor:andMinor`

Check `BeaconConfiguratorDelegate.h` to see other self-explanatory delegate's callbacks

## Beacon Monitor
To obtain the shared instance, just call `[BeaconMonitor sharedInstance]`.

``` objc
#import "BeaconMonitor.h"
...
// Obtain the monitor
BeaconMonitor* monitor = [BeaconMonitor sharedInstance];

// Add a new region to monitor
[monitor addRegionWithIdentifier:@"kitchen" major:major minor:minor];

//Start monitoring
[monitor startMonitoring];
...
//Access nearest regions
NSLog(@"%@",monitor.nearestRegions) // > ["kitchen","bedroom","bathroom"]

```

Check `BeaconMonitor.h` to see other self-explanatory methods

## Beacon Monitor Delegate
The method `nearestRegionsDidChange:(NSArray*)regionsIdentifier` gets called on the delegate each time the `nearestRegions` changes.
Check `BeaconMonitorDelegate.h` to see other self-explanatory delegate's callbacks

