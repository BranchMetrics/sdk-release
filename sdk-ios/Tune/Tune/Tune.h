//
//  Tune.h
//  Tune
//
//  Created by Tune on 03/20/14.
//  Copyright (c) 2013 Tune. All rights reserved.
//

//#import <AvailabilityMacros.h>
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS
#import <CoreSpotlight/CoreSpotlight.h>
#endif

#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CoreLocation.h>

#import "TuneConstants.h"
#import "TuneEvent.h"
#import "TuneEventItem.h"
#import "TunePreloadData.h"

#define TUNEVERSION @"6.0.1"


@protocol TuneDelegate;

/**
 Tune provides the methods to send events and actions to the
 HasOffers servers.
 */
@interface Tune : NSObject


#pragma mark - Intitializing Tune With Advertiser Information

/**
 Starts Tune with Tune Advertiser ID and Tune Conversion Key. Both values are required.

 @param aid the Tune Advertiser ID provided in Tune.
 @param key the Tune Conversion Key provided in Tune.
 */
+ (void)initializeWithTuneAdvertiserId:(nonnull NSString *)aid tuneConversionKey:(nonnull NSString *)key;

/**
 Starts Mobile App Tracker with MAT Advertiser ID and MAT Conversion Key. All values are required.

 @param aid the MAT Advertiser ID provided in Mobile App Tracking.
 @param key the MAT Conversion Key provided in Mobile App Tracking.
 @param name the package name used when setting up the app in Mobile App Tracking.
 */
+ (void)initializeWithTuneAdvertiserId:(nonnull NSString *)aid tuneConversionKey:(nonnull NSString *)key tunePackageName:(nullable NSString *)name;

#pragma mark - Deeplinking

/**
 Set the deeplink listener that will be called when either a deferred deeplink is found for a fresh install or for handling an opened Tune Link.

 Registering a deeplink listener will trigger an asynchronous call to check for deferred deeplinks during the first session after installing of the app with the Tune SDK.

 The tuneDidFailDeeplinkWithError: callback will be called if there is no deferred deeplink from Tune for this user or in the event of an error from the server (possibly due to misconfiguration).

 The tuneDidReceiveDeeplink: callback will be called when there is a deep link from Tune that you should route the user to. The string should be a fully qualified deep link url string.

 @param delegate Delegate that will be called with deferred deeplinks after install or expanded Tune links. May be nil. Passing nil will clear the previously set listener, although you may use unregisterDeeplinkListener: instead.
 */
+ (void)registerDeeplinkListener:(nullable id<TuneDelegate>)delegate;

/**
 Remove the deeplink listener previously set with registerDeeplinkListener:
 */
+ (void)unregisterDeeplinkListener;

/**
 Test if your custom Tune Link domain is registered with Tune.
 Tune Links are Tune-hosted Universal Links. Tune Links are often shared as short-urls, and the Tune SDK will handle expanding the url and returning the in-app destination url to tuneDidReceiveDeeplink: registered via registerDeeplinkListener:

 @param linkUrl URL to test if it is a Tune Link. Must not be nil.

 @return True if this link is a Tune Link that will be measured by Tune and routed into the TuneDelegate.
 */
+ (BOOL)isTuneLink:(nonnull NSString *)linkUrl;

/**
 If you have set up a custom domain for use with Tune Links (cname to a *.tlnk.io domain), then register it with this method.
 Tune Links are Tune-hosted Universal Links. Tune Links are often shared as short-urls, and the Tune SDK will handle expanding the url and returning the in-app destination url to tuneDidReceiveDeeplink: registered via registerDeeplinkListener:
 This method will test if any clicked links match the given suffix. Do not include a * for wildcard subdomains, instead pass the suffix that you would like to match against the url.
 So, ".customize.it" will match "1235.customize.it" and "56789.customize.it" but not "customize.it"
 And, "customize.it" will match "1235.customize.it" and "56789.customize.it", "customize.it", and "1235.tocustomize.it"
 You can register as many custom subdomains as you like.

 @param domain The domain which you are using for Tune Links. Must not be nil.
 */
+ (void)registerCustomTuneLinkDomain:(nonnull NSString *)domain;

/**
 Set the url and source when your application is opened via a deeplink.

 Tune uses this information to measure re-engagement.

 If the url is a Tune Link, this method will invoke tuneDidReceiveDeeplink: or tuneDidFailDeeplinkWithError:

 @param url The url used to open the app.
 @param options A dictionary of URL handling options.

 @return Whether url is a Tune Link. If NO, the Tune deeplink callbacks will not be invoked and you should handle the routing yourself.
 */
