package com.tune;

import android.location.Location;
import android.net.Uri;

import com.tune.utils.TuneUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Date;
import java.util.Set;
import java.util.UUID;

class TuneUrlBuilder {
    /**
     * Builds a new link string based on parameter values.
     * @return encrypted URL string based on class settings.
     */
    static String appendTuneLinkParameters(final TuneParameters params, String clickedTuneLinkUrl) {
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
    static String buildLink(final TuneParameters params, TuneEvent eventData, TunePreloadData preloaded, boolean debugMode) {
        Set<String> redactKeys = TuneParameters.getRedactedKeys();

        StringBuilder link = new StringBuilder("https://").append(params.getAdvertiserId()).append(".");
        link.append(TuneConstants.TUNE_DOMAIN);
        link.append("/serve?");
        link.append(TuneUrlKeys.SDK_VER + "=").append(Tune.getSDKVersion());
        link.append("&" + TuneUrlKeys.TRANSACTION_ID + "=").append(UUID.randomUUID().toString());
        link.append("&" + TuneUrlKeys.SDK_RETRY_ATTEMPT + "=0");

        safeAppend(link, redactKeys, TuneUrlKeys.SDK, params.getSDKType().toString());
        safeAppend(link, redactKeys, TuneUrlKeys.ACTION, params.getAction());
        safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_ID, params.getAdvertiserId());
        safeAppend(link, redactKeys, TuneUrlKeys.PACKAGE_NAME, params.getPackageName());
        safeAppend(link, redactKeys, TuneUrlKeys.REFERRAL_SOURCE, params.getReferralSource());
        safeAppend(link, redactKeys, TuneUrlKeys.REFERRAL_URL, params.getReferralUrl());
        safeAppend(link, redactKeys, TuneUrlKeys.TRACKING_ID, params.getTrackingId());

        if (!TuneParameters.ACTION_SESSION.equals(params.getAction()) && !TuneParameters.ACTION_CLICK.equals(params.getAction())) {
            safeAppend(link, redactKeys, TuneUrlKeys.EVENT_NAME, eventData.getEventName());
        }

        // Append preloaded params, must have attr_set=1 in order to attribute
        if (preloaded != null) {
            link.append("&attr_set=1");
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_ID, preloaded.getPublisherId());
            safeAppend(link, redactKeys, TuneUrlKeys.OFFER_ID, preloaded.getOfferId());
            safeAppend(link, redactKeys, TuneUrlKeys.AGENCY_ID, preloaded.getAgencyId());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_REF_ID, preloaded.getPublisherReferenceId());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB_PUBLISHER, preloaded.getPublisherSubPublisher());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB_SITE, preloaded.getPublisherSubSite());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB_CAMPAIGN, preloaded.getPublisherSubCampaign());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB_ADGROUP, preloaded.getPublisherSubAdgroup());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB_AD, preloaded.getPublisherSubAd());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB_KEYWORD, preloaded.getPublisherSubKeyword());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB1, preloaded.getPublisherSub1());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB2, preloaded.getPublisherSub2());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB3, preloaded.getPublisherSub3());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB4, preloaded.getPublisherSub4());
            safeAppend(link, redactKeys, TuneUrlKeys.PUBLISHER_SUB5, preloaded.getPublisherSub5());
            safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_SUB_PUBLISHER, preloaded.getAdvertiserSubPublisher());
            safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_SUB_SITE, preloaded.getAdvertiserSubSite());
            safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_SUB_CAMPAIGN, preloaded.getAdvertiserSubCampaign());
            safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_SUB_ADGROUP, preloaded.getAdvertiserSubAdgroup());
            safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_SUB_AD, preloaded.getAdvertiserSubAd());
            safeAppend(link, redactKeys, TuneUrlKeys.ADVERTISER_SUB_KEYWORD, preloaded.getAdvertiserSubKeyword());
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
    static synchronized String buildDataUnencrypted(final TuneParameters params, final TuneEvent eventData) {
        Set<String> redactKeys = TuneParameters.getRedactedKeys();
        StringBuilder link = new StringBuilder();

        link.append(TuneUrlKeys.CONNECTION_TYPE + "=").append(params.getConnectionType());
        safeAppend(link, redactKeys, TuneUrlKeys.ANDROID_ID, params.getAndroidId());
        safeAppend(link, redactKeys, TuneUrlKeys.ANDROID_ID_MD5, params.getAndroidIdMd5());
        safeAppend(link, redactKeys, TuneUrlKeys.ANDROID_ID_SHA1, params.getAndroidIdSha1());
        safeAppend(link, redactKeys, TuneUrlKeys.ANDROID_ID_SHA256, params.getAndroidIdSha256());

        safeAppend(link, redactKeys, TuneUrlKeys.APP_NAME, params.getAppName());
        safeAppend(link, redactKeys, TuneUrlKeys.APP_VERSION, params.getAppVersion());
        safeAppend(link, redactKeys, TuneUrlKeys.APP_VERSION_NAME, params.getAppVersionName());
        safeAppend(link, redactKeys, TuneUrlKeys.COUNTRY_CODE, params.getCountryCode());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_BRAND, params.getDeviceBrand());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_BUILD, params.getDeviceBuild());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_CARRIER, params.getDeviceCarrier());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_CPU_TYPE, params.getDeviceCpuType());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_CPU_SUBTYPE, params.getDeviceCpuSubtype());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_MODEL, params.getDeviceModel());
        safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_ID, params.getDeviceId());
        safeAppend(link, redactKeys, TuneUrlKeys.FIRE_AID, params.getFireAdvertisingId());
        safeAppend(link, redactKeys, TuneUrlKeys.GOOGLE_AID, params.getGoogleAdvertisingId());
        safeAppend(link, redactKeys, TuneUrlKeys.INSTALL_DATE, params.getInstallDate());
        safeAppend(link, redactKeys, TuneUrlKeys.INSTALL_BEGIN_TIMESTAMP, params.getInstallBeginTimestampSeconds());
        safeAppend(link, redactKeys, TuneUrlKeys.REFERRER_CLICK_TIMESTAMP, params.getReferrerClickTimestampSeconds());
        safeAppend(link, redactKeys, TuneUrlKeys.INSTALLER, params.getInstaller());
        safeAppend(link, redactKeys, TuneUrlKeys.INSTALL_REFERRER, params.getInstallReferrer());
        safeAppend(link, redactKeys, TuneUrlKeys.LANGUAGE, params.getLanguage());
        safeAppend(link, redactKeys, TuneUrlKeys.LAST_OPEN_LOG_ID, params.getLastOpenLogId());
        if (params.getLocation() != null) {
            safeAppend(link, redactKeys, TuneUrlKeys.ALTITUDE, Double.toString(params.getLocation().getAltitude()));
            safeAppend(link, redactKeys, TuneUrlKeys.LATITUDE, Double.toString(params.getLocation().getLatitude()));
            safeAppend(link, redactKeys, TuneUrlKeys.LONGITUDE, Double.toString(params.getLocation().getLongitude()));
        }
        safeAppend(link, redactKeys, TuneUrlKeys.LOCALE, params.getLocale());
        safeAppend(link, redactKeys, TuneUrlKeys.MAT_ID, params.getMatId());
        safeAppend(link, redactKeys, TuneUrlKeys.MOBILE_COUNTRY_CODE, params.getMCC());
        safeAppend(link, redactKeys, TuneUrlKeys.MOBILE_NETWORK_CODE, params.getMNC());
        safeAppend(link, redactKeys, TuneUrlKeys.OPEN_LOG_ID, params.getOpenLogId());
        safeAppend(link, redactKeys, TuneUrlKeys.OS_VERSION, params.getOsVersion());
        safeAppend(link, redactKeys, TuneUrlKeys.SDK_PLUGIN, params.getPluginName());
        safeAppend(link, redactKeys, TuneUrlKeys.PLATFORM_AID, params.getPlatformAdvertisingId());
        safeAppend(link, redactKeys, TuneUrlKeys.PURCHASE_STATUS, params.getPurchaseStatus());
        safeAppend(link, redactKeys, TuneUrlKeys.REFERRER_DELAY, params.getReferrerDelay());
        safeAppend(link, redactKeys, TuneUrlKeys.SCREEN_DENSITY, params.getScreenDensity());
        safeAppend(link, redactKeys, TuneUrlKeys.SCREEN_LAYOUT_SIZE, params.getScreenWidth() + "x" + params.getScreenHeight());
        safeAppend(link, redactKeys, TuneUrlKeys.SDK_VERSION, Tune.getSDKVersion());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_AGENT, params.getUserAgent());

        // Append event-level params
        safeAppend(link, redactKeys, TuneUrlKeys.ATTRIBUTE1, eventData.getAttribute1());
        safeAppend(link, redactKeys, TuneUrlKeys.ATTRIBUTE2, eventData.getAttribute2());
        safeAppend(link, redactKeys, TuneUrlKeys.ATTRIBUTE3, eventData.getAttribute3());
        safeAppend(link, redactKeys, TuneUrlKeys.ATTRIBUTE4, eventData.getAttribute4());
        safeAppend(link, redactKeys, TuneUrlKeys.ATTRIBUTE5, eventData.getAttribute5());
        safeAppend(link, redactKeys, TuneUrlKeys.CONTENT_ID, eventData.getContentId());
        safeAppend(link, redactKeys, TuneUrlKeys.CONTENT_TYPE, eventData.getContentType());
        safeAppend(link, redactKeys, TuneUrlKeys.CURRENCY_CODE, eventData.getCurrencyCode());

        if (eventData.getDate1() != null) {
            safeAppend(link, redactKeys, TuneUrlKeys.DATE1, Long.toString(eventData.getDate1().getTime() / 1000));
        }
        if (eventData.getDate2() != null) {
            safeAppend(link, redactKeys, TuneUrlKeys.DATE2, Long.toString(eventData.getDate2().getTime() / 1000));
        }
        if (eventData.getDeviceForm() != null) {
            safeAppend(link, redactKeys, TuneUrlKeys.DEVICE_FORM, eventData.getDeviceForm());
        }
        if (eventData.getLevel() != 0) {
            safeAppend(link, redactKeys, TuneUrlKeys.LEVEL, Integer.toString(eventData.getLevel()));
        }
        if (eventData.getQuantity() != 0) {
            safeAppend(link, redactKeys, TuneUrlKeys.QUANTITY, Integer.toString(eventData.getQuantity()));
        }
        if (eventData.getRating() != 0) {
            safeAppend(link, redactKeys, TuneUrlKeys.RATING, Double.toString(eventData.getRating()));
        }
        safeAppend(link, redactKeys, TuneUrlKeys.REF_ID, eventData.getRefId());
        safeAppend(link, redactKeys, TuneUrlKeys.REVENUE, Double.toString(eventData.getRevenue()));
        safeAppend(link, redactKeys, TuneUrlKeys.SEARCH_STRING, eventData.getSearchString());

        // Append user information
        safeAppend(link, redactKeys, TuneUrlKeys.AGE, params.getAge());
        safeAppend(link, redactKeys, TuneUrlKeys.EXISTING_USER, params.getExistingUser());
        safeAppend(link, redactKeys, TuneUrlKeys.FACEBOOK_USER_ID, params.getFacebookUserId());
        safeAppend(link, redactKeys, TuneUrlKeys.GENDER, params.getGender());
        safeAppend(link, redactKeys, TuneUrlKeys.GOOGLE_USER_ID, params.getGoogleUserId());
        safeAppend(link, redactKeys, TuneUrlKeys.IS_PAYING_USER, params.isPayingUser());
        safeAppend(link, redactKeys, TuneUrlKeys.TWITTER_USER_ID, params.getTwitterUserId());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_EMAIL_MD5, params.getUserEmailMd5());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_EMAIL_SHA1, params.getUserEmailSha1());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_EMAIL_SHA256, params.getUserEmailSha256());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_ID, params.getUserId());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_NAME_MD5, params.getUserNameMd5());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_NAME_SHA1, params.getUserNameSha1());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_NAME_SHA256, params.getUserNameSha256());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_PHONE_MD5, params.getPhoneNumberMd5());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_PHONE_SHA1, params.getPhoneNumberSha1());
        safeAppend(link, redactKeys, TuneUrlKeys.USER_PHONE_SHA256, params.getPhoneNumberSha256());

        // Age is handled differently with regards to COPPA.
        safeAppend(link, redactKeys, TuneUrlKeys.IS_COPPA, (params.isPrivacyProtectedDueToAge() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));

        // AppAdTracking is handled differently with regards to COPPA, but is defaulted "true" if it is not set on the server
        if (params.isAppAdTrackingSet()) {
            safeAppend(link, redactKeys, TuneUrlKeys.APP_AD_TRACKING, (params.getAppAdTrackingEnabled() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));
        }

        safeAppend(link, redactKeys, TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, (params.getPlatformAdTrackingLimited() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET)); // DEPRECATED
        safeAppend(link, redactKeys, TuneUrlKeys.FIRE_AD_TRACKING_DISABLED, (params.getPlatformAdTrackingLimited() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));   // DEPRECATED
        safeAppend(link, redactKeys, TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, (params.getPlatformAdTrackingLimited() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));

        return link.toString();
    }


    /**
     * Update the advertising ID and install referrer, if present, and encrypts the data string.
     * @return encrypted string
     */
    static synchronized String updateAndEncryptData(final TuneParameters params, String data, final TuneEncryption encryption) {
        if (data == null) {
            data = "";
        }

        Set<String> redactKeys = TuneParameters.getRedactedKeys();
        StringBuilder updatedData = new StringBuilder(data);

        if (params != null) {
            String gaid = params.getGoogleAdvertisingId();
            if (gaid != null && !data.contains("&" + TuneUrlKeys.GOOGLE_AID + "=")) {
                // DEPRECATED
                safeAppend(updatedData, redactKeys, TuneUrlKeys.GOOGLE_AID, gaid);
                safeAppend(updatedData, redactKeys, TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, (params.getPlatformAdTrackingLimited() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));
            }

            String fireAid = params.getFireAdvertisingId();
            if (fireAid != null && !data.contains("&" + TuneUrlKeys.FIRE_AID + "=")) {
                // DEPRECATED
                safeAppend(updatedData, redactKeys, TuneUrlKeys.FIRE_AID, fireAid);
                safeAppend(updatedData, redactKeys, TuneUrlKeys.FIRE_AD_TRACKING_DISABLED, (params.getPlatformAdTrackingLimited() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));
            }

            String platformAid = params.getPlatformAdvertisingId();
            if (platformAid != null && !data.contains("&" + TuneUrlKeys.PLATFORM_AID + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.PLATFORM_AID, platformAid);
                safeAppend(updatedData, redactKeys, TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, (params.getPlatformAdTrackingLimited() ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET));
            }

            String androidId = params.getAndroidId();
            if (androidId != null && !data.contains("&" + TuneUrlKeys.ANDROID_ID + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.ANDROID_ID, androidId);
            }

            String referrer = params.getInstallReferrer();
            if (referrer != null && !data.contains("&" + TuneUrlKeys.INSTALL_REFERRER + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.INSTALL_REFERRER, referrer);
            }
            String referralSource = params.getReferralSource();
            if (referralSource != null && !data.contains("&" + TuneUrlKeys.REFERRAL_SOURCE + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.REFERRAL_SOURCE, referralSource);
            }
            String referralUrl = params.getReferralUrl();
            if (referralUrl != null && !data.contains("&" + TuneUrlKeys.REFERRAL_URL + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.REFERRAL_URL, referralUrl);
            }
            String installBeginTimestamp = params.getInstallBeginTimestampSeconds();
            if (installBeginTimestamp != null && !data.contains("&" + TuneUrlKeys.INSTALL_BEGIN_TIMESTAMP + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.INSTALL_BEGIN_TIMESTAMP, installBeginTimestamp);
            }
            String referrerClickTimestamp = params.getReferrerClickTimestampSeconds();
            if (referrerClickTimestamp != null && !data.contains("&" + TuneUrlKeys.REFERRER_CLICK_TIMESTAMP + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.REFERRER_CLICK_TIMESTAMP, referrerClickTimestamp);
            }
            String userAgent = params.getUserAgent();
            if (userAgent != null && !data.contains("&" + TuneUrlKeys.USER_AGENT + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.USER_AGENT, userAgent);
            }
            String fbUserId = params.getFacebookUserId();
            if (fbUserId != null && !data.contains("&" + TuneUrlKeys.FACEBOOK_USER_ID + "=")) {
                safeAppend(updatedData, redactKeys, TuneUrlKeys.FACEBOOK_USER_ID, fbUserId);
            }
            Location location = params.getLocation();
            if (location != null) {
                if (!data.contains("&" + TuneUrlKeys.ALTITUDE + "=")) {
                    safeAppend(updatedData, redactKeys, TuneUrlKeys.ALTITUDE, Double.toString(location.getAltitude()));
                }
                if (!data.contains("&" + TuneUrlKeys.LATITUDE + "=")) {
                    safeAppend(updatedData, redactKeys, TuneUrlKeys.LATITUDE, Double.toString(location.getLatitude()));
                }
                if (!data.contains("&" + TuneUrlKeys.LONGITUDE + "=")) {
                    safeAppend(updatedData, redactKeys, TuneUrlKeys.LONGITUDE, Double.toString(location.getLongitude()));
                }
            }

        }
        // Add system date of original request
        if (!data.contains("&" + TuneUrlKeys.SYSTEM_DATE + "=")) {
            long now = new Date().getTime()/1000;
            safeAppend(updatedData, redactKeys, TuneUrlKeys.SYSTEM_DATE, Long.toString(now));
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
    static synchronized JSONObject buildBody(JSONArray eventItems, String iapData, String iapSignature, JSONArray emails) {
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
            TuneDebugLog.d("Could not build JSON body of request");
            e.printStackTrace();
        }

        return postData;
    }

    /*
     * URL builders
     */
    private static synchronized void safeAppend(StringBuilder link, Set<String> redactKeys, String key, String value) {
        if (value != null && !value.equals("")) {
            if (redactKeys.contains(key)) {
                // Key is redacted, and will not be appended.
                // TuneDebugLog.d("REDACTED: " + key);
            } else {
                try {
                    link.append("&").append(key).append("=").append(URLEncoder.encode(value, "UTF-8"));
                } catch (UnsupportedEncodingException e) {
                    TuneDebugLog.w("failed encoding value " + value + " for key " + key, e);
                }
            }
        }
    }
}
