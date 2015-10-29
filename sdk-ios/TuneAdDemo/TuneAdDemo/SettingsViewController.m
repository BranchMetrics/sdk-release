//
//  SettingsViewController.m
//  TuneAdDemo
//
//  Created by Harshal Ogale on 7/24/14.
//  Copyright (c) 2014 HasOffers Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"

@import MobileAppTracker;
@import AdSupport;
//#import <Tune/TuneAdView.h>
//#import <Tune/Tune.h>

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

NSString * kAdServerProd = @"aa.tuneapi.com"; // Prod
NSString * kAdServerStage = @"aa.stage.tuneapi.com"; // Stage
NSString * kAdServerSam = @"192.168.197.66:8080"; // Stage

NSString * kAdvListUrl      = @"/api/v1/demo/advertisers";
NSString * kAppListUrl      = @"/api/v1/demo/apps";

//Dev:
//http://DEV_SERVER_IP/api/v1/...
//Stage:
//http://ADVERTISER_ID.request.aa.stage.tuneapi.com/api/v1/... (for ad requests)
//http://ADVERTISER_ID.event.aa.stage.tuneapi.com/api/v1/... (for view/close/etc.)
//http://ADVERTISER_ID.click.aa.stage.tuneapi.com/api/v1/... (for clicks)
//Prod:
//http://ADVERTISER_ID.request.aa.tuneapi.com/api/v1/... (for ad requests)
//http://ADVERTISER_ID.event.aa.tuneapi.com/api/v1/... (for view/close/etc.)
//http://ADVERTISER_ID.click.aa.tuneapi.com/api/v1/... (for clicks)

@interface SettingsViewController ()
{
    NSString *demoServerUrl;
    
    NSMutableArray *arrAdvIds;
    NSMutableArray *arrAdvNames;
    NSMutableDictionary *dictApps;
    
    NSArray *arrServers;
    NSArray *arrServerName;
    
    NSArray *arrApps;
    
    NSString *appAdvId;
    NSString *appId;
    NSString *appName;
    NSString *appPackageName;
    NSString *appConversionKey;
    NSString *appLogoUrl;
        
    /*
     apps:
     [
         {
             id: 2787,
             name: "Big Fish Casino",
             os: "iOS",
             package: "com.bigfishgames.bfcasinouniversalfreemium",
             conversionKey: "495be9a626d2fe0ee8c3c74043145689",
             logo: "http://cdn-games.bigfishsites.com/en_big-fish-casino/big-fish-casino_feature.jpg"
         }
     ]
     */
}

@property (nonatomic, assign) BOOL canDisplayAd;

@end

@implementation SettingsViewController

@synthesize btnAdv, btnApp, pickerAdv, pickerApp, pickerServer, labelAdv, labelApp, labelServer, labelPicker, adServer, scrollView, contentView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    arrServers = @[kAdServerProd, kAdServerStage, kAdServerSam];
    arrServerName = @[@"Prod", @"Stage", @"Sam"];
    
    self.pickerAdv.dataSource = self;
    self.pickerAdv.delegate = self;
    
    self.pickerApp.dataSource = self;
    self.pickerApp.delegate = self;
    
    self.pickerServer.dataSource = self;
    self.pickerServer.delegate = self;
    
    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    ad.tuneAdViewDebugMode = self.switchDebug.on;
    
    self.adServer.text = kAdServerProd;
    
    [self changeAdSource];
    
    [self showAdvPicker:nil];
    
    UITapGestureRecognizer* gestureTapAdv = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAdvPicker:)];
    [self.labelAdv setUserInteractionEnabled:YES];
    [self.labelAdv addGestureRecognizer:gestureTapAdv];
    
    UITapGestureRecognizer* gestureTapApp = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAppPicker:)];
    [self.labelApp setUserInteractionEnabled:YES];
    [self.labelApp addGestureRecognizer:gestureTapApp];
    
    UITapGestureRecognizer* gestureTapServer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showServerPicker)];
    [self.labelServer setUserInteractionEnabled:YES];
    [self.labelServer addGestureRecognizer:gestureTapServer];

