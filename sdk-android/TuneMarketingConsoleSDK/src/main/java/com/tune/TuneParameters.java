package com.tune;

import android.annotation.SuppressLint;
import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.webkit.WebSettings;
import android.webkit.WebView;

import com.tune.utils.TuneScreenUtils;
import com.tune.utils.TuneSharedPrefsDelegate;
import com.tune.utils.TuneStringUtils;
import com.tune.utils.TuneUtils;

import org.json.JSONArray;

import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class TuneParameters {
    // Tune SDK instance
    private ITune mTune;
    // Executor Service
    private ExecutorService mExecutor;


    // Actions
    public static final String ACTION_SESSION = "session";
    public static final String ACTION_CLICK = "click";
    public static final String ACTION_CONVERSION = "conversion";

    private TuneSharedPrefsDelegate mPrefs;
    private CountDownLatch initializationComplete;

    TuneParameters() {
    }
    
    public static TuneParameters init(ITune tune, Context context, String advertiserId, String conversionKey, String packageName) {
        TuneParameters INSTANCE = new TuneParameters();

        // Only instantiate and populate common params the first time
        INSTANCE.mTune = tune;
        INSTANCE.mExecutor = Executors.newSingleThreadExecutor();

        // Two primary threads that need to complete
        INSTANCE.initializationComplete = new CountDownLatch(2);

        INSTANCE.mPrefs = new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_TUNE);
        INSTANCE.populateParams(context, advertiserId, conversionKey, packageName);

        INSTANCE.initializationComplete.countDown();

        return INSTANCE;
    }
    
    public void destroy() {
        mExecutor.shutdown();
        try {
            mExecutor.awaitTermination(1, TimeUnit.SECONDS);

            // The executor is done, however it may have posted events.  It is difficult to know
            // when those are done, but without a sleep() here, they generally are *not* done.
            Thread.sleep(100);
        } catch (InterruptedException e) {
        }
        mExecutor = null;
    }

    /**
     * Wait for Initialization to complete.
     * @param milliseconds Number of milliseconds to wait for initialization to complete.
     * @return true if initialization completed in the time frame expected.
     */
    boolean waitForInitComplete(long milliseconds) {
        try {
            initializationComplete.await(milliseconds, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        boolean isComplete = (initializationComplete.getCount() == 0);
        TuneDebugLog.alwaysLog("TuneParameters InitComplete() " + isComplete);

        return isComplete;
    }

    /**
     * Helper to populate the device params to send
     * @param context the application Context
     * @param advertiserId the advertiser id in TUNE
     * @param conversionKey the conversion key in TUNE
     */
    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    private synchronized void populateParams(Context context, String advertiserId, String conversionKey, String packageName) {
        if (TuneStringUtils.isNullOrEmpty(advertiserId) || TuneStringUtils.isNullOrEmpty(conversionKey) || TuneStringUtils.isNullOrEmpty(packageName)) {
            TuneDebugLog.e("Invalid parameters");
            return;
        }

        try {
            // Strip the whitespace from advertiser id and key
            setAdvertiserId(advertiserId.trim());
            setConversionKey(conversionKey.trim());

            // Strip and save the package name
            packageName = packageName.trim();
            setPackageName(packageName);

            // Fetch the Advertising Id in the background
            new Thread(new GetAdvertisingId(context)).start();

            // Retrieve user agent
            calculateUserAgent(context);

            // Set the MAT ID, from existing or generate a new UUID
            String matId = getMatId();
            if (matId == null || matId.length() == 0) {
                matId = UUID.randomUUID().toString();
                setMatId(matId);
            }

            // Get app name
            PackageManager pm = context.getPackageManager();
            try {
                final ApplicationInfo ai = pm.getApplicationInfo(packageName, 0);
                setAppName(pm.getApplicationLabel(ai).toString());
            } catch (NameNotFoundException e) {
            }

            // Get app version
            try {
                PackageInfo pi = pm.getPackageInfo(packageName, 0);
                setAppVersion(Integer.toString(pi.versionCode));
                setAppVersionName(pi.versionName);
                setInstallDate(Long.toString(pi.firstInstallTime / 1000));
            } catch (NameNotFoundException e) {
                setAppVersion("0");
            }
            // Get installer package
            setInstaller(pm.getInstallerPackageName(packageName));

            // Get generic device information
            setDeviceModel(Build.MODEL);
            setDeviceBrand(Build.MANUFACTURER);
            setDeviceBuild(Build.DISPLAY);
            setDeviceCpuType(System.getProperty("os.arch"));
            setOsVersion(Build.VERSION.RELEASE);
            // Screen density
            setScreenDensity(Float.toString(TuneScreenUtils.getScreenDensity(context)));
            // Screen width and height
            setScreenWidth(Integer.toString(TuneScreenUtils.getScreenWidthPixels(context)));
            setScreenHeight(Integer.toString(TuneScreenUtils.getScreenHeightPixels(context)));

            // Set the device connection type, wifi or mobile
            ConnectivityManager connManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (connManager != null) {
                NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
                if (mWifi != null) {
                    if (mWifi.isConnected()) {
                        setConnectionType("wifi");
                    } else {
                        setConnectionType("mobile");
                    }
                }
            }

            // Network and locale info
            // Manually format locale, AdWords sample code is wrong...
            setLocale(Locale.getDefault().getLanguage() + "_" + Locale.getDefault().getCountry());
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

            // User Params
            loadPrivacyProtectedSetting();
        } catch (Exception e) {
            TuneDebugLog.d("MobileAppTracking params initialization failed");
            e.printStackTrace();
        }
    }
    
    /**
     * Determine the device's user agent and set the corresponding field.
     */
    private void calculateUserAgent(Context context) {
        String userAgent = System.getProperty("http.agent", "");
        if (!TuneStringUtils.isNullOrEmpty(userAgent)) {
            setUserAgent(userAgent);
        } else {
            // If system doesn't have user agent,
            // execute Runnable on UI thread to get WebView user agent
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new GetWebViewUserAgent(context));
        }
    }
    
    private class GetAdvertisingId implements Runnable {
        private final WeakReference<Context> weakContext;
        private String deviceId;
        private boolean isLAT = false;
        
        public GetAdvertisingId(Context context) {
            weakContext = new WeakReference<>(context);
        }

        private boolean obtainGoogleAidInfo() {
            try {
                // Call the AdvertisingIdClient's getAdvertisingIdInfo method with Context
                Method adIdMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient").getDeclaredMethod("getAdvertisingIdInfo", Context.class);
                Object adInfo = adIdMethod.invoke(null, new Object[] { weakContext.get() });

                Method getIdMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info").getDeclaredMethod("getId");
                deviceId = (String) getIdMethod.invoke(adInfo);
                // Don't save advertising id if it's all zeroes
                if (deviceId.equals(TuneConstants.UUID_EMPTY)) {
                    deviceId = null;
                }

                Method getLATMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info").getDeclaredMethod("isLimitAdTrackingEnabled");
                isLAT = (Boolean) getLATMethod.invoke(adInfo);

                // Set GAID in SDK singleton
                TuneInternal.getInstance().setGoogleAdvertisingId(deviceId, isLAT);
            } catch (Exception e) {
                TuneDebugLog.d("Failed to get Google AID Info");
            }

            return !TuneStringUtils.isNullOrEmpty(deviceId);
        }

        private boolean obtainFireAidInfo() {
            ContentResolver contentResolver = weakContext.get().getContentResolver();

            try {
                // Get Fire Advertising ID
                deviceId = Secure.getString(contentResolver, TuneConstants.FIRE_ADVERTISING_ID_KEY);
                // Don't save advertising id if it's all zeroes
                if (TuneStringUtils.isNullOrEmpty(deviceId) || deviceId.equals(TuneConstants.UUID_EMPTY)) {
                    deviceId = null;
                }

                // Get Fire limit ad tracking preference
                isLAT = Secure.getInt(contentResolver, TuneConstants.FIRE_LIMIT_AD_TRACKING_KEY) != 0;

                // Set Fire Advertising ID in SDK singleton
                TuneInternal.getInstance().setFireAdvertisingId(deviceId, isLAT);
            } catch (Exception e1) {
                TuneDebugLog.d("Failed to get Fire AID Info");
            }

            return !TuneStringUtils.isNullOrEmpty(deviceId);
        }

        private boolean obtainDefaultAidInfo() {
            ContentResolver contentResolver = weakContext.get().getContentResolver();

            deviceId = Secure.getString(contentResolver, Secure.ANDROID_ID);

            // Set ANDROID_ID in SDK singleton, in order to set ANDROID_ID for dplinkr
            TuneInternal.getInstance().setAndroidId(deviceId);

            return !TuneStringUtils.isNullOrEmpty(deviceId);
        }

        public void run() {
            if (obtainGoogleAidInfo()) {
                // Successfully obtained Google Advertising Info
                TuneParameters.this.setSDKType(SDKTYPE.ANDROID);
            } else if (obtainFireAidInfo()) {
                // Successfully obtained Fire Advertising Info
                TuneParameters.this.setSDKType(SDKTYPE.FIRE);
            } else {
                TuneDebugLog.d("TUNE SDK failed to get Advertising Id, collecting ANDROID_ID instead");
                obtainDefaultAidInfo();
                TuneParameters.this.setSDKType(SDKTYPE.ANDROID);
            }

            initializationComplete.countDown();
        }
    }
    
    /**
     *  Runnable for getting the WebView user agent
     */
    @SuppressLint("NewApi")
    private class GetWebViewUserAgent implements Runnable {
        private final WeakReference<Context> weakContext;

        public GetWebViewUserAgent(Context context) {
            weakContext = new WeakReference<>(context);
        }

        public void run() {
            try {
                Class.forName("android.os.AsyncTask"); // prevents WebView from crashing on certain devices
                if (Build.VERSION.SDK_INT >= 17) {
                    setUserAgent(WebSettings.getDefaultUserAgent(weakContext.get()));
                } else {
                    // Create WebView to set user agent, then destroy WebView
                    WebView wv = new WebView(weakContext.get());
                    setUserAgent(wv.getSettings().getUserAgentString());
                    wv.destroy();
                }
            } catch (Exception e) {
                // Alcatel has WebView implementation that causes getDefaultUserAgent to NPE
                // Reference: https://groups.google.com/forum/#!topic/google-admob-ads-sdk/SX9yb3F_PNk
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
    public synchronized int getAgeNumeric() {
        String ageString = getAge();
        int age = 0;
        if (ageString != null) {
            try {
                age = Integer.parseInt(ageString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e("Error parsing age value " + ageString, e);
            }
        }

        return age;
    }

    public synchronized void setAge(String age) {
        mAge = age;
        savePrivacyProtectionState();
    }
    
    private String mAndroidId = null;
    public synchronized String getAndroidId() {
        return mAndroidId;
    }

    // We don't want to persist the AndroidId to local storage, because we don't want to
    // use it if we can collect a better ID later.
    public synchronized void setAndroidId(String androidId) {
        mAndroidId = androidId;

        // Also set the hash variations
        setAndroidIdMd5(TuneUtils.md5(androidId));
        setAndroidIdSha1(TuneUtils.sha1(androidId));
        setAndroidIdSha256(TuneUtils.sha256(androidId));
    }
    
    private String mAndroidIdMd5 = null;
    public synchronized String getAndroidIdMd5() { return mAndroidIdMd5; }
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
    // COPPA rules apply
    public synchronized boolean getAppAdTrackingEnabled() {
        String appAdTrackingEnabledString = getAppAdTrackingEnabledParameter();
        if (TuneStringUtils.isNullOrEmpty(appAdTrackingEnabledString)) {
            return false;
        }

        int adTrackingEnabled = 0;
        try {
            adTrackingEnabled = Integer.parseInt(appAdTrackingEnabledString);
        } catch (NumberFormatException e) {
            TuneDebugLog.e("Error parsing adTrackingEnabled value " + appAdTrackingEnabledString, e);
        }

        return (!isPrivacyProtectedDueToAge() && adTrackingEnabled != 0);
    }
    private synchronized String getAppAdTrackingEnabledParameter() {
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
        //NOTE: We don't need to track this for TMA + it isn't used as a URL param for MAT
    }

    private String mCountryCode = null;
    public synchronized String getCountryCode() {
        return mCountryCode;
    }
    public synchronized void setCountryCode(String countryCode) {
        mCountryCode = countryCode;
    }

    private String mDeviceBrand = null;
    public synchronized String getDeviceBrand() {
        return mDeviceBrand;
    }
    public synchronized void setDeviceBrand(String deviceBrand) {
        mDeviceBrand = deviceBrand;
    }

    private String mDeviceBuild = null;
    public synchronized String getDeviceBuild() {
        return mDeviceBuild;
    }
    public synchronized void setDeviceBuild(String deviceBuild) {
        mDeviceBuild = deviceBuild;
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

    @Deprecated private String mFireAdvertisingId = null;
    @Deprecated synchronized String getFireAdvertisingId() {
        return mFireAdvertisingId;
    }
    @Deprecated synchronized void setFireAdvertisingId(String adId) {
        // Retain FIRE_AID until fully deprecated.
        mFireAdvertisingId = adId;
    }

    @Deprecated synchronized void setFireAdTrackingLimited(String limited) {
        // Retain FIRE_AD_TRACKING Limited until fully deprecated.
    }

    private String mGender = null;
    public synchronized String getGender() {
        return mGender;
    }
    public synchronized void setGender(TuneGender gender) {
        switch(gender) {
            case MALE:
                mGender = "0";
                break;
            case FEMALE:
                mGender = "1";
                break;
            default:
                mGender = "";
                break;
        }
    }

    @Deprecated private String mGaid = null;
    @Deprecated synchronized String getGoogleAdvertisingId() {
        return mGaid;
    }
    @Deprecated synchronized void setGoogleAdvertisingId(String adId) {
        // Retain GOOGLE_AID until fully deprecated.
        mGaid = adId;
    }

    @Deprecated synchronized void setGoogleAdTrackingLimited(String limited) {
        // Retain GOOGLE_AD_TRACKING_DISABLED Limited until fully deprecated.
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

    private String mInstallBeginTimestampSeconds = null;
    public synchronized String getInstallBeginTimestampSeconds() {
        if (mInstallBeginTimestampSeconds == null) {
            mInstallBeginTimestampSeconds = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_INSTALL_BEGIN_TIMESTAMP, null);
        }

        return mInstallBeginTimestampSeconds;
    }
    public synchronized void setInstallBeginTimestampSeconds(long timestampSeconds) {
        mInstallBeginTimestampSeconds = Long.toString(timestampSeconds);
        mExecutor.execute(new Runnable() {
            public void run() {
            mPrefs.saveToSharedPreferences(TuneConstants.KEY_INSTALL_BEGIN_TIMESTAMP, mInstallBeginTimestampSeconds);
            }
        });
    }

    private String mReferrerClickTimestampSeconds = null;
    public synchronized String getReferrerClickTimestampSeconds() {
        if (mReferrerClickTimestampSeconds == null) {
            mReferrerClickTimestampSeconds = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_REFERRER_CLICK_TIMESTAMP, null);
        }

        return mReferrerClickTimestampSeconds;
    }
    public synchronized void setReferrerClickTimestampSeconds(long timestampSeconds) {
        mInstallBeginTimestampSeconds = Long.toString(timestampSeconds);
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_REFERRER_CLICK_TIMESTAMP, mInstallBeginTimestampSeconds);
            }
        });
    }

    private String mInstallerPackage = null;
    public synchronized String getInstaller() {
        return mInstallerPackage;
    }
    public synchronized void setInstaller(String installer) {
        mInstallerPackage = installer;
    }

    private String mInstallReferrer;
    public synchronized String getInstallReferrer() {
        if (mInstallReferrer == null) {
            mInstallReferrer = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_REFERRER, null);
        }

        return mInstallReferrer;
    }
    public synchronized void setInstallReferrer(final String installReferrer) {
        mInstallReferrer = installReferrer;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_REFERRER, installReferrer);
            }
        });
    }

    private Boolean mHasInstallFlagBeenSet;
    public synchronized boolean hasInstallFlagBeenSet() {
        if (mHasInstallFlagBeenSet == null) {
            mHasInstallFlagBeenSet = mPrefs.getBooleanFromSharedPreferences(TuneConstants.KEY_INSTALL, false);
        }
        return mHasInstallFlagBeenSet;
    }

    public synchronized void setInstallFlag() {
        mHasInstallFlagBeenSet = Boolean.TRUE;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveBooleanToSharedPreferences(TuneConstants.KEY_INSTALL, true);
            }
        });
    }

    private String mIsPayingUser;
    public synchronized String isPayingUser() {
        if (mIsPayingUser == null) {
            mIsPayingUser = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_PAYING_USER, null);
        }
        return mIsPayingUser;
    }
    public synchronized void setPayingUser(final String isPayingUser) {
        mIsPayingUser = isPayingUser;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_PAYING_USER, isPayingUser);
            }
        });
    }

    private String mLanguage = null;
    public synchronized String getLanguage() {
        return mLanguage;
    }
    public synchronized void setLanguage(String language) {
        mLanguage = language;
    }

    private String mLastOpenLogId = null;
    public synchronized String getLastOpenLogId() {
        if (mLastOpenLogId == null) {
            mLastOpenLogId = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_LAST_LOG_ID, null);
        }
        return mLastOpenLogId;
    }
    public synchronized void setLastOpenLogId(final String logId) {
        mLastOpenLogId = logId;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_LAST_LOG_ID, logId);
            }
        });
    }

    private String mLocale = null;
    public synchronized String getLocale() {
        return mLocale;
    }
    public synchronized void setLocale(String locale) {
        mLocale = locale;
    }

    private Location mLocation = null;
    private void createLocationIfMissing() {
        if (mLocation == null) {
            mLocation = new Location("");
        }
    }

    public void setLocation(final Location location) {
        mLocation = new Location(location);
    }

    public void setLocation(double latitude, double longitude, double altitude) {
        createLocationIfMissing();
        mLocation.setLatitude(latitude);
        mLocation.setLongitude(longitude);
        mLocation.setAltitude(altitude);
    }

    public final Location getLocation() {
        return mLocation;
    }

    private String mMacAddress = null;
    public synchronized String getMacAddress() {
        return mMacAddress;
    }
    public synchronized void setMacAddress(String mac_address) {
        mMacAddress = mac_address;
    }

    private String mMatId = null;
    public synchronized String getMatId() {
        if (mMatId == null) {
            mMatId = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_TUNE_ID, null);
        }
        return mMatId;
    }
    public synchronized void setMatId(final String matId) {
        mMatId = matId;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_TUNE_ID, matId);
            }
        });
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

    private String mOpenLogId = null;
    public synchronized String getOpenLogId() {
        if (mOpenLogId == null) {
            mOpenLogId = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_LOG_ID, null);
        }
        return mOpenLogId;
    }
    public synchronized void setOpenLogId(final String logId) {
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_LOG_ID, logId);
            }
        });
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
    private synchronized void setPackageName(String packageName) {
        mPackageName = packageName;
    }

    private String mPhoneNumber = null;
    public synchronized String getPhoneNumber() {
        if (mPhoneNumber == null) {
            setPhoneNumber(mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_PHONE_NUMBER, null));
        }
        return mPhoneNumber;
    }
    public synchronized void setPhoneNumber(final String phoneNumber) {
        mPhoneNumber = normalizePhoneNumber(phoneNumber);

        // Also set the hash variations
        setPhoneNumberMd5(TuneUtils.md5(mPhoneNumber));
        setPhoneNumberSha1(TuneUtils.sha1(mPhoneNumber));
        setPhoneNumberSha256(TuneUtils.sha256(mPhoneNumber));

        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_PHONE_NUMBER, mPhoneNumber);
            }
        });
    }

    private String normalizePhoneNumber(String phoneNumber) {
        if (!TuneStringUtils.isNullOrEmpty(phoneNumber)) {
            // Regex remove all non-digits from phoneNumber
            String phoneNumberDigits = phoneNumber.replaceAll("\\D+", "");
            // Convert to digits from foreign characters if needed
            StringBuilder digitsBuilder = new StringBuilder();
            for (int i = 0; i < phoneNumberDigits.length(); i++) {
                int numberParsed = Integer.parseInt(String.valueOf(phoneNumberDigits.charAt(i)));
                digitsBuilder.append(numberParsed);
            }

            phoneNumber = digitsBuilder.toString();
        }

        return phoneNumber;
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

    private String mPlatformAdvertisingId = null;
    public synchronized String getPlatformAdvertisingId() {
        return mPlatformAdvertisingId;
    }
    public synchronized void setPlatformAdvertisingId(String adId) {
        mPlatformAdvertisingId = adId;
    }

    private String mPlatformAdTrackingLimited = null;
    // COPPA rules apply
    public synchronized boolean getPlatformAdTrackingLimited() {
        String platformAdTrackingLimitedString = getPlatformAdTrackingLimitedParameter();
        if (TuneStringUtils.isNullOrEmpty(platformAdTrackingLimitedString)) {
            return false;
        }

        int platformAdTrackingLimited = 0;
        try {
            platformAdTrackingLimited = Integer.parseInt(platformAdTrackingLimitedString);
        } catch (NumberFormatException e) {
            TuneDebugLog.e("Error parsing platformAdTrackingLimited value " + platformAdTrackingLimitedString, e);
        }

        return (!isPrivacyProtectedDueToAge() && platformAdTrackingLimited != 0);
    }
    private synchronized String getPlatformAdTrackingLimitedParameter() {
        return mPlatformAdTrackingLimited;
    }
    public synchronized void setPlatformAdTrackingLimited(String limited) {
        mPlatformAdTrackingLimited = limited;
    }

    private String mPluginName = null;
    public synchronized String getPluginName() {
        return mPluginName;
    }
    public synchronized void setPluginName(String pluginName) {
        mPluginName = pluginName;
    }

    private boolean mPrivacyExplicitlySetAsProtected = false;
    private synchronized boolean isPrivacyExplicitlySetAsProtected() {
        return mPrivacyExplicitlySetAsProtected;
    }
    public synchronized void setPrivacyExplicitlySetAsProtected(boolean isSet) {
        mPrivacyExplicitlySetAsProtected = isSet;
        savePrivacyProtectionState();
    }
    private synchronized void loadPrivacyProtectedSetting() {
        mPrivacyExplicitlySetAsProtected = mPrefs.getBooleanFromSharedPreferences(TuneConstants.KEY_COPPA);
    }

    /**
     * @return True if COPPA rules apply
     */
    public synchronized boolean isPrivacyProtectedDueToAge() {
        int age = getAgeNumeric();
        boolean isCoppaAgeRestricted = (age > 0 && age < TuneConstants.COPPA_MINIMUM_AGE);

        return (isCoppaAgeRestricted || isPrivacyExplicitlySetAsProtected());
    }

    /**
     * Save the COPPA PrivacyProtection state
     */
    private void savePrivacyProtectionState() {
        final boolean isPrivacyProtected = isPrivacyProtectedDueToAge();
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveBooleanToSharedPreferences(TuneConstants.KEY_COPPA, isPrivacyProtected);
            }
        });
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

    enum SDKTYPE {
        ANDROID,
        FIRE;

        @Override
        public String toString() {
            return super.toString().toLowerCase(Locale.ENGLISH);
        }
    }

    private SDKTYPE mSDKType = SDKTYPE.ANDROID;
    public synchronized SDKTYPE getSDKType() {
        return mSDKType;
    }
    public synchronized void setSDKType(SDKTYPE sdkType) {
        mSDKType = sdkType;
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

    private String mTimeZone = null;
    public synchronized String getTimeZone() {
        return mTimeZone;
    }
    public synchronized void setTimeZone(String timeZone) {
        mTimeZone = timeZone;
        //TODO: Only Crosspromo uses this, and we track our own timezone stuff through minutesFromGMT
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
    private synchronized void setUserAgent(String userAgent) {
        mUserAgent = userAgent;
    }

    private String mUserEmail = null;
    public synchronized String getUserEmail() {
        if (mUserEmail == null) {
            setUserEmail(mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAIL, null));
        }
        return mUserEmail;
    }

    public synchronized void setUserEmail(final String userEmail) {
        mUserEmail = userEmail;

        // Also set the hash variations
        setUserEmailMd5(TuneUtils.md5(userEmail));
        setUserEmailSha1(TuneUtils.sha1(userEmail));
        setUserEmailSha256(TuneUtils.sha256(userEmail));

        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_EMAIL, userEmail);
            }
        });
    }

    public synchronized void clearUserEmail() {
        mUserEmail = null;
        clearUserEmailMd5();
        clearUserEmailSha1();
        clearUserEmailSha256();

        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.remove(TuneConstants.KEY_USER_EMAIL);
            }
        });
    }
    
    private String mUserEmailMd5;
    public synchronized String getUserEmailMd5() {
        return mUserEmailMd5;
    }
    public synchronized void setUserEmailMd5(String userEmailMd5) {
        mUserEmailMd5 = userEmailMd5;
    }

    public synchronized void clearUserEmailMd5() {
        mUserEmailMd5 = null;
    }
    
    private String mUserEmailSha1;
    public synchronized String getUserEmailSha1() {
        return mUserEmailSha1;
    }
    public synchronized void setUserEmailSha1(String userEmailSha1) {
        mUserEmailSha1 = userEmailSha1;
    }

    public synchronized void clearUserEmailSha1() {
        mUserEmailSha1 = null;
    }
    
    private String mUserEmailSha256;
    public synchronized String getUserEmailSha256() {
        return mUserEmailSha256;
    }

    public synchronized void setUserEmailSha256(String userEmailSha256) {
        mUserEmailSha256 = userEmailSha256;
    }

    public synchronized void clearUserEmailSha256() {
        mUserEmailSha256 = null;
    }
    
    private JSONArray mUserEmails = null;
    public synchronized JSONArray getUserEmails() {
        return mUserEmails;
    }

    public synchronized void setUserEmails(String[] emails) {
        mUserEmails = new JSONArray();
        for (String email : emails) {
            mUserEmails.put(email);
        }
    }

    public synchronized void clearUserEmails() {
        mUserEmails = new JSONArray();
    }

    private String mUserId = null;
    public synchronized String getUserId() {
        if (mUserId == null) {
            mUserId = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_ID, null);
        }
        return mUserId;
    }
    public synchronized void setUserId(final String user_id) {
        mUserId = user_id;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_ID, user_id);
            }
        });
    }

    private String mUserName = null;
    public synchronized String getUserName() {
        if (mUserName == null) {
            setUserName(mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_NAME, null));
        }
        return mUserName;
    }
    public synchronized void setUserName(final String userName) {
        mUserName = userName;

        // Also set the hash variations
        setUserNameMd5(TuneUtils.md5(userName));
        setUserNameSha1(TuneUtils.sha1(userName));
        setUserNameSha256(TuneUtils.sha256(userName));

        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_NAME, userName);
            }
        });
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


    public static Set<String> getRedactedKeys() {
        Set<String> redactKeys = new HashSet<>();
        if (Tune.getInstance().isPrivacyProtectedDueToAge()) {
            redactKeys.addAll(TuneUrlKeys.getRedactedUrlKeys());
        }

        return redactKeys;
    }

}
