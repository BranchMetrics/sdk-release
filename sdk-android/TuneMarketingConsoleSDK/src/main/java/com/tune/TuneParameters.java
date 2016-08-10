package com.tune;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Point;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.text.TextUtils;
import android.view.Display;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.TuneHashType;
import com.tune.ma.analytics.model.TuneVariableType;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneGetGAIDCompleted;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONArray;
import org.json.JSONException;

import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;
import java.util.UUID;

public class TuneParameters {
    // Application context
    private Context mContext;
    // Tune SDK instance
    private Tune mTune;

    private static TuneParameters INSTANCE = null;

    private TuneSharedPrefsDelegate mPrefs;

    public TuneParameters() {
    }
    
    public static TuneParameters init(Tune tune, Context context, String advertiserId, String conversionKey) {
        if (INSTANCE == null) {
            // Only instantiate and populate common params the first time
            INSTANCE = new TuneParameters();
            INSTANCE.mTune = tune;
            INSTANCE.mContext = context;
            INSTANCE.mPrefs = new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_TUNE);
            INSTANCE.populateParams(context, advertiserId, conversionKey);
        }
        return INSTANCE;
    }
    
    public static TuneParameters getInstance() {
        return INSTANCE;
    }
    
    public void clear() {
        INSTANCE = null;
    }

    /**
     * Helper to populate the device params to send
     * @param context the application Context
     * @param advertiserId the advertiser id in TUNE
     * @param conversionKey the conversion key in TUNE
     * @return whether params were successfully collected or not
     */
    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    private synchronized boolean populateParams(Context context, String advertiserId, String conversionKey) {
        try {
            // Strip the whitespace from advertiser id and key
            setAdvertiserId(advertiserId.trim());
            setConversionKey(conversionKey.trim());

            // Default params
            setCurrencyCode(TuneConstants.DEFAULT_CURRENCY_CODE);

            new Thread(new GetGAID(context)).start();
            
            // Retrieve user agent
            calculateUserAgent();

            // Set the MAT ID, from existing or generate a new UUID
            String matId = getMatId();
            if (matId == null || matId.length() == 0) {
                matId = UUID.randomUUID().toString();
                setMatId(matId);
            }
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MAT_ID, matId)));
            
            // Get app package information
            final String packageName = context.getPackageName();
            setPackageName(packageName);

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
            setDeviceCpuType(System.getProperty("os.arch"));
            //setDeviceCpuSubtype(SystemProperties.get("ro.product.cpu.abi"));
            setOsVersion(Build.VERSION.RELEASE);
            // Screen density
            float density = context.getResources().getDisplayMetrics().density;
            setScreenDensity(Float.toString(density));
            Display display = ((WindowManager)context.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay();
            int width;
            int height;
            Point size = new Point();
            if (Build.VERSION.SDK_INT >= 17) {
                display.getRealSize(size);
                width = size.x;
                height = size.y;
            } else if (Build.VERSION.SDK_INT >= 13) {
                display.getSize(size);
                width = size.x;
                height = size.y;
            } else {
                width = display.getWidth();
                height = display.getHeight();
            }
            setScreenWidth(Integer.toString(width));
            setScreenHeight(Integer.toString(height));

            // Set the device connection type, wifi or mobile
            ConnectivityManager connManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
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
            
            return true;
        } catch (Exception e) {
            TuneUtils.log("MobileAppTracking params initialization failed");
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Determine the device's user agent and set the corresponding field.
     */
    private void calculateUserAgent() {
        String userAgent = System.getProperty("http.agent", "");
        if (!TextUtils.isEmpty(userAgent)) {
            setUserAgent(userAgent);
        } else {
            // If system doesn't have user agent,
            // execute Runnable on UI thread to get WebView user agent
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new GetWebViewUserAgent(mContext));
        }
    }
    
    private class GetGAID implements Runnable {
        private final WeakReference<Context> weakContext;
        private String deviceId;
        private boolean isLAT = false;
        private boolean gotGaid = false;
        
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
                deviceId = (String) getIdMethod.invoke(adInfo);
                
                Method getLATMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info").getDeclaredMethod("isLimitAdTrackingEnabled");
                isLAT = ((Boolean) getLATMethod.invoke(adInfo)).booleanValue();

                gotGaid = true;
                
                // mTune's params may not be initialized by the time this thread finishes
                if (mTune.params == null) {
                    // Call the setters manually
                    setGoogleAdvertisingId(deviceId);
                    int intLimit = isLAT? 1 : 0;
                    setGoogleAdTrackingLimited(Integer.toString(intLimit));
                }
                // Set GAID in SDK singleton
                mTune.setGoogleAdvertisingId(deviceId, isLAT);
            } catch (Exception e) {
                TuneUtils.log("TUNE SDK failed to get Google Advertising Id, collecting ANDROID_ID instead");

                deviceId = Secure.getString(weakContext.get().getContentResolver(), Secure.ANDROID_ID);
                // mTune's params may not be initialized by the time this thread finishes
                if (mTune.params == null) {
                    // Call the setter manually
                    setAndroidId(deviceId);
                }
                // Set ANDROID_ID in SDK singleton, in order to set ANDROID_ID for dplinkr
                mTune.setAndroidId(deviceId);
            } finally {
                // Post event that GAID completed
                TuneEventBus.post(new TuneGetGAIDCompleted(gotGaid, deviceId, isLAT));
            }
        }
    }
    
    /**
     *  Runnable for getting the WebView user agent
     */
    @SuppressLint("NewApi")
    private class GetWebViewUserAgent implements Runnable {
        private final WeakReference<Context> weakContext;

        public GetWebViewUserAgent(Context context) {
            weakContext = new WeakReference<Context>(context);
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
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ACTION, action)));
    }

    private String mAdvertiserId = null;
    public synchronized String getAdvertiserId() {
        return mAdvertiserId;
    }
    public synchronized void setAdvertiserId(String advertiserId) {
        mAdvertiserId = advertiserId;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_ID, advertiserId)));
        // Save advertiser ID to SharedPreferences for IAM App ID
        new TuneSharedPrefsDelegate(mContext, TuneUserProfile.PREFS_TMA_PROFILE).saveToSharedPreferences(TuneUrlKeys.ADVERTISER_ID, advertiserId);
    }
    
    private String mAge = null;
    public synchronized String getAge() {
        return mAge;
    }
    public synchronized void setAge(String age) {
        mAge = age;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGE, Integer.parseInt(age))));
    }
    
    private String mAltitude = null;
    public synchronized String getAltitude() {
        return mAltitude;
    }
    public synchronized void setAltitude(String altitude) {
        mAltitude = altitude;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ALTITUDE, altitude)));
    }

    private String mAndroidId = null;
    public synchronized String getAndroidId() {
        return mAndroidId;
    }
    public synchronized void setAndroidId(String androidId) {
        mAndroidId = androidId;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID, androidId)));
    }
    
    private String mAndroidIdMd5 = null;
    public synchronized String getAndroidIdMd5() { return mAndroidIdMd5; }
    public synchronized void setAndroidIdMd5(String androidIdMd5) {
        mAndroidIdMd5 = androidIdMd5;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID_MD5, androidIdMd5)));
    }
    
    private String mAndroidIdSha1 = null;
    public synchronized String getAndroidIdSha1() {
        return mAndroidIdSha1;
    }
    public synchronized void setAndroidIdSha1(String androidIdSha1) {
        mAndroidIdSha1 = androidIdSha1;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID_SHA1, androidIdSha1)));
    }
    
    private String mAndroidIdSha256 = null;
    public synchronized String getAndroidIdSha256() {
        return mAndroidIdSha256;
    }
    public synchronized void setAndroidIdSha256(String androidIdSha256) {
        mAndroidIdSha256 = androidIdSha256;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID_SHA256, androidIdSha256)));
    }
    
    private String mAppAdTracking = null;
    public synchronized String getAppAdTrackingEnabled() {
        return mAppAdTracking;
    }
    public synchronized void setAppAdTrackingEnabled(String adTrackingEnabled) {
        mAppAdTracking = adTrackingEnabled;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_AD_TRACKING, adTrackingEnabled)));
    }

    private String mAppName = null;
    public synchronized String getAppName() {
        return mAppName;
    }
    public synchronized void setAppName(String app_name) {
        mAppName = app_name;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_NAME, app_name)));
    }

    private String mAppVersion = null;
    public synchronized String getAppVersion() {
        return mAppVersion;
    }
    public synchronized void setAppVersion(String appVersion) {
        mAppVersion = appVersion;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_VERSION, appVersion, TuneVariableType.VERSION)));
    }

    private String mAppVersionName = null;
    public synchronized String getAppVersionName() {
        return mAppVersionName;
    }
    public synchronized void setAppVersionName(String appVersionName) {
        mAppVersionName = appVersionName;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_VERSION_NAME, appVersionName)));
    }

    private String mConnectionType = null;
    public synchronized String getConnectionType() {
        return mConnectionType;
    }
    public synchronized void setConnectionType(String connection_type) {
        mConnectionType = connection_type;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.CONNECTION_TYPE, connection_type)));
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
        if (countryCode != null) {
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.COUNTRY_CODE, countryCode.toUpperCase(Locale.ENGLISH))));
        }
    }

    private String mCurrencyCode = null;
    public synchronized String getCurrencyCode() {
        return mCurrencyCode;
    }
    public synchronized void setCurrencyCode(String currencyCode) {
        mCurrencyCode = currencyCode;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.CURRENCY_CODE, currencyCode)));
    }

    private String mDeviceBrand = null;
    public synchronized String getDeviceBrand() {
        return mDeviceBrand;
    }
    public synchronized void setDeviceBrand(String deviceBrand) {
        mDeviceBrand = deviceBrand;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_BRAND, deviceBrand)));
    }

    private String mDeviceCarrier = null;
    public synchronized String getDeviceCarrier() {
        return mDeviceCarrier;
    }
    public synchronized void setDeviceCarrier(String carrier) {
        mDeviceCarrier = carrier;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_CARRIER, carrier)));
    }

    private String mDeviceCpuType = null;
    public synchronized String getDeviceCpuType() {
        return mDeviceCpuType;
    }
    public synchronized void setDeviceCpuType(String cpuType) {
        mDeviceCpuType = cpuType;
        // TODO: Confirm type
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_CPU_TYPE, cpuType)));
    }

    private String mDeviceCpuSubtype = null;
    public synchronized String getDeviceCpuSubtype() {
        return mDeviceCpuSubtype;
    }
    public synchronized void setDeviceCpuSubtype(String cpuType) {
        mDeviceCpuSubtype = cpuType;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_CPU_SUBTYPE, cpuType)));
    }

    private String mDeviceId = null;
    public synchronized String getDeviceId() {
        return mDeviceId;
    }
    public synchronized void setDeviceId(String deviceId) {
        mDeviceId = deviceId;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_ID, deviceId)));
    }
    
    private String mDeviceModel = null;
    public synchronized String getDeviceModel() {
        return mDeviceModel;
    }
    public synchronized void setDeviceModel(String model) {
        mDeviceModel = model;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_MODEL, model)));
    }

    private boolean mDebugMode = false;
    public synchronized boolean getDebugMode() {
        return mDebugMode;
    }
    public synchronized void setDebugMode(boolean debug) {
        mDebugMode = debug;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEBUG_MODE, debug)));
    }
    
    private String mExistingUser = null;
    public synchronized String getExistingUser() {
        return mExistingUser;
    }
    public synchronized void setExistingUser(String existingUser) {
        mExistingUser = existingUser;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.EXISTING_USER, TuneUtils.convertToBoolean(existingUser))));
    }
    
    private String mFbUserId = null;
    public synchronized String getFacebookUserId() {
        return mFbUserId;
    }
    public synchronized void setFacebookUserId(String fb_user_id) {
        mFbUserId = fb_user_id;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.FACEBOOK_USER_ID, fb_user_id)));
    }
    
    private String mGender = null;
    public synchronized String getGender() {
        return mGender;
    }
    public synchronized void setGender(TuneGender gender) {
        if (gender == TuneGender.MALE) {
            mGender = "0";
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GENDER, "0", TuneVariableType.FLOAT)));
        } else if (gender == TuneGender.FEMALE) {
            mGender = "1";
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GENDER, "1", TuneVariableType.FLOAT)));
        } else {
            mGender = "";
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GENDER, "2", TuneVariableType.FLOAT)));
        }
    }

    private String mGaid = null;
    public synchronized String getGoogleAdvertisingId() {
        return mGaid;
    }
    public synchronized void setGoogleAdvertisingId(String adId) {
        mGaid = adId;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_AID, adId)));
    }

    private String mGaidLimited = null;
    public synchronized String getGoogleAdTrackingLimited() {
        return mGaidLimited;
    }
    public synchronized void setGoogleAdTrackingLimited(String limited) {
        mGaidLimited = limited;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_AD_TRACKING, limited)));
    }
    
    private String mGgUserId = null;
    public synchronized String getGoogleUserId() {
        return mGgUserId;
    }
    public synchronized void setGoogleUserId(String google_user_id) {
        mGgUserId = google_user_id;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_USER_ID, google_user_id)));
    }

    private String mInstallDate = null;
    public synchronized String getInstallDate() {
        return mInstallDate;
    }
    public synchronized void setInstallDate(String installDate) {
        mInstallDate = installDate;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.INSTALL_DATE, new Date(Long.parseLong(installDate) * 1000))));
    }
    
    private String mInstallerPackage = null;
    public synchronized String getInstaller() {
        return mInstallerPackage;
    }
    public synchronized void setInstaller(String installer) {
        mInstallerPackage = installer;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.INSTALLER, installer)));
    }

    public synchronized String getInstallReferrer() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_REFERRER);
    }
    public synchronized void setInstallReferrer(String installReferrer) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_REFERRER, installReferrer);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.INSTALL_REFERRER, installReferrer)));
    }
    
    public synchronized String getIsPayingUser() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_PAYING_USER);
    }
    public synchronized void setIsPayingUser(String isPayingUser) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_PAYING_USER, isPayingUser);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.IS_PAYING_USER, TuneUtils.convertToBoolean(isPayingUser))));
    }

    private String mLanguage = null;
    public synchronized String getLanguage() {
        return mLanguage;
    }
    public synchronized void setLanguage(String language) {
        mLanguage = language;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LANGUAGE, language)));
    }

    public synchronized String getLastOpenLogId() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_LAST_LOG_ID);
    }
    public synchronized void setLastOpenLogId(String logId) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_LAST_LOG_ID, logId);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LAST_OPEN_LOG_ID, logId)));
    }

    private String mLatitude = null;
    public synchronized String getLatitude() {
        return mLatitude;
    }
    public synchronized void setLatitude(String latitude) {
        mLatitude = latitude;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LATITUDE, latitude)));
        if (mLongitude != null) {
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.GEO_COORDINATE, new TuneLocation(Double.valueOf(mLongitude), Double.valueOf(mLatitude)))));
        }
    }

    private TuneLocation mLocation = null;
    public synchronized TuneLocation getLocation() {
        return mLocation;
    }
    public synchronized void setLocation(TuneLocation location) {
        mLocation = location;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.GEO_COORDINATE, location)));
    }

    private String mLongitude = null;
    public synchronized String getLongitude() {
        return mLongitude;
    }
    public synchronized void setLongitude(String longitude) {
        mLongitude = longitude;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LONGITUDE, longitude)));
        if (mLatitude != null) {
            TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.GEO_COORDINATE, new TuneLocation(Double.valueOf(mLongitude), Double.valueOf(mLatitude)))));
        }
    }

    private String mMacAddress = null;
    public synchronized String getMacAddress() {
        return mMacAddress;
    }
    public synchronized void setMacAddress(String mac_address) {
        mMacAddress = mac_address;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MAC_ADDRESS, mac_address)));
    }

    public synchronized String getMatId() {
        if (mPrefs.contains("mat_id")) {
            return mPrefs.getStringFromSharedPreferences("mat_id");
        }
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_TUNE_ID);
    }
    public synchronized void setMatId(String matId) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_TUNE_ID, matId);
    }

    private String mMCC = null;
    public synchronized String getMCC() {
        return mMCC;
    }
    public synchronized void setMCC(String mcc) {
        mMCC = mcc;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MOBILE_COUNTRY_CODE, mcc)));
    }

    private String mMNC = null;
    public synchronized String getMNC() {
        return mMNC;
    }
    public synchronized void setMNC(String mnc) {
        mMNC = mnc;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MOBILE_NETWORK_CODE, mnc)));
    }

    public synchronized String getOpenLogId() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_LOG_ID);
    }
    public synchronized void setOpenLogId(String logId) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_LOG_ID, logId);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.OPEN_LOG_ID, logId)));
    }

    private String mOsVersion = null;
    public synchronized String getOsVersion() {
        return mOsVersion;
    }
    public synchronized void setOsVersion(String osVersion) {
        mOsVersion = osVersion;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.OS_VERSION, osVersion, TuneVariableType.VERSION)));
    }

    private String mPackageName = null;
    public synchronized String getPackageName() {
        return mPackageName;
    }
    public synchronized void setPackageName(String packageName) {
        mPackageName = packageName;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PACKAGE_NAME, packageName)));
        // Save package name to SharedPreferences for IAM App ID
        new TuneSharedPrefsDelegate(mContext, TuneUserProfile.PREFS_TMA_PROFILE).saveToSharedPreferences(TuneUrlKeys.PACKAGE_NAME, packageName);
    }
    
    public synchronized String getPhoneNumber() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_PHONE_NUMBER);
    }
    public synchronized void setPhoneNumber(String phoneNumber) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_PHONE_NUMBER, phoneNumber);
        setPhoneNumberMd5(TuneUtils.md5(phoneNumber));
        setPhoneNumberSha1(TuneUtils.sha1(phoneNumber));
        setPhoneNumberSha256(TuneUtils.sha256(phoneNumber));
    }
    
    private String mPhoneNumberMd5;
    public synchronized String getPhoneNumberMd5() {
        return mPhoneNumberMd5;
    }
    public synchronized void setPhoneNumberMd5(String phoneNumberMd5) {
        mPhoneNumberMd5 = phoneNumberMd5;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_PHONE_MD5)
                        .withValue(phoneNumberMd5)
                        .withHash(TuneHashType.MD5)
                        .build()));
    }
    
    private String mPhoneNumberSha1;
    public synchronized String getPhoneNumberSha1() {
        return mPhoneNumberSha1;
    }
    public synchronized void setPhoneNumberSha1(String phoneNumberSha1) {
        mPhoneNumberSha1 = phoneNumberSha1;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_PHONE_SHA1)
                        .withValue(phoneNumberSha1)
                        .withHash(TuneHashType.SHA1)
                        .build()));
    }
    
    private String mPhoneNumberSha256;
    public synchronized String getPhoneNumberSha256() {
        return mPhoneNumberSha256;
    }
    public synchronized void setPhoneNumberSha256(String phoneNumberSha256) {
        mPhoneNumberSha256 = phoneNumberSha256;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_PHONE_SHA256)
                        .withValue(phoneNumberSha256)
                        .withHash(TuneHashType.SHA256)
                        .build()));
    }

    private String mPluginName = null;
    public synchronized String getPluginName() {
        return mPluginName;
    }
    public synchronized void setPluginName(String pluginName) {
        mPluginName = pluginName;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SDK_PLUGIN, pluginName)));
    }
    
    private String mPurchaseStatus = null;
    public synchronized String getPurchaseStatus() {
        return mPurchaseStatus;
    }
    public synchronized void setPurchaseStatus(String purchaseStatus) {
        mPurchaseStatus = purchaseStatus;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PURCHASE_STATUS, purchaseStatus)));
    }

    private String mReferralSource = null;
    public synchronized String getReferralSource() {
        return mReferralSource;
    }
    public synchronized void setReferralSource(String referralPackage) {
        mReferralSource = referralPackage;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.REFERRAL_SOURCE, referralPackage)));
    }

    private String mReferralUrl = null;
    public synchronized String getReferralUrl() {
        return mReferralUrl;
    }
    public synchronized void setReferralUrl(String referralUrl) {
        mReferralUrl = referralUrl;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.REFERRAL_URL, referralUrl)));
    }

    private String mReferrerDelay = null;
    public synchronized String getReferrerDelay() {
        return mReferrerDelay;
    }
    public synchronized void setReferrerDelay(long referrerDelay) {
        mReferrerDelay = Long.toString(referrerDelay);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.REFERRER_DELAY, referrerDelay)));
    }

    private String mScreenDensity = null;
    public synchronized String getScreenDensity() {
        return mScreenDensity;
    }
    public synchronized void setScreenDensity(String density) {
        mScreenDensity = density;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SCREEN_DENSITY, Float.parseFloat(density))));
    }

    private String mScreenHeight = null;
    public synchronized String getScreenHeight() {
        return mScreenHeight;
    }
    public synchronized void setScreenHeight(String screenheight) {
        mScreenHeight = screenheight;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.SCREEN_HEIGHT, Integer.parseInt(screenheight))));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SCREEN_SIZE, getScreenWidth() + "x" + getScreenHeight())));
    }

    private String mScreenWidth = null;
    public synchronized String getScreenWidth() {
        return mScreenWidth;
    }
    public synchronized void setScreenWidth(String screenwidth) {
        mScreenWidth = screenwidth;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.SCREEN_WIDTH, Integer.parseInt(screenwidth))));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SCREEN_SIZE, getScreenWidth() + "x" + getScreenHeight())));
    }

    public synchronized String getSdkVersion() {
        return TuneConstants.SDK_VERSION;
    }
    // no setter

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
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.TRACKING_ID, trackingId)));
    }

    private String mTrusteId = null;
    public synchronized String getTRUSTeId() {
        return mTrusteId;
    }
    public synchronized void setTRUSTeId(String tpid) {
        mTrusteId = tpid;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.TRUSTE_ID, tpid)));
    }
    
    private String mTwUserId = null;
    public synchronized String getTwitterUserId() {
        return mTwUserId;
    }
    public synchronized void setTwitterUserId(String twitter_user_id) {
        mTwUserId = twitter_user_id;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.TWITTER_USER_ID, twitter_user_id)));
    }

    private String mUserAgent = null;
    public synchronized String getUserAgent() {
        return mUserAgent;
    }
    private synchronized void setUserAgent(String userAgent) {
        mUserAgent = userAgent;
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.USER_AGENT, userAgent)));
    }
    
    public synchronized String getUserEmail() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAIL);
    }
    public synchronized void setUserEmail(String userEmail) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_EMAIL, userEmail);
        setUserEmailMd5(TuneUtils.md5(userEmail));
        setUserEmailSha1(TuneUtils.sha1(userEmail));
        setUserEmailSha256(TuneUtils.sha256(userEmail));
    }
    
    private String mUserEmailMd5;
    public synchronized String getUserEmailMd5() {
        return mUserEmailMd5;
    }
    public synchronized void setUserEmailMd5(String userEmailMd5) {
        mUserEmailMd5 = userEmailMd5;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAIL_MD5)
                        .withValue(userEmailMd5)
                        .withHash(TuneHashType.MD5)
                        .build()));
    }
    
    private String mUserEmailSha1;
    public synchronized String getUserEmailSha1() {
        return mUserEmailSha1;
    }
    public synchronized void setUserEmailSha1(String userEmailSha1) {
        mUserEmailSha1 = userEmailSha1;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAIL_SHA1)
                        .withValue(userEmailSha1)
                        .withHash(TuneHashType.SHA1)
                        .build()));
    }
    
    private String mUserEmailSha256;
    public synchronized String getUserEmailSha256() {
        return mUserEmailSha256;
    }
    public synchronized void setUserEmailSha256(String userEmailSha256) {
        mUserEmailSha256 = userEmailSha256;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAIL_SHA256)
                        .withValue(userEmailSha256)
                        .withHash(TuneHashType.SHA256)
                        .build()));
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
        try {
            TuneEventBus.post(new TuneUpdateUserProfile(
                    TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAILS)
                            .withValue(mUserEmails.join(","))
                            .build()));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public synchronized String getUserId() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_ID);
    }
    public synchronized void setUserId(String user_id) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_ID, user_id);
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.USER_ID, user_id)));
    }

    public synchronized String getUserName() {
        return mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_NAME);
    }
    public synchronized void setUserName(String userName) {
        mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_NAME, userName);
        setUserNameMd5(TuneUtils.md5(userName));
        setUserNameSha1(TuneUtils.sha1(userName));
        setUserNameSha256(TuneUtils.sha256(userName));
    }
    
    private String mUserNameMd5;
    public synchronized String getUserNameMd5() {
        return mUserNameMd5;
    }
    public synchronized void setUserNameMd5(String userNameMd5) {
        mUserNameMd5 = userNameMd5;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_NAME_MD5)
                        .withValue(userNameMd5)
                        .withHash(TuneHashType.MD5)
                        .build()));
    }
    
    private String mUserNameSha1;
    public synchronized String getUserNameSha1() {
        return mUserNameSha1;
    }
    public synchronized void setUserNameSha1(String userNameSha1) {
        mUserNameSha1 = userNameSha1;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_NAME_SHA1)
                    .withValue(userNameSha1)
                    .withHash(TuneHashType.SHA1)
                    .build()));
    }
    
    private String mUserNameSha256;
    public synchronized String getUserNameSha256() {
        return mUserNameSha256;
    }
    public synchronized void setUserNameSha256(String userNameSha256) {
        mUserNameSha256 = userNameSha256;
        TuneEventBus.post(new TuneUpdateUserProfile(
                TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_NAME_SHA256)
                        .withValue(userNameSha256)
                        .withHash(TuneHashType.SHA256)
                        .build()));
    }
}