//    appAdvId = @"9790";
//    appConversionKey = @"c8a118802a11db2fde60010f3a3935b7";
//    appPackageName = @"com.LevelZed.DummyEscapeLite.iOS";
    
//    appAdvId = @"1835";
//    appConversionKey = @"0c499ad7db74db3d417b13342532e00f";
//    appPackageName = @"com.stofledesigns.bubblegalaxywithbuddies";
    
//    appAdvId = @"883";
//    appConversionKey = @"c8b3466c229f97271581b778aa2919cd";
//    appPackageName = @"com.bigfishgames.9thedarksideiphonefree.ceunlock";
    
//    appAdvId = @"877";
//    appConversionKey = @"8c14d6bbe466b65211e781d62e301eec";
//    appPackageName = @"com.HasOffers.InAppPurchaseTracker";

    appAdvId = @"877";
    appConversionKey = @"40c19f41ef0ec2d433f595f0880d39b9";
    appPackageName = @"edu.self.AtomicDodgeBallLite";
    
    [Tune initializeWithTuneAdvertiserId:appAdvId
                       tuneConversionKey:appConversionKey];
    
    [Tune setPackageName:appPackageName];
    
    [Tune setAppleAdvertisingIdentifier:[[ASIdentifierManager sharedManager] advertisingIdentifier]
             advertisingTrackingEnabled:[[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]];
}


#pragma mark -

- (IBAction)refresh:(id)sender
{
    appAdvId = nil;
    appId = nil;
    appName = nil;
    appPackageName = nil;
    appConversionKey = nil;
    appLogoUrl = nil;
    
    if([self.adServer isFirstResponder])
    {
        [self.adServer resignFirstResponder];
    }
    
    [self.btnAdv setTitle:@"----" forState:UIControlStateNormal];
    [self.btnApp setTitle:@"----" forState:UIControlStateNormal];
    
    [self populateLists];
    
    [self showAdvPicker:nil];
    
    [self.pickerAdv selectRow:0 inComponent:0 animated:YES];
    [self.pickerApp selectRow:0 inComponent:0 animated:YES];
}

- (IBAction)debugMode:(id)sender
{
    if([self.adServer isFirstResponder])
    {
        [self.adServer resignFirstResponder];
    }
    
    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    ad.tuneAdViewDebugMode = self.switchDebug.on;
}

- (void)changeAdSource
{
    demoServerUrl = self.adServer.text;
    
    if(NSNotFound != [demoServerUrl rangeOfString:@"http://"].location 
       && NSNotFound != [demoServerUrl rangeOfString:@"https://"].location)
    {
        demoServerUrl = [NSString stringWithFormat:@"http://%@", demoServerUrl];
    }
    else if([[demoServerUrl substringFromIndex:demoServerUrl.length - 1] isEqualToString:@"/"])
    {
        demoServerUrl = [demoServerUrl substringWithRange:NSMakeRange(0, demoServerUrl.length - 1)];
    }

//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//    [[TuneAdView class] performSelector:@selector(setTuneAdServer:) withObject:demoServerUrl];
//#pragma clang diagnostic pop
    
    if([self.adServer isFirstResponder])
    {
        [self.adServer resignFirstResponder];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TuneAdDemoServerChanged" object:nil userInfo:nil];
    
    [self refresh:nil];
}

- (void)populateLists
{
    // ex. http://877.event.aa.stage.tuneapi.com/api/v1/demo/advertisers
    
    BOOL isProdOrStage = -1 != [demoServerUrl compare:kAdServerProd options:NSCaseInsensitiveSearch] || -1 != [demoServerUrl compare:kAdServerStage options:NSCaseInsensitiveSearch];
    NSString *urlPrefix = isProdOrStage ? @"877.event." : @"";
    
    NSURL *demoAdvListUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@%@", urlPrefix, demoServerUrl, kAdvListUrl]];
    
    NSLog(@"demoAdvListUrl = %@", demoAdvListUrl);
    
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:demoAdvListUrl];
        
        [self fetchDemoAdvertisers:data];
    });
}

