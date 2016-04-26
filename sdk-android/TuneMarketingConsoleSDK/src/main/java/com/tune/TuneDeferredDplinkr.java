package com.tune;

import android.content.Context;

import com.tune.http.UrlRequester;

public class TuneDeferredDplinkr {
    private String advertiserId;
    private String conversionKey;
    private String packageName;
    private String googleAdvertisingId;
    private int isLATEnabled;
    private String androidId;
    private String userAgent;
    private TuneDeeplinkListener listener;
    private boolean enabled;
    
    private static volatile TuneDeferredDplinkr dplinkr;
    
    private TuneDeferredDplinkr() {
        advertiserId = null;
        conversionKey = null;
        packageName = null;
        googleAdvertisingId = null;
        isLATEnabled = 0;
        androidId = null;
        userAgent = null;
        listener = null;
    }
    
    public static synchronized TuneDeferredDplinkr initialize(String advertiserId, String conversionKey, String packageName) {
        dplinkr = new TuneDeferredDplinkr();
        dplinkr.advertiserId = advertiserId;
        dplinkr.conversionKey = conversionKey;
        dplinkr.packageName = packageName;
        return dplinkr;
    }
    
    public static synchronized TuneDeferredDplinkr getInstance() {
        return dplinkr;
    }
    
    public void setAdvertiserId(String advertiserId) {
        dplinkr.advertiserId = advertiserId;
    }
    
    public String getAdvertiserId() {
        return dplinkr.advertiserId;
    }
    
    public void setConversionKey(String conversionKey) {
        dplinkr.conversionKey = conversionKey;
    }
    
    public String getConversionKey() {
        return dplinkr.conversionKey;
    }
    
    public void setPackageName(String packageName) {
        dplinkr.packageName = packageName;
    }
    
    public String getPackageName() {
        return dplinkr.packageName;
    }
    
    public void setUserAgent(String userAgent) {
        dplinkr.userAgent = userAgent;
    }
    
    public String getUserAgent() {
        return dplinkr.userAgent;
    }
    
    public void setGoogleAdvertisingId(String googleAdvertisingId, int isLATEnabled) {
        dplinkr.googleAdvertisingId = googleAdvertisingId;
        dplinkr.isLATEnabled = isLATEnabled;
    }
    
    public String getGoogleAdvertisingId() {
        return dplinkr.googleAdvertisingId;
    }
    
    public int getGoogleAdTrackingLimited() {
        return dplinkr.isLATEnabled;
    }
    
    public void setAndroidId(String androidId) {
        dplinkr.androidId = androidId;
    }
    
    public String getAndroidId() {
        return dplinkr.androidId;
    }
    
    public void setListener(TuneDeeplinkListener listener) {
        dplinkr.listener = listener;
    }
    
    public TuneDeeplinkListener getListener() {
        return dplinkr.listener;
    }
    
    public void enable(boolean enable) {
        enabled = enable;
    }
    
    public boolean isEnabled() {
        return enabled;
    }
    
    public void checkForDeferredDeeplink(final Context context, final UrlRequester urlRequester) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                // If advertiser ID, conversion key, or package name were not set, return
                if (dplinkr.advertiserId == null || dplinkr.conversionKey == null || dplinkr.packageName == null) {
                    if (listener != null) {
                        listener.didFailDeeplink("Advertiser ID, conversion key, or package name not set");
                    }
                }
                
                // If no device identifiers collected, return
                if (dplinkr.googleAdvertisingId == null && dplinkr.androidId == null) {
                    if (listener != null) {
                        listener.didFailDeeplink("No device identifiers collected");
                    }
                }
                
                // Query for deeplink url
                urlRequester.requestDeeplink(dplinkr);
            }
        }).start();
    }
}
