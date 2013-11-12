//
//  BeaconConfigurator.m
//  WatchMyKids
//
//  Created by Daniele Rossetti on 27/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import "BeaconConfigurator.h"
#import "BeaconConstants.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString *const RBL_SERVICE_UUID = @"B0702880-A295-A8AB-F734-031A98A512DE";
NSString *const RBL_CHARACTERISTIC_MAJOR_UUID = @"B0702882-A295-A8AB-F734-031A98A512DE";
NSString *const RBL_CHARACTERISTIC_MINOR_UUID = @"B0702883-A295-A8AB-F734-031A98A512DE";

@interface BeaconConfigurator() <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableOrderedSet *discoveredPeripherals; //of CBPeripheral
@property (strong, nonatomic) NSMutableArray *discoveredPeripheralsIdentifier;
@property (strong,nonatomic) CBCharacteristic *majorCharacteristic;
@property (strong,nonatomic) CBCharacteristic *minorCharacteristic;
@property (nonatomic) NSUInteger selectedMajor;
@property (nonatomic) NSUInteger selectedMinor;
@property BOOL attemptedScan;
@end

@implementation BeaconConfigurator

#pragma mark - Properties
- (NSArray*) discoveredPeripheralsIdentifier{
    if(!_discoveredPeripheralsIdentifier) _discoveredPeripheralsIdentifier = [[NSMutableArray alloc] init];
    return _discoveredPeripheralsIdentifier;
}
- (NSMutableOrderedSet*) discoveredPeripherals{
    if(!_discoveredPeripherals) _discoveredPeripherals = [[NSMutableOrderedSet alloc] init];
    return _discoveredPeripherals;
}
#pragma mark - Public Methods

- (BeaconConfigurator*) initWithDelegate:(id<BeaconConfiguratorDelegate>)delegate{
    self = [super init];
    if (self) {
        self.delegate = delegate;
#warning CoreBluetooth[WARNING] <CBCentralManager: 0x16672180> is disabling duplicate filtering, but is using the default queue (main thread) for delegate events
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

- (void) scan{
#warning need to connect to peripheral to discover service -- bug?
    if(self.centralManager.state != CBCentralManagerStatePoweredOn){
        self.attemptedScan = YES;
        return;
    }
//    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:RBL_SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
}
- (void) stopScan{
    [self.centralManager stopScan];
}
- (void) configureBeacon:(NSString*) selectedIdentifier withMajor:(NSUInteger)major andMinor:(NSUInteger)minor;
{
    CBPeripheral *selectedPeripheral = [self getPeripheralFromIdentifier:selectedIdentifier];
    self.selectedMajor = major;
    self.selectedMinor = minor;
    uint8_t buf[] = {0x00 , 0x00};
    buf[1] =  (unsigned int) (major & 0xff);
    buf[0] =  (unsigned int) (major>>8 & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:buf length:2];
    selectedPeripheral.delegate = self;
    [selectedPeripheral writeValue:data forCharacteristic:self.majorCharacteristic type:CBCharacteristicWriteWithResponse];
    buf[1] =  (unsigned int) (minor & 0xff);
    buf[0] =  (unsigned int) (minor>>8 & 0xff);
    data = [[NSData alloc] initWithBytes:buf length:2];
    [selectedPeripheral writeValue:data forCharacteristic:self.minorCharacteristic type:CBCharacteristicWriteWithResponse];
    
}

#pragma mark - CBCentralManagerDelegate Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStateUnsupported:
            [self.delegate deviceUnsupported];
            break;
        case CBCentralManagerStateUnauthorized:
            self.attemptedScan = YES;
            NSLog(@"Unautorized");
            break;
        case CBCentralManagerStatePoweredOff:
            self.attemptedScan = YES;
            NSLog(@"Powered Off");
            break;
        default:
            if(self.attemptedScan){
                [self scan];
                self.attemptedScan = NO;
            }
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(![self.discoveredPeripherals containsObject:peripheral]){
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
        [self.discoveredPeripherals addObject:peripheral];
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    
    
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    [self.discoveredPeripherals removeObject:peripheral];
    [self.discoveredPeripheralsIdentifier removeObject:[peripheral.identifier UUIDString]];
    [self notifyDelegateAboutChanges];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Fail to Connect");
    [self.centralManager cancelPeripheralConnection:peripheral];
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"discovered services for: %@",peripheral.identifier);
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup:peripheral];
        [self.delegate beaconDidFailConfiguring];
        return;
    }
    BOOL isBeacon = NO;
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:RBL_SERVICE_UUID]]) {
            isBeacon = YES;
            [peripheral discoverCharacteristics:nil forService:service];
            [self.discoveredPeripheralsIdentifier addObject:[peripheral.identifier UUIDString]];
            [self notifyDelegateAboutChanges];
        }
    }
    if(!isBeacon) [self cleanup:peripheral];
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self.delegate beaconDidFailConfiguring];
        return;
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MAJOR_UUID]]) {
         self.majorCharacteristic = characteristic;
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MINOR_UUID]]) {
        self.minorCharacteristic = characteristic;
    }
}
- (CBPeripheral*) getPeripheralFromIdentifier:(NSString*)identifier{
    CBPeripheral *selectedPeripheral = nil;
    for(CBPeripheral *p in self.discoveredPeripherals){
        NSString *identifier = [p.identifier UUIDString];
        if ([identifier isEqualToString:identifier]){
            selectedPeripheral = p;
        }
    }
    return selectedPeripheral;
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
{
    if(error){
        [self.delegate beaconDidFailConfiguring];
    }else{
        if (characteristic == self.majorCharacteristic)
            self.majorCharacteristic = nil;
        else if (characteristic == self.minorCharacteristic)
            self.minorCharacteristic = nil;
        if (!self.majorCharacteristic && !self.minorCharacteristic){
            NSLog(@"Configuration Completed");
            for(CBPeripheral *p in [self.centralManager retrieveConnectedPeripheralsWithServices:@[]]){
                [self.centralManager cancelPeripheralConnection:p];
            }
            [self.centralManager stopScan];
            self.centralManager = nil;
            [self.delegate beaconDidConfigure:[peripheral.identifier description] withMajor:self.selectedMajor minor:self.selectedMinor];
        }
    }
}


#pragma mark - dInternal Methods
-(NSString*)getUUIDString:(CFUUIDRef)ref {
    NSString *str = [NSString stringWithFormat:@"%@",ref];
    return [[NSString stringWithFormat:@"%@",str] substringWithRange:NSMakeRange(str.length - 36, 36)];
}
- (void) notifyDelegateAboutChanges{
    [self.delegate didDiscoverdBeacons:[self.discoveredPeripheralsIdentifier copy]];
}
- (void) cleanUp{
    for(CBPeripheral *p in self.discoveredPeripherals){
        [self cleanup:p];
    }
}
- (void)cleanup:(CBPeripheral*) peripheral;
{
    if (!peripheral.state!=CBPeripheralStateConnected) {
        return;
    }
    [self.centralManager cancelPeripheralConnection:peripheral];
    [self.discoveredPeripherals removeObject:peripheral];
    [self.discoveredPeripheralsIdentifier removeObject:[peripheral.identifier UUIDString]];
}

@end
