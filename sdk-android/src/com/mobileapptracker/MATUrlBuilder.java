package com.mobileapptracker;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Date;
import java.util.UUID;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

class MATUrlBuilder {
    private static Parameters params;
    /**
     * Builds a new link string based on parameter values.
     * @return encrypted URL string based on class settings.
     */
    public static String buildLink(boolean debugMode, boolean preLoaded, boolean postConversion) {
        params = Parameters.getInstance();
        
        StringBuilder link = new StringBuilder("https://").append(params.getAdvertiserId()).append(".");
        if (debugMode) {
            link.append(MATConstants.MAT_DOMAIN_DEBUG);
        } else {
            link.append(MATConstants.MAT_DOMAIN);
        }
        
        link.append("/serve?ver=").append(params.getSdkVersion());
        link.append("&transaction_id=").append(UUID.randomUUID().toString());

        safeAppend(link, "sdk", "android");
        safeAppend(link, "action", params.getAction());
        safeAppend(link, "advertiser_id", params.getAdvertiserId());
        safeAppend(link, "site_event_id", params.getEventId());
        safeAppend(link, "site_event_name", params.getEventName());
        safeAppend(link, "package_name", params.getPackageName());
        safeAppend(link, "referral_source", params.getReferralSource());
        safeAppend(link, "referral_url", params.getReferralUrl());
        safeAppend(link, "site_id", params.getSiteId());
        safeAppend(link, "tracking_id", params.getTrackingId());

        // Append preloaded params, must have attr_set=1 in order to attribute
        if (preLoaded) {
            link.append("&attr_set=1");
        }
        safeAppend(link, "publisher_id", params.getPublisherId());
        safeAppend(link, "offer_id", params.getOfferId());
        safeAppend(link, "publisher_ref_id", params.getPublisherReferenceId());
        safeAppend(link, "publisher_sub_publisher", params.getPublisherSubPublisher());
        safeAppend(link, "publisher_sub_site", params.getPublisherSubSite());
        safeAppend(link, "publisher_sub_campaign", params.getPublisherSubCampaign());
        safeAppend(link, "publisher_sub_adgroup", params.getPublisherSubAdgroup());
        safeAppend(link, "publisher_sub_ad", params.getPublisherSubAd());
        safeAppend(link, "publisher_sub_keyword", params.getPublisherSubKeyword());
        safeAppend(link, "advertiser_sub_publisher", params.getAdvertiserSubPublisher());
        safeAppend(link, "advertiser_sub_site", params.getAdvertiserSubSite());
        safeAppend(link, "advertiser_sub_campaign", params.getAdvertiserSubCampaign());
        safeAppend(link, "advertiser_sub_adgroup", params.getAdvertiserSubAdgroup());
        safeAppend(link, "advertiser_sub_ad", params.getAdvertiserSubAd());
        safeAppend(link, "advertiser_sub_keyword", params.getAdvertiserSubKeyword());
        safeAppend(link, "publisher_sub1", params.getPublisherSub1());
        safeAppend(link, "publisher_sub2", params.getPublisherSub2());
        safeAppend(link, "publisher_sub3", params.getPublisherSub3());
        safeAppend(link, "publisher_sub4", params.getPublisherSub4());
        safeAppend(link, "publisher_sub5", params.getPublisherSub5());

        // If allow duplicates on, skip duplicate check logic
        String allowDups = params.getAllowDuplicates();
        if (allowDups != null) {
            int intAllowDups = Integer.parseInt(allowDups);
            if (intAllowDups == 1) {
                link.append("&skip_dup=1");
            }
        }

        // If logging on, use debug mode
        if (debugMode) {
            link.append("&debug=1");
        }

        if (postConversion) {
            link.append("&post_conversion=1");
        }
        
        return link.toString();
    }
    