- (void)fetchDemoAdvertisers:(NSData *)data
{
    // Ref: https://github.com/MobileAppTracking/ads/pull/76
    
    // ex. http://192.168.197.78:8888/api/v1/demo/advertisers
    
    /*
     {
     advertisers: [
     {id: 883, name: "Big Fish Games"},
     {id: 943, name: "EA"},
     {id: 885, name: "Kabam"},
     {id: 6580, name: "Storm8"},
     {id: 12276, name: "Wargaming"},
     {id: 881, name: "Zynga Game Network"}
     ]
     }
     */
    
    // remove old data
    [arrAdvIds removeAllObjects];
    [arrAdvNames removeAllObjects];
    [dictApps removeAllObjects];
    
    arrAdvIds = [NSMutableArray array];
    arrAdvNames = [NSMutableArray array];
    dictApps = [NSMutableDictionary dictionary];
    
    if(data)
    {
        // parse out the json data
        NSError* error;
        NSMutableDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:kNilOptions 
                                                                      error:&error];
        
        if(error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self alertDemoDataError:@"Unable to parse demo advertiser list."];
            });
        }
        else
        {
            NSArray* list = [json objectForKey:@"advertisers"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self writeToConsole:[NSString stringWithFormat:@"demo advertiser list %@", list]];
            });
            
            for (NSDictionary *dictAdv in list)
            {
                NSLog(@"adv id = %@, adv name = %@", dictAdv[@"id"], dictAdv[@"name"]);
                
                NSString *strId = dictAdv[@"id"];
                NSString *strName = dictAdv[@"name"];
                
                [arrAdvIds addObject:strId];
                [arrAdvNames addObject:strName];
                
                dispatch_async(kBgQueue, ^{
                    
                    BOOL isProdOrStage = -1 != [demoServerUrl compare:kAdServerProd options:NSCaseInsensitiveSearch] || -1 != [demoServerUrl compare:kAdServerStage options:NSCaseInsensitiveSearch];
                    NSString *urlPrefix = isProdOrStage ? @"877.event." : @"";
                    
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@%@?advertiserId=%@&platform=ios", urlPrefix, demoServerUrl, kAppListUrl, strId]];
                    
                    NSData* dataApps = [NSData dataWithContentsOfURL:url];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self writeToConsole:[NSString stringWithFormat:@"adv id = %@, app list = %@", strId, dataApps ? @"found" : @"empty"]];
                    });
                    
                    NSLog(@"adv id = %@, app list = %@", strId, dataApps ? @"found" : @"empty");
                    
                    if(dataApps)
                    {
                        [self fetchDemoApps:@[dataApps, strId]];
                    }
                    else
                    {
                        NSLog(@"No apps available for advertiser %@.", strId);
                        
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self alertDemoDataError:[NSString stringWithFormat:@"No apps available for advertiser %@.", strId]];
//                        });
                    }
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pickerAdv reloadAllComponents];
                
                if(arrAdvIds.count > 0)
                {
                    [self.pickerAdv selectRow:0 inComponent:0 animated:YES];
                }
            });
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertDemoDataError:@"Unable to fetch demo advertiser list."];
        });
    }
}

- (void)alertDemoDataError:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}

