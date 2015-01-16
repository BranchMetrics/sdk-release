package com.mobileapptracker;

import java.io.File;
import java.lang.ref.WeakReference;
import java.util.Date;
import java.util.Locale;
import java.util.UUID;

import org.json.JSONArray;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Point;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.view.WindowManager;
import android.webkit.WebView;

public class Parameters {
    // Application context
    private Context mContext;

    private static Parameters INSTANCE = null;

    public Parameters() {
    }
    
    public static void init(Context context, String advertiserId, String conversionKey) {
        if (INSTANCE == null) {
            // Only instantiate and populate common params the first time
            INSTANCE = new Parameters();
            INSTANCE.mContext = context;
            INSTANCE.populateParams(context, advertiserId);
        }
    }
    
    public static Parameters getInstance() {
        return INSTANCE;
    }
    
    public void clear() {
        INSTANCE = null;
    }
    
    /**
     * Helper to populate the device params to send
     * @param context the application Context
     * @param advertiserId the advertiser id in MAT
     * @return whether params were successfully collected or not
     */
    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    private synchronized boolean populateParams(Context context, String advertiserId) {
        try {
            // Strip the whitespace from advertiser id
            setAdvertiserId(advertiserId.trim());

            // Default params
            setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);

            // execute Runnable on UI thread to set user agent
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new GetUserAgent(mContext));

            // Get app package information
            String packageName = mContext.getPackageName();
            setPackageName(packageName);

            // Get app name
            PackageManager pm = mContext.getPackageManager();
            try {
                ApplicationInfo ai = pm.getApplicationInfo(packageName, 0);
                setAppName(pm.getApplicationLabel(ai).toString());

                // Get last modified date of app file as install date
                String appFile = pm.getApplicationInfo(packageName, 0).sourceDir;
                long insdate = new File(appFile).lastModified();
                long installDate = new Date(insdate).getTime()/1000;  // convert ms to s
                setInstallDate(Long.toString(installDate));
            } catch (NameNotFoundException e) {
            }
            // Get app version
            try {
                PackageInfo pi = pm.getPackageInfo(packageName, 0);
                setAppVersion(Integer.toString(pi.versionCode));
            } catch (NameNotFoundException e) {
                setAppVersion("0");
            }
            // Get installer package
            setInstaller(pm.getInstallerPackageName(packageName));

            // Get generic device information
            setDeviceModel(Build.MODEL);
            setDeviceBrand(Build.MANUFACTURER);
            setDeviceCpuType(System.getProperty("os.arch"));
            //setDeviceCpuSubtype(SystemProperties.get("ro.product.cpu.abi"));
            setOsVersion(Build.VERSION.RELEASE);
            // Screen density
            float density = context.getResources().getDisplayMetrics().density;
            setScreenDensity(Float.toString(density));
            WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            int width;
            int height;
            // Screen layout size
            if (android.os.Build.VERSION.SDK_INT >= 13) {
                Point size = new Point();
                wm.getDefaultDisplay().getSize(size);
                width = size.x;
                height = size.y;
            } else {
                width = wm.getDefaultDisplay().getWidth();
                height = wm.getDefaultDisplay().getHeight();
            }
            setScreenWidth(Integer.toString(width));
            setScreenHeight(Integer.toString(height));

            // Set the device connection type, WIFI or mobile
            ConnectivityManager connManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
            if (mWifi.isConnected()) {
                setConnectionType("WIFI");
            } else {
                setConnectionType("mobile");
            }

            // Network and locale info
            setLanguage(Locale.getDefault().getDisplayLanguage(Locale.US));
            TelephonyManager tm = (TelephonyManager) mContext.getSystemService(Context.TELEPHONY_SERVICE);
            if (tm != null) {
                if (tm.getNetworkCountryIso() != null) {
                    setCountryCode(tm.getNetworkCountryIso());
                }
                setDeviceCarrier(tm.getNetworkOperatorName());

                // Set Mobile Country Code and Mobile Network Code
                String networkOperator = tm.getNetworkOperator();
                if (networkOperator != null) {
                    try {
                        String mcc = networkOperator.substring(0, 3);
                        String mnc = networkOperator.substring(3);
                        setMCC(mcc);
                        setMNC(mnc);
                    } catch (IndexOutOfBoundsException e) {
                    }
                }
            } else {
                setCountryCode(Locale.getDefault().getCountry());
            }

