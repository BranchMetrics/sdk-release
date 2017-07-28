package com.tune;

import android.net.Uri;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Date;
import java.util.UUID;

class TuneUrlBuilder {
    private static TuneParameters params;

    /**
     * Builds a new link string based on parameter values.
     * @return encrypted URL string based on class settings.
     */
    public static String appendTuneLinkParameters(String clickedTuneLinkUrl) {
        params = TuneParameters.getInstance();

        final Uri uri = Uri.parse(clickedTuneLinkUrl);
        final Uri.Builder builder = uri.buildUpon();

        builder.appendQueryParameter(TuneUrlKeys.MAT_ID, params.getMatId());

        if (!"json".equals(uri.getQueryParameter(TuneUrlKeys.RESPONSE_FORMAT))) {
            builder.appendQueryParameter(TuneUrlKeys.RESPONSE_FORMAT, "json");
        }

        builder.appendQueryParameter(TuneUrlKeys.ACTION, TuneParameters.ACTION_CLICK);

        return builder.toString();
    }

    /**
     * Builds a new link string based on parameter values.
     * @return encrypted URL string based on class settings.
     */
    public static String buildLink(TuneEvent eventData, TunePreloadData preloaded, boolean debugMode) {
        params = TuneParameters.getInstance();
        
        StringBuilder link = new StringBuilder("https://").append(params.getAdvertiserId()).append(".");
        if (debugMode) {
            link.append(TuneConstants.TUNE_DOMAIN_DEBUG);
        } else {
            link.append(TuneConstants.TUNE_DOMAIN);
        }
        
        link.append("/serve?");
        link.append(TuneUrlKeys.SDK_VER + "=").append(Tune.getSDKVersion());
        link.append("&" + TuneUrlKeys.TRANSACTION_ID + "=").append(UUID.randomUUID().toString());
        link.append("&" + TuneUrlKeys.SDK_RETRY_ATTEMPT + "=0");

        safeAppend(link, TuneUrlKeys.SDK, "android");
        safeAppend(link, TuneUrlKeys.ACTION, params.getAction());
        safeAppend(link, TuneUrlKeys.ADVERTISER_ID, params.getAdvertiserId());
        safeAppend(link, TuneUrlKeys.PACKAGE_NAME, params.getPackageName());
        safeAppend(link, TuneUrlKeys.REFERRAL_SOURCE, params.getReferralSource());
        safeAppend(link, TuneUrlKeys.REFERRAL_URL, params.getReferralUrl());
        safeAppend(link, TuneUrlKeys.TRACKING_ID, params.getTrackingId());

        if (eventData.getEventId() != 0) {
            safeAppend(link, TuneUrlKeys.EVENT_ID, Integer.toString(eventData.getEventId()));
        }
        if (!TuneParameters.ACTION_SESSION.equals(params.getAction()) && !TuneParameters.ACTION_CLICK.equals(params.getAction())) {
            safeAppend(link, TuneUrlKeys.EVENT_NAME, eventData.getEventName());
        }

        // Append preloaded params, must have attr_set=1 in order to attribute
        if (preloaded != null) {
            link.append("&attr_set=1");
            safeAppend(link, TuneUrlKeys.PUBLISHER_ID, preloaded.publisherId);
            safeAppend(link, TuneUrlKeys.OFFER_ID, preloaded.offerId);
            safeAppend(link, TuneUrlKeys.AGENCY_ID, preloaded.agencyId);
            safeAppend(link, TuneUrlKeys.PUBLISHER_REF_ID, preloaded.publisherReferenceId);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB_PUBLISHER, preloaded.publisherSubPublisher);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB_SITE, preloaded.publisherSubSite);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB_CAMPAIGN, preloaded.publisherSubCampaign);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB_ADGROUP, preloaded.publisherSubAdgroup);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB_AD, preloaded.publisherSubAd);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB_KEYWORD, preloaded.publisherSubKeyword);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB1, preloaded.publisherSub1);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB2, preloaded.publisherSub2);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB3, preloaded.publisherSub3);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB4, preloaded.publisherSub4);
            safeAppend(link, TuneUrlKeys.PUBLISHER_SUB5, preloaded.publisherSub5);
            safeAppend(link, TuneUrlKeys.ADVERTISER_SUB_PUBLISHER, preloaded.advertiserSubPublisher);
            safeAppend(link, TuneUrlKeys.ADVERTISER_SUB_SITE, preloaded.advertiserSubSite);
            safeAppend(link, TuneUrlKeys.ADVERTISER_SUB_CAMPAIGN, preloaded.advertiserSubCampaign);
            safeAppend(link, TuneUrlKeys.ADVERTISER_SUB_ADGROUP, preloaded.advertiserSubAdgroup);
            safeAppend(link, TuneUrlKeys.ADVERTISER_SUB_AD, preloaded.advertiserSubAd);
            safeAppend(link, TuneUrlKeys.ADVERTISER_SUB_KEYWORD, preloaded.advertiserSubKeyword);
        }

        // If logging on, use debug mode
        if (debugMode) {
            link.append("&" + TuneUrlKeys.DEBUG_MODE + "=1");
        }

        return link.toString();
    }
    

    /**
     * Builds data in conversion link based on class member values, to be encrypted.
     * @return URL-encoded string based on class settings.
     */
    public static synchronized String buildDataUnencrypted(TuneEvent eventData) {
        params = TuneParameters.getInstance();

        StringBuilder link = new StringBuilder();

        link.append(TuneUrlKeys.CONNECTION_TYPE + "=" + params.getConnectionType());
        safeAppend(link, TuneUrlKeys.ANDROID_ID, params.getAndroidId());
        safeAppend(link, TuneUrlKeys.ANDROID_ID_MD5, params.getAndroidIdMd5());
        safeAppend(link, TuneUrlKeys.ANDROID_ID_SHA1, params.getAndroidIdSha1());
        safeAppend(link, TuneUrlKeys.ANDROID_ID_SHA256, params.getAndroidIdSha256());
        safeAppend(link, TuneUrlKeys.APP_AD_TRACKING, params.getAppAdTrackingEnabled());
        safeAppend(link, TuneUrlKeys.APP_NAME, params.getAppName());
        safeAppend(link, TuneUrlKeys.APP_VERSION, params.getAppVersion());
        safeAppend(link, TuneUrlKeys.APP_VERSION_NAME, params.getAppVersionName());
        safeAppend(link, TuneUrlKeys.COUNTRY_CODE, params.getCountryCode());
        safeAppend(link, TuneUrlKeys.DEVICE_BRAND, params.getDeviceBrand());
        safeAppend(link, TuneUrlKeys.DEVICE_BUILD, params.getDeviceBuild());
        safeAppend(link, TuneUrlKeys.DEVICE_CARRIER, params.getDeviceCarrier());
        safeAppend(link, TuneUrlKeys.DEVICE_CPU_TYPE, params.getDeviceCpuType());
        safeAppend(link, TuneUrlKeys.DEVICE_CPU_SUBTYPE, params.getDeviceCpuSubtype());
        safeAppend(link, TuneUrlKeys.DEVICE_MODEL, params.getDeviceModel());
        safeAppend(link, TuneUrlKeys.DEVICE_ID, params.getDeviceId());
        safeAppend(link, TuneUrlKeys.FIRE_AID, params.getFireAdvertisingId());
        safeAppend(link, TuneUrlKeys.FIRE_AD_TRACKING_DISABLED, params.getFireAdTrackingLimited());
        safeAppend(link, TuneUrlKeys.GOOGLE_AID, params.getGoogleAdvertisingId());
        safeAppend(link, TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, params.getGoogleAdTrackingLimited());
        safeAppend(link, TuneUrlKeys.INSTALL_DATE, params.getInstallDate());
        safeAppend(link, TuneUrlKeys.INSTALLER, params.getInstaller());
        safeAppend(link, TuneUrlKeys.INSTALL_REFERRER, params.getInstallReferrer());
        safeAppend(link, TuneUrlKeys.LANGUAGE, params.getLanguage());
        safeAppend(link, TuneUrlKeys.LAST_OPEN_LOG_ID, params.getLastOpenLogId());
        if (params.getLocation() != null) {
            safeAppend(link, TuneUrlKeys.ALTITUDE, Double.toString(params.getLocation().getAltitude()));
            safeAppend(link, TuneUrlKeys.LATITUDE, Double.toString(params.getLocation().getLatitude()));
            safeAppend(link, TuneUrlKeys.LONGITUDE, Double.toString(params.getLocation().getLongitude()));
        } else {
            safeAppend(link, TuneUrlKeys.ALTITUDE, params.getAltitude());
            safeAppend(link, TuneUrlKeys.LATITUDE, params.getLatitude());
            safeAppend(link, TuneUrlKeys.LONGITUDE, params.getLongitude());
        }
        safeAppend(link, TuneUrlKeys.LOCALE, params.getLocale());
        safeAppend(link, TuneUrlKeys.MAC_ADDRESS, params.getMacAddress());
        safeAppend(link, TuneUrlKeys.MAT_ID, params.getMatId());
        safeAppend(link, TuneUrlKeys.MOBILE_COUNTRY_CODE, params.getMCC());
        safeAppend(link, TuneUrlKeys.MOBILE_NETWORK_CODE, params.getMNC());
        safeAppend(link, TuneUrlKeys.OPEN_LOG_ID, params.getOpenLogId());
        safeAppend(link, TuneUrlKeys.OS_VERSION, params.getOsVersion());
        safeAppend(link, TuneUrlKeys.SDK_PLUGIN, params.getPluginName());
        safeAppend(link, TuneUrlKeys.PURCHASE_STATUS, params.getPurchaseStatus());
        safeAppend(link, TuneUrlKeys.REFERRER_DELAY, params.getReferrerDelay());
        safeAppend(link, TuneUrlKeys.SCREEN_DENSITY, params.getScreenDensity());
        safeAppend(link, TuneUrlKeys.SCREEN_SIZE, params.getScreenWidth() + "x" + params.getScreenHeight());
        safeAppend(link, TuneUrlKeys.SDK_VERSION, Tune.getSDKVersion());
        safeAppend(link, TuneUrlKeys.TRUSTE_ID, params.getTRUSTeId());
        safeAppend(link, TuneUrlKeys.USER_AGENT, params.getUserAgent());
        
        // Append event-level params
        safeAppend(link, TuneUrlKeys.ATTRIBUTE1, eventData.getAttribute1());
        safeAppend(link, TuneUrlKeys.ATTRIBUTE2, eventData.getAttribute2());
        safeAppend(link, TuneUrlKeys.ATTRIBUTE3, eventData.getAttribute3());
        safeAppend(link, TuneUrlKeys.ATTRIBUTE4, eventData.getAttribute4());
        safeAppend(link, TuneUrlKeys.ATTRIBUTE5, eventData.getAttribute5());
        safeAppend(link, TuneUrlKeys.CONTENT_ID, eventData.getContentId());
        safeAppend(link, TuneUrlKeys.CONTENT_TYPE, eventData.getContentType());
        // Event-level currency overrides TUNE class-level
        if (eventData.getCurrencyCode() != null) {
            safeAppend(link, TuneUrlKeys.CURRENCY_CODE, eventData.getCurrencyCode());
        } else {
            safeAppend(link, TuneUrlKeys.CURRENCY_CODE, params.getCurrencyCode());
        }
        if (eventData.getDate1() != null) {
            safeAppend(link, TuneUrlKeys.DATE1, Long.toString(eventData.getDate1().getTime() / 1000));
        }
        if (eventData.getDate2() != null) {
            safeAppend(link, TuneUrlKeys.DATE2, Long.toString(eventData.getDate2().getTime() / 1000));
        }
        if (eventData.getDeviceForm() != null) {
            safeAppend(link, TuneUrlKeys.DEVICE_FORM, eventData.getDeviceForm());
        }
        if (eventData.getLevel() != 0) {
            safeAppend(link, TuneUrlKeys.LEVEL, Integer.toString(eventData.getLevel()));
        }
        if (eventData.getQuantity() != 0) {
            safeAppend(link, TuneUrlKeys.QUANTITY, Integer.toString(eventData.getQuantity()));
        }
        if (eventData.getRating() != 0) {
            safeAppend(link, TuneUrlKeys.RATING, Double.toString(eventData.getRating()));
        }
        safeAppend(link, TuneUrlKeys.REF_ID, eventData.getRefId());
        safeAppend(link, TuneUrlKeys.REVENUE, Double.toString(eventData.getRevenue()));
        safeAppend(link, TuneUrlKeys.SEARCH_STRING, eventData.getSearchString());
        
        // Append user information
        safeAppend(link, TuneUrlKeys.AGE, params.getAge());
        safeAppend(link, TuneUrlKeys.EXISTING_USER, params.getExistingUser());
        safeAppend(link, TuneUrlKeys.FACEBOOK_USER_ID, params.getFacebookUserId());
        safeAppend(link, TuneUrlKeys.GENDER, params.getGender());
        safeAppend(link, TuneUrlKeys.GOOGLE_USER_ID, params.getGoogleUserId());
        safeAppend(link, TuneUrlKeys.IS_PAYING_USER, params.getIsPayingUser());
        safeAppend(link, TuneUrlKeys.TWITTER_USER_ID, params.getTwitterUserId());
        safeAppend(link, TuneUrlKeys.USER_EMAIL_MD5, params.getUserEmailMd5());
        safeAppend(link, TuneUrlKeys.USER_EMAIL_SHA1, params.getUserEmailSha1());
        safeAppend(link, TuneUrlKeys.USER_EMAIL_SHA256, params.getUserEmailSha256());
        safeAppend(link, TuneUrlKeys.USER_ID, params.getUserId());
        safeAppend(link, TuneUrlKeys.USER_NAME_MD5, params.getUserNameMd5());
        safeAppend(link, TuneUrlKeys.USER_NAME_SHA1, params.getUserNameSha1());
        safeAppend(link, TuneUrlKeys.USER_NAME_SHA256, params.getUserNameSha256());
        safeAppend(link, TuneUrlKeys.USER_PHONE_MD5, params.getPhoneNumberMd5());
        safeAppend(link, TuneUrlKeys.USER_PHONE_SHA1, params.getPhoneNumberSha1());
        safeAppend(link, TuneUrlKeys.USER_PHONE_SHA256, params.getPhoneNumberSha256());
        
        return link.toString();
    }

    
    /**
     * Update the advertising ID and install referrer, if present, and encrypts the data string.
     * @return encrypted string
     */
    public static synchronized String updateAndEncryptData(String data, TuneEncryption encryption) {
        if (data == null) {
            data = "";
        }

        StringBuilder updatedData = new StringBuilder(data);
        
        params = TuneParameters.getInstance();
        if (params != null) {
            String gaid = params.getGoogleAdvertisingId();
            if (gaid != null && !data.contains("&" + TuneUrlKeys.GOOGLE_AID + "=")) {
                safeAppend(updatedData, TuneUrlKeys.GOOGLE_AID, gaid);
                safeAppend(updatedData, TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, params.getGoogleAdTrackingLimited());
            }

            String fireAid = params.getFireAdvertisingId();
            if (fireAid != null && !data.contains("&" + TuneUrlKeys.FIRE_AID + "=")) {
                safeAppend(updatedData, TuneUrlKeys.FIRE_AID, fireAid);
                safeAppend(updatedData, TuneUrlKeys.FIRE_AD_TRACKING_DISABLED, params.getFireAdTrackingLimited());
            }
            
            String androidId = params.getAndroidId();
            if (androidId != null && !data.contains("&" + TuneUrlKeys.ANDROID_ID + "=")) {
                safeAppend(updatedData, TuneUrlKeys.ANDROID_ID, androidId);
            }
            
            String referrer = params.getInstallReferrer();
            if (referrer != null && !data.contains("&" + TuneUrlKeys.INSTALL_REFERRER + "=")) {
                safeAppend(updatedData, TuneUrlKeys.INSTALL_REFERRER, referrer);
            }
            String referralSource = params.getReferralSource();
            if (referralSource != null && !data.contains("&" + TuneUrlKeys.REFERRAL_SOURCE + "=")) {
                safeAppend(updatedData, TuneUrlKeys.REFERRAL_SOURCE, referralSource);
            }
            String referralUrl = params.getReferralUrl();
            if (referralUrl != null && !data.contains("&" + TuneUrlKeys.REFERRAL_URL + "=")) {
                safeAppend(updatedData, TuneUrlKeys.REFERRAL_URL, referralUrl);
            }
            String userAgent = params.getUserAgent();
            if (userAgent != null && !data.contains("&" + TuneUrlKeys.USER_AGENT + "=")) {
                safeAppend(updatedData, TuneUrlKeys.USER_AGENT, userAgent);
            }
            String fbUserId = params.getFacebookUserId();
            if (fbUserId != null && !data.contains("&" + TuneUrlKeys.FACEBOOK_USER_ID + "=")) {
                safeAppend(updatedData, TuneUrlKeys.FACEBOOK_USER_ID, fbUserId);
            }
            TuneLocation location = params.getLocation();
            if (location != null) {
                if (!data.contains("&" + TuneUrlKeys.ALTITUDE + "=")) {
                    safeAppend(updatedData, TuneUrlKeys.ALTITUDE, Double.toString(location.getAltitude()));
                }
                if (!data.contains("&" + TuneUrlKeys.LATITUDE + "=")) {
                    safeAppend(updatedData, TuneUrlKeys.LATITUDE, Double.toString(location.getLatitude()));
                }
                if (!data.contains("&" + TuneUrlKeys.LONGITUDE + "=")) {
                    safeAppend(updatedData, TuneUrlKeys.LONGITUDE, Double.toString(location.getLongitude()));
                }
            }

        }
        // Add system date of original request
        if (!data.contains("&" + TuneUrlKeys.SYSTEM_DATE + "=")) {
            long now = new Date().getTime()/1000;
            safeAppend(updatedData, TuneUrlKeys.SYSTEM_DATE, Long.toString(now));
        }
        
        String updatedDataStr = updatedData.toString();
        try {
            updatedDataStr = TuneUtils.bytesToHex(encryption.encrypt(updatedDataStr));
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
                postData.put(TuneUrlKeys.EVENT_ITEMS, eventItems);
            }
            if (iapData != null) {
                postData.put(TuneUrlKeys.RECEIPT_DATA, iapData);
            }
            if (iapSignature != null) {
                postData.put(TuneUrlKeys.RECEIPT_SIGNATURE, iapSignature);
            }
            if (emails != null) {
                postData.put(TuneUrlKeys.USER_EMAILS, emails);
            }
        } catch (JSONException e) {
            TuneUtils.log("Could not build JSON body of request");
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
                Log.w(TuneConstants.TAG, "failed encoding value " + value + " for key " + key);
                e.printStackTrace();
            }
        }
    }
}
