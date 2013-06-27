//
//  MobileAppTracker.h
//  MobileAppTracker
//
//  Created by HasOffers on 04/08/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MATVERSION @"2.3"

@protocol MobileAppTrackerDelegate;

/*!
 MobileAppTracker provides the methods to send events and actions to the
 HasOffers servers.
 */
@interface MobileAppTracker : NSObject


#pragma mark - MobileAppTracker Shared Instance

/** @name MobileAppTracker Shared Instance */
/*!
 A singleton of the MobileAppTracker Class
 */
+ (MobileAppTracker *)sharedManager;


#pragma mark - Main Initializer

/** @name Intitializing MobileAppTracker With Advertiser Information */
/*!
 Starts Mobile App Tracker with MAT Advertiser Id and MAT Conversion Key. Both values are required.
 @param aid the MAT Advertiser Id provided in Mobile App Tracking.
 @param key the MAT Conversion Key provided in Mobile App Tracking.
 @param error optional, use this to view an error in starting mobile app tracker.
 @return TRUE if error occurs, FALSE otherwise.
 */
- (BOOL)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key withError:(NSError **)error;


#pragma mark - Properties

/** @name MAT SDK Callback Delegate */
/*!
 [MobileAppTrackerDelegate](MobileAppTrackerDelegate) : A Delegate used by MobileAppTracker to callback.
 Set this to receive success and failure callbacks from the MAT SDK.
 */
@property (nonatomic, assign) id <MobileAppTrackerDelegate> delegate;

/** @name MAT Data Parameters */
/*!
 Provides a view of the parameters used by the sdk at any time.
 */
@property (nonatomic, readonly) NSDictionary *sdkDataParameters;


#pragma mark - Debug And Test

/** @name Debug And Test */

/*!
 Specifies that the server responses should include debug information.
 
 @warning This is only for testing. You must turn this off for release builds.
 
 @param yesorno defaults to NO.
 */
- (void)setDebugMode:(BOOL)yesorno;

/*!
 Set to YES to allow duplicate requests to be registered with the tracking engine.
 
 @warning This is only for testing. You must turn this off for release builds.
 
 @param yesorno defaults to NO.
 */
- (void)setAllowDuplicateRequests:(BOOL)yesorno;

#pragma mark - Data Parameters

/** @name Setter Methods */

/*!
 Set the Apple Advertising Identifier available in iOS 6
 @param advertising_identifier - Apple Advertising Identifier
 */
- (void)setAppleAdvertisingIdentifier:(NSUUID *)advertising_identifier;

/*!
 Set the Apple Vendor Identifier available in iOS 6
 @param vendor_identifier - Apple Vendor Identifier
 */
- (void)setAppleVendorIdentifier:(NSUUID * )vendor_identifier;

/*!
 Sets the currency code for the engine.
 Default: USD
 @param currency_code The string name for the currency code.
 */
- (void)setCurrencyCode:(NSString *)currency_code;

/*!
 Sets the jailbroken device flag for the engine.
 @param yesorno The jailbroken device flag.
 */
- (void)setJailbroken:(BOOL)yesorno;

/*!
 Sets the MAT advertiser id for the engine.
 @param advertiser_id The string id for the MAT advertiser id.
 */
- (void)setMATAdvertiserId:(NSString *)advertiser_id;

/*!
 Sets the MAT conversion key for the engine.
 @param conversion_key The string value for the MAT conversion key.
 */
- (void)setMATConversionKey:(NSString *)conversion_key;

/*!
 Set the OpenUDID for the engine.
 @param open_udid a string value for the open udid value.
 */
- (void)setOpenUDID:(NSString *)open_udid;

/*!
 Sets the package name (bundle_id) for the engine.
 Defaults to the bundle_id of the app that is running the sdk.
 @param package_name The string name for the package.
 */
- (void)setPackageName:(NSString *)package_name;

/*!
 Specifies if the sdk should auto detect if the iOS device is jailbroken.
 YES/NO
 @param yesorno yes will detect if the device is jailbroken, defaults to yes.
 */
- (void)setShouldAutoDetectJailbroken:(BOOL)yesorno;

/*!
 Specifies if the sdk should pull the Apple Advertising Identifier from the device.
 YES/NO
 @param yesorno yes will set the Apple Advertising Identifier key, defaults to no.
 */
- (void)setShouldAutoGenerateAppleAdvertisingIdentifier:(BOOL)yesorno;

/*!
 Specifies if the sdk should pull the Apple Vendor Identifier from the device.
 YES/NO
 @param yesorno yes will set the Apple Vendor Identifier key, defaults to no.
 */
- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)yesorno;

/*!
 Specifies if the sdk should auto generate a mac address identifier.
 YES/NO
 @param yesorno yes will create a mac address, defaults to yes.
 */