- (void)fetchDemoApps:(NSArray *)dataAndAdvId
{
    // fetch list of apps for the currently selected demo advertiser
    // ex. http://192.168.197.78:8888/api/v1/demo/apps?advertiserId=883&platform=ios
    
    /*
     {
     apps: [
     {
     id: 2787,
     name: "Big Fish Casino",
     os: "iOS",
     package: "com.bigfishgames.bfcasinouniversalfreemium",
     conversionKey: "495be9a626d2fe0ee8c3c74043145689",
     logo: "http://cdn-games.bigfishsites.com/en_big-fish-casino/big-fish-casino_feature.jpg"
     },
     {
     id: 39320,
     name: "Big Fish Casino HO Test",
     os: "iOS",
     package: "bfcasinouniversalfreemium",
     conversionKey: "c8b3466c229f97271581b778aa2919cd",
     logo: "http://cdn-games.bigfishsites.com/en_big-fish-casino/big-fish-casino_feature.jpg"
     },
     {
     id: 34070,
     name: "Big Fish Casino UK",
     os: "iOS",
     package: "com.bigfishgames.bfcasinoukuniversalfreemium",
     conversionKey: "c8b3466c229f97271581b778aa2919cd",
     logo: "http://cdn-games.bigfishsites.com/en_big-fish-casino/big-fish-casino_feature.jpg"
     }
     ]
     }
     */
    
    NSData *data = [dataAndAdvId objectAtIndex:0];
    NSString *strAdvId = [dataAndAdvId objectAtIndex:1];
    
    if(data && data != (id)[NSNull null])
    {
        // parse out the json data
        NSError* error;
        NSMutableDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:kNilOptions 
                                                                      error:&error];
        
        if(error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self alertDemoDataError:[NSString stringWithFormat:@"Unable to parse demo app list for advertiser %@.", strAdvId]];
            });
        }
        else
        {
            NSArray* list = [json objectForKey:@"apps"];
            
            if(list && [NSNull null] != (id)list)
            {
                [dictApps setObject:list forKey:strAdvId];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pickerApp reloadAllComponents];
            });
            //NSLog(@"dictApps = %@", dictApps);
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertDemoDataError:[NSString stringWithFormat:@"Unable to fetch demo app list for advertiser %@.", strAdvId]];
        });
    }
}

- (IBAction)showAdvPicker:(id)sender
{
    if([self.adServer isFirstResponder])
    {
        [self.adServer resignFirstResponder];
    }
    
    self.labelApp.backgroundColor = UIColor.lightGrayColor;
    self.labelAdv.backgroundColor = UIColor.orangeColor;
    self.labelServer.backgroundColor = UIColor.lightGrayColor;
    
    [self.view bringSubviewToFront:self.pickerAdv];
    self.pickerApp.hidden = YES;
    self.pickerAdv.hidden = NO;
    self.pickerServer.hidden = YES;
    
    self.labelPicker.text = @" Advertisers:";
    self.labelPicker.textColor = UIColor.whiteColor;
    [self.labelPicker performSelector:@selector(setTextColor:) withObject:UIColor.blackColor afterDelay:0.3];
    [self.labelPicker performSelector:@selector(setBackgroundColor:) 
                           withObject:[UIColor colorWithRed:171.0/255.0 green:130.0/255.0 blue:255.0/255.0 alpha:1.0]
                           afterDelay:0.3];
}

- (IBAction)showAppPicker:(id)sender
{
    if([self.adServer isFirstResponder])
    {
        [self.adServer resignFirstResponder];
    }
    
    self.labelApp.backgroundColor = UIColor.orangeColor;
    self.labelAdv.backgroundColor = UIColor.lightGrayColor;
    self.labelServer.backgroundColor = UIColor.lightGrayColor;
    
    [self.view bringSubviewToFront:self.pickerApp];
    self.pickerAdv.hidden = YES;
    self.pickerApp.hidden = NO;
    self.pickerServer.hidden = YES;
    
    self.labelPicker.text = @" Apps:";
    self.labelPicker.textColor = UIColor.whiteColor;
    [self.labelPicker performSelector:@selector(setTextColor:) withObject:UIColor.blackColor afterDelay:0.3];
    [self.labelPicker performSelector:@selector(setBackgroundColor:) withObject:UIColor.cyanColor afterDelay:0.3];
}

- (void)showServerPicker
{
    self.labelApp.backgroundColor = UIColor.lightGrayColor;
    self.labelAdv.backgroundColor = UIColor.lightGrayColor;
    self.labelServer.backgroundColor = UIColor.orangeColor;
    
    [self.view bringSubviewToFront:self.pickerServer];
    self.pickerAdv.hidden = YES;
    self.pickerApp.hidden = YES;
    self.pickerServer.hidden = NO;
    
    self.labelPicker.text = @" Server Presets:";
    self.labelPicker.textColor = UIColor.whiteColor;
    [self.labelPicker performSelector:@selector(setTextColor:) withObject:UIColor.blackColor afterDelay:0.3];
    [self.labelPicker performSelector:@selector(setBackgroundColor:) 
                           withObject:[UIColor colorWithRed:255.0/255.0 green:195.0/255.0 blue:255.0/255.0 alpha:1.0]
                           afterDelay:0.3];
}

