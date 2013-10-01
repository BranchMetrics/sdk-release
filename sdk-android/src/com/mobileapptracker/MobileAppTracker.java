package com.mobileapptracker;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Observable;
import java.util.Observer;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.database.Cursor;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.view.WindowManager;
import android.webkit.WebView;

/**
 * @author tony@hasoffers.com
 * @author john.gu@hasoffers.com
 */
public class MobileAppTracker implements Observer {
    public static final int GENDER_MALE = 0;
    public static final int GENDER_FEMALE = 1;
    
    private static final Uri ATTRIBUTION_ID_CONTENT_URI = Uri.parse("content://com.facebook.katana.provider.AttributionIdProvider");
    private static final String ATTRIBUTION_ID_COLUMN_NAME = "aid";
    private static final String IV = "heF9BATUfWuISyO8";
    
    // Interface for reading platform response to tracking calls
    private MATResponse matResponse;
    // Interface for making url requests
    private UrlRequester urlRequester;
    
    // Whether connectivity receiver is registered or not
    private boolean isRegistered = false;
    // Whether to allow duplicate installs from this device
    private boolean allowDups = false;
    // Whether to show debug output
    private boolean debugMode = false;
    // Whether variables were initialized correctly
    private boolean initialized = false;
    // Whether MobileAppTracker class was constructed
    private boolean constructed = false;
    // Whether app has been installed or not
    private String install;
    // Advertiser key in our system
    private String key;
    
    // Table of fields to pass in http request
    private ConcurrentHashMap<String, String> paramTable;
    // The context passed into the constructor
    private Context context;
    // Local Encryption object
    private Encryption URLEnc;
    // Thread pool for running the GetLink Runnables
    private ScheduledExecutorService pool;
    // The fields to encrypt in http request
    private List<String> encryptList;
    // Binary semaphore for controlling adding to queue/dumping queue
    private Semaphore queueAvailable;
    // SharedPreferences for storing events that were not fired
    private SharedPreferences EventQueue;
    private SharedPreferences SP;
    
    /**
     * Instantiates a new MobileAppTracker.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     */
    public MobileAppTracker(Context context, String advertiserId, String key) {
        if (constructed) return;
        constructed = true;
        this.context = context;
        pool = Executors.newSingleThreadScheduledExecutor();
        queueAvailable = new Semaphore(1, true);
        urlRequester = new UrlRequester();
        
        paramTable = new ConcurrentHashMap<String, String>();
        encryptList = Arrays.asList("ir",
                                    "d",
                                    "db",
                                    "dm",
                                    "ma",
                                    "ov",
                                    "cc",
                                    "l",
                                    "an",
                                    "pn",
                                    "av",
                                    "dc",
                                    "ad",
                                    "android_id_md5",
                                    "android_id_sha1",
                                    "android_id_sha256",
                                    "r",
                                    "c",
                                    "id",
                                    "ua",
                                    "tpid",
                                    "ar",
                                    "ti",
                                    "age",
                                    "gender",
                                    "latitude",
                                    "longitude",
                                    "altitude",
                                    "connection_type",
                                    "mobile_country_code",
                                    "mobile_network_code",
                                    "screen_density",
                                    "screen_layout_size",
                                    "android_purchase_status",
                                    "referral_source",
                                    "referral_url",
                                    "app_ad_tracking");
        
        // Add listener for INSTALL_REFERRER
        Tracker.getObservable().addObserver(this);
        
        initialized = initializeVariables(context, advertiserId, key);
        
        // Try to convert context to an Activity to get referral source and url
        try {
            Activity act = ((Activity) context);
            // Set source package
            setReferralSource(act.getCallingPackage());
            // Set source url query
            Intent intent = act.getIntent();
            if (intent != null) {
                Uri uri = intent.getData();
                if (uri != null) {
                    String referralUrl = uri.toString();
                    setReferralUrl(referralUrl);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            Log.d(MATConstants.TAG,"Context is not an Activity, can't get referral source and url");
        }
        
        URLEnc = new Encryption(key, MobileAppTracker.IV);
        EventQueue = context.getSharedPreferences(MATConstants.PREFS_NAME, 0);
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        install = SP.getString("install", "");
        if (initialized && getQueueSize() > 0 && isOnline()) {
            try {
                dumpQueue();
            } catch (InterruptedException e) {
                e.printStackTrace();
                Thread.currentThread().interrupt();
            }
        }
        
        // Set up connectivity listener so we dump the queue when re-connected to Internet
        BroadcastReceiver networkStateReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (isOnline() && getQueueSize() > 0) {
                    try {
                        dumpQueue();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                        Thread.currentThread().interrupt();
                    }
                }
            }
        };
        
        if (isRegistered) {
            // Unregister receiver in case one is still previously registered
            context.getApplicationContext().unregisterReceiver(networkStateReceiver);
            isRegistered = false;
        }
        
        IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
        context.getApplicationContext().registerReceiver(networkStateReceiver, filter);
        isRegistered = true;
    }

    /**
     * Saves an event to the queue, used if there is no Internet connection.
     * @param link URL of the event postback
     * @param eventItems (Optional) MATEventItem JSON information to post to server
     * @param action the action for the event (conversion/install/open)
     * @param revenue value associated with the event
     * @param currency currency code for the revenue
     * @param refId the advertiser ref ID associated with the event
     * @param iapData the receipt data from Google Play
     * @param iapSignature the receipt signature from Google Play
     * @param shouldBuildData whether link needs encrypted data to be appended or not
     */
    private void addEventToQueue(String link, String eventItems, String action, double revenue, String currency, String refId, String iapData, String iapSignature, boolean shouldBuildData) throws InterruptedException {
        // Acquire semaphore before modifying queue
        queueAvailable.acquire();

        try {
            // JSON-serialize the link and json to store in Shared Preferences as a string
            JSONObject jsonEvent = new JSONObject();
            try {
                jsonEvent.put("link", link);
                if (eventItems != null) {
                    jsonEvent.put("event_items", eventItems);
                }
                jsonEvent.put("action", action);
                jsonEvent.put("revenue", revenue);
                if (currency == null) {
                    currency = "USD";
                }
                jsonEvent.put("currency", currency);
                if (refId != null) {
                    jsonEvent.put("ref_id", refId);
                }
                if (iapData != null) {
                    jsonEvent.put("iap_data", iapData);
                }
                if (iapSignature != null) {
                    jsonEvent.put("iap_signature", iapSignature);
                }
                jsonEvent.put("should_build_data", shouldBuildData);
            } catch (JSONException e) {
                e.printStackTrace();
                // Return if we can't create JSONObject
                return;
            }
            SharedPreferences.Editor editor = EventQueue.edit();
            int count = getQueueSize() + 1;
            setQueueSize(count);
            String eventIndex = Integer.valueOf(count).toString();
            editor.putString(eventIndex, jsonEvent.toString());
            editor.commit();
        } finally {
            queueAvailable.release();
        }
    }

