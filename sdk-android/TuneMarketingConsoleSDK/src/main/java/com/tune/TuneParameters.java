package com.tune;

import android.annotation.SuppressLint;
import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.text.TextUtils;
import android.webkit.WebSettings;
import android.webkit.WebView;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneHashType;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.inapp.TuneScreenUtils;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONArray;
import org.json.JSONException;

import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class TuneParameters {
    // Application context
    private Context mContext;
    // Tune SDK instance
    private Tune mTune;
    // Executor Service
    private ExecutorService mExecutor;


    // Actions
    public static final String ACTION_SESSION = "session";
    public static final String ACTION_CLICK = "click";
    public static final String ACTION_CONVERSION = "conversion";

    private TuneSharedPrefsDelegate mPrefs;
    private CountDownLatch initializationComplete;

    public TuneParameters() {
    }
    
    public static TuneParameters init(Tune tune, Context context, String advertiserId, String conversionKey) {
        TuneParameters INSTANCE = new TuneParameters();

        // Only instantiate and populate common params the first time
        INSTANCE.mTune = tune;
        INSTANCE.mContext = context;
        INSTANCE.mExecutor = Executors.newSingleThreadExecutor();

        // Two primary threads that need to complete
        INSTANCE.initializationComplete = new CountDownLatch(2);

        INSTANCE.mPrefs = new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_TUNE);
        INSTANCE.populateParams(context, advertiserId, conversionKey);

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

            new Thread(new GetAdvertisingId(context)).start();
            
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
            setDeviceBuild(Build.DISPLAY);
            setDeviceCpuType(System.getProperty("os.arch"));
            //setDeviceCpuSubtype(SystemProperties.get("ro.product.cpu.abi"));
            setOsVersion(Build.VERSION.RELEASE);
            // Screen density
            setScreenDensity(Float.toString(TuneScreenUtils.getScreenDensity(context)));
            // Screen width and height
            setScreenWidth(Integer.toString(TuneScreenUtils.getScreenWidthPixels(context)));
            setScreenHeight(Integer.toString(TuneScreenUtils.getScreenHeightPixels(context)));

            // Set the device connection type, wifi or mobile
            ConnectivityManager connManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
            if (mWifi.isConnected()) {
                setConnectionType("wifi");
            } else {
                setConnectionType("mobile");
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
    
    private class GetAdvertisingId implements Runnable {
        private final WeakReference<Context> weakContext;
        private String deviceId;
        private boolean isLAT = false;
        
        public GetAdvertisingId(Context context) {
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
                // Don't save advertising id if it's all zeroes
                if (deviceId.equals(TuneConstants.UUID_EMPTY)) {
                    deviceId = null;
                }
                
                Method getLATMethod = Class.forName("com.google.android.gms.ads.identifier.AdvertisingIdClient$Info").getDeclaredMethod("isLimitAdTrackingEnabled");
                isLAT = ((Boolean) getLATMethod.invoke(adInfo)).booleanValue();
                
                // mTune's params may not be initialized by the time this thread finishes
                if (mTune.params == null) {
                    // Call the setters manually
                    setGoogleAdvertisingId(deviceId);
                    int intLimit = isLAT ? 1 : 0;
                    setGoogleAdTrackingLimited(Integer.toString(intLimit));
                }
                // Set GAID in SDK singleton
                mTune.setGoogleAdvertisingId(deviceId, isLAT);

                // Post event that getting Google Advertising ID completed
                TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.GOOGLE_AID, deviceId, isLAT));
            } catch (Exception e) {
                // GAID retrieval failed, try to get Fire Advertising ID
                ContentResolver contentResolver = weakContext.get().getContentResolver();

                try {
                    // Get Fire Advertising ID
                    deviceId = Secure.getString(contentResolver, TuneConstants.FIRE_ADVERTISING_ID_KEY);
                    // Don't save advertising id if it's all zeroes
                    if (deviceId.equals(TuneConstants.UUID_EMPTY)) {
                        deviceId = null;
                    }

                    // Get Fire limit ad tracking preference
                    isLAT = (Secure.getInt(contentResolver, TuneConstants.FIRE_LIMIT_AD_TRACKING_KEY) == 0) ? false : true;

                    // mTune's params may not be initialized by the time this thread finishes
                    if (mTune.params == null) {
                        // Call the setters manually
                        setFireAdvertisingId(deviceId);
                        int intLimit = isLAT ? 1 : 0;
                        setFireAdTrackingLimited(Integer.toString(intLimit));
                    }
                    // Set Fire Advertising ID in SDK singleton
                    mTune.setFireAdvertisingId(deviceId, isLAT);

                    // Post event that getting Fire Advertising ID completed
                    TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.FIRE_AID, deviceId, isLAT));
                } catch (Exception e1) {
                    TuneUtils.log("TUNE SDK failed to get Advertising Id, collecting ANDROID_ID instead");

                    deviceId = Secure.getString(contentResolver, Secure.ANDROID_ID);
                    // mTune's params may not be initialized by the time this thread finishes
                    if (mTune.params == null) {
                        // Call the setter manually
                        setAndroidId(deviceId);
                    }
                    // Set ANDROID_ID in SDK singleton, in order to set ANDROID_ID for dplinkr
                    mTune.setAndroidId(deviceId);

                    // Post event that getting Android ID completed
                    TuneEventBus.post(new TuneGetAdvertisingIdCompleted(TuneGetAdvertisingIdCompleted.Type.ANDROID_ID, deviceId, isLAT));
                }
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
    public synchronized void setAction(final String action) {
        mAction = action;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ACTION, action)));
            }
        });
    }

    private String mAdvertiserId = null;
    public synchronized String getAdvertiserId() {
        return mAdvertiserId;
    }
    public synchronized void setAdvertiserId(final String advertiserId) {
        mAdvertiserId = advertiserId;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_ID, advertiserId)));
                // Save advertiser ID to SharedPreferences for IAM App ID
                // TODO: REVISIT.  This has too much knowledge of how UserProfile values are saved.
                new TuneSharedPrefsDelegate(mContext, TuneUserProfile.PREFS_TMA_PROFILE).saveToSharedPreferences(TuneUrlKeys.ADVERTISER_ID, advertiserId);
            }
        });
    }
    
    private String mAge = null;
    public synchronized String getAge() {
        return mAge;
    }
    public synchronized void setAge(final String age) {
        mAge = age;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGE, Integer.parseInt(age))));
            }
        });
    }
    
    private String mAltitude = null;
    public synchronized String getAltitude() {
        return mAltitude;
    }
    public synchronized void setAltitude(final String altitude) {
        mAltitude = altitude;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ALTITUDE, altitude)));
            }
        });
    }

    private String mAndroidId = null;
    public synchronized String getAndroidId() {
        return mAndroidId;
    }
    public synchronized void setAndroidId(final String androidId) {
        mAndroidId = androidId;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID, androidId)));
            }
        });
    }
    
    private String mAndroidIdMd5 = null;
    public synchronized String getAndroidIdMd5() { return mAndroidIdMd5; }
    public synchronized void setAndroidIdMd5(final String androidIdMd5) {
        mAndroidIdMd5 = androidIdMd5;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID_MD5, androidIdMd5)));
            }
        });
    }
    
    private String mAndroidIdSha1 = null;
    public synchronized String getAndroidIdSha1() {
        return mAndroidIdSha1;
    }
    public synchronized void setAndroidIdSha1(final String androidIdSha1) {
        mAndroidIdSha1 = androidIdSha1;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID_SHA1, androidIdSha1)));
            }
        });
    }
    
    private String mAndroidIdSha256 = null;
    public synchronized String getAndroidIdSha256() {
        return mAndroidIdSha256;
    }
    public synchronized void setAndroidIdSha256(final String androidIdSha256) {
        mAndroidIdSha256 = androidIdSha256;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID_SHA256, androidIdSha256)));
            }
        });
    }
    
    private String mAppAdTracking = null;
    public synchronized String getAppAdTrackingEnabled() {
        return mAppAdTracking;
    }
    public synchronized void setAppAdTrackingEnabled(final String adTrackingEnabled) {
        mAppAdTracking = adTrackingEnabled;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_AD_TRACKING, adTrackingEnabled)));
            }
        });
    }

    private String mAppName = null;
    public synchronized String getAppName() {
        return mAppName;
    }
    public synchronized void setAppName(final String app_name) {
        mAppName = app_name;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_NAME, app_name)));
            }
        });
    }

    private String mAppVersion = null;
    public synchronized String getAppVersion() {
        return mAppVersion;
    }
    public synchronized void setAppVersion(final String appVersion) {
        mAppVersion = appVersion;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_VERSION, appVersion, TuneVariableType.VERSION)));
            }
        });
    }

    private String mAppVersionName = null;
    public synchronized String getAppVersionName() {
        return mAppVersionName;
    }
    public synchronized void setAppVersionName(final String appVersionName) {
        mAppVersionName = appVersionName;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.APP_VERSION_NAME, appVersionName)));
            }
        });
    }

    private String mConnectionType = null;
    public synchronized String getConnectionType() {
        return mConnectionType;
    }
    public synchronized void setConnectionType(final String connection_type) {
        mConnectionType = connection_type;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.CONNECTION_TYPE, connection_type)));
            }
        });
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
    public synchronized void setCountryCode(final String countryCode) {
        mCountryCode = countryCode;
        if (countryCode != null) {
            mExecutor.execute(new Runnable() {
                public void run() {
                    TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.COUNTRY_CODE, countryCode.toUpperCase(Locale.ENGLISH))));
                }
            });
        }
    }

    private String mCurrencyCode = null;
    public synchronized String getCurrencyCode() {
        return mCurrencyCode;
    }
    public synchronized void setCurrencyCode(final String currencyCode) {
        mCurrencyCode = currencyCode;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.CURRENCY_CODE, currencyCode)));
            }
        });
    }

    private String mDeviceBrand = null;
    public synchronized String getDeviceBrand() {
        return mDeviceBrand;
    }
    public synchronized void setDeviceBrand(final String deviceBrand) {
        mDeviceBrand = deviceBrand;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_BRAND, deviceBrand)));
            }
        });
    }

    private String mDeviceBuild = null;
    public synchronized String getDeviceBuild() {
        return mDeviceBuild;
    }
    public synchronized void setDeviceBuild(final String deviceBuild) {
        mDeviceBuild = deviceBuild;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_BUILD, deviceBuild)));
            }
        });
    }

    private String mDeviceCarrier = null;
    public synchronized String getDeviceCarrier() {
        return mDeviceCarrier;
    }
    public synchronized void setDeviceCarrier(final String carrier) {
        mDeviceCarrier = carrier;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_CARRIER, carrier)));
            }
        });
    }

    private String mDeviceCpuType = null;
    public synchronized String getDeviceCpuType() {
        return mDeviceCpuType;
    }
    public synchronized void setDeviceCpuType(final String cpuType) {
        mDeviceCpuType = cpuType;
        mExecutor.execute(new Runnable() {
            public void run() {
                // TODO: Confirm type
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_CPU_TYPE, cpuType)));
            }
        });
    }

    private String mDeviceCpuSubtype = null;
    public synchronized String getDeviceCpuSubtype() {
        return mDeviceCpuSubtype;
    }
    public synchronized void setDeviceCpuSubtype(final String cpuType) {
        mDeviceCpuSubtype = cpuType;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_CPU_SUBTYPE, cpuType)));
            }
        });
    }

    private String mDeviceId = null;
    public synchronized String getDeviceId() {
        return mDeviceId;
    }
    public synchronized void setDeviceId(final String deviceId) {
        mDeviceId = deviceId;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_ID, deviceId)));
            }
        });
    }
    
    private String mDeviceModel = null;
    public synchronized String getDeviceModel() {
        return mDeviceModel;
    }
    public synchronized void setDeviceModel(final String model) {
        mDeviceModel = model;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEVICE_MODEL, model)));
            }
        });
    }

    private boolean mDebugMode = false;
    public synchronized boolean getDebugMode() {
        return mDebugMode;
    }
    public synchronized void setDebugMode(final boolean debug) {
        mDebugMode = debug;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.DEBUG_MODE, debug)));
            }
        });
    }
    
    private String mExistingUser = null;
    public synchronized String getExistingUser() {
        return mExistingUser;
    }
    public synchronized void setExistingUser(final String existingUser) {
        mExistingUser = existingUser;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.EXISTING_USER, TuneUtils.convertToBoolean(existingUser))));
            }
        });
    }
    
    private String mFbUserId = null;
    public synchronized String getFacebookUserId() {
        return mFbUserId;
    }
    public synchronized void setFacebookUserId(final String fb_user_id) {
        mFbUserId = fb_user_id;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.FACEBOOK_USER_ID, fb_user_id)));
            }
        });
    }

    private String mFireAdvertisingId = null;
    public synchronized String getFireAdvertisingId() {
        return mFireAdvertisingId;
    }
    public synchronized void setFireAdvertisingId(final String adId) {
        mFireAdvertisingId = adId;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.FIRE_AID, adId)));
            }
        });
    }

    private String mFireAdTrackingLimited = null;
    public synchronized String getFireAdTrackingLimited() {
        return mFireAdTrackingLimited;
    }
    public synchronized void setFireAdTrackingLimited(final String limited) {
        mFireAdTrackingLimited = limited;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.FIRE_AD_TRACKING_DISABLED, limited)));
            }
        });
    }
    
    private String mGender = null;
    public synchronized String getGender() {
        return mGender;
    }
    public synchronized void setGender(TuneGender gender) {
        if (gender == TuneGender.MALE) {
            mGender = "0";
        } else if (gender == TuneGender.FEMALE) {
            mGender = "1";
        } else {
            mGender = "";
        }
        mExecutor.execute(new Runnable() {
            public void run() {
                String setGender = mGender;
                if (setGender.length() == 0) {
                    // TODO: REVISIT
                    setGender = "2";
                }
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GENDER, setGender, TuneVariableType.FLOAT)));
            }
        });

    }

    private String mGaid = null;
    public synchronized String getGoogleAdvertisingId() {
        return mGaid;
    }
    public synchronized void setGoogleAdvertisingId(final String adId) {
        mGaid = adId;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_AID, adId)));
            }
        });
    }

    private String mGaidLimited = null;
    public synchronized String getGoogleAdTrackingLimited() {
        return mGaidLimited;
    }
    public synchronized void setGoogleAdTrackingLimited(final String limited) {
        mGaidLimited = limited;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, limited)));
            }
        });
    }
    
    private String mGgUserId = null;
    public synchronized String getGoogleUserId() {
        return mGgUserId;
    }
    public synchronized void setGoogleUserId(final String google_user_id) {
        mGgUserId = google_user_id;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_USER_ID, google_user_id)));
            }
        });
    }

    private String mInstallDate = null;
    public synchronized String getInstallDate() {
        return mInstallDate;
    }
    public synchronized void setInstallDate(final String installDate) {
        mInstallDate = installDate;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.INSTALL_DATE, new Date(Long.parseLong(installDate) * 1000))));
            }
        });
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
    public synchronized void setInstaller(final String installer) {
        mInstallerPackage = installer;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.INSTALLER, installer)));
            }
        });
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
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.INSTALL_REFERRER, installReferrer)));
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
    public synchronized String getIsPayingUser() {
        if (mIsPayingUser == null) {
            mIsPayingUser = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_PAYING_USER, null);
        }
        return mIsPayingUser;
    }
    public synchronized void setIsPayingUser(final String isPayingUser) {
        mIsPayingUser = isPayingUser;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_PAYING_USER, isPayingUser);
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.IS_PAYING_USER, TuneUtils.convertToBoolean(isPayingUser))));
            }
        });
    }

    private String mLanguage = null;
    public synchronized String getLanguage() {
        return mLanguage;
    }
    public synchronized void setLanguage(final String language) {
        mLanguage = language;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LANGUAGE, language)));
            }
        });
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
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LAST_OPEN_LOG_ID, logId)));
            }
        });
    }

    private String mLatitude = null;
    public synchronized String getLatitude() {
        return mLatitude;
    }
    public synchronized void setLatitude(final String latitude) {
        mLatitude = latitude;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LATITUDE, latitude)));
                if (mLongitude != null) {
                    TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.GEO_COORDINATE, new TuneLocation(Double.valueOf(mLongitude), Double.valueOf(mLatitude)))));
                }
            }
        });
    }

    private String mLocale = null;
    public synchronized String getLocale() {
        return mLocale;
    }
    public synchronized void setLocale(final String locale) {
        mLocale = locale;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LOCALE, locale)));
            }
        });
    }

    private TuneLocation mLocation = null;
    public synchronized TuneLocation getLocation() {
        return mLocation;
    }
    public synchronized void setLocation(final TuneLocation location) {
        mLocation = location;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.GEO_COORDINATE, location)));
            }
        });
    }

    private String mLongitude = null;
    public synchronized String getLongitude() {
        return mLongitude;
    }
    public synchronized void setLongitude(final String longitude) {
        mLongitude = longitude;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.LONGITUDE, longitude)));
                if (mLatitude != null) {
                    TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.GEO_COORDINATE, new TuneLocation(Double.valueOf(mLongitude), Double.valueOf(mLatitude)))));
                }
            }
        });
    }

    private String mMacAddress = null;
    public synchronized String getMacAddress() {
        return mMacAddress;
    }
    public synchronized void setMacAddress(final String mac_address) {
        mMacAddress = mac_address;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MAC_ADDRESS, mac_address)));
            }
        });
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
    public synchronized void setMCC(final String mcc) {
        mMCC = mcc;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MOBILE_COUNTRY_CODE, mcc)));
            }
        });
    }

    private String mMNC = null;
    public synchronized String getMNC() {
        return mMNC;
    }
    public synchronized void setMNC(final String mnc) {
        mMNC = mnc;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.MOBILE_NETWORK_CODE, mnc)));
            }
        });
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
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.OPEN_LOG_ID, logId)));
            }
        });
    }

    private String mOsVersion = null;
    public synchronized String getOsVersion() {
        return mOsVersion;
    }
    public synchronized void setOsVersion(final String osVersion) {
        mOsVersion = osVersion;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.OS_VERSION, osVersion, TuneVariableType.VERSION)));
            }
        });
    }

    private String mPackageName = null;
    public synchronized String getPackageName() {
        return mPackageName;
    }
    public synchronized void setPackageName(final String packageName) {
        mPackageName = packageName;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PACKAGE_NAME, packageName)));
                // Save package name to SharedPreferences for IAM App ID
                // TODO: REVISIT.  This has too much knowledge of how UserProfile values are saved.
                new TuneSharedPrefsDelegate(mContext, TuneUserProfile.PREFS_TMA_PROFILE).saveToSharedPreferences(TuneUrlKeys.PACKAGE_NAME, packageName);
            }
        });
    }

    private String mPhoneNumber = null;
    public synchronized String getPhoneNumber() {
        if (mPhoneNumber == null) {
            mPhoneNumber = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_PHONE_NUMBER, null);
        }
        return mPhoneNumber;
    }
    public synchronized void setPhoneNumber(final String phoneNumber) {
        mPhoneNumber = phoneNumber;
        setPhoneNumberMd5(TuneUtils.md5(phoneNumber));
        setPhoneNumberSha1(TuneUtils.sha1(phoneNumber));
        setPhoneNumberSha256(TuneUtils.sha256(phoneNumber));

        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_PHONE_NUMBER, phoneNumber);
            }
        });

    }
    
    private String mPhoneNumberMd5;
    public synchronized String getPhoneNumberMd5() {
        return mPhoneNumberMd5;
    }
    public synchronized void setPhoneNumberMd5(final String phoneNumberMd5) {
        mPhoneNumberMd5 = phoneNumberMd5;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_PHONE_MD5)
                                .withValue(phoneNumberMd5)
                                .withHash(TuneHashType.MD5)
                                .build()));
            }
        });
    }
    
    private String mPhoneNumberSha1;
    public synchronized String getPhoneNumberSha1() {
        return mPhoneNumberSha1;
    }
    public synchronized void setPhoneNumberSha1(final String phoneNumberSha1) {
        mPhoneNumberSha1 = phoneNumberSha1;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_PHONE_SHA1)
                                .withValue(phoneNumberSha1)
                                .withHash(TuneHashType.SHA1)
                                .build()));
            }
        });
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
    public synchronized void setPluginName(final String pluginName) {
        mPluginName = pluginName;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SDK_PLUGIN, pluginName)));
            }
        });
    }

    private boolean mPrivacyProtectedDueToAge = false;
    public synchronized boolean isPrivacyProtectedDueToAge() {
        return mPrivacyProtectedDueToAge;
    }
    public synchronized void setPrivacyProtectedDueToAge(final boolean isPrivacyProtectedDueToAge) {
        mPrivacyProtectedDueToAge = isPrivacyProtectedDueToAge;
        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveBooleanToSharedPreferences(TuneConstants.KEY_COPPA, isPrivacyProtectedDueToAge);
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.IS_COPPA, isPrivacyProtectedDueToAge)));
            }
        });
    }
    private synchronized void loadPrivacyProtectedSetting() {
        mPrivacyProtectedDueToAge = mPrefs.getBooleanFromSharedPreferences(TuneConstants.KEY_COPPA);
    }

    private String mPurchaseStatus = null;
    public synchronized String getPurchaseStatus() {
        return mPurchaseStatus;
    }
    public synchronized void setPurchaseStatus(final String purchaseStatus) {
        mPurchaseStatus = purchaseStatus;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PURCHASE_STATUS, purchaseStatus)));
            }
        });
    }

    private String mReferralSource = null;
    public synchronized String getReferralSource() {
        return mReferralSource;
    }
    public synchronized void setReferralSource(final String referralPackage) {
        mReferralSource = referralPackage;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.REFERRAL_SOURCE, referralPackage)));
            }
        });
    }

    private String mReferralUrl = null;
    public synchronized String getReferralUrl() {
        return mReferralUrl;
    }
    public synchronized void setReferralUrl(final String referralUrl) {
        mReferralUrl = referralUrl;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.REFERRAL_URL, referralUrl)));
            }
        });
    }

    private String mReferrerDelay = null;
    public synchronized String getReferrerDelay() {
        return mReferrerDelay;
    }
    public synchronized void setReferrerDelay(final long referrerDelay) {
        mReferrerDelay = Long.toString(referrerDelay);
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.REFERRER_DELAY, referrerDelay)));
            }
        });
    }

    private String mScreenDensity = null;
    public synchronized String getScreenDensity() {
        return mScreenDensity;
    }
    public synchronized void setScreenDensity(final String density) {
        mScreenDensity = density;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SCREEN_DENSITY, Float.parseFloat(density))));
            }
        });
    }

    private String mScreenHeight = null;
    public synchronized String getScreenHeight() {
        return mScreenHeight;
    }
    public synchronized void setScreenHeight(final String screenheight) {
        mScreenHeight = screenheight;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.SCREEN_HEIGHT, Integer.parseInt(screenheight))));
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SCREEN_SIZE, getScreenWidth() + "x" + getScreenHeight())));
            }
        });
    }

    private String mScreenWidth = null;
    public synchronized String getScreenWidth() {
        return mScreenWidth;
    }
    public synchronized void setScreenWidth(final String screenwidth) {
        mScreenWidth = screenwidth;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneProfileKeys.SCREEN_WIDTH, Integer.parseInt(screenwidth))));
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.SCREEN_SIZE, getScreenWidth() + "x" + getScreenHeight())));
            }
        });
    }

    /**
     * @return the SDK Version
     * @deprecated Use {@link Tune#getSDKVersion()}  }
     */
    public synchronized String getSdkVersion() {
        return Tune.getSDKVersion();
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
    public synchronized void setTrackingId(final String trackingId) {
        mTrackingId = trackingId;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.TRACKING_ID, trackingId)));
            }
        });
    }

    private String mTrusteId = null;
    public synchronized String getTRUSTeId() {
        return mTrusteId;
    }
    public synchronized void setTRUSTeId(final String tpid) {
        mTrusteId = tpid;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.TRUSTE_ID, tpid)));
            }
        });
    }
    
    private String mTwUserId = null;
    public synchronized String getTwitterUserId() {
        return mTwUserId;
    }
    public synchronized void setTwitterUserId(final String twitter_user_id) {
        mTwUserId = twitter_user_id;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.TWITTER_USER_ID, twitter_user_id)));
            }
        });
    }

    private String mUserAgent = null;
    public synchronized String getUserAgent() {
        return mUserAgent;
    }
    private synchronized void setUserAgent(final String userAgent) {
        mUserAgent = userAgent;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.USER_AGENT, userAgent)));
            }
        });
    }

    private String mUserEmail = null;
    public synchronized String getUserEmail() {
        if (mUserEmail == null) {
            mUserEmail = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_EMAIL, null);
        }
        return mUserEmail;
    }
    public synchronized void setUserEmail(final String userEmail) {
        mUserEmail = userEmail;
        setUserEmailMd5(TuneUtils.md5(userEmail));
        setUserEmailSha1(TuneUtils.sha1(userEmail));
        setUserEmailSha256(TuneUtils.sha256(userEmail));

        mExecutor.execute(new Runnable() {
            public void run() {
                mPrefs.saveToSharedPreferences(TuneConstants.KEY_USER_EMAIL, userEmail);
            }
        });
    }
    
    private String mUserEmailMd5;
    public synchronized String getUserEmailMd5() {
        return mUserEmailMd5;
    }
    public synchronized void setUserEmailMd5(final String userEmailMd5) {
        mUserEmailMd5 = userEmailMd5;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAIL_MD5)
                                .withValue(userEmailMd5)
                                .withHash(TuneHashType.MD5)
                                .build()));
            }
        });
    }
    
    private String mUserEmailSha1;
    public synchronized String getUserEmailSha1() {
        return mUserEmailSha1;
    }
    public synchronized void setUserEmailSha1(final String userEmailSha1) {
        mUserEmailSha1 = userEmailSha1;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAIL_SHA1)
                                .withValue(userEmailSha1)
                                .withHash(TuneHashType.SHA1)
                                .build()));
            }
        });
    }
    
    private String mUserEmailSha256;
    public synchronized String getUserEmailSha256() {
        return mUserEmailSha256;
    }
    public synchronized void setUserEmailSha256(final String userEmailSha256) {
        mUserEmailSha256 = userEmailSha256;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAIL_SHA256)
                                .withValue(userEmailSha256)
                                .withHash(TuneHashType.SHA256)
                                .build()));
            }
        });
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
        mExecutor.execute(new Runnable() {
            public void run() {
                try {
                    TuneEventBus.post(new TuneUpdateUserProfile(
                            TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_EMAILS)
                                    .withValue(mUserEmails.join(","))
                                    .build()));
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });

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
                TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.USER_ID, user_id)));
            }
        });
    }

    private String mUserName = null;
    public synchronized String getUserName() {
        if (mUserName == null) {
            mUserName = mPrefs.getStringFromSharedPreferences(TuneConstants.KEY_USER_NAME, null);
        }
        return mUserName;
    }
    public synchronized void setUserName(final String userName) {
        mUserName = userName;
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
    public synchronized void setUserNameMd5(final String userNameMd5) {
        mUserNameMd5 = userNameMd5;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_NAME_MD5)
                                .withValue(userNameMd5)
                                .withHash(TuneHashType.MD5)
                                .build()));
            }
        });
    }
    
    private String mUserNameSha1;
    public synchronized String getUserNameSha1() {
        return mUserNameSha1;
    }
    public synchronized void setUserNameSha1(final String userNameSha1) {
        mUserNameSha1 = userNameSha1;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_NAME_SHA1)
                                .withValue(userNameSha1)
                                .withHash(TuneHashType.SHA1)
                                .build()));
            }
        });
    }
    
    private String mUserNameSha256;
    public synchronized String getUserNameSha256() {
        return mUserNameSha256;
    }
    public synchronized void setUserNameSha256(final String userNameSha256) {
        mUserNameSha256 = userNameSha256;
        mExecutor.execute(new Runnable() {
            public void run() {
                TuneEventBus.post(new TuneUpdateUserProfile(
                        TuneAnalyticsVariable.Builder(TuneUrlKeys.USER_NAME_SHA256)
                                .withValue(userNameSha256)
                                .withHash(TuneHashType.SHA256)
                                .build()));
            }
        });
    }
}