- (void)setShouldAutoGenerateMacAddress:(BOOL)yesorno;

/*!
 Specifies if the sdk should auto generate an ODIN-1 key.
 YES/NO
 @param yesorno yes will create an ODIN-1 key, defaults to yes.
 */
- (void)setShouldAutoGenerateODIN1Key:(BOOL)yesorno;

/*!
 Specifies if the sdk should auto generate an Open UDID key.
 YES/NO
 @param yesorno yes will create an ODIN-1 key, defaults to yes.
 */
- (void)setShouldAutoGenerateOpenUDIDKey:(BOOL)yesorno;

/*!
 Sets the site id for the engine.
 @param site_id The string id for the site id.
 */
- (void)setSiteId:(NSString *)site_id;

/*!
 Set the Trusted Preference Identifier (TPID).
 @param truste_tpid - Trusted Preference Identifier (TPID)
 */
- (void)setTrusteTPID:(NSString *)truste_tpid;

/*!
 Use HTTPS for the urls to the tracking engine.
 YES/NO
 @param yesorno yes means use https, default is yes.
 */
- (void)setUseHTTPS:(BOOL)yesorno;

/*!
 Sets the user id for the engine.
 @param user_id The string name for the user id.
 */
- (void)setUserId:(NSString *)user_id;


#pragma mark - Track Install/Update Methods

/** @name Track Installs and/or Updates */

/*!
 Record an Install or an Update by determining if a previous
 version of this app is already installed on the user's device.
 To be used if this is the first version of the app
 or the previous version also included MAT sdk.
 To be called when an app opens; typically in the didFinishLaunching event.
 Works only once per app version, does not have any effect if called again in the same app version.
 */
- (void)trackInstall;

/*!
 Record an Install or an Update by determining if a previous
 version of this app is already installed on the user's device.
 To be used if this is the first version of the app
 or the previous version also included MAT sdk.
 To be called when an app opens; typically in the didFinishLaunching event.
 Works only once per app version, does not have any effect if called again in the same app version.
 @param refId A reference id used to track an install and/or update.
 */
- (void)trackInstallWithReferenceId:(NSString *)refId;

/*!
 Instead of an Install, force an Update to be recorded.
 To be used if MAT sdk was not integrated in the previous
 version of this app. Only use this method if your app can distinguish
 between an install and an update, else use trackInstall.
 To be called when an app opens; typically in the didFinishLaunching event.
 Works only once per app version, does not have any effect if called again in the same app version.
 */
- (void)trackUpdate;

/*!
 Instead of an Install, force an Update to be recorded.
 To be used if MAT sdk was not integrated in the previous
 version of this app. Only use this method if your app can distinguish
 between an install and an update, else use trackInstallWithReferenceId.
 To be called when an app opens; typically in the didFinishLaunching event.
 Works only once per app version, does not have any effect if called again in the same app version.
 @param refId A reference id used to track an update.
 */
- (void)trackUpdateWithReferenceId:(NSString *)refId;


#pragma mark - Track Actions

/** @name Track Actions */

/*!
 Record a Track Action for an Event Id or Name.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId;

/*!
 Record a Track Action for an Event Id or Name and reference id.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param refId The referencId for an event.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                        referenceId:(NSString *)refId;


/*!
 Record a Track Action for an Event Id or Name, revenue and currency.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param revenueAmount The revenue amount for the event.
 @param currencyCode The currency code override for the event. Blank defaults to sdk setting.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;

/*!
 Record a Track Action for an Event Id or Name and reference id, revenue and currency.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param refId The referencId for an event.
 @param revenueAmount The revenue amount for the event.
 @param currencyCode The currency code override for the event. Blank defaults to sdk setting.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;


#pragma mark - Track Actions With Event Items

/** @name Track Actions With Event Items */

/*!
 Record a Track Action for an Event Id or Name and a list of event items.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param eventItems A list of dictionaries that contain elements: item, unit_price, quantity and revenue
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems;

/*!
 Record a Track Action for an Event Name or Id.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param eventItems A list of dictionaries that contain elements: item, unit_price, quantity and revenue
 @param refId The referencId for an event.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId;

/*!
 Record a Track Action for an Event Name or Id.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param eventItems A list of dictionaries that contain elements: item, unit_price, quantity and revenue
 @param revenueAmount The revenue amount for the event.
 @param currencyCode The currency code override for the event. Blank defaults to sdk setting.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;

/*!
 Record a Track Action for an Event Name or Id.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param eventItems A list of dictionaries that contain elements: item, unit_price, quantity and revenue
 @param refId The referencId for an event.
 @param revenueAmount The revenue amount for the event.
 @param currencyCode The currency code override for the event. Blank defaults to sdk setting.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;

/*!
 Record a Track Action for an Event Name or Id.
 @param eventIdOrName The event name or event id.
 @param isId Yes if the event is an Id otherwise No if the event is a name only.
 @param eventItems A list of dictionaries that contain elements: item, unit_price, quantity and revenue
 @param refId The referencId for an event.
 @param revenueAmount The revenue amount for the event.
 @param currencyCode The currency code override for the event. Blank defaults to sdk setting.
 @param transactionState The in-app purchase transaction SKPaymentTransactionState as received from the iTunes store.
 */
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState;