+ (BOOL)handleOpenURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

/**
 Set the url and source when your application is opened via a deeplink.

 Tune uses this information to measure re-engagement.

 If the url is a Tune Link, this method will invoke tuneDidReceiveDeeplink: or tuneDidFailDeeplinkWithError:

 @param url The url used to open the app.
 @param sourceApplication the source used to open your app. For example, mobile safari.

 @return Whether url is a Tune Link. If NO, the Tune deeplink callbacks will not be invoked and you should handle the routing yourself.
 */
+ (BOOL)handleOpenURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication;

/**
 Set the url and source when your application is opened via a universal link.

 Tune uses this information to measure re-engagement.

 If the url is a Tune Link, this method will invoke tuneDidReceiveDeeplink: or tuneDidFailDeeplinkWithError:

 @param userActivity The NSUserActivity used to open the app.
 @param restorationHandler Block to execute if your app creates objects to perform the task.

 @return Whether url is a Tune Link. If NO, the Tune deeplink callbacks will not be invoked and you should handle the routing yourself.
 */
+ (BOOL)handleContinueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * _Nonnull restorableObjects))restorationHandler;


#pragma mark - Debug And Test

/**
 Sets a callback block for log messages from Tune.
 Reroute the Tune log messages to NSLog, os_log or any logging system.
 
 @warning Log messages can come from any thread.

 @param callback where log messages are sent.  By default, only errors are logged.
 */
+ (void)setDebugLogCallback:(void (^)(NSString * _Nonnull logMessage))callback;

/**
 Enables verbose log messages.  This will provide more log information to the log callback.
 
 @warning This is only for testing and should be disabled for release.
 
 @param enable defaults to NO.
 */
+ (void)setDebugLogVerbose:(BOOL)enable;

#pragma mark - Behavior Flags

/**
 Enable automatic measurement of app store in-app-purchase events. When enabled, your code should not explicitly measure events for successful purchases related to StoreKit to avoid event duplication. If your app provides subscription IAP items, please make sure you enter the iTunes Shared Secret on the TUNE dashboard, otherwise Apple receipt validation will fail and the events will be marked as rejected.

 @param automate Automate IAP purchase event measurement. Defaults to NO.
 */
+ (void)automateInAppPurchaseEventMeasurement:(BOOL)automate;

/**
 Set whether the Tune events should also be logged to the Facebook SDK. This flag is ignored if the Facebook SDK is not present.

 @param logging Whether to send Tune events to FB as well
 @param limit Whether data such as that generated through FBAppEvents and sent to Facebook should be restricted from being used for other than analytics and conversions.  Defaults to NO.  This value is stored on the device and persists across app launches.
 */
+ (void)setFacebookEventLogging:(BOOL)logging limitEventAndDataUsage:(BOOL)limit;


#pragma mark - Data Setters

/**
 Set whether this is an existing user or a new one. This is generally used to
 distinguish users who were using previous versions of the app, prior to
 integration of the Tune SDK. The default is to assume a new user.

 @see http://support.mobileapptracking.com/entries/22621001-Handling-Installs-prior-to-SDK-implementation

 @param existingUser - Is this a pre-existing user of the app? Default: NO
 */
+ (void)setExistingUser:(BOOL)existingUser;

/**
 Sets the jailbroken device flag.

 @param jailbroken The jailbroken device flag.
 */
+ (void)setJailbroken:(BOOL)jailbroken;

/**
 Disable auto collection of device location data.
 
 */
+ (void)disableLocationAutoCollection;

/**
 Sets the MD5, SHA-1 and SHA-256 hash representations of the user's email address.

 @param userEmail The user's email address.
 */
+ (void)setUserEmail:(nullable NSString *)userEmail;

/**
 Sets the user ID.

 @param userId The string name for the user ID.
 */
+ (void)setUserId:(nullable NSString *)userId;

/**
 Sets the MD5, SHA-1 and SHA-256 hash representations of the user's name.

 @param userName The user's name.
 */
+ (void)setUserName:(nullable NSString *)userName;

/**
 Sets the MD5, SHA-1 and SHA-256 hash representations of the user's phone number.

 @param phoneNumber The user's phone number.
 */
+ (void)setPhoneNumber:(nullable NSString *)phoneNumber;

/**
 Set the user's Facebook ID.

 @param facebookUserId string containing the user's Facebook user ID.
 */
+ (void)setFacebookUserId:(nullable NSString *)facebookUserId;

/**
 Set the user's Twitter ID.

 @param twitterUserId string containing the user's Twitter user ID.
 */
+ (void)setTwitterUserId:(nullable NSString *)twitterUserId;

