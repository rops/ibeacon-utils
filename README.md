## iBeacon Utilits

Set of classes to handle configuration and monitoring of iBeacons

- BeaconConfigurator
- BeaconConfigurator Delegate
- BeaconMonitor
- BeaconMonitor Delegate


## Beacon Configurator
Import `BeaconConfigurator.h`

``` objc
// Initialize the configurator
BeaconConfigurator* configurator = [[BeaconConfigurator alloc] initWithDelegate:self];

// Start scanning for beacons
[configurator scan];

//Stop scanning for beacons 
[configurator stopScan];

// Configure Beacon
// Check BeaconConfiguratorDelegate.h to see how to obtain the beacon identifiers
[configurator configureBeacon:beaconIdentifier identifier withMajor:major andMinor:minor;]

```

## Beacon Configurator Delegate

`didDiscoverdBeacons:(NSArray*)discoveredBeacons;` gets called each time the configurator discover new beacons. The discoveredBeacons array contains the identifiers of the discovered beacons

// Check ``BeaconConfiguratorDelegate.h` to see other self-explanatory delegate's callbacks

## Beacon Monitor
Import [header](BeaconMonitor.h)

``` objc
// Initialize the configurator
BeaconConfigurator* configurator = [[BeaconConfigurator alloc] initWithDelegate:self];

// Start scanning for beacons
[configurator scan];

//Stop scanning for beacons 
[configurator stopScan];

// Configure Beacon
// Check [header](BeaconConfiguratorDelegate.h) to see how to obtain the beacon identifiers
[configurator configureBeacon:beaconIdentifier identifier withMajor:major andMinor:minor;]

```