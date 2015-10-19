//
//  SettingsViewController.h
//  TuneAdDemo
//
//  Created by Harshal Ogale on 7/24/14.
//  Copyright (c) 2014 HasOffers Inc. All rights reserved.
//

@import UIKit;

@interface SettingsViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UILabel *labelAdv;
@property (weak, nonatomic) IBOutlet UILabel *labelApp;
@property (weak, nonatomic) IBOutlet UILabel *labelServer;

@property (weak, nonatomic) IBOutlet UIButton *btnAdv;
@property (weak, nonatomic) IBOutlet UIButton *btnApp;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerAdv;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerApp;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerServer;

@property (weak, nonatomic) IBOutlet UILabel *labelPicker;

@property (weak, nonatomic) IBOutlet UITextField *adServer;

@property (weak, nonatomic) IBOutlet UISwitch *switchDebug;

- (IBAction)showAdvPicker:(id)sender;
- (IBAction)showAppPicker:(id)sender;

- (IBAction)refresh:(id)sender;

- (IBAction)debugMode:(id)sender;


@end