/**
 Set the user's Google ID.

 @param googleUserId string containing the user's Google user ID.
 */
+ (void)setGoogleUserId:(nullable NSString *)googleUserId;

/**
 Sets the user's age.
 When age is set to a value less than 13 this device profile will be marked as privacy protected
 for the purposes of the protection of children from ad targeting and
 personal data collection. In the US this is part of the COPPA law.

 @see https://developers.tune.com/sdk/settings-for-user-characteristics/

 @param userAge user's age
 */
+ (void)setAge:(NSInteger)userAge;

/**
 Set this device profile as privacy protected for the purposes of the protection of children
 from ad targeting and personal data collection. In the US this is part of the COPPA law.
 You cannot turn privacy protection "off" for if the user's age is set to less than 13.

 @see https://developers.tune.com/sdk/settings-for-user-characteristics/ for more information

 @param privacyProtected if privacy should be protected for this user.
 */
+ (void)setPrivacyProtectedDueToAge:(BOOL)privacyProtected;

/**
 Returns whether this device profile is flagged as privacy protected.
 This will be true if either the age is set to less than 13 or if this profile has been set explicitly as privacy protected.

 @return privacy protection status, if the age has been set to less than 13 OR this profile has been set explicitly as privacy protected.
 */
+ (BOOL)isPrivacyProtectedDueToAge;

/**
 Sets the user's gender.

 @param userGender user's gender, possible values TuneGenderMale, TuneGenderFemale, TuneGenderUnknown
 */
+ (void)setGender:(TuneGender)userGender;

/**
 Sets the user's location. Manually setting the location through this method disables location auto-collection.
 
 @param location CLLocation from Core Location
 */
+ (void)setLocation:(nonnull CLLocation *)location;

/**
 Sets the user's location. Manually setting the location through this method disables location auto-collection.
 
 @param latitude device latitude
 @param longitude device longitude
 @param altitude device altitude
 */
+ (void)setLocationWithLatitude:(nonnull NSNumber *)latitude longitude:(nonnull NSNumber *)longitude altitude:(nullable NSNumber *)altitude;

/**
 Set app level ad tracking.
 YES/NO

 @param enable YES means opt-in, NO means opt-out.
 */
+ (void)setAppAdTrackingEnabled:(BOOL)enable;

/**
 Set whether the user is generating revenue for the app or not.
 If measureEvent is called with a non-zero revenue, this is automatically set to YES.

 @param isPayingUser YES if the user is revenue-generating, NO if not
 */
+ (void)setPayingUser:(BOOL)isPayingUser;

/**
 Sets publisher information for attribution.

 @param preloadData Preload app attribution data
 */
+ (void)setPreloadedAppData:(nonnull TunePreloadData *)preloadData;

#pragma mark - Data Getters

/**
 Get the Apple Advertising Identifier.

 @return Apple Advertising Identifier (IFA)
 */
+ (nullable NSString *)appleAdvertisingIdentifier;

/**
 Get the TUNE ID for this installation (mat_id).

 @return TUNE ID
 */
+ (nullable NSString *)tuneId;

/**
 Get the Tune log ID for the first app open (open_log_id).

 @return open log ID
 */
+ (nullable NSString *)openLogId;

/**
 Get whether the user is revenue-generating.

 @return YES if the user has produced revenue, NO if not
 */
+ (BOOL)isPayingUser;

#pragma mark - Measuring Sessions

/**
 To be called when an app opens; typically in the applicationDidBecomeActive event.
 */
+ (void)measureSession;


#pragma mark - Measuring Events

/**
 Record an event for an Event Name.

 @param eventName The event name.
 */
+ (void)measureEventName:(nonnull NSString *)eventName;

/**
 Record an event with a TuneEvent.

 @param event The TuneEvent.
 */
+ (void)measureEvent:(nonnull TuneEvent *)event;

@end


#pragma mark - TuneDelegate

/**
 Protocol that allows for callbacks from the Tune methods.
 To use, set your class as the delegate for Tune and implement these methods.
 Delegate methods are called on an arbitrary thread.
 */
@protocol TuneDelegate <NSObject>
@optional

/**
 Delegate method called when a deferred deeplink becomes available.
 The deeplink should be used to open the appropriate screen in your app.
 
 @param deeplink String representation of the deeplink url.
 */
- (void)tuneDidReceiveDeeplink:(nullable NSString *)deeplink;

/**
 Delegate method called when a deferred deeplink request fails.
 
 @param error Error object indicating why the request failed.
 */
- (void)tuneDidFailDeeplinkWithError:(nullable NSError *)error;

@end

