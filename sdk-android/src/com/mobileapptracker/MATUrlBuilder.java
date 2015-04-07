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
    private static MATParameters params;
    /**
     * Builds a new link string based on parameter values.
     * @return encrypted URL string based on class settings.
     */
    public static String buildLink(MATEvent eventData, MATPreloadData preloaded, boolean debugMode) {
        params = MATParameters.getInstance();
        
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
        safeAppend(link, "package_name", params.getPackageName());
        safeAppend(link, "referral_source", params.getReferralSource());
        safeAppend(link, "referral_url", params.getReferralUrl());
        safeAppend(link, "site_id", params.getSiteId());
        safeAppend(link, "tracking_id", params.getTrackingId());
        
        if (eventData.getEventId() != 0) {
            safeAppend(link, "site_event_id", Integer.toString(eventData.getEventId()));
        }
        if (!params.getAction().equals("session")) {
            safeAppend(link, "site_event_name", eventData.getEventName());
        }

        // Append preloaded params, must have attr_set=1 in order to attribute
        if (preloaded != null) {
            link.append("&attr_set=1");
            safeAppend(link, "publisher_id", preloaded.publisherId);
            safeAppend(link, "offer_id", preloaded.offerId);
            safeAppend(link, "publisher_ref_id", preloaded.publisherReferenceId);
            safeAppend(link, "publisher_sub_publisher", preloaded.publisherSubPublisher);
            safeAppend(link, "publisher_sub_site", preloaded.publisherSubSite);
            safeAppend(link, "publisher_sub_campaign", preloaded.publisherSubCampaign);
            safeAppend(link, "publisher_sub_adgroup", preloaded.publisherSubAdgroup);
            safeAppend(link, "publisher_sub_ad", preloaded.publisherSubAd);
            safeAppend(link, "publisher_sub_keyword", preloaded.publisherSubKeyword);
            safeAppend(link, "advertiser_sub_publisher", preloaded.advertiserSubPublisher);
            safeAppend(link, "advertiser_sub_site", preloaded.advertiserSubSite);
            safeAppend(link, "advertiser_sub_campaign", preloaded.advertiserSubCampaign);
            safeAppend(link, "advertiser_sub_adgroup", preloaded.advertiserSubAdgroup);
            safeAppend(link, "advertiser_sub_ad", preloaded.advertiserSubAd);
            safeAppend(link, "advertiser_sub_keyword", preloaded.advertiserSubKeyword);
            safeAppend(link, "publisher_sub1", preloaded.publisherSub1);
            safeAppend(link, "publisher_sub2", preloaded.publisherSub2);
            safeAppend(link, "publisher_sub3", preloaded.publisherSub3);
            safeAppend(link, "publisher_sub4", preloaded.publisherSub4);
            safeAppend(link, "publisher_sub5", preloaded.publisherSub5);
        }

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
        
        return link.toString();
    }
    

    /**
     * Builds data in conversion link based on class member values, to be encrypted.
     * @return URL-encoded string based on class settings.
     */
    public static synchronized String buildDataUnencrypted(MATEvent eventData) {
        params = MATParameters.getInstance();

        StringBuilder link = new StringBuilder();

        link.append("connection_type=" + params.getConnectionType());
        safeAppend(link, "age", params.getAge());
        safeAppend(link, "altitude", params.getAltitude());
        safeAppend(link, "android_id", params.getAndroidId());
        safeAppend(link, "android_id_md5", params.getAndroidIdMd5());
        safeAppend(link, "android_id_sha1", params.getAndroidIdSha1());
        safeAppend(link, "android_id_sha256", params.getAndroidIdSha256());
        safeAppend(link, "app_ad_tracking", params.getAppAdTrackingEnabled());
        safeAppend(link, "app_name", params.getAppName());
        safeAppend(link, "app_version", params.getAppVersion());
        safeAppend(link, "app_version_name", params.getAppVersionName());
        safeAppend(link, "country_code", params.getCountryCode());
        safeAppend(link, "device_brand", params.getDeviceBrand());
        safeAppend(link, "device_carrier", params.getDeviceCarrier());
        safeAppend(link, "device_cpu_type", params.getDeviceCpuType());
        safeAppend(link, "device_cpu_subtype", params.getDeviceCpuSubtype());
        safeAppend(link, "device_model", params.getDeviceModel());
        safeAppend(link, "device_id", params.getDeviceId());
        safeAppend(link, "existing_user", params.getExistingUser());
        safeAppend(link, "facebook_user_id", params.getFacebookUserId());
        safeAppend(link, "gender", params.getGender());
        safeAppend(link, "google_aid", params.getGoogleAdvertisingId());
        safeAppend(link, "google_ad_tracking_disabled", params.getGoogleAdTrackingLimited());
        safeAppend(link, "google_user_id", params.getGoogleUserId());
        safeAppend(link, "insdate", params.getInstallDate());
        safeAppend(link, "installer", params.getInstaller());
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
        safeAppend(link, "referrer_delay", params.getReferrerDelay());
        safeAppend(link, "screen_density", params.getScreenDensity());
        safeAppend(link, "screen_layout_size", params.getScreenWidth() + "x" + params.getScreenHeight());
        safeAppend(link, "sdk_version", params.getSdkVersion());
        safeAppend(link, "truste_tpid", params.getTRUSTeId());
        safeAppend(link, "twitter_user_id", params.getTwitterUserId());
        safeAppend(link, "conversion_user_agent", params.getUserAgent());
        safeAppend(link, "user_email_md5", params.getUserEmailMd5());
        safeAppend(link, "user_email_sha1", params.getUserEmailSha1());
        safeAppend(link, "user_email_sha256", params.getUserEmailSha256());
        safeAppend(link, "user_id", params.getUserId());
        safeAppend(link, "user_name_md5", params.getUserNameMd5());
        safeAppend(link, "user_name_sha1", params.getUserNameSha1());
        safeAppend(link, "user_name_sha256", params.getUserNameSha256());
        safeAppend(link, "user_phone_md5", params.getPhoneNumberMd5());
        safeAppend(link, "user_phone_sha1", params.getPhoneNumberSha1());
        safeAppend(link, "user_phone_sha256", params.getPhoneNumberSha256());
        
        // Append event-level params
        safeAppend(link, "attribute_sub1", eventData.getAttribute1());
        safeAppend(link, "attribute_sub2", eventData.getAttribute2());
        safeAppend(link, "attribute_sub3", eventData.getAttribute3());
        safeAppend(link, "attribute_sub4", eventData.getAttribute4());
        safeAppend(link, "attribute_sub5", eventData.getAttribute5());
        safeAppend(link, "content_id", eventData.getContentId());
        safeAppend(link, "content_type", eventData.getContentType());
        // Event-level currency overrides MAT class-level
        if (eventData.getCurrencyCode() != null) {
            safeAppend(link, "currency_code", eventData.getCurrencyCode());
        } else {
            safeAppend(link, "currency_code", params.getCurrencyCode());
        }
        if (eventData.getDate1() != null) {
            safeAppend(link, "date1", Long.toString(eventData.getDate1().getTime()/1000));
        }
        if (eventData.getDate2() != null) {
            safeAppend(link, "date2", Long.toString(eventData.getDate2().getTime()/1000));
        }
        if (eventData.getLevel() != 0) {
            safeAppend(link, "level", Integer.toString(eventData.getLevel()));
        }
        if (eventData.getQuantity() != 0) {
            safeAppend(link, "quantity", Integer.toString(eventData.getQuantity()));
        }
        if (eventData.getRating() != 0) {
            safeAppend(link, "rating", Double.toString(eventData.getRating()));
        }
        safeAppend(link, "search_string", eventData.getSearchString());
        safeAppend(link, "advertiser_ref_id", eventData.getRefId());
        safeAppend(link, "revenue", Double.toString(eventData.getRevenue()));
        
        return link.toString();
    }

    
    /**
     * Update the Google Ad ID and install referrer, if present, and encrypts the data string.
     * @return encrypted string
     */
    public static synchronized String updateAndEncryptData(String data, MATEncryption encryption) {
        StringBuilder updatedData = new StringBuilder(data);
        
        params = MATParameters.getInstance();
        if (params != null) {
            String gaid = params.getGoogleAdvertisingId();
            if (gaid != null && !data.contains("&google_aid=")) {
                safeAppend(updatedData, "google_aid", gaid);
                safeAppend(updatedData, "google_ad_tracking_disabled", params.getGoogleAdTrackingLimited());
            }
            
            String androidId = params.getAndroidId();
            if (androidId != null && !data.contains("&android_id=")) {
                safeAppend(updatedData, "android_id", androidId);
            }
            
            String referrer = params.getInstallReferrer();
            if (referrer != null && !data.contains("&install_referrer=")) {
                safeAppend(updatedData, "install_referrer", referrer);
            }
            String userAgent = params.getUserAgent();
            if (userAgent != null && !data.contains("&conversion_user_agent=")) {
                safeAppend(updatedData, "conversion_user_agent", userAgent);
            }
        }
        // Add system date of original request
        if (!data.contains("&system_date=")) {
            long now = new Date().getTime()/1000;
            safeAppend(updatedData, "system_date", Long.toString(now));
        }
        
        String updatedDataStr = updatedData.toString();
        try {
            updatedDataStr = MATEncryption.bytesToHex(encryption.encrypt(updatedDataStr));
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        return updatedDataStr;
}
    
    /**
     * Builds JSONObject for body of POST request
     * @return appropriately parameterized object
     */
    public static synchronized JSONObject buildBody(JSONArray eventItems, String iapData, String iapSignature, JSONArray emails) {
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
            if (emails != null) {
                postData.put("user_emails", emails);
            }
        } catch (JSONException e) {
            Log.d(MATConstants.TAG, "Could not build JSON body of request");
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