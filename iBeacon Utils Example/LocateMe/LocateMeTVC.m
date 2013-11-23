//
//  LocateMeTVC.m
//  LocateMe
//
//  Created by Daniele Rossetti on 29/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import "LocateMeTVC.h"
#import "BeaconMonitor.h"
#import "BeaconConstants.h"

@interface LocateMeTVC ()<BeaconMonitorDelegate>
@property (nonatomic,strong) NSArray* regions;
@end

@implementation LocateMeTVC


- (NSArray*) regions{
    if (!_regions) _regions = [[NSArray alloc] init];
    return _regions;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [[BeaconMonitor sharedMonitor] setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newConfiguration:) name:@"NewBeaconConfigured" object:nil];
    
}
- (void) newConfiguration:(NSNotification*)notification{
    NSDictionary *userinfo = notification.userInfo;
    NSString* description = userinfo[@"Description"];
    NSUInteger major = [userinfo[@"Major"] intValue];
    NSUInteger minor = [userinfo[@"Minor"] intValue];
    [[BeaconMonitor sharedMonitor] addRegionWithIdentifier:description major:major minor:minor];
}
- (IBAction)switchMonitor:(UISwitch *)sender {
    if ([sender isOn]){
        [[BeaconMonitor sharedMonitor] startMonitoring];
    }else{
        [[BeaconMonitor sharedMonitor] stopMonitoring];
    }
}
#pragma mark BeaconMonitorDelegate
- (void) regionMonitoringUnsupported{
    UISwitch* sw =  (UISwitch*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
    [sw setOn:NO animated:YES];
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device is not supported!"
                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
}
- (void) regionMonitoringUnauthorized{
    UISwitch* sw =  (UISwitch*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
    [sw setOn:NO animated:YES];
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Give me location permissions!"
                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
}
- (void) nearestRegionsDidChange:(NSArray*)regionsIdentifier{
    self.regions = regionsIdentifier;
    [self.tableView reloadData];
}
- (void) didExitRegion:(NSString *)identifier{
    NSLog(@"exit %@",identifier);
}
- (void) didEnterRegion:(NSString *)identifier{
    NSLog(@"enter %@",identifier);    
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section==0) ? 1 : [self.regions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0){
        static NSString *CellSwitchIdentifier = @"Switch Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellSwitchIdentifier forIndexPath:indexPath];
        return cell;
        
    }else if (indexPath.section == 1){
        static NSString *CellBeaconIdentifier = @"Beacon Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellBeaconIdentifier forIndexPath:indexPath];
        NSDictionary *item = self.regions[indexPath.row];
        NSString *text = [NSString stringWithFormat:@"ID: %@ PROXIMITY:%@ ACCURACY:%@",item[BEACON_IDENTIFIER_KEY],item[BEACON_PROXIMITY_KEY],item[BEACON_ACCURACY_KEY]];
        cell.textLabel.text = text;
        
    }
    return cell;
}



@end
