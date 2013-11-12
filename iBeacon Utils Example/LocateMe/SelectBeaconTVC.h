//
//  SelectBeaconTVC.h
//  LocateMe
//
//  Created by Daniele Rossetti on 30/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectBeaconTVC : UITableViewController
@property (nonatomic) NSUInteger major;
@property (nonatomic) NSUInteger minor;
@property (nonatomic) NSString* beaconDescription;
@end
