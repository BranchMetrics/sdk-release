package com.mobileapptracker;

import java.io.File;
import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;
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
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.view.WindowManager;
import android.webkit.WebView;

public class MATParameters {
    // Application context
    private Context mContext;
    // Tune SDK instance
    private MobileAppTracker mTune;

    private static MATParameters INSTANCE = null;

    public MATParameters() {
    }
    
    public static MATParameters init(MobileAppTracker tune, Context context, String advertiserId, String conversionKey) {
        if (INSTANCE == null) {
            // Only instantiate and populate common params the first time
            INSTANCE = new MATParameters();
            INSTANCE.mTune = tune;
            INSTANCE.mContext = context;
            INSTANCE.populateParams(context, advertiserId, conversionKey);
        }
        return INSTANCE;
    }
    
    public static MATParameters getInstance() {
        return INSTANCE;
    }
    
    public void clear() {
        INSTANCE = null;
    }
    
    /**
     * Helper to populate the device params to send
     * @param context the application Context
     * @param advertiserId the advertiser id in MAT
     * @param conversionKey the conversion key in MAT
     * @return whether params were successfully collected or not
     */
    @SuppressWarnings( "deprecation" )
    @SuppressLint("NewApi")
    private synchronized boolean populateParams(Context context, String advertiserId, String conversionKey) {
        try {
            // Strip the whitespace from advertiser id and key
            setAdvertiserId(advertiserId.trim());
            setConversionKey(conversionKey.trim());

            // Default params
            setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);

            new Thread(new GetGAID(context)).start();
            
            // Execute Runnable on UI thread to set user agent
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
                setAppVersionName(pi.versionName);
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

            // Set the device connection type, wifi or mobile
            ConnectivityManager connManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
            if (mWifi.isConnected()) {
                setConnectionType("wifi");
            } else {
                setConnectionType("mobile");
            }

            // Network and locale info
            setLanguage(Locale.getDefault().getLanguage());
            setCountryCode(Locale.getDefault().getCountry());
            setTimeZone(TimeZone.getDefault().getDisplayName(false, TimeZone.SHORT, Locale.US));
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
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
            Log.d(MATConstants.TAG, "MobileAppTracking params initialization failed");
            e.printStackTrace();
            return false;
        }
    }
    
    private class GetGAID implements Runnable {
        private final WeakReference<Context> weakContext;
        
        public GetGAID(Context context) {
            weakContext = new WeakReference<Context>(context);
        }
        
        public void run() {
            try {
                Class<?>[] adIdMethodParams = new Class[1];
                adIdMethodParams[0] = Context.class;
                
                // Call the AdvertisingIdClient's getAdvertisingIdInfo method with Context
                Method adIdMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient").getDeclaredMethod("getAdvertisingIdInfo", Context.class);
                Object adInfo = adIdMethod.invoke(null, new Object[] { weakContext.get() });
                
                Method getIdMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info").getDeclaredMethod("getId");
                String adId = (String) getIdMethod.invoke(adInfo);
                
                Method getLATMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info").getDeclaredMethod("isLimitAdTrackingEnabled");
                boolean isLAT = ((Boolean) getLATMethod.invoke(adInfo)).booleanValue();
                
                // mTune's params may not be initialized by the time this thread finishes
                if (mTune.params == null) {
                    // Call the setters manually
                    setGoogleAdvertisingId(adId);
                    int intLimit = isLAT? 1 : 0;
                    setGoogleAdTrackingLimited(Integer.toString(intLimit));
                }
                // Set GAID in SDK singleton
                mTune.setGoogleAdvertisingId(adId, isLAT);
            } catch (Exception e) {
                e.printStackTrace();
                Log.d(MATConstants.TAG, "MAT SDK failed to get Google Advertising Id, collecting ANDROID_ID instead");
                
                // mTune's params may not be initialized by the time this thread finishes
                if (mTune.params == null) {
                    // Call the setter manually
                    setAndroidId(Secure.getString(weakContext.get().getContentResolver(), Secure.ANDROID_ID));
                }
                // Set ANDROID_ID in SDK singleton, in order to set ANDROID_ID for dplinkr
                mTune.setAndroidId(Secure.getString(weakContext.get().getContentResolver(), Secure.ANDROID_ID));
            }
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
            } catch (VerifyError e) {
                // Some device vendors have their own WebView implementation which crashes on our init
            }
        }
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

    private String mAppVersionName = null;
    public synchronized String getAppVersionName() {
        return mAppVersionName;
    }
    public synchronized void setAppVersionName(String appVersionName) {
        mAppVersionName = appVersionName;
    }

    private String mConnectionType = null;
    public synchronized String getConnectionType() {
        return mConnectionType;
    }
    public synchronized void setConnectionType(String connection_type) {
        mConnectionType = connection_type;
    }

    private String mConversionKey = null;
    public synchronized String getConversionKey() {
        return mConversionKey;
    }
    public synchronized void setConversionKey(String conversionKey) {
        mConversionKey = conversionKey;
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

    private boolean mDebugMode = false;
    public synchronized boolean getDebugMode() {
        return mDebugMode;
    }
    public synchronized void setDebugMode(boolean debug) {
        mDebugMode = debug;
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
    public synchronized void setGender(MATGender gender) {
        if (gender == MATGender.MALE) {
            mGender = "0";
        } else if (gender == MATGender.FEMALE) {
            mGender = "1";
        } else {
            mGender = "";
        }
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

    public synchronized String getInstallReferrer() {
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_REFERRER);
    }
    public synchronized void setInstallReferrer(String installReferrer) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_REFERRER, installReferrer);
    }
    
    public synchronized String getIsPayingUser() {
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_PAYING_USER);
    }
    public synchronized void setIsPayingUser(String isPayingUser) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_PAYING_USER, isPayingUser);
    }

    private String mLanguage = null;
    public synchronized String getLanguage() {
        return mLanguage;
    }
    public synchronized void setLanguage(String language) {
        mLanguage = language;
    }

    public synchronized String getLastOpenLogId() {
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_LAST_LOG_ID);
    }
    public synchronized void setLastOpenLogId(String logId) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_LAST_LOG_ID, logId);
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
        if (mContext.getSharedPreferences("mat_id", Context.MODE_PRIVATE).contains("mat_id")) {
            return mContext.getSharedPreferences("mat_id", Context.MODE_PRIVATE).getString("mat_id", "");
        }
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_MAT_ID);
    }
    public synchronized void setMatId(String matId) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_MAT_ID, matId);
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
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_LOG_ID);
    }
    public synchronized void setOpenLogId(String logId) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_LOG_ID, logId);
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
    
    public synchronized String getPhoneNumber() {
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_PHONE_NUMBER);
    }
    public synchronized void setPhoneNumber(String phoneNumber) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_PHONE_NUMBER, phoneNumber);
        setPhoneNumberMd5(MATUtils.md5(phoneNumber));
        setPhoneNumberSha1(MATUtils.sha1(phoneNumber));
        setPhoneNumberSha256(MATUtils.sha256(phoneNumber));
    }
    
    private String mPhoneNumberMd5;
    public synchronized String getPhoneNumberMd5() {
        return mPhoneNumberMd5;
    }
    public synchronized void setPhoneNumberMd5(String phoneNumberMd5) {
        mPhoneNumberMd5 = phoneNumberMd5;
    }
    
    private String mPhoneNumberSha1;
    public synchronized String getPhoneNumberSha1() {
        return mPhoneNumberSha1;
    }
    public synchronized void setPhoneNumberSha1(String phoneNumberSha1) {
        mPhoneNumberSha1 = phoneNumberSha1;
    }
    
    private String mPhoneNumberSha256;
    public synchronized String getPhoneNumberSha256() {
        return mPhoneNumberSha256;
    }
    public synchronized void setPhoneNumberSha256(String phoneNumberSha256) {
        mPhoneNumberSha256 = phoneNumberSha256;
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

    private String mReferrerDelay = null;
    public synchronized String getReferrerDelay() {
        return mReferrerDelay;
    }
    public synchronized void setReferrerDelay(long referrerDelay) {
        mReferrerDelay = Long.toString(referrerDelay);
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

    private String mTimeZone = null;
    public synchronized String getTimeZone() {
        return mTimeZone;
    }
    public synchronized void setTimeZone(String timeZone) {
        mTimeZone = timeZone;
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

    private String mUserAgent = null;
    public synchronized String getUserAgent() {
        return mUserAgent;
    }
    private void setUserAgent(String userAgent) {
        mUserAgent = userAgent;
    }
    
    public synchronized String getUserEmail() {
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_USER_EMAIL);
    }
    public synchronized void setUserEmail(String userEmail) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_USER_EMAIL, userEmail);
        setUserEmailMd5(MATUtils.md5(userEmail));
        setUserEmailSha1(MATUtils.sha1(userEmail));
        setUserEmailSha256(MATUtils.sha256(userEmail));
    }
    
    private String mUserEmailMd5;
    public synchronized String getUserEmailMd5() {
        return mUserEmailMd5;
    }
    public synchronized void setUserEmailMd5(String userEmailMd5) {
        mUserEmailMd5 = userEmailMd5;
    }
    
    private String mUserEmailSha1;
    public synchronized String getUserEmailSha1() {
        return mUserEmailSha1;
    }
    public synchronized void setUserEmailSha1(String userEmailSha1) {
        mUserEmailSha1 = userEmailSha1;
    }
    
    private String mUserEmailSha256;
    public synchronized String getUserEmailSha256() {
        return mUserEmailSha256;
    }
    public synchronized void setUserEmailSha256(String userEmailSha256) {
        mUserEmailSha256 = userEmailSha256;
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
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_USER_ID);
    }
    public synchronized void setUserId(String user_id) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_USER_ID, user_id);
    }

    public synchronized String getUserName() {
        return MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_USER_NAME);
    }
    public synchronized void setUserName(String userName) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_USER_NAME, userName);
        setUserNameMd5(MATUtils.md5(userName));
        setUserNameSha1(MATUtils.sha1(userName));
        setUserNameSha256(MATUtils.sha256(userName));
    }
    
    private String mUserNameMd5;
    public synchronized String getUserNameMd5() {
        return mUserNameMd5;
    }
    public synchronized void setUserNameMd5(String userNameMd5) {
        mUserNameMd5 = userNameMd5;
    }
    
    private String mUserNameSha1;
    public synchronized String getUserNameSha1() {
        return mUserNameSha1;
    }
    public synchronized void setUserNameSha1(String userNameSha1) {
        mUserNameSha1 = userNameSha1;
    }
    
    private String mUserNameSha256;
    public synchronized String getUserNameSha256() {
        return mUserNameSha256;
    }
    public synchronized void setUserNameSha256(String userNameSha256) {
        mUserNameSha256 = userNameSha256;
    }
}
