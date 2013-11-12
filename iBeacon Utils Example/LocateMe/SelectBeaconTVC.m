//
//  SelectBeaconTVC.m
//  LocateMe
//
//  Created by Daniele Rossetti on 30/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import "SelectBeaconTVC.h"
#import "BeaconConfigurator.h"
#import "BeaconConfiguratorDelegate.h"

@interface SelectBeaconTVC ()<BeaconConfiguratorDelegate>
@property (nonatomic,strong) BeaconConfigurator* beaconConfigurator;
@property (nonatomic,strong) NSArray* discoveredBeacons;
@end

@implementation SelectBeaconTVC


- (void)viewDidLoad
{
    [super viewDidLoad];
    _beaconConfigurator = [[BeaconConfigurator alloc] initWithDelegate:self];
    [_beaconConfigurator scan];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark BeaconConfiguratoDelegate
- (void) beaconDidConfigure:(NSString*)identifier withMajor:(NSUInteger) major minor:(NSUInteger)minor;{
    NSLog(@"%@",identifier);
    [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Configuration complete! Restart the beacon before start using it"
                               delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewBeaconConfigured" object:self
                                                      userInfo:@{@"Description":self.beaconDescription,@"Major":@(self.major),@"Minor":@(self.minor)}];
}

- (void) didDiscoverdBeacons:(NSArray*)discoveredBeacons{
    self.discoveredBeacons = discoveredBeacons;
    [self.tableView reloadData];
}
- (void) beaconDidFailConfiguring{
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Configuration error! Try again"
                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
}

- (void) deviceUnsupported{
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device is not supported!"
                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Beacons in Range";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.discoveredBeacons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Beacon Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Beacon";
    cell.detailTextLabel.text = self.discoveredBeacons[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.beaconConfigurator configureBeacon:self.discoveredBeacons[indexPath.row] withMajor:self.major andMinor:self.minor];
}


@end