            // Set the MAT ID, from existing or generate a new UUID
            String matId = getMatId();
            if (matId == null || matId.length() == 0) {
                // generate MAT ID once and save in shared preferences
                setMatId(UUID.randomUUID().toString());
            }
            
            return true;
        } catch (Exception e) {
            Log.d(MATConstants.TAG, "MobileAppTracker initialization failed");
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     *  Runnable for creating a WebView and getting the device user agent
     */
    private class GetUserAgent implements Runnable {
        private final WeakReference<Context> weakContext;

        public GetUserAgent(Context context) {
            weakContext = new WeakReference<Context>(context);
        }

        public void run() {
            try {
                // Create WebView to set user agent, then destroy WebView
                WebView wv = new WebView(weakContext.get());
                String userAgent = wv.getSettings().getUserAgentString();
                wv.destroy();
                setUserAgent(userAgent);
            } catch (Exception e) {
            }
        }
    }
    
    /**
     * Reset attributes that are specific to only one event.
     */
    public synchronized void resetAfterRequest() {
        setEventId(null);
        setEventName(null);
        setRevenue(null);
        setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);
        setRefId(null);
        setEventContentType(null);
        setEventContentId(null);
        setEventLevel(null);
        setEventQuantity(null);
        setEventSearchString(null);
        setEventRating(null);
        setEventDate1(null);
        setEventDate2(null);
        setEventAttribute1(null);
        setEventAttribute2(null);
        setEventAttribute3(null);
        setEventAttribute4(null);
        setEventAttribute5(null);
        
        // Clear any pre-loaded attribution values
        setPublisherId(null);
        setOfferId(null);
        setPublisherReferenceId(null);
        setPublisherSub1(null);
        setPublisherSub2(null);
        setPublisherSub3(null);
        setPublisherSub4(null);
        setPublisherSub5(null);
        setPublisherSubAd(null);
        setPublisherSubAdgroup(null);
        setPublisherSubCampaign(null);
        setPublisherSubKeyword(null);
        setPublisherSubPublisher(null);
        setPublisherSubSite(null);
        setAdvertiserSubAd(null);
        setAdvertiserSubAdgroup(null);
        setAdvertiserSubCampaign(null);
        setAdvertiserSubKeyword(null);
        setAdvertiserSubPublisher(null);
        setAdvertiserSubSite(null);
    }
    
    /*
     * Param storage
     */

    private String mAction = null;
    public synchronized String getAction() {
        return mAction;
    }
    public synchronized void setAction(String action) {
        mAction = action;
    }

    private String mAdvertiserId = null;
    public synchronized String getAdvertiserId() {
        return mAdvertiserId;
    }
    public synchronized void setAdvertiserId(String advertiserId) {
        mAdvertiserId = advertiserId;
    }

    private String mAge = null;
    public synchronized String getAge() {
        return mAge;
    }
    public synchronized void setAge(String age) {
        mAge = age;
    }
    
    private String mAllowDups = null;
    public synchronized String getAllowDuplicates() {
        return mAllowDups;
    }
    public synchronized void setAllowDuplicates(String allowDuplicates) {
        mAllowDups = allowDuplicates;
    }

    private String mAltitude = null;
    public synchronized String getAltitude() {
        return mAltitude;
    }
    public synchronized void setAltitude(String altitude) {
        mAltitude = altitude;
    }

    private String mAndroidId = null;
    public synchronized String getAndroidId() {
        return mAndroidId;
    }
    public synchronized void setAndroidId(String androidId) {
        mAndroidId = androidId;
    }
    
    private String mAndroidIdMd5 = null;
    public synchronized String getAndroidIdMd5() {
        return mAndroidIdMd5;
    }
    public synchronized void setAndroidIdMd5(String androidIdMd5) {
        mAndroidIdMd5 = androidIdMd5;
    }
    
    private String mAndroidIdSha1 = null;
    public synchronized String getAndroidIdSha1() {
        return mAndroidIdSha1;
    }
    public synchronized void setAndroidIdSha1(String androidIdSha1) {
        mAndroidIdSha1 = androidIdSha1;
    }
    
    private String mAndroidIdSha256 = null;
    public synchronized String getAndroidIdSha256() {
        return mAndroidIdSha256;
    }
    public synchronized void setAndroidIdSha256(String androidIdSha256) {
        mAndroidIdSha256 = androidIdSha256;
    }
    
    private String mAppAdTracking = null;
    public synchronized String getAppAdTrackingEnabled() {
        return mAppAdTracking;
    }
    public synchronized void setAppAdTrackingEnabled(String adTrackingEnabled) {
        mAppAdTracking = adTrackingEnabled;
    }

    private String mAppName = null;
    public synchronized String getAppName() {
        return mAppName;
    }
    public synchronized void setAppName(String app_name) {
        mAppName = app_name;
    }

    private String mAppVersion = null;
    public synchronized String getAppVersion() {
        return mAppVersion;
    }
    public synchronized void setAppVersion(String appVersion) {
        mAppVersion = appVersion;
    }

    private String mConnectionType = null;
    public synchronized String getConnectionType() {
        return mConnectionType;
    }
    public synchronized void setConnectionType(String connection_type) {
        mConnectionType = connection_type;
    }

    private String mCountryCode = null;
    public synchronized String getCountryCode() {
        return mCountryCode;
    }
    public synchronized void setCountryCode(String countryCode) {
        mCountryCode = countryCode;
    }

    private String mCurrencyCode = null;
    public synchronized String getCurrencyCode() {
        return mCurrencyCode;
    }
    public synchronized void setCurrencyCode(String currencyCode) {
        mCurrencyCode = currencyCode;
    }

    private String mDeviceBrand = null;
    public synchronized String getDeviceBrand() {
        return mDeviceBrand;
    }
    public synchronized void setDeviceBrand(String deviceBrand) {
        mDeviceBrand = deviceBrand;
    }

    private String mDeviceCarrier = null;
    public synchronized String getDeviceCarrier() {
        return mDeviceCarrier;
    }
    public synchronized void setDeviceCarrier(String carrier) {
        mDeviceCarrier = carrier;
    }

    private String mDeviceCpuType = null;
    public synchronized String getDeviceCpuType() {
        return mDeviceCpuType;
    }
    public synchronized void setDeviceCpuType(String cpuType) {
        mDeviceCpuType = cpuType;
    }

    private String mDeviceCpuSubtype = null;
    public synchronized String getDeviceCpuSubtype() {
        return mDeviceCpuSubtype;
    }
    public synchronized void setDeviceCpuSubtype(String cpuType) {
        mDeviceCpuSubtype = cpuType;
    }

    private String mDeviceId = null;
    public synchronized String getDeviceId() {
        return mDeviceId;
    }
    public synchronized void setDeviceId(String deviceId) {
        mDeviceId = deviceId;
    }
    
    private String mDeviceModel = null;
    public synchronized String getDeviceModel() {
        return mDeviceModel;
    }
    public synchronized void setDeviceModel(String model) {
        mDeviceModel = model;
    }

    private String mEventAttribute1 = null;
    public synchronized String getEventAttribute1() {
        return mEventAttribute1;
    }
    public synchronized void setEventAttribute1(String value) {
        mEventAttribute1 = value;
    }

    private String mEventAttribute2 = null;
    public synchronized String getEventAttribute2() {
        return mEventAttribute2;
    }
    public synchronized void setEventAttribute2(String value) {
        mEventAttribute2 = value;
    }

    private String mEventAttribute3 = null;
    public synchronized String getEventAttribute3() {
        return mEventAttribute3;
    }
    public synchronized void setEventAttribute3(String value) {
        mEventAttribute3 = value;
    }

    private String mEventAttribute4 = null;
    public synchronized String getEventAttribute4() {
        return mEventAttribute4;
    }
    public synchronized void setEventAttribute4(String value) {
        mEventAttribute4 = value;
    }

    private String mEventAttribute5 = null;
    public synchronized String getEventAttribute5() {
        return mEventAttribute5;
    }
    public synchronized void setEventAttribute5(String value) {
        mEventAttribute5 = value;
    }

    private String mEventContentId = null;
    public synchronized String getEventContentId() {
        return mEventContentId;
    }
    public synchronized void setEventContentId(String contentId) {
        mEventContentId = contentId;
    }

    private String mEventContentType = null;
    public synchronized String getEventContentType() {
        return mEventContentType;
    }
    public synchronized void setEventContentType(String contentType) {
        mEventContentType = contentType;
    }

    private String mEventDate1 = null;
    public synchronized String getEventDate1() {
        return mEventDate1;
    }
    public synchronized void setEventDate1(String date) {
        mEventDate1 = date;
    }

    private String mEventDate2 = null;
    public synchronized String getEventDate2() {
        return mEventDate2;
    }
    public synchronized void setEventDate2(String date) {
        mEventDate2 = date;
    }

    private String mEventId = null;
    public synchronized String getEventId() {
        return mEventId;
    }
    public synchronized void setEventId(String eventId) {
        mEventId = eventId;
    }

    private String mEventLevel = null;
    public synchronized String getEventLevel() {
        return mEventLevel;
    }
    public synchronized void setEventLevel(String level) {
        mEventLevel = level;
    }

    private String mEventName = null;
    public synchronized String getEventName() {
        return mEventName;
    }
    public synchronized void setEventName(String eventName) {
        mEventName = eventName;
    }

    private String mEventQuantity = null;
    public synchronized String getEventQuantity() {
        return mEventQuantity;
    }
    public synchronized void setEventQuantity(String quantity) {
        mEventQuantity = quantity;
    }

    private String mEventRating = null;
    public synchronized String getEventRating() {
        return mEventRating;
    }      
    public synchronized void setEventRating(String rating) {
        mEventRating = rating;
    }
    
    private String mEventSearchString = null;
    public synchronized String getEventSearchString() {
        return mEventSearchString;
    }
    public synchronized void setEventSearchString(String searchString) {
        mEventSearchString = searchString;
    }

    private String mExistingUser = null;
    public synchronized String getExistingUser() {
        return mExistingUser;
    }
    public synchronized void setExistingUser(String existingUser) {
        mExistingUser = existingUser;
    }

    private String mFbUserId = null;
    public synchronized String getFacebookUserId() {
        return mFbUserId;
    }
    public synchronized void setFacebookUserId(String fb_user_id) {
        mFbUserId = fb_user_id;
    }

    private String mGender = null;
    public synchronized String getGender() {
        return mGender;
    }
    public synchronized void setGender(String gender) {
        mGender = gender;
    }

    private String mGaid = null;
    public synchronized String getGoogleAdvertisingId() {
        return mGaid;
    }
    public synchronized void setGoogleAdvertisingId(String adId) {
        mGaid = adId;
    }

    private String mGaidLimited = null;
    public synchronized String getGoogleAdTrackingLimited() {
        return mGaidLimited;
    }
    public synchronized void setGoogleAdTrackingLimited(String limited) {
        mGaidLimited = limited;
    }

    private String mGgUserId = null;
    public synchronized String getGoogleUserId() {
        return mGgUserId;
    }
    public synchronized void setGoogleUserId(String google_user_id) {
        mGgUserId = google_user_id;
    }

    private String mInstallDate = null;
    public synchronized String getInstallDate() {
        return mInstallDate;
    }
    public synchronized void setInstallDate(String installDate) {
        mInstallDate = installDate;
    }
    
    private String mInstallerPackage = null;
    public synchronized String getInstaller() {
        return mInstallerPackage;
    }
    public synchronized void setInstaller(String installer) {
        mInstallerPackage = installer;
    }

    public synchronized String getInstallLogId() {
        return getStringFromSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, MATConstants.PREFS_LOG_ID_KEY);
    }
    // no setter

    public synchronized String getInstallReferrer() {
        return getStringFromSharedPreferences(MATConstants.PREFS_REFERRER, "referrer");
    }
    public synchronized void setInstallReferrer(String installReferrer) {
        saveToSharedPreferences(MATConstants.PREFS_REFERRER, "referrer", installReferrer);
    }

    public synchronized String getIsPayingUser() {
        return getStringFromSharedPreferences(MATConstants.PREFS_IS_PAYING_USER, MATConstants.PREFS_IS_PAYING_USER);
    }
    public synchronized void setIsPayingUser(String isPayingUser) {
        saveToSharedPreferences(MATConstants.PREFS_IS_PAYING_USER, MATConstants.PREFS_IS_PAYING_USER, isPayingUser);
    }

    private String mLanguage = null;
    public synchronized String getLanguage() {
        return mLanguage;
    }
    public synchronized void setLanguage(String language) {
        mLanguage = language;
    }

    public synchronized String getLastOpenLogId() {
        return getStringFromSharedPreferences(MATConstants.PREFS_LOG_ID_LAST_OPEN, MATConstants.PREFS_LOG_ID_KEY);
    }
    public synchronized void setLastOpenLogId(String logId) {
        saveToSharedPreferences(MATConstants.PREFS_LOG_ID_LAST_OPEN, MATConstants.PREFS_LOG_ID_KEY, logId);
    }

    private String mLatitude = null;
    public synchronized String getLatitude() {
        return mLatitude;
    }
    public synchronized void setLatitude(String latitude) {
        mLatitude = latitude;
    }

    private Location mLocation = null;
    public synchronized Location getLocation() {
        return mLocation;
    }
    public synchronized void setLocation(Location location) {
        mLocation = location;
    }

    private String mLongitude = null;
    public synchronized String getLongitude() {
        return mLongitude;
    }
    public synchronized void setLongitude(String longitude) {
        mLongitude = longitude;
    }

    private String mMacAddress = null;
    public synchronized String getMacAddress() {
        return mMacAddress;
    }
    public synchronized void setMacAddress(String mac_address) {
        mMacAddress = mac_address;
    }

    public synchronized String getMatId() {
        return getStringFromSharedPreferences(MATConstants.PREFS_MAT_ID, MATConstants.PREFS_MAT_ID);
    }
    public synchronized void setMatId(String matId) {
        saveToSharedPreferences(MATConstants.PREFS_MAT_ID, MATConstants.PREFS_MAT_ID, matId);
    }

    private String mMCC = null;
    public synchronized String getMCC() {
        return mMCC;
    }
    public synchronized void setMCC(String mcc) {
        mMCC = mcc;
    }

    private String mMNC = null;
    public synchronized String getMNC() {
        return mMNC;
    }
    public synchronized void setMNC(String mnc) {
        mMNC = mnc;
    }

    public synchronized String getOpenLogId() {
        return getStringFromSharedPreferences(MATConstants.PREFS_LOG_ID_OPEN, MATConstants.PREFS_LOG_ID_KEY);
    }
    public synchronized void setOpenLogId(String logId) {
        saveToSharedPreferences(MATConstants.PREFS_LOG_ID_OPEN, MATConstants.PREFS_LOG_ID_KEY, logId);
    }

    private String mOsVersion = null;
    public synchronized String getOsVersion() {
        return mOsVersion;
    }
    public synchronized void setOsVersion(String osVersion) {
        mOsVersion = osVersion;
    }

    private String mPackageName = null;
    public synchronized String getPackageName() {
        return mPackageName;
    }
    public synchronized void setPackageName(String packageName) {
        mPackageName = packageName;
    }

    private String mPluginName = null;
    public synchronized String getPluginName() {
        return mPluginName;
    }
    public synchronized void setPluginName(String pluginName) {
        mPluginName = null;
    }
    
    private String mPurchaseStatus = null;
    public synchronized String getPurchaseStatus() {
        return mPurchaseStatus;
    }
    public synchronized void setPurchaseStatus(String purchaseStatus) {
        mPurchaseStatus = purchaseStatus;
    }

    private String mReferralSource = null;
    public synchronized String getReferralSource() {
        return mReferralSource;
    }
    public synchronized void setReferralSource(String referralPackage) {
        mReferralSource = referralPackage;
    }

    private String mReferralUrl = null;
    public synchronized String getReferralUrl() {
        return mReferralUrl;
    }
    public synchronized void setReferralUrl(String referralUrl) {
        mReferralUrl = referralUrl;
    }

    private String mRefId = null;
    public synchronized String getRefId() {
        return mRefId;
    }
    public synchronized void setRefId(String refId) {
        mRefId = refId;
    }

    private String mRevenue = null;
    public synchronized String getRevenue() {
        return mRevenue;
    }
    public synchronized void setRevenue(String revenue) {
        mRevenue = revenue;
    }

    private String mScreenDensity = null;
    public synchronized String getScreenDensity() {
        return mScreenDensity;
    }
    public synchronized void setScreenDensity(String density) {
        mScreenDensity = density;
    }

    private String mScreenHeight = null;
    public synchronized String getScreenHeight() {
        return mScreenHeight;
    }
    public synchronized void setScreenHeight(String screenheight) {
        mScreenHeight = screenheight;
    }

    private String mScreenWidth = null;
    public synchronized String getScreenWidth() {
        return mScreenWidth;
    }
    public synchronized void setScreenWidth(String screenwidth) {
        mScreenWidth = screenwidth;
    }

    public synchronized String getSdkVersion() {
        return MATConstants.SDK_VERSION;
    }
    // no setter

    private String mSiteId = null;
    public synchronized String getSiteId() {
        return mSiteId;
    }
    public synchronized void setSiteId(String siteId) {
        mSiteId = siteId;
    }
    
    private String mTrackingId = null;
    public synchronized String getTrackingId() {
        return mTrackingId;
    }
    public synchronized void setTrackingId(String trackingId) {
        mTrackingId = trackingId;
    }

    private String mTrusteId = null;
    public synchronized String getTRUSTeId() {
        return mTrusteId;
    }
    public synchronized void setTRUSTeId(String tpid) {
        mTrusteId = tpid;
    }

    private String mTwUserId = null;
    public synchronized String getTwitterUserId() {
        return mTwUserId;
    }
    public synchronized void setTwitterUserId(String twitter_user_id) {
        mTwUserId = twitter_user_id;
    }

    public synchronized String getUpdateLogId() {
        return getStringFromSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, MATConstants.PREFS_LOG_ID_KEY);
    }
    // no setter

    private String mUserAgent = null;
    public synchronized String getUserAgent() {
        return mUserAgent;
    }
    private void setUserAgent(String userAgent) {
        mUserAgent = userAgent;
    }

    public synchronized String getUserEmail() {
        return getStringFromSharedPreferences(MATConstants.PREFS_USER_IDS, "user_email");
    }
    public synchronized void setUserEmail(String user_email) {
        saveToSharedPreferences(MATConstants.PREFS_USER_IDS, "user_email", user_email);
    }
    
    private JSONArray mUserEmails = null;
    public synchronized JSONArray getUserEmails() {
        return mUserEmails;
    }
    public synchronized void setUserEmails(String[] emails) {
        mUserEmails = new JSONArray();
        for (int i = 0; i < emails.length; i++) {
            mUserEmails.put(emails[i]);
        }
    }

    public synchronized String getUserId() {
        return getStringFromSharedPreferences(MATConstants.PREFS_USER_IDS, "user_id");
    }
    public synchronized void setUserId(String user_id) {
        saveToSharedPreferences(MATConstants.PREFS_USER_IDS, "user_id", user_id);
    }

    public synchronized String getUserName() {
        return getStringFromSharedPreferences(MATConstants.PREFS_USER_IDS, "user_name");
    }
    public synchronized void setUserName(String user_name) {
        saveToSharedPreferences(MATConstants.PREFS_USER_IDS, "user_name", user_name);
    }
    
    /*
     * Publisher pre-loaded params
     */
    private String mOfferId = null;
    public synchronized String getOfferId() {
        return mOfferId;
    }
    public synchronized void setOfferId(String offerId) {
        mOfferId = offerId;
    }
    
    private String mPublisherId = null;
    public synchronized String getPublisherId() {
        return mPublisherId;
    }
    public synchronized void setPublisherId(String publisherId) {
        mPublisherId = publisherId;
    }

    private String mPublisherRefId = null;
    public synchronized String getPublisherReferenceId() {
        return mPublisherRefId;
    }
    public synchronized void setPublisherReferenceId(String publisherRefId) {
        mPublisherRefId = publisherRefId;
    }
    
    private String mAdvertiserSubPub = null;
    public synchronized String getAdvertiserSubPublisher() {
        return mAdvertiserSubPub;
    }
    public synchronized void setAdvertiserSubPublisher(String subPublisher) {
        mAdvertiserSubPub = subPublisher;
    }
    
    private String mAdvertiserSubSite = null;
    public synchronized String getAdvertiserSubSite() {
        return mAdvertiserSubSite;
    }
    public synchronized void setAdvertiserSubSite(String subSite) {
        mAdvertiserSubSite = subSite;
    }
    
    private String mAdvertiserSubCampaign = null;
    public synchronized String getAdvertiserSubCampaign() {
        return mAdvertiserSubCampaign;
    }
    public synchronized void setAdvertiserSubCampaign(String subCampaign) {
        mAdvertiserSubCampaign = subCampaign;
    }
    
    private String mAdvertiserSubAdgroup = null;
    public synchronized String getAdvertiserSubAdgroup() {
        return mAdvertiserSubAdgroup;
    }
    public synchronized void setAdvertiserSubAdgroup(String subAdgroup) {
        mAdvertiserSubAdgroup = subAdgroup;
    }
    
    private String mAdvertiserSubAd = null;
    public synchronized String getAdvertiserSubAd() {
        return mAdvertiserSubAd;
    }
    public synchronized void setAdvertiserSubAd(String subAd) {
        mAdvertiserSubAd = subAd;
    }
    
    private String mAdvertiserSubKeyword = null;
    public synchronized String getAdvertiserSubKeyword() {
        return mAdvertiserSubKeyword;
    }
    public synchronized void setAdvertiserSubKeyword(String subKeyword) {
        mAdvertiserSubKeyword = subKeyword;
    }
    
    private String mPublisherSubPub = null;
    public synchronized String getPublisherSubPublisher() {
        return mPublisherSubPub;
    }
    public synchronized void setPublisherSubPublisher(String subPublisher) {
        mPublisherSubPub = subPublisher;
    }
    
    private String mPublisherSubSite = null;
    public synchronized String getPublisherSubSite() {
        return mPublisherSubSite;
    }
    public synchronized void setPublisherSubSite(String subSite) {
        mPublisherSubSite = subSite;
    }
    
    private String mPublisherSubCampaign = null;
    public synchronized String getPublisherSubCampaign() {
        return mPublisherSubCampaign;
    }
    public synchronized void setPublisherSubCampaign(String subCampaign) {
        mPublisherSubCampaign = subCampaign;
    }
    
    private String mPublisherSubAdgroup = null;
    public synchronized String getPublisherSubAdgroup() {
        return mPublisherSubAdgroup;
    }
    public synchronized void setPublisherSubAdgroup(String subAdgroup) {
        mPublisherSubAdgroup = subAdgroup;
    }
    
    private String mPublisherSubAd = null;
    public synchronized String getPublisherSubAd() {
        return mPublisherSubAd;
    }
    public synchronized void setPublisherSubAd(String subAd) {
        mPublisherSubAd = subAd;
    }
    
    private String mPublisherSubKeyword = null;
    public synchronized String getPublisherSubKeyword() {
        return mPublisherSubKeyword;
    }
    public synchronized void setPublisherSubKeyword(String subKeyword) {
        mPublisherSubKeyword = subKeyword;
    }
    
    private String mPublisherSub1 = null;
    public synchronized String getPublisherSub1() {
        return mPublisherSub1;
    }
    public synchronized void setPublisherSub1(String sub1) {
        mPublisherSub1 = sub1;
    }
    
    private String mPublisherSub2 = null;
    public synchronized String getPublisherSub2() {
        return mPublisherSub2;
    }
    public synchronized void setPublisherSub2(String sub2) {
        mPublisherSub2 = sub2;
    }
    
    private String mPublisherSub3 = null;
    public synchronized String getPublisherSub3() {
        return mPublisherSub3;
    }
    public synchronized void setPublisherSub3(String sub3) {
        mPublisherSub3 = sub3;
    }
    
    private String mPublisherSub4 = null;
    public synchronized String getPublisherSub4() {
        return mPublisherSub4;
    }
    public synchronized void setPublisherSub4(String sub4) {
        mPublisherSub4 = sub4;
    }
    
    private String mPublisherSub5 = null;
    public synchronized String getPublisherSub5() {
        return mPublisherSub5;
    }
    public synchronized void setPublisherSub5(String sub5) {
        mPublisherSub5 = sub5;
    }

    /*
     * Helper functions for shared prefs
     */
    
    private synchronized void saveToSharedPreferences(String prefsName, String prefsKey, String prefsValue) {
        mContext.getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit().putString(prefsKey, prefsValue).commit();
    }

    private synchronized String getStringFromSharedPreferences(String prefsName, String prefsKey) {
        return mContext.getSharedPreferences(prefsName, Context.MODE_PRIVATE).getString(prefsKey, "");
    }
}