    /**
     * Returns the current event queue size.
     * @return the event queue size
     */
    private int getQueueSize() {
        return EventQueue.getInt("queuesize", 0);
    }

    /**
     * Sets the event queue size to value.
     * @param value the new queue size
     */
    private void setQueueSize(int value) {
        SharedPreferences.Editor editor = EventQueue.edit();
        if (value < 0) value = 0;
        editor.putInt("queuesize", value);
        editor.commit();
    }

    /**
     * Processes the event queue, method will only process MAX_DUMP_SIZE events per call.
     * @return void
     * @throws InterruptedException 
     */
    private synchronized void dumpQueue() throws InterruptedException {
        queueAvailable.acquire();
        
        try {
            int size = getQueueSize();
            if (size == 0) {
                return;
            }
            
            int index = 1;
            if (size > MATConstants.MAX_DUMP_SIZE) {
                index = 1 + (size - MATConstants.MAX_DUMP_SIZE);
            }
            
            // Iterate through events and do postbacks for each, using GetLink
            for (; index <= size; index++) {
                String key = Integer.valueOf(index).toString();
                String eventJson = EventQueue.getString(key, null);
                
                if (eventJson != null) {
                    String link = null;
                    String eventItems = null;
                    String action = null;
                    double revenue = 0;
                    String currency = null;
                    String refId = null;
                    String iapData = null;
                    String iapSignature = null;
                    boolean shouldBuildData = false;
                    try {
                        // De-serialize the stored string from the queue to get URL and json values
                        JSONObject event = new JSONObject(eventJson);
                        link = event.getString("link");
                        if (event.has("event_items")) {
                            eventItems = event.getString("event_items");
                        }
                        action = event.getString("action");
                        revenue = event.getDouble("revenue");
                        currency = event.getString("currency");
                        if (event.has("ref_id")) {
                            refId = event.getString("ref_id");
                        }
                        if (event.has("iap_data")) {
                            iapData = event.getString("iap_data");
                        }
                        if (event.has("iap_signature")) {
                            iapSignature = event.getString("iap_signature");
                        }
                        shouldBuildData = event.getBoolean("should_build_data");
                    } catch (JSONException e) {
                        e.printStackTrace();
                        // Can't rebuild saved request, remove from queue and return
                        setQueueSize(getQueueSize() - 1);
                        SharedPreferences.Editor editor = EventQueue.edit();
                        editor.remove(key);
                        editor.commit();
                        return;
                    }
                    
                    // Remove request from queue and execute
                    setQueueSize(getQueueSize() - 1);
                    SharedPreferences.Editor editor = EventQueue.edit();
                    editor.remove(key);
                    editor.commit();
                    
                    try {
                        pool.execute(new GetLink(link, eventItems, action, revenue, currency, refId, iapData, iapSignature, shouldBuildData));
                    } catch (Exception e) {
                        e.printStackTrace();
                        Log.d(MATConstants.TAG, "Request could not be executed from queue");
                    }
                }
            }
        } finally {
            queueAvailable.release();
        }
    }

    /**
     * Returns the class initialization state.
     * @return whether MobileAppTracker was initialized or not
     */
    public boolean isInitialized() {
        return initialized;
    }

    /**
     * Returns true if an Internet connection is detected.
     * @return whether Internet connection exists
     */
    private boolean isOnline() {
        ConnectivityManager connectivityManager = (ConnectivityManager) this.context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    /**
     * Initializes all main class variables.
     * @param context the application context
     * @param advertiserId the advertiser id in MAT
     * @param key the advertiser key
     * @return whether variables were initialized successfully
     */
    private boolean initializeVariables(Context context, String advertiserId, String key) {
        try {
            // Strip the whitespace from advertiser id and key before storing
            setAdvertiserId(advertiserId.trim());
            setKey(key.trim());
            setAction("conversion");
            
            boolean collectDeviceId = false;
            boolean collectMacAddress = false;
            if (context.checkCallingOrSelfPermission(MATConstants.DEVICE_ID_PERMISSION) == PackageManager.PERMISSION_GRANTED) {
                collectDeviceId = true;
            }
            if (context.checkCallingOrSelfPermission(MATConstants.MAC_ADDRESS_PERMISSION) == PackageManager.PERMISSION_GRANTED) {
                collectMacAddress = true;
            }
            
            SP = context.getSharedPreferences(MATConstants.PREFS_MAT_ID, 0);
            String matId = SP.getString("mat_id", "");
            if (matId.length() == 0) {
                // generate MAT ID once and save in shared preferences
                matId = UUID.randomUUID().toString();
                SharedPreferences.Editor editor = SP.edit();
                editor.putString("mat_id", matId);
                editor.commit();
            }
            setMatId(matId);
            setAndroidId(Secure.getString(context.getContentResolver(), Secure.ANDROID_ID));
            setDeviceModel(android.os.Build.MODEL);
            setDeviceBrand(android.os.Build.MANUFACTURER);
            setOsVersion(android.os.Build.VERSION.RELEASE);
            
            // Only collect device id if READ_PHONE_STATE permission exists
            if (collectDeviceId) {
                setDeviceId(getDeviceId(context));
            }
            
            // Only collect MAC address if ACCESS_WIFI_STATE permission exists
            if (collectMacAddress) {
                WifiManager wifiMan = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
                if (wifiMan != null) {
                    WifiInfo wifiInfo = wifiMan.getConnectionInfo();
                    if (wifiInfo != null) {
                        if (wifiInfo.getMacAddress() != null) {
                            setMacAddress(wifiInfo.getMacAddress());
                        }
                    }
                }
            }
            
            // Set the device connection type, WIFI or mobile
            ConnectivityManager connManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
            if (mWifi.isConnected()) {
                setConnectionType("WIFI");
            } else {
                setConnectionType("mobile");
            }
            
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
            if (tm != null) {
                if (tm.getNetworkCountryIso() != null) {
                    setCountryCode(tm.getNetworkCountryIso());
                } else if (collectDeviceId) {
                    if (tm.getSimCountryIso() != null) {
                        setCountryCode(tm.getSimCountryIso());
                    }
                }
                setCarrier(tm.getNetworkOperatorName());
                
                // Set Mobile Country Code and Mobile Network Code
                String networkOperator = tm.getNetworkOperator();
                if (networkOperator != null) {
                    try {
                        String mcc = networkOperator.substring(0, 3);
                        String mnc = networkOperator.substring(3);
                        setMCC(mcc);
                        setMNC(mnc);
                    } catch (IndexOutOfBoundsException e) {
                        // networkOperator is unreliable for CDMA devices
                        Log.d(MATConstants.TAG, "MCC/MNC not found");
                    }
                }
            } else {
                setCountryCode(Locale.getDefault().getCountry());
            }
            
            setLanguage(Locale.getDefault().getDisplayLanguage(Locale.US));
            setCurrencyCode("USD");
            
            String packageName = context.getPackageName();
            setPackageName(packageName);
            
            PackageManager pm = context.getPackageManager();
            ApplicationInfo ai;
            try {
                ai = pm.getApplicationInfo(packageName, 0);
            } catch (NameNotFoundException e) {
                ai = null;
                Log.d(MATConstants.TAG, "ApplicationInfo not found");
                e.printStackTrace();
            }
            if (ai != null) {
                setAppName(pm.getApplicationLabel(ai).toString());
                
                String appFile = pm.getApplicationInfo(packageName, 0).sourceDir;
                long insdate = new File(appFile).lastModified();
                Date installDate = new Date(insdate);
                SimpleDateFormat sdfDate = new SimpleDateFormat(MATConstants.DATE_FORMAT, Locale.US);
                sdfDate.setTimeZone(TimeZone.getTimeZone("UTC"));
                setInstallDate(sdfDate.format(installDate));
            }
            
            try {
                PackageInfo pi = pm.getPackageInfo(packageName, 0);
                setAppVersion(pi.versionCode);
            } catch (NameNotFoundException e) {
                Log.d(MATConstants.TAG, "App version not found");
                setAppVersion(0);
            }
            
            SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
            install = SP.getString("install", "");
            
            // execute Runnable on UI thread to set user agent
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new GetUserAgent(context));
            
            // Set screen density
            float density = context.getResources().getDisplayMetrics().density;
            setScreenDensity(Float.toString(density));
            
            // Set screen layout size
            WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            @SuppressWarnings("deprecation")
            int width = wm.getDefaultDisplay().getWidth();
            @SuppressWarnings("deprecation")
            int height = wm.getDefaultDisplay().getHeight();
            setScreenSize(Integer.toString(width) + "x" + Integer.toString(height));
            
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            Log.d(MATConstants.TAG, "MobileAppTracker initialization failed");
            return false;
        }
    }