    /**
     * Builds data in conversion link based on class member values, to be encrypted.
     * @return URL-encoded string based on class settings.
     */
    public static synchronized String buildDataUnencrypted() {
        params = Parameters.getInstance();

        StringBuilder link = new StringBuilder();

        link.append("connection_type=" + params.getConnectionType());
        safeAppend(link, "age", params.getAge());
        safeAppend(link, "altitude", params.getAltitude());
        safeAppend(link, "android_id", params.getAndroidId());
        safeAppend(link, "app_ad_tracking", params.getAppAdTrackingEnabled());
        safeAppend(link, "app_name", params.getAppName());
        safeAppend(link, "app_version", params.getAppVersion());
        safeAppend(link, "country_code", params.getCountryCode());
        safeAppend(link, "currency_code", params.getCurrencyCode());
        safeAppend(link, "device_brand", params.getDeviceBrand());
        safeAppend(link, "device_carrier", params.getDeviceCarrier());
        safeAppend(link, "device_cpu_type", params.getDeviceCpuType());
        safeAppend(link, "device_cpu_subtype", params.getDeviceCpuSubtype());
        safeAppend(link, "device_model", params.getDeviceModel());
        safeAppend(link, "device_id", params.getDeviceId());
        safeAppend(link, "attribute_sub1", params.getEventAttribute1());
        safeAppend(link, "attribute_sub2", params.getEventAttribute2());
        safeAppend(link, "attribute_sub3", params.getEventAttribute3());
        safeAppend(link, "attribute_sub4", params.getEventAttribute4());
        safeAppend(link, "attribute_sub5", params.getEventAttribute5());
        safeAppend(link, "content_id", params.getEventContentId());
        safeAppend(link, "content_type", params.getEventContentType());
        safeAppend(link, "date1", params.getEventDate1());
        safeAppend(link, "date2", params.getEventDate2());
        safeAppend(link, "level", params.getEventLevel());
        safeAppend(link, "quantity", params.getEventQuantity());
        safeAppend(link, "rating", params.getEventRating());
        safeAppend(link, "search_string", params.getEventSearchString());
        safeAppend(link, "existing_user", params.getExistingUser());
        safeAppend(link, "facebook_user_id", params.getFacebookUserId());
        safeAppend(link, "gender", params.getGender());
        safeAppend(link, "google_aid", params.getGoogleAdvertisingId());
        safeAppend(link, "google_ad_tracking_disabled", params.getGoogleAdTrackingLimited());
        safeAppend(link, "google_user_id", params.getGoogleUserId());
        safeAppend(link, "insdate", params.getInstallDate());
        safeAppend(link, "installer", params.getInstaller());
        safeAppend(link, "install_log_id", params.getInstallLogId());
        safeAppend(link, "install_referrer", params.getInstallReferrer());
        safeAppend(link, "is_paying_user", params.getIsPayingUser());
        safeAppend(link, "language", params.getLanguage());
        safeAppend(link, "last_open_log_id", params.getLastOpenLogId());
        safeAppend(link, "latitude", params.getLatitude());
        safeAppend(link, "longitude", params.getLongitude());
        safeAppend(link, "mac_address", params.getMacAddress());
        safeAppend(link, "mat_id", params.getMatId());
        safeAppend(link, "mobile_country_code", params.getMCC());
        safeAppend(link, "mobile_network_code", params.getMNC());
        safeAppend(link, "open_log_id", params.getOpenLogId());
        safeAppend(link, "os_version", params.getOsVersion());
        safeAppend(link, "sdk_plugin", params.getPluginName());
        safeAppend(link, "android_purchase_status", params.getPurchaseStatus());
        safeAppend(link, "advertiser_ref_id", params.getRefId());
        safeAppend(link, "revenue", params.getRevenue());
        safeAppend(link, "screen_density", params.getScreenDensity());
        safeAppend(link, "screen_layout_size", params.getScreenWidth() + "x" + params.getScreenHeight());
        safeAppend(link, "sdk_version", params.getSdkVersion());
        safeAppend(link, "truste_tpid", params.getTRUSTeId());
        safeAppend(link, "twitter_user_id", params.getTwitterUserId());
        safeAppend(link, "update_log_id", params.getUpdateLogId());
        safeAppend(link, "conversion_user_agent", params.getUserAgent());
        safeAppend(link, "user_email", params.getUserEmail());
        safeAppend(link, "user_id", params.getUserId());
        safeAppend(link, "user_name", params.getUserName());
        
        return link.toString();
    }

    
    /**
     * Update the Google Ad ID and install referrer, if present, and encrypts the data string.
     * @return encrypted string
     */
    public static synchronized String updateAndEncryptData(String data, Encryption encryption) {
        StringBuilder updatedData = new StringBuilder(data);
        
        params = Parameters.getInstance();
        if (params != null) {
            String gaid = params.getGoogleAdvertisingId();
            if (gaid != null && !data.contains("&google_aid=")) {
                safeAppend(updatedData, "google_aid", gaid);
                safeAppend(updatedData, "google_ad_tracking_disabled", params.getGoogleAdTrackingLimited());
            }
            
            String referrer = params.getInstallReferrer();
            if (referrer != null && !data.contains("&install_referrer=")) {
                safeAppend(updatedData, "install_referrer", referrer);
            }
        }
        // Add system date of original request
        if (!data.contains("&system_date=")) {
            long now = new Date().getTime()/1000;
            safeAppend(updatedData, "system_date", Long.toString(now));
        }
        
        String updatedDataStr = updatedData.toString();
        try {
            updatedDataStr = Encryption.bytesToHex(encryption.encrypt(updatedDataStr));
        } catch (Exception e) {
            e.printStackTrace();
        }
                
        return updatedDataStr;
}
    
    /**
     * Builds JSONObject for body of POST request
     * @return appropriately parameterized object
     */
    public static synchronized JSONObject buildBody(JSONArray eventItems, String iapData, String iapSignature) {
        JSONObject postData = new JSONObject();

        try {
            if (eventItems != null) {
                postData.put("data", eventItems);
            }
            if (iapData != null) {
                postData.put("store_iap_data", iapData);
            }
            if (iapSignature != null) {
                postData.put("store_iap_signature", iapSignature);
            }
        } catch (JSONException e) {
            Log.d(MATConstants.TAG, "Could not build JSON for event items or verification values");
            e.printStackTrace();
        }
        
        return postData;
    }
    
    /*
     * URL builders
     */
    private static synchronized void safeAppend(StringBuilder link, String key, String value) {
        if (value != null && !value.equals("")) {
            try {
                link.append("&" + key + "=" + URLEncoder.encode(value, "UTF-8"));
            } catch (UnsupportedEncodingException e) {
                Log.w(MATConstants.TAG, "failed encoding value " + value + " for key " + key); 
                e.printStackTrace();
            }
        }
    }
}