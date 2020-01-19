package com.tune;

import android.location.Location;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

/**
 * Public Interface to the Tune SDK.
 * To create an instance of the Tune singleton, use the appropriate init methods from {@link Tune}.
 * <br>
 * At any time after initialization, the {@link ITune} interface can be retrieved
 * by calling the static method {@link Tune#getInstance()}
 */
public interface ITune {
    /**
     * Event measurement function that measures an event for the given eventName.
     * @param eventName event name in TUNE system.  The eventName parameter cannot be null or empty
     */
    void measureEvent(@NonNull String eventName);

    /**
     * Event measurement function that measures an event based on TuneEvent values.
     * Create a TuneEvent to pass in with:<br>
     * <pre>new TuneEvent(eventName)</pre>
     * @param eventData custom data to associate with the event
     */
    void measureEvent(final TuneEvent eventData);


    /* ========================================================================================== */
    /* Public Getters                                                                             */
    /* ========================================================================================== */

    /**
     * Gets the action of the event.
     * @return install/update/conversion
     */
    String getAction();

    /**
     * Gets the TUNE advertiser ID.
     * @return TUNE advertiser ID
     */
    String getAdvertiserId();

    /**
     * Gets the user age.
     * NOTE: this value must be set with {@link #setAge(int)} otherwise this method will return 0.
     *
     * @return age, if set. If no value is set this method returns 0.
     */
    int getAge();

    /**
     * Gets the ANDROID_ID of the device if it was auto collected.
     * @return ANDROID_ID
     */
    String getAndroidId();

    /**
     * Get whether the user has app-level ad tracking enabled or not.
     * Note that COPPA rules apply.
     * @return app-level ad tracking enabled or not
     */
    boolean getAppAdTrackingEnabled();

    /**
     * Gets the app name.
     * @return app name
     */
    String getAppName();

    /**
     * Gets the app version.
     * @return app version
     */
    int getAppVersion();

    /**
     * Gets the connection type (mobile or WIFI).
     * @return whether device is connected by WIFI or mobile data connection
     */
    String getConnectionType();

    /**
     * Gets the ISO 639-1 country code.
     * @return ISO 639-1 country code
     */
    String getCountryCode();

    /**
     * Gets the device brand/manufacturer (HTC, Apple, etc).
     * @return device brand/manufacturer name
     */
    String getDeviceBrand();

    /**
     * Gets the device build.
     * @return device build name
     */
    String getDeviceBuild();

    /**
     * Gets the device carrier if any.
     * @return mobile device carrier/service provider name
     */
    String getDeviceCarrier();

    /**
     * Gets the Device ID, also known as IMEI/MEID, if any.
     * @return device IMEI/MEID
     */
    String getDeviceId();

    /**
     * Gets the device model name.
     * @return device model name
     */
    String getDeviceModel();

    /**
     * Gets value previously set of existing user or not.
     * @return whether user existed prior to install
     */
    boolean getExistingUser();

    /**
     * Gets the Facebook user ID previously set.
     * @return Facebook user ID
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    String getFacebookUserId();

    /**
     * Gets the user gender set with {@link #setGender(TuneGender)}.
     * @return gender
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    TuneGender getGender();

    /**
     * Gets the Google user ID previously set.
     * @return Google user ID
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    String getGoogleUserId();

    /**
     * Gets the date of app install.
     * @return date that app was installed, epoch seconds
     */
    long getInstallDate();

    /**
     * Gets the Google Play Referrer Library referrerUrl.
     * @return referrerUrl
     */
    String getInstallReferrer();

    /**
     * Gets whether the user is revenue-generating or not.
     * @return true if the user has produced revenue, false if not
     */
    boolean isPayingUser();

    /**
     * Returns whether this device profile is flagged as privacy protected.
     * This will be true if either the age is set to less than 13 or if {@link #setPrivacyProtectedDueToAge(boolean)} is set to true.
     * @return true if the age has been set to less than 13 OR this profile has been set explicitly as privacy protected.
     */
    boolean isPrivacyProtectedDueToAge();

    /**
     * Gets the language of the device.
     * @return device language
     */
    String getLanguage();

    /**
     * Gets the device locale.
     * @return device locale
     */
    String getLocale();

    /**
     * Get the device location.
     * @return device Location
     */
    Location getLocation();

    /**
     * Gets the MAT ID generated on install.
     * @return MAT ID
     */
    String getMatId();

    /**
     * Gets the mobile country code.
     * @return mobile country code associated with the carrier
     */
    String getMCC();

    /**
     * Gets the mobile network code.
     * @return mobile network code associated with the carrier
     */
    String getMNC();