    /**
     * Insert referring app info into target app's content provider. Redirects user to target app's download url if doRedirect is true.
     * @param publisherAdvertiserId the advertiser id of the publishing app (referring app)
     * @param targetPackageName the target package name being referred to
     * @param publisherId (optional) the publisher id for referral
     * @param campaignId (optional) the campaign id for referral
     * @param doRedirect whether to automatically redirect user to target app's url or not
     * @return download url to target app
     */
    public String setTracking(String publisherAdvertiserId, String targetPackageName, String publisherId, String campaignId, boolean doRedirect) {
        // Track a click with the app-to-app parameters and get a tracking ID back
        String trackingId = "";
        String redirectUrl = "";
        
        StringBuilder url = new StringBuilder("https://").append(MATConstants.MAT_DOMAIN).append("/serve?action=click&sdk=android");
        url.append("&publisher_advertiser_id=").append(publisherAdvertiserId);
        url.append("&package_name=").append(targetPackageName);
        if (publisherId != null) {
            url.append("&publisher_id=").append(publisherId);
        }
        if (campaignId != null) {
            url.append("&campaign_id=").append(campaignId);
        }
        url.append("&response_format=json");
        
        JSONObject response = urlRequester.requestUrl(url.toString(), null);
        if (response != null) {
            try {
                trackingId = response.getString("tracking_id");
                redirectUrl = response.getString("url");
            } catch (JSONException e) {
                Log.d(MATConstants.TAG, "Unable to get tracking ID or redirect url from app-to-app tracking");
                return "";
            }
        }
        
        ContentValues values = new ContentValues();
        values.put(MATProvider.PUBLISHER_PACKAGE_NAME, getPackageName());
        values.put(MATProvider.TRACKING_ID, trackingId);
        
        Uri CONTENT_URI = Uri.parse("content://" + targetPackageName + "/referrer_apps");
        context.getContentResolver().insert(CONTENT_URI, values);
        
        // If doRedirect is true, take user to the url returned by the server
        if (doRedirect) {
            try {
                Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(redirectUrl));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(i);
            } catch (ActivityNotFoundException e) {
                Log.d(MATConstants.TAG, "Unable to start activity to open " + redirectUrl);
            }
        }
        
