//
//  BeaconDetailsVC.m
//  LocateMe
//
//  Created by Daniele Rossetti on 30/10/13.
//  Copyright (c) 2013 Daniele Rossetti. All rights reserved.
//

#import "BeaconDetailsVC.h"
#import "SelectBeaconTVC.h"

@interface BeaconDetailsVC ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *majorTextField;
@property (weak, nonatomic) IBOutlet UITextField *minorTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UIButton *selectBeaconButton;

@end

@implementation BeaconDetailsVC

#pragma mark - Navigation

- (void)viewDidLayoutSubviews{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
}
- (void) dismiss:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) textFieldDidBeginEditing:(UITextField *)textField{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard:)];
}
- (void) dismissKeyboard:(id)sender{
    self.navigationItem.rightBarButtonItem = nil;
    [self.view endEditing:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if([self.majorTextField.text length]>0 && [self.minorTextField.text length]>0)
        self.selectBeaconButton.enabled = YES;
    else
        self.selectBeaconButton.enabled = NO;
}
// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Select Beacon"]){
        SelectBeaconTVC *sbtvc = (SelectBeaconTVC*) [segue destinationViewController];
        sbtvc.major = [self.majorTextField.text intValue];
        sbtvc.minor = [self.minorTextField.text intValue];
        sbtvc.beaconDescription = self.descriptionTextField.text;
    }
}




@end