    /**
     * Gets the first TUNE open log ID.
     * @return first TUNE open log ID
     */
    String getOpenLogId();

    /**
     * Gets the Android OS version.
     * @return Android OS version
     */
    String getOsVersion();

    /**
     * Gets the app package name.
     * @return package name of app
     */
    String getPackageName();

    /**
     * Gets whether use of the Platform Advertising ID is limited by user request.
     * Note that COPPA rules apply.
     * @return whether tracking is limited
     */
    boolean getPlatformAdTrackingLimited();

    /**
     * Gets the Platform Advertising ID.
     * @return Platform advertising ID
     */
    String getPlatformAdvertisingId();

    /**
     * Gets the url scheme that started this Activity, if any.
     * @return full url of app scheme that caused open
     */
    String getReferralUrl();

    /**
     * Gets the screen density of the device.
     * @return 0.75/1.0/1.5/2.0/3.0/4.0 for ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
     */
    String getScreenDensity();

    /**
     * Gets the screen height of the device in pixels.
     * @return height
     */
    String getScreenHeight();

    /**
     * Gets the screen width of the device in pixels.
     * @return width
     */
    String getScreenWidth();

    /**
     * Gets the Twitter user ID previously set.
     * @return Twitter user ID
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    String getTwitterUserId();

    /**
     * Gets the device browser user agent.
     * @return device user agent
     */
    String getUserAgent();

    /**
     * Gets the custom user email.
     * @return custom user email
     */
    String getUserEmail();

    /**
     * Gets the custom user ID.
     * @return custom user id
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    String getUserId();

    /**
     * Gets the custom user name.
     * @return custom user name
     */
    String getUserName();


    /* ========================================================================================== */
    /* Public Setters                                                                             */
    /* ========================================================================================== */

    /**
     * Sets the user's age.
     * When age is set to a value less than 13 this device profile will be marked as privacy protected
     * for the purposes of the protection of children from ad targeting and
     * personal data collection. In the US this is part of the COPPA law.
     * This method is related to {@link #setPrivacyProtectedDueToAge(boolean)}
     * See https://developers.tune.com/sdk/settings-for-user-characteristics/ for more information
     * @param age User age
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setAge(int age);

    /**
     * Sets whether app-level ad tracking is enabled.
     * @param adTrackingEnabled false if user has opted out of ad tracking at the app-level, true if the user has opted in
     */
    void setAppAdTrackingEnabled(boolean adTrackingEnabled);

    /**
     * Sets whether app was previously installed prior to version with TUNE SDK. This should be called BEFORE your first activity resumes.
     * @param existing true if this user already had the app installed prior to updating to TUNE version
     */
    void setExistingUser(boolean existing);

    /**
     * Sets the user ID to associate with Facebook.
     * @param userId the Facebook user id
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setFacebookUserId(String userId);

    /**
     * Sets the user gender.
     * @param gender use TuneGender.MALE, TuneGender.FEMALE
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setGender(final TuneGender gender);

    /**
     * Sets the user ID to associate with Google.
     * @param userId the Google user id
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setGoogleUserId(String userId);

    /**
     * Sets referrerUrl received from the Play Store Referrer Library
     * @param referrer referrerUrl (page where user clicked on the url that lead to Play Store)
     */
    void setInstallReferrer(String referrer);

    /**
     * Sets whether the user is revenue-generating or not.
     * @param isPayingUser true if the user has produced revenue, false if not
     */
    void setPayingUser(boolean isPayingUser);

    /**
     * Sets the device location.
     * Manually setting the location through this method disables geo-location auto-collection.
     * @param location the device location
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setLocation(final Location location);

    /**
     * Sets the device location.
     * Manually setting the location through this method disables geo-location auto-collection.
     * @param latitude the device latitude
     * @param longitude the device longitude
     * @param altitude the device altitude
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setLocation(double latitude, double longitude, double altitude);

    /**
     * Sets the device phone number.
     * @param phoneNumber Phone number
     */
    void setPhoneNumber(String phoneNumber);

    /**
     * Sets publisher information for device preloaded apps.
     * @param preloadData Preload app attribution data
     */
    void setPreloadedAppData(final TunePreloadData preloadData);

    /**
     * Set privacy as protected.
     * Set this device profile as privacy protected for the purposes of the protection of children
     * from ad targeting and personal data collection. In the US this is part of the COPPA law.
     * This method is related to {@link #setAge(int)}.
     * @param isPrivacyProtected True if privacy should be protected for this user.
     * @return true if age requirements are met.  For example, you cannot turn privacy protection "off" for children who meet the COPPA standard.
     */
    boolean setPrivacyProtectedDueToAge(boolean isPrivacyProtected);