- (void)writeToConsole:(id)object
{
    NSDictionary *dict = @{@"object":object};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TuneAdDemoNewLogText"
                                                        object:nil
                                                      userInfo:dict];
}


#pragma mark - UIPickerViewDataSource Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger rows = 0;
    
    if(pickerAdv == pickerView)
    {
        rows = arrAdvIds.count;
    }
    else if(pickerApp == pickerView)
    {
        rows = arrApps.count;
    }
    else if(pickerServer == pickerView)
    {
        rows = arrServers.count;
    }
    
    return rows;
}


#pragma mark - UIPickerViewDelegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *str = nil;
    
    if(pickerAdv == pickerView && row < arrAdvNames.count)
    {
        str = arrAdvNames[row];
    }
    else if(pickerApp == pickerView && row < arrApps.count)
    {
        NSDictionary *curApp = [arrApps objectAtIndex:row];
        str = curApp[@"name"];
    }
    else if(pickerServer == pickerView && row < arrServers.count)
    {
        str = [arrServerName objectAtIndex:row];
    }
    
    return str;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"selected picker row = %ld", (long)row);
    
    if([self.adServer isFirstResponder])
    {
        [self.adServer resignFirstResponder];
    }
    
    if(pickerAdv == pickerView && arrAdvIds.count > row)
    {
        arrApps = dictApps[arrAdvIds[row]];
        
        [self.pickerApp reloadAllComponents];
        if(arrApps.count > 0)
        {
            [self.pickerApp selectRow:0 inComponent:0 animated:NO];
        }
        
        [self showAppPicker:nil];
        
        [self.btnAdv setTitle:[arrAdvNames objectAtIndex:row] forState:UIControlStateNormal];
        
        if(1 == arrApps.count)
        {
            [self pickerView:self.pickerApp didSelectRow:0 inComponent:0];
        }
        else
        {
            [self.btnApp setTitle:@"----" forState:UIControlStateNormal];
        }
        
        appAdvId = [NSString stringWithFormat:@"%@", arrAdvIds[row]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TuneAdDemoAdvertiserChanged" object:nil userInfo:nil];
    }
    else if(pickerApp == pickerView && arrApps.count > row)
    {
        NSDictionary *curApp = [arrApps objectAtIndex:row];
        
        appId = [NSString stringWithFormat:@"%@", curApp[@"id"]];
        appName = curApp[@"name"];
        appPackageName = curApp[@"package"];
        appConversionKey = curApp[@"conversionKey"];
        appLogoUrl = curApp[@"logo"];
        
        [Tune initializeWithTuneAdvertiserId:appAdvId
                           tuneConversionKey:appConversionKey];
        [Tune setPackageName:appPackageName];
        
        [self.btnApp setTitle:appName forState:UIControlStateNormal];
        
        // delay other actions, give the Tune methods a chance to finish first
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TuneAdDemoAppChanged" object:nil userInfo:nil];
        });
        
        NSLog(@"selected app = %@", curApp);
    }
    else if(pickerServer == pickerView)
    {
        self.adServer.text = arrServers[row];
        
        [self changeAdSource];
    }
}


#pragma mark - UITextViewDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self showServerPicker];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(![demoServerUrl isEqualToString:textField.text])
    {
        [self changeAdSource];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(![demoServerUrl isEqualToString:textField.text])
    {
        [self changeAdSource];
    }
    
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"SettingsVC: scrollViewDidScroll");
//    
//    NSLog(@"scrollView.contentSize = %@, frame = %@", NSStringFromCGSize(self.scrollView.contentSize), NSStringFromCGRect(self.scrollView.frame));
}

@end