#pragma mark - Cookie Tracking

/** @name Cookie Tracking */
/*!
 Sets whether or not to user cookie based tracking.
 Default: NO
 @param yesorno YES/NO for cookie based tracking.
 */
- (void)setUseCookieTracking:(BOOL)yesorno;


#pragma mark - App-to-app Tracking

/** @name App-To-App Tracking */

/*!
 Sets a url to be used with app-to-app tracking so that
 the sdk can open the download (redirect) url. This is
 used in conjunction with the setTracking:advertiserId:offerId:publisherId:redirect: method.
 @param redirect_url The string name for the url.
 */
- (void)setRedirectUrl:(NSString *)redirect_url;

/*!
 Start a Tracking Session on the MAT server.
 @param targetAppId The bundle identifier of the target app.
 @param advertiserId The MAT advertiser id of the target app.
 @param offerId The MAT offer id of the target app.
 @param publisherId The MAT publisher id of the target app.
 @param shouldRedirect Should redirect to the download url if the tracking session was successfully created. See setRedirectUrl:.
 */
- (void)setTracking:(NSString *)targetAppId
       advertiserId:(NSString *)advertiserId
            offerId:(NSString *)offerId
        publisherId:(NSString *)publisherId
           redirect:(BOOL)shouldRedirect;


#pragma mark - Re-Engagement Method

/** @name Application Re-Engagement */

/*!
 Record the URL and Source when an application is opened via a URL scheme.
 This typically occurs during OAUTH or when an app exits and is returned
 to via a URL. The data will be sent to the HasOffers server so that a
 Re-Engagement can be recorded.
 @param urlString the url string used to open your app.
 @param sourceApplication the source used to open your app. For example, mobile safari.
 */
- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication;

@end

#pragma mark - Deprecated Methods

@interface MobileAppTracker (Deprecated)

// Note: A method identified as deprecated has been superseded and may become unsupported in the future.

/*!
 <span style="color:red">Deprecated Method:</span> Instead use startTrackerWithMATAdvertiserId:MATConversionKey:withError:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (BOOL)startTrackerWithAdvertiserId:(NSString *)aid advertiserKey:(NSString *)key withError:(NSError **)error __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setMATAdvertiserId:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setAdvertiserId:(NSString *)advertiser_id __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setMATConversionKey:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setAdvertiserKey:(NSString *)advertiser_key __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setAppleAdvertisingIdentifier:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setAdvertiserIdentifier:(NSUUID *)advertiser_identifier __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setAppleVendorIdentifier:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setVendorIdentifier:(NSUUID * )vendor_identifier __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setShouldAutoGenerateAppleAdvertisingIdentifier:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setShouldAutoGenerateAdvertiserIdentifier:(BOOL)yesorno __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setShouldAutoGenerateAppleVendorIdentifier:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setShouldAutoGenerateVendorIdentifier:(BOOL)yesorno __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setDebugMode:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setShouldDebugResponseFromServer:(BOOL)yesorno __deprecated;

/*!
 <span style="color:red">Deprecated Method:</span> Instead use setAllowDuplicateRequests:
 @warning <span style="color:red">Deprecated Method</span>
 */
- (void)setShouldAllowDuplicateRequests:(BOOL)yesorno __deprecated;

@end


#pragma mark - MobileAppTrackerDelegate

/** @name MobileAppTrackerDelegate */

/*!
 Protocol that allows for callbacks from the MobileAppTracker methods.
 To use, set your class as the delegate for MAT and implement these methods.
 */
@protocol MobileAppTrackerDelegate <NSObject>
@optional

/*!
 Delegate method called when a track action succeeds.
 @param tracker The MobileAppTracker instance.
 @param data The success data returned by the MobileAppTracker.
 */
- (void)mobileAppTracker:(MobileAppTracker *)tracker didSucceedWithData:(NSData *)data;

/*!
 Delegate method called when a track action fails.
 @param tracker The MobileAppTracker instance.
 @param error Error object returned by the MobileAppTracker.
 */
- (void)mobileAppTracker:(MobileAppTracker *)tracker didFailWithError:(NSError *)error;
@end