    /**
     * Set referral url (deeplink).
     * You usually do not need to call this directly. If called, this method should be called BEFORE Tune measures the Session.
     * @param url deeplink with which app was invoked
     */
    void setReferralUrl(String url);

    /**
     * Sets the user ID to associate with Twitter.
     * @param userId the Twitter user id
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setTwitterUserId(String userId);

    /**
     * Sets the custom user email.
     * @param userEmail the user email
     */
    void setUserEmail(String userEmail);

    /**
     * Sets the custom user ID.
     * @param userId the user id
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void setUserId(String userId);

    /**
     * Sets the custom user name.
     * @param userName the username
     */
    void setUserName(String userName);

    /**
     * Enables primary Gmail address collection (and other emails linked to account.)
     * Requires GET_ACCOUNTS permission
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void collectEmails();

    /**
     * Disables primary Gmail address collection (and other emails linked to account.)
     * Requires GET_ACCOUNTS permission
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void clearEmails();

    /**
     * Whether to log TUNE events in the FB SDK as well.
     * @param logging Whether to send TUNE events to FB as well
     * @param limitEventAndDataUsage Whether user opted out of ads targeting
     */
    void setFacebookEventLogging(boolean logging, boolean limitEventAndDataUsage);

    /**
     * Disable auto collection of device location data.
     * Note that location data is auto-collected at initialization if not explicitly disabled.
     * @deprecated data no longer transmitted.  API will be removed in version 7.0.0
     */
    @Deprecated
    void disableLocationAutoCollection();

    /* ========================================================================================== */
    /* Deeplink API                                                                               */
    /* ========================================================================================== */

    /**
     * Remove the deeplink listener previously set with {@link #registerDeeplinkListener(TuneDeeplinkListener)}.
     */
    void unregisterDeeplinkListener();

    /**
     * Set the deeplink listener that will be called when either a deferred deeplink is found for a fresh install or for handling an opened Tune Link.
     * Registering a deeplink listener will trigger an asynchronous call to check for deferred deeplinks
     * during the first session after installing of the app with the Tune SDK.
     * <br>
     * The {@code TuneDeeplinkListener#didFailWithError} callback will be called if there is no
     * deferred deeplink from Tune for this user or in the event of an error from the server
     * (possibly due to misconfiguration).
     * <br>
     * The {@code TuneDeeplinkListener#didReceiveDeeplink} callback will be called when there is a
     * deep link from Tune that you should route the user to. The string should be a fully qualified deep link url string.
     *
     * @param listener will be called with deferred deeplinks after install or expanded Tune links. May be null.
     *                 Passing null will clear the previously set listener, although you may use {@link #unregisterDeeplinkListener()} instead.
     */
    void registerDeeplinkListener(@Nullable TuneDeeplinkListener listener);

    /**
     * If you have set up a custom domain for use with Tune Links (cname to a *.tlnk.io domain), then register it with this method.
     * Tune Links are Tune-hosted App Links. Tune Links are often shared as short-urls, and the Tune SDK
     * will handle expanding the url and returning the in-app destination url to
     * {@link TuneDeeplinkListener#didReceiveDeeplink(String)} registered via
     * {@link #registerDeeplinkListener(TuneDeeplinkListener)}
     * This method will test if any clicked links match the given suffix. Do not include a * for
     * wildcard subdomains, instead pass the suffix that you would like to match against the url.
     * <br>
     * So, ".customize.it" will match "1235.customize.it" and "56789.customize.it" but not "customize.it"
     * And, "customize.it" will match "1235.customize.it" and "56789.customize.it", "customize.it", and "1235.tocustomize.it"
     * You can register as many custom subdomains as you like.
     * @param domainSuffix domain which you are using for Tune Links. Must not be null.
     */
    void registerCustomTuneLinkDomain(@NonNull String domainSuffix);

    /**
     * Test if your custom Tune Link domain is registered with Tune.
     * Tune Links are Tune-hosted App Links. Tune Links are often shared as short-urls, and the Tune SDK
     * will handle expanding the url and returning the in-app destination url to {@link TuneDeeplinkListener#didReceiveDeeplink(String)}
     * registered via {@link #registerDeeplinkListener(TuneDeeplinkListener)}
     * @param appLinkUrl url to test if it is a Tune Link. Must not be null.
     * @return true if this link is a Tune Link that will be measured by Tune and routed into the {@link TuneDeeplinkListener}.
     */
    boolean isTuneLink(@NonNull String appLinkUrl);
}