        return redirectUrl;
    }

    /**
     * Main tracking install function, this function only needs to be successfully called one time on application install.
     * Subsequent calls will not send more installs.
     * @return 1 on request sent, 2 on already installed state, 3 on update, and -1 on failure
     */
    public int trackInstall() {
        SharedPreferences.Editor editor;
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        install = SP.getString("install", "");
        if (!install.equals("")) { // has it been tracked before?
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            String savedVersion = SP.getString("version", "");
            if (savedVersion.length() != 0 && Integer.parseInt(savedVersion) != getAppVersion()) { // If have been tracked before, check if is an update
                if (debugMode) Log.d(MATConstants.TAG, "App version has changed since last trackInstall, sending update to server");
                track("update", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
                editor = SP.edit();
                editor.putString("version", Integer.toString(getAppVersion()));
                editor.commit();
                return 3;
            }
            if (debugMode) Log.d(MATConstants.TAG, "Install has been tracked before");
            return 2;
        } else {
            // mark app as tracked so that postback url won't be called again
            SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
            editor = SP.edit();
            editor.putString("install", "installed");
            editor.commit();
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            editor = SP.edit();
            editor.putString("version", Integer.toString(getAppVersion()));
            editor.commit();
        }
        return track("install", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking update function, this function can be called to send an update event.
     * @return 1 on request sent and -1 on failure.
     */
    public int trackUpdate() {
        SharedPreferences.Editor editor;
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        install = SP.getString("install", "");
        if (!install.equals("")) { // has it been tracked before?
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            String savedVersion = SP.getString("version", "");
            if (savedVersion.length() != 0 && Integer.parseInt(savedVersion) != getAppVersion()) { // If have been tracked before, check if is an update
                if (debugMode) Log.d(MATConstants.TAG, "App version has changed since last trackInstall, sending update to server");
                track("update", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
                editor = SP.edit();
                editor.putString("version", Integer.toString(getAppVersion()));
                editor.commit();
                return 3;
            }
            if (debugMode) Log.d(MATConstants.TAG, "Update has been tracked before");
            return 2;
        } else {
            // mark app as tracked so that postback url won't be called again
            SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
            editor = SP.edit();
            editor.putString("install", "installed");
            editor.commit();
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            editor = SP.edit();
            editor.putString("version", Integer.toString(getAppVersion()));
            editor.commit();
            this.install = "installed";
        }
        return track("update", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track purchase events with a special purchase status parameter.
     * @param event event name or event ID in MAT system
     * @param purchaseStatus the status of the purchase: 0 for success, 1 for fail, 2 for refund
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure
     */
    public int trackPurchase(String event, int purchaseStatus, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        setPurchaseStatus(purchaseStatus);
        return track(event, null, revenue, currency, refId, inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name.
     * @param event event name or event ID in MAT system
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event) {
        return track(event, null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, and event item.
     * @param event event name or event ID in MAT system
     * @param eventItem event item to post to server.
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, MATEventItem eventItem) {
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(eventItem.toJSON());
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }
    
    /**
     * Tracking event function, track events by event ID or name, event item, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param eventItem event item to post to server.
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, MATEventItem eventItem, String inAppPurchaseData, String inAppSignature) {
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(eventItem.toJSON());
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name, and a list of event items.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list) {
        // Create a JSONArray of event items
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            jsonArray.put(list.get(i).toJSON());
        }
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }
    
    /**
     * Tracking event function, track events by event ID or name, a list of event items, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list, String inAppPurchaseData, String inAppSignature) {
        // Create a JSONArray of event items
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            jsonArray.put(list.get(i).toJSON());
        }
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue) {
        return track(event, null, revenue, getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue and currency.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency) {
        return track(event, null, revenue, currency, getRefId(), null, null);
    }
    
    /**
     * Tracking event function, track events by event ID or name, revenue, currency, and advertiser ref ID.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency, String refId) {
        return track(event, null, revenue, currency, refId, null, null);
    }
    
    /**
     * Tracking event function, track events by event ID or name, revenue, currency, advertiser ref ID, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        return track(event, null, revenue, currency, refId, inAppPurchaseData, inAppSignature);
    }

    /**
     * Method calls a new action event based on class member settings.
     * @param event event name or event ID in MAT system
     * @param eventItems MATEventItem json data to post to the server
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    private synchronized int track(String event, String eventItems, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        if (!initialized) return -1;
        
        if (isOnline() && getQueueSize() > 0) {
            try {
                dumpQueue();
            } catch (InterruptedException e) {
                e.printStackTrace();
                Thread.currentThread().interrupt();
            }
        }
        
        // Clear the parameters from parameter table that should be reset between events
        paramTable.remove("ei");
        paramTable.remove("en");
        paramTable.remove("ar");
        paramTable.remove("r");
        
        setAction("conversion"); // Default to conversion
        if (containsChar(event)) { // check if eventid contains a character
            if (event.equals("open")) setAction("open");
            else if (event.equals("close")) return -1; // Don't send close events anymore
            else if (event.equals("install")) setAction("install");
            else if (event.equals("update")) setAction("update");
            else setEventName(event);
        } else {
            setEventId(event);
        }
        
        String link = buildLink();
        if (link == null) {
            Log.d(MATConstants.TAG, "Error constructing url for tracking call");
            return -1;
        }
        
        String action = getAction();
        if (isOnline()) {
            try {
                if (getReferrer() == null || (getInstallLogId() == null && getUpdateLogId() == null)) {
                    pool.schedule(new GetLink(link, eventItems, action, revenue, currency, refId, inAppPurchaseData, inAppSignature, true), MATConstants.DELAY, TimeUnit.MILLISECONDS);
                } else {
                    pool.execute(new GetLink(link, eventItems, action, revenue, currency, refId, inAppPurchaseData, inAppSignature, true));
                }
            } catch (Exception e) {
                e.printStackTrace();
                Log.d(MATConstants.TAG, "Request could not be executed from track");
            }
        } else {
            if (!action.equals("open")) {
                if (debugMode) Log.d(MATConstants.TAG, "Not online: track will be queued");
                try {
                    addEventToQueue(link, eventItems, action, revenue, currency, refId, inAppPurchaseData, inAppSignature, true);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    Thread.currentThread().interrupt();
                }
            }
        }
        return 1;
    }
    
    /**
     * Builds a new link string based on class member values.
     * @return encrypted URL string based on class settings.
     */
    private String buildLink() {
        StringBuilder link = new StringBuilder("https://").append(getAdvertiserId()).append(".");
        if (debugMode) {
            link.append(MATConstants.MAT_DOMAIN_DEBUG);
        } else {
            link.append(MATConstants.MAT_DOMAIN);
        }
        link.append("/serve?s=android&ver=").append(MATConstants.SDK_VERSION).append("&pn=").append(getPackageName());
        for (String key: paramTable.keySet()) {
            // Append fields from paramTable that don't need to be encrypted
            if (!encryptList.contains(key)) {
                link.append("&").append(key).append("=").append(paramTable.get(key));
            }
        }
        
        // If allow duplicates on, skip duplicate check logic
        if (allowDups) {
            link.append("&skip_dup=1");
        }
        
        // If logging on, use debug mode
        if (debugMode) {
            link.append("&debug=1");
        }
        
        // Append app-to-app tracking id if exists
        try {
            Uri allTitles = Uri.parse("content://" + getPackageName() + "/referrer_apps");
            Cursor c = context.getContentResolver().query(allTitles, null, null, null, "publisher_package_name desc");
            // Append tracking ID from content provider if exists
            if (c != null && c.moveToFirst()) {
                String trackingId = c.getString(c.getColumnIndex(MATProvider.TRACKING_ID));
                // UTF-8 encode the tracking ID
                try {
                    trackingId = URLEncoder.encode(trackingId, "UTF-8");
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
                
                // Add to paramTable for data encrypting
                paramTable.put("ti", trackingId);
                c.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
            Log.d(MATConstants.TAG, "Error reading app-to-app values");
        }
        return link.toString();
    }
    
    /**
     * Builds encrypted data in conversion link based on class member values.
     * @param origLink the base URL to append data to
     * @param action the event action (install/update/open/conversion)
     * @param revenue revenue associated with event
     * @param currency currency code for event
     * @param refId the advertiser ref ID to associate with the event
     * @return encrypted URL string based on class settings.
     */
    private String buildData(String origLink, String action, double revenue, String currency, String refId) {
        StringBuilder link = new StringBuilder(origLink);
        
        setRevenue(revenue);
        if (currency != null) {
            setCurrencyCode(currency);
        }
        setRefId(refId);
        
        // Try to update referrer value if we don't have one
        if (getReferrer() == null) {
            SP = context.getSharedPreferences(MATConstants.PREFS_REFERRER, 0);
            String referrer = SP.getString("referrer", "");
            setReferrer(referrer);
        }
        
        // For opens and events, try to add install_log_id
        if (action.equals("open") || action.equals("conversion")) {
            // Append install log id for opens and events if we have it stored
            if (getInstallLogId().length() > 0) {
                link.append("&install_log_id=" + getInstallLogId());
            } else if (getUpdateLogId().length() > 0) {
                link.append("&update_log_id=" + getUpdateLogId());
            } else {
                // Call GetLog endpoint
                if (isTodayLatestDate(MATConstants.PREFS_LAST_LOG_ID, MATConstants.PREFS_LAST_LOG_ID_KEY)) {
                    // Build the url to request the log id
                    StringBuilder logIdUrl = new StringBuilder("https://").append(MATConstants.MAT_DOMAIN).append("/v1/Integrations/Sdk/GetLog?sdk=android&package_name=").append(getPackageName()).append("&advertiser_id=").append(getAdvertiserId()).append("&keys[mac_address]=").append(getMacAddress()).append("&keys[device_id]=").append(getDeviceId());
                    // Add encrypted package name as data
                    StringBuilder encryptedPackageName = new StringBuilder("package_name=").append(getPackageName());
                    try {
                        encryptedPackageName = new StringBuilder(URLEnc.bytesToHex(URLEnc.encrypt(encryptedPackageName.toString())));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    logIdUrl.append("&data=").append(encryptedPackageName.toString());
                    
                    String logId = "";
                    String type = "";
                    JSONObject response = urlRequester.requestUrl(logIdUrl.toString(), null);
                    if (response != null) {
                        if (!response.isNull("data")) {
                            try {
                                JSONObject data = response.getJSONObject("data");
                                logId = data.getString("log_id");
                                type = data.getString("type");
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    }
                    
                    // Set the returned log id and append to link
                    if (logId.length() > 0) {
                        if (type.equals("install")) {
                            setInstallLogId(logId);
                            link.append("&install_log_id=" + logId);
                        } else if (type.equals("update")) {
                            setUpdateLogId(logId);
                            link.append("&update_log_id=" + logId);
                        }
                    } else {
                        // If open doesn't contain log_id, log it to serve_no_log
                        if (action.equals("open")) {
                            if (debugMode) Log.d(MATConstants.TAG, "Log ID not found for open/event, sending as no_log data");
                            // Change tracking engine url to hit serve_no_log endpoint
                            link = new StringBuilder(link.toString().replace("serve", "serve_no_log"));
                        }
                    }
                } else {
                    if (debugMode) Log.d(MATConstants.TAG, "SDK has already requested a log ID today, not requesting");
                    // If open doesn't contain log_id, log it to serve_no_log
                    if (action.equals("open")) {
                        if (debugMode) Log.d(MATConstants.TAG, "Log ID not found for open/event, sending as no_log data");
                        // Change tracking engine url to hit serve_no_log endpoint
                        link = new StringBuilder(link.toString().replace("serve", "serve_no_log"));
                    }
                }
            }
        }
        
        // Append Facebook mobile cookie value if exists
        try {
            String facebookCookie = getAttributionId(context.getContentResolver());
            if (facebookCookie != null) {
                link.append("&fb_cookie_id=").append(facebookCookie);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        // Check if there is a Facebook re-engagement intent saved in SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_FACEBOOK_INTENT, 0);
        String intent = SP.getString("action", "");
        if (intent.length() != 0) {
            try {
                intent = URLEncoder.encode(intent, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            // Append Facebook re-engagement intent to url as "source"
            link.append("&source=").append(intent);
            // Clear the fb intent
            SharedPreferences.Editor editor = SP.edit();
            editor.remove("action");
            editor.commit();
        }
        
        // Construct the data string from field names in encryptList and encrypt it
        StringBuilder data = new StringBuilder();
        for (String encrypt: encryptList) {
            if (paramTable.get(encrypt) != null) {
                data.append("&").append(encrypt).append("=").append(paramTable.get(encrypt));
            }
        }
        
        SimpleDateFormat sdfDate = new SimpleDateFormat(MATConstants.DATE_FORMAT, Locale.US);
        Date now = new Date();
        String currentTime = sdfDate.format(now);
        try {
            currentTime = URLEncoder.encode(currentTime, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        data.append("&sd=").append(currentTime);
        
        try {
            data = new StringBuilder(this.URLEnc.bytesToHex(this.URLEnc.encrypt(data.toString())));
        } catch (Exception e) {
            e.printStackTrace();
        }
        link.append("&da=").append(data.toString());
        
        return link.toString();
    }
    
    /**
     *  Function that checks whether we have set a date value for given SharedPreferences filename and key in the past day
     *  @param prefsName SharedPreferences filename of saved date value
     *  @param prefsKey SharedPreferences key in filename for saved date value
     *  @return true if first time being set today, false otherwise
     */
    private boolean isTodayLatestDate(String prefsName, String prefsKey) {
        SimpleDateFormat sdf = new SimpleDateFormat(MATConstants.DATE_ONLY_FORMAT, Locale.getDefault());
        Calendar today = Calendar.getInstance();
        
        SP = context.getSharedPreferences(prefsName, 0);
        String lastDateStr = SP.getString(prefsKey, "");
        
        // Check if last date exists in SharedPreferences
        if (lastDateStr.length() > 0) {
            // Recreate Calendar of last open date from string
            Calendar lastDate = Calendar.getInstance();
            try {
                lastDate.setTime(sdf.parse(lastDateStr));
            } catch (ParseException e) {
                e.printStackTrace();
            }
            
            // Compare today's date with last date seen
            TimeIgnoringComparator dateComparator = new TimeIgnoringComparator();
            if (dateComparator.compare(today, lastDate) == 1) {
                // Save today's date as last open
                setLastDate(sdf, today, prefsName, prefsKey);
                return true;
            } else {
                // Current date is not newer than last seen date so do not send open
                return false;
            }
        } else {
            // No previous last date, save today's date as last seen date
            setLastDate(sdf, today, prefsName, prefsKey);
            return true;
        }
    }
    
    /**
     *  Runnable for creating a WebView and getting the device user agent
     */
    private class GetUserAgent implements Runnable {
        private Context context;
        
        public GetUserAgent(Context context) {
            this.context = context;
        }
        
        public void run() {
            try {
                // Create WebView to set user agent, then destroy WebView
                WebView wv = new WebView(this.context);
                String userAgent = wv.getSettings().getUserAgentString();
                wv.destroy();
                setUserAgent(userAgent);
            } catch (Exception e) {
                e.printStackTrace();
                Log.d(MATConstants.TAG, "Could not get user agent");
            }
        }
    }
    
    /**
     * Runnable for making a single http request.
     */
    private class GetLink implements Runnable {
        private String link = null;
        private String eventItems = null;
        private String action = null;
        private double revenue = 0;
        private String currency = null;
        private String refId = null;
        private String iapData = null;
        private String iapSignature = null;
        private boolean shouldBuildData = false;
        
        /**
         * Instantiates a new GetLink Runnable.
         * @param link url to request
         * @param eventItems eventItem data to post
         * @param action the event action
         * @param revenue the revenue amount
         * @param currency the currency code
         * @param refId the advertiser ref ID associated with the event
         * @param iapData the receipt data from Google Play
         * @param iapSignature the receipt signature from Google Play
         * @param shouldBuildData whether link needs encrypted data appended
         */
        public GetLink(String link, String eventItems, String action, double revenue, String currency, String refId, String iapData, String iapSignature, boolean shouldBuildData) {
            this.link = link;
            this.eventItems = eventItems;
            this.action = action;
            this.revenue = revenue;
            this.currency = currency;
            this.refId = refId;
            this.iapData = iapData;
            this.iapSignature = iapSignature;
            this.shouldBuildData = shouldBuildData;
        }
        
        public void run() {
            if (shouldBuildData) {
                link = buildData(link, action, revenue, currency, refId);
            }
            
            // If action is open, check whether we have done an open in the past 24h
            // If true, don't send open
            if (action.equals("open")) {
                if (!isTodayLatestDate(MATConstants.PREFS_LAST_OPEN, MATConstants.PREFS_LAST_OPEN_KEY)) {
                    if (debugMode) Log.d(MATConstants.TAG, "SDK has already sent an open today, not sending request");
                    return;
                }
            }
            
            Log.d(MATConstants.TAG, "Sending " + action + " event to server...");
            
            // Construct JSONObject from eventItems and iapData/iapSignature
            JSONObject postData = new JSONObject();
            try {
                if (eventItems != null) {
                    // Add event items under key "data"
                    JSONArray eventItemsJson = new JSONArray(eventItems);
                    postData.put("data", eventItemsJson);
                }
                
                if (iapData != null) {
                    postData.put("store_iap_data", iapData);
                }
                
                if (iapSignature != null) {
                    postData.put("store_iap_signature", iapSignature);
                }
            } catch (JSONException e) {
                if (debugMode) Log.d(MATConstants.TAG, "Could not build JSON for event items or verification values");
                e.printStackTrace();
            }
            
            JSONObject response = urlRequester.requestUrl(link, postData);
            if (response == null) {
                try {
                    addEventToQueue(link, eventItems, action, revenue, currency, refId, iapData, iapSignature, false);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    Thread.currentThread().interrupt();
                }
                if (debugMode) Log.d(MATConstants.TAG, "Request failed: track will be queued");
                return;
            }
            
            // Signal didSucceedWithData event to interface
            if (matResponse != null) {
                matResponse.didSucceedWithData(response);
            }
            
            // Set log ID from install/update response
            if (action.equals("install")) {
                try {
                    setInstallLogId(response.getString("log_id"));
                } catch (JSONException e) {
                    e.printStackTrace();
                    Log.d(MATConstants.TAG, "Install log id could not be found in response");
                }
            } else if (action.equals("update")) {
                try {
                    setUpdateLogId(response.getString("log_id"));
                } catch (JSONException e) {
                    Log.d(MATConstants.TAG, "Update log id could not be found in response");
                    e.printStackTrace();
                }
            }
            
            if (debugMode) {
                Log.d(MATConstants.TAG, "Server response: " + response.toString());
                if (response.length() > 0) {
                    try {
                        if (!response.getString("log_action").equals("null")) {
                            JSONObject logAction = response.getJSONObject("log_action");
                            if (logAction.has("conversion")) {
                                JSONObject conversion = logAction.getJSONObject("conversion");
                                if (conversion.has("status")) {
                                    String status = conversion.getString("status");
                                    if (status.equals("rejected")) {
                                        String statusCode = conversion.getString("status_code");
                                        Log.d(MATConstants.TAG, "Event was rejected by server: status code " + statusCode);
                                    } else {
                                        Log.d(MATConstants.TAG, "Event was accepted by server");
                                    }
                                }
                            }
                        } else {
                            if (response.has("options")) {
                                JSONObject options = response.getJSONObject("options");
                                if (options.has("conversion_status")) {
                                    String conversionStatus = options.getString("conversion_status");
                                    Log.d(MATConstants.TAG, "Event was " + conversionStatus + " by server");
                                }
                            }
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Log.d(MATConstants.TAG, "Server response status could not be parsed");
                    }
                }
            }
        }
    }
    
    /******************
     * Public Setters *
     ******************/
    
    /**
     * Gets the MAT advertiser ID.
     * @return MAT advertiser ID
     */
    public String getAdvertiserId() {
        return paramTable.get("adv");
    }

    /**
     * Sets the MAT advertiser ID.
     * @param advertiser_id MAT advertiser ID
     */
    public void setAdvertiserId(String advertiser_id) {
        putInParamTable("adv", advertiser_id);
    }

    /**
     * Gets the user age set.
     * @return age
     */
    public int getAge() {
        if (paramTable.get("age") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("age"));
    }

    /**
     * Sets the user's age.
     * @param age User age to track in MAT
     */
    public void setAge(int age) {
        putInParamTable("age", Integer.toString(age));
    }

    /**
     * Gets the device altitude. Must be set, not automatically retrieved.
     * @return device altitude
     */
    public double getAltitude() {
        if (paramTable.get("altitude") == null) {
            return 0;
        }
        return Double.parseDouble(paramTable.get("altitude"));
    }

    /**
     * Sets the device altitude.
     * @param altitude device altitude
     */
    public void setAltitude(double altitude) {
        putInParamTable("altitude", Double.toString(altitude));
    }

    /**
     * Sets whether the app allows for ad tracking.
     * @param appAdTracking false if user has opted out of ad tracking, true if not (default)
     */
    public void setAppAdTracking(boolean appAdTracking) {
        if (appAdTracking) {
            putInParamTable("app_ad_tracking", Integer.toString(1));
        } else {
            putInParamTable("app_ad_tracking", Integer.toString(0));
        }
    }

    /**
     * Gets the ISO 4217 currency code.
     * @return ISO 4217 currency code
     */
    public String getCurrencyCode() {
        return paramTable.get("c");
    }

    /**
     * Sets the ISO 4217 currency code.
     * @param currency_code the currency code
     */
    public void setCurrencyCode(String currency_code) {
        putInParamTable("c", currency_code);
    }

    /**
     * Gets the user gender set.
     * @return gender 0 for male, 1 for female
     */
    public int getGender() {
        if (paramTable.get("gender") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("gender"));
    }
    
    /**
     * Sets the user gender.
     * @param gender use MobileAppTracker.GENDER_MALE, MobileAppTracker.GENDER_FEMALE
     */
    public void setGender(int gender) {
        putInParamTable("gender", Integer.toString(gender));
    }

    /**
     * Gets the key used for encrypting the event urls.
     * @return conversion key
     */
    public final String getKey() {
        return this.key;
    }

    /**
     * Sets the key used for encrypting the event urls, key length needs to be either 128, 192, or 256 bits.
     * @param key the new key
     */
    public void setKey(String key) {
        this.key = key;
        URLEnc = new Encryption(key, MobileAppTracker.IV);
    }

    /**
     * Gets the device latitude. Must be set, not automatically retrieved.
     * @return device latitude
     */
    public double getLatitude() {
        if (paramTable.get("latitude") == null) {
            return 0;
        }
        return Double.parseDouble(paramTable.get("latitude"));
    }
    
    /**
     * Sets the device latitude.
     * @param latitude the device latitude
     */
    public void setLatitude(double latitude) {
        putInParamTable("latitude", Double.toString(latitude));
    }

    /**
     * Gets the device longitude. Must be set, not automatically retrieved.
     * @return device longitude
     */
    public double getLongitude() {
        if (paramTable.get("longitude") == null) {
            return 0;
        }
        return Double.parseDouble(paramTable.get("longitude"));
    }
    
    /**
     * Sets the device longitude.
     * @param longitude the device longitude
     */
    public void setLongitude(double longitude) {
        putInParamTable("longitude", Double.toString(longitude));
    }

    /**
     * Register a MATResponse interface to receive server response callback
     * @param response a MATResponse object that will be called when server request is complete
     */
    public void setMATResponse(MATResponse response) {
        matResponse = response;
    }

    /**
     * Gets the app package name
     * @return package name of app
     */
    public String getPackageName() {
        return paramTable.get("pn");
    }

    /**
     * Sets the app package name
     * @param package_name App package name
     */
    public void setPackageName(String package_name) {
        putInParamTable("pn", package_name);
    }

    /**
     * Gets the Google Play INSTALL_REFERRER
     * @return Play INSTALL_REFERRER
     */
    public String getReferrer() {
        return paramTable.get("ir");
    }

    /**
     * Overrides the Google Play INSTALL_REFERRER received
     * @param referrer Your custom referrer value
     */
    public void setReferrer(String referrer) {
        putInParamTable("ir", referrer);
    }

    /**
     * Gets the advertiser ref ID.
     * @return advertiser ref ID set by SDK
     */
    public String getRefId() {
        return paramTable.get("ar");
    }

    /**
     * Sets the advertiser ref ID.
     * @param ref_id the new ref ID
     */
    public void setRefId(String ref_id) {
        putInParamTable("ar", ref_id);
    }

    /**
     * Gets the revenue amount set
     * @return revenue amount
     */
    public Double getRevenue() {
        if (paramTable.get("r") == null) {
            return Double.valueOf(0);
        }
        return Double.parseDouble(paramTable.get("r"));
    }

    /**
     * Sets the revenue amount to report on next tracking call
     * @param revenue Revenue amount
     */
    public void setRevenue(double revenue) {
        putInParamTable("r", Double.toString(revenue));
    }

    /**
     * Gets the MAT site ID set
     * @return site ID in MAT
     */
    public String getSiteId() {
        return paramTable.get("si");
    }

    /**
     * Sets the MAT site ID to specify which app to attribute to
     * @param site_id MAT site ID to attribute to
     */
    public void setSiteId(String site_id) {
        putInParamTable("si", site_id);
    }

    /**
     * Gets the TRUSTe ID set
     * @return TRUSTe ID
     */
    public String getTRUSTeId() {
        return paramTable.get("tpid");
    }

    /**
     * Sets the TRUSTe ID, should generate via their SDK
     * @param tpid TRUSTe ID
     */
    public void setTRUSTeId(String tpid) {
        putInParamTable("tpid", tpid);
    }

    /**
     * Gets the custom user ID.
     * @return custom user id
     */
    public String getUserId() {
        return paramTable.get("ui");
    }

    /**
     * Sets the custom user ID.
     * @param user_id the new user id
     */
    public void setUserId(String user_id) {
        putInParamTable("ui", user_id);
    }

    /*******************
     * Private Setters *
     *******************/
    
    /**
     * Gets the action of the event
     * @return install/update/conversion
     */
    public String getAction() {
        return paramTable.get("ac");
    }

    private void setAction(String action) {
        putInParamTable("ac", action);
    }

    /**
     * Gets the ANDROID_ID of the device
     * @return ANDROID_ID
     */
    public String getAndroidId() {
        return paramTable.get("ad");
    }

    private void setAndroidId(String android_id) {
        putInParamTable("ad", android_id);
    }

    /**
     * Gets the MD5 hash of the ANDROID_ID of the device
     * @return ANDROID_ID MD5 hash
     */
    public String getAndroidIdMd5() {
        return paramTable.get("android_id_md5");
    }

    private void setAndroidIdMd5(String android_id_md5) {
        putInParamTable("android_id_md5", android_id_md5);
    }

    /**
     * Gets the SHA-1 hash of the ANDROID_ID of the device
     * @return ANDROID_HD SHA-1 hash
     */
    public String getAndroidIdSha1() {
        return paramTable.get("android_id_sha1");
    }

    private void setAndroidIdSha1(String android_id_sha1) {
        putInParamTable("android_id_sha1", android_id_sha1);
    }

    /**
     * Gets the SHA-256 hash of the ANDROID_ID of the device
     * @return ANDROID_HD SHA-256 hash
     */
    public String getAndroidIdSha256() {
        return paramTable.get("android_id_sha256");
    }

    private void setAndroidIdSha256(String android_id_sha256) {
        putInParamTable("android_id_sha256", android_id_sha256);
    }

    /**
     * Gets the app name
     * @return app name
     */
    public String getAppName() {
        return paramTable.get("an");
    }

    private void setAppName(String app_name) {
        putInParamTable("an", app_name);
    }

    /**
     * Gets the app version
     * @return app version
     */
    public int getAppVersion() {
        if (paramTable.get("av") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("av"));
    }

    private void setAppVersion(int app_version) {
        putInParamTable("av", Integer.toString(app_version));
    }

    /**
     * Gets the device carrier if any
     * @return mobile device carrier/service provider name
     */
    public String getCarrier() {
        return paramTable.get("dc");
    }

    private void setCarrier(String carrier) {
        putInParamTable("dc", carrier);
    }

    /**
     * Gets the connection type (mobile or WIFI);.
     * @return whether device is connected by WIFI or mobile data connection
     */
    public String getConnectionType() {
        return paramTable.get("connection_type");
    }

    private void setConnectionType(String connection_type) {
        putInParamTable("connection_type", connection_type);
    }

    /**
     * Gets the ISO 639-1 country code
     * @return ISO 639-1 country code
     */
    public String getCountryCode() {
        return paramTable.get("cc");
    }

    private void setCountryCode(String country_code) {
        putInParamTable("cc", country_code);
    }

    /**
     * Gets the device brand/manufacturer (HTC, Apple, etc)
     * @return device brand/manufacturer name
     */
    public String getDeviceBrand() {
        return paramTable.get("db");
    }

    private void setDeviceBrand(String device_brand) {
        putInParamTable("db", device_brand);
    }

    /**
     * Gets the Device ID, also known as IMEI/MEID, if any
     * @return device IMEI/MEID
     */
    public String getDeviceId() {
        return paramTable.get("d");
    }

    private void setDeviceId(String device_id) {
        putInParamTable("d", device_id);
    }

    /**
     * Gets the device model name
     * @return device model name
     */
    public String getDeviceModel() {
        return paramTable.get("dm");
    }

    private void setDeviceModel(String device_model) {
        putInParamTable("dm", device_model);
    }

    /**
     * Gets the last event id set.
     * @return event ID in MAT
     */
    public String getEventId() {
        return paramTable.get("ei");
    }

    /**
     * Sets the event id set.
     * @return event_id the event ID in MAT
     */
    private void setEventId(String event_id) {
        putInParamTable("ei", event_id);
    }

    /**
     * Gets the last event name set.
     * @return event name in MAT
     */
    public String getEventName() {
        return paramTable.get("en");
    }

    private void setEventName(String event_name) {
        putInParamTable("en", event_name);
    }

    /**
     * Gets the date of app install
     * @return date that app was installed
     */
    public String getInstallDate() {
        return paramTable.get("id");
    }

    private void setInstallDate(String install_date) {
        putInParamTable("id", install_date);
    }

    /**
     * Gets the MAT install log ID
     * @return MAT install log ID
     */
    public String getInstallLogId() {
        // Get log id from SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, 0);
        return SP.getString("logId", "");
    }

    private void setInstallLogId(String logId) {
        // Store log id from install in SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(MATConstants.PREFS_LOG_ID_KEY, logId);
        editor.commit();
    }

    /**
     * Gets the language of the device
     * @return device language
     */
    public String getLanguage() {
        return paramTable.get("l");
    }

    private void setLanguage(String language) {
        putInParamTable("l", language);
    }

    // Sets last date in given SharedPreferences file and key to given date
    private void setLastDate(SimpleDateFormat sdf, Calendar date, String prefsName, String key) {
        String dateStr = sdf.format(date.getTime());
        SP = context.getSharedPreferences(prefsName, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(key, dateStr);
        editor.commit();
    }

    /**
     * Gets the MAC address of device
     * @return device MAC address
     */
    public String getMacAddress() {
        return paramTable.get("ma");
    }

    private void setMacAddress(String mac_address) {
        putInParamTable("ma", mac_address);
    }

    /**
     * Gets the MAT ID generated on install
     * @return MAT ID
     */
    public String getMatId() {
        return paramTable.get("mi");
    }

    private void setMatId(String mat_id) {
        putInParamTable("mi", mat_id);
    }

    /**
     * Gets the mobile country code.
     * @return mobile country code associated with the carrier
     */
    public String getMCC() {
        return paramTable.get("mobile_country_code");
    }

    private void setMCC(String mcc) {
        putInParamTable("mobile_country_code", mcc);
    }

    /**
     * Gets the mobile network code.
     * @return mobile network code associated with the carrier
     */
    public String getMNC() {
        return paramTable.get("mobile_network_code");
    }

    private void setMNC(String mnc) {
        putInParamTable("mobile_network_code", mnc);
    }

    /**
     * Gets the Android OS version
     * @return Android OS version
     */
    public String getOsVersion() {
        return paramTable.get("ov");
    }

    private void setOsVersion(String os_version) {
        putInParamTable("ov", os_version);
    }

    private void setPurchaseStatus(int purchaseStatus) {
        putInParamTable("android_purchase_status", Integer.toString(purchaseStatus));
    }

    /**
     * Gets the package name of the app that started this Activity, if any
     * @return source package name that caused open via StartActivityForResult
     */
    public String getReferralSource() {
        return paramTable.get("referral_source");
    }

    private void setReferralSource(String referralPackage) {
        putInParamTable("referral_source", referralPackage);
    }

    /**
     * Gets the url scheme that started this Activity, if any
     * @return full url of app scheme that caused open
     */
    public String getReferralUrl() {
        return paramTable.get("referral_url");
    }

    private void setReferralUrl(String referralUrl) {
        putInParamTable("referral_url", referralUrl);
    }

    /**
     * Gets the screen density of the device
     * @return 0.75/1.0/1.5/2.0/3.0/4.0 for ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
     */
    public String getScreenDensity() {
        return paramTable.get("screen_density");
    }

    private void setScreenDensity(String density) {
        putInParamTable("screen_density", density);
    }

    /**
     * Gets the screen size of the device
     * @return widthxheight
     */
    public String getScreenSize() {
        return paramTable.get("screen_layout_size");
    }

    private void setScreenSize(String screensize) {
        putInParamTable("screen_layout_size", screensize);
    }

    /**
     * Gets the MAT update log ID
     * @return MAT update log ID
     */
    public String getUpdateLogId() {
        // Get log id from SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, 0);
        return SP.getString("logId", "");
    }

    private void setUpdateLogId(String logId) {
        // Store log id from install in SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(MATConstants.PREFS_LOG_ID_KEY, logId);
        editor.commit();
    }

    /**
     * Gets the device browser user agent
     * @return device user agent
     */
    public String getUserAgent() {
        return paramTable.get("ua");
    }

    private void setUserAgent(String user_agent) {
        putInParamTable("ua", user_agent);
    }

    /**
     * Helper method to UTF-8 encode and null-check before putting value in param table.
     * @param key the key
     * @param value the value
     */
    private void putInParamTable(String key, String value) {
        if (key != null && value != null) {
            try {
                value = URLEncoder.encode(value, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            paramTable.put(key, value);
        }
    }
    
    /**
     * Enable sending ANDROID_ID as MD5 hash in request - removes raw ANDROID_ID
     */
    public void setUseAndroidIdMd5() {
        setAndroidIdMd5(URLEnc.md5(Secure.getString(context.getContentResolver(), Secure.ANDROID_ID)));
        setAndroidId("");
    }
    
    /**
     * Enable sending ANDROID_ID as SHA-1 hash in request - removes raw ANDROID_ID
     */
    public void setUseAndroidIdSha1() {
        setAndroidIdSha1(URLEnc.sha1(Secure.getString(context.getContentResolver(), Secure.ANDROID_ID)));
        setAndroidId("");
    }
    
    /**
     * Enable sending ANDROID_ID as SHA-256 hash in request - removes raw ANDROID_ID
     */
    public void setUseAndroidIdSha256() {
        setAndroidIdSha256(URLEnc.sha256(Secure.getString(context.getContentResolver(), Secure.ANDROID_ID)));
        setAndroidId("");
    }
    
    /**
     * Enables acceptance of duplicate installs from this device.
     * @param allow whether to allow duplicate installs from device
     */
    public void setAllowDuplicates(boolean allow) {
        allowDups = allow;
    }
    
    /**
     * Turns debug mode on or off, under tag "MobileAppTracker".
     * @param debug whether to enable debug output
     */
    public void setDebugMode(boolean debug) {
        debugMode = debug;
    }
    
    /**
     * Facebook's code for retrieving Facebook cookie value
     * @param contentResolver app's ContentResolver to access to FB ContentProvider
     * @return Facebook cookie id, or null if not there
     */
    private String getAttributionId(ContentResolver contentResolver) {
        String [] projection = {ATTRIBUTION_ID_COLUMN_NAME};
        Cursor c = contentResolver.query(ATTRIBUTION_ID_CONTENT_URI, projection, null, null, null);
        if (c == null || !c.moveToFirst()) {
            return null;
        }
        String attributionId = c.getString(c.getColumnIndex(ATTRIBUTION_ID_COLUMN_NAME));
        c.close();
        return attributionId;
    }
    
    /**
     * Returns the Android device ID.
     * @param context the application context
     * @return Android device ID
     */
    private String getDeviceId(Context context) {
        return ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE)).getDeviceId();
    }
    
    /**
     * Helper method for whether String contains a char.
     * @param s the string
     * @return whether given String contains a char
     */
    private static boolean containsChar(final String s) {
        for (char c: s.toCharArray()) {
            if (Character.isLetter(c)) {
                return true;
            }
        }
        return false;
    }

    // Update referrer value from Tracker
    public void update(Observable observable, Object data) {
        setReferrer((String) data);
    }
}