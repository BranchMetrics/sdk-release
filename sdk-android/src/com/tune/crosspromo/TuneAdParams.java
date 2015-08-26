package com.tune.crosspromo;

import java.util.Date;
import java.util.Set;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.res.Configuration;
import android.location.Location;

import com.mobileapptracker.MATGender;
import com.mobileapptracker.MATParameters;

/**
 * Class for holding params to send with ad metadata
 */
public class TuneAdParams {
    private TuneAdOrientation mOrientation;
    private String mPlacement;

    private String advertiserId;
    private String altitude;
    private String androidId;
    private String appName;
    private String appVersion;
    private String connectionType;
    private String countryCode;
    private String currentOrientation;
    private String deviceBrand;
    private String deviceCarrier;
    private String deviceCpuType;
    private String deviceModel;
    private String facebookUserId;
    private String googleAdId;
    private boolean googleIsLATEnabled;
    private String googleUserId;
    private String installDate;
    private String installReferrer;
    private String installer;
    private String keyCheck;
    private String language;
    private String lastOpenLogId;
    private String latitude;
    private String longitude;
    private String matId;
    private String mcc;
    private String mnc;
    private String osVersion;
    private String packageName;
    private boolean payingUser;
    private String pluginName;
    private String referralSource;
    private String referralUrl;
    private float screenDensity;
    private int screenHeight;
    private int screenWidth;
    private String sdkVersion;
    private String timeZone;
    private String twitterUserId;
    private String userAgent;
    private String userId;
    private String userEmailMd5;
    private String userEmailSha1;
    private String userEmailSha256;
    private String userNameMd5;
    private String userNameSha1;
    private String userNameSha256;
    private String userPhoneMd5;
    private String userPhoneSha1;
    private String userPhoneSha256;

    private Date birthDate;
    private MATGender gender;
    private Set<String> keywords;
    private Location location;
    private JSONObject customTargets;
    private JSONObject refs;
    
    public boolean debugMode;

    public int adWidthPortrait;
    public int adHeightPortrait;
    public int adWidthLandscape;
    public int adHeightLandscape;

    public TuneAdParams(String placement, MATParameters params, TuneAdMetadata metadata, TuneAdOrientation orientation, int lastOrientation) {
        mPlacement = placement;
        mOrientation = orientation;
        
        if (lastOrientation == Configuration.ORIENTATION_LANDSCAPE) {
            currentOrientation = "landscape";
        } else {
            currentOrientation = "portrait";
        }
        
        advertiserId = params.getAdvertiserId();
        androidId = params.getAndroidId();
        appName = params.getAppName();
        appVersion = params.getAppVersion();
        connectionType = params.getConnectionType();
        countryCode = params.getCountryCode();
        debugMode = params.getDebugMode();
        deviceBrand = params.getDeviceBrand();
        deviceCarrier = params.getDeviceCarrier();
        deviceCpuType = params.getDeviceCpuType();
        deviceModel = params.getDeviceModel();
        googleAdId = params.getGoogleAdvertisingId();
        googleIsLATEnabled = (params.getGoogleAdTrackingLimited() != null && params
                .getGoogleAdTrackingLimited().equals("1")) ? true : false;
        installDate = params.getInstallDate();
        installReferrer = params.getInstallReferrer();
        installer = params.getInstaller();
        String conversionKey = params.getConversionKey();
        keyCheck = conversionKey.substring(Math.max(0, conversionKey.length() - 4));
        language = params.getLanguage();
        lastOpenLogId = params.getLastOpenLogId();
        matId = params.getMatId();
        mcc = params.getMCC();
        mnc = params.getMNC();
        osVersion = params.getOsVersion();
        packageName = params.getPackageName();
        pluginName = params.getPluginName();
        referralSource = params.getReferralSource();
        referralUrl = params.getReferralUrl();
        screenDensity = Float.parseFloat(params.getScreenDensity());
        screenHeight = Integer.parseInt(params.getScreenHeight());
        screenWidth = Integer.parseInt(params.getScreenWidth());
        sdkVersion = params.getSdkVersion();
        timeZone = params.getTimeZone();
        userAgent = params.getUserAgent();

        gender = MATGender.UNKNOWN;
        String matGender = params.getGender();
        if (matGender != null) {
            if (matGender.equals("0")) {
                gender = MATGender.MALE;
            } else if (matGender.equals("1")) {
                gender = MATGender.FEMALE;
            }
        }
        facebookUserId = params.getFacebookUserId();
        googleUserId = params.getGoogleUserId();
        twitterUserId = params.getTwitterUserId();
        if (params.getIsPayingUser().equals("1")) {
            payingUser = true;
        } else {
            payingUser = false;
        }
        userEmailMd5 = params.getUserEmailMd5();
        userEmailSha1 = params.getUserEmailSha1();
        userEmailSha256 = params.getUserEmailSha256();
        userId = params.getUserId();
        userNameMd5 = params.getUserNameMd5();
        userNameSha1 = params.getUserNameSha1();
        userNameSha256 = params.getUserNameSha256();
        userPhoneMd5 = params.getPhoneNumberMd5();
        userPhoneSha1 = params.getPhoneNumberSha1();
        userPhoneSha256 = params.getPhoneNumberSha256();
        
        // Default adsize: landscape dimensions = portrait flipped
        if (lastOrientation == Configuration.ORIENTATION_LANDSCAPE) {
            adWidthLandscape = screenWidth;
            adHeightLandscape = screenHeight;
            adWidthPortrait = screenHeight;
            adHeightPortrait = screenWidth;
        } else {
            adWidthPortrait = screenWidth;
            adHeightPortrait = screenHeight;
            adWidthLandscape = screenHeight;
            adHeightLandscape = screenWidth;
        }

        if (metadata != null) {
            birthDate = metadata.getBirthDate();
            gender = metadata.getGender();
            keywords = metadata.getKeywords();
            location = metadata.getLocation();
            if (location != null) {
                altitude = String.valueOf(location.getAltitude());
                latitude = String.valueOf(location.getLatitude());
                longitude = String.valueOf(location.getLongitude());
            }
            if (metadata.getLatitude() != 0.0 && metadata.getLongitude() != 0.0) {
                latitude = String.valueOf(metadata.getLatitude());
                longitude = String.valueOf(metadata.getLongitude());
            }
            if (metadata.getCustomTargets() != null) {
                customTargets = new JSONObject(metadata.getCustomTargets());
            }
            if (metadata.isInDebugMode()) {
                debugMode = metadata.isInDebugMode();
            }

            // Set the same params in MAT
            params.setGender(gender);
            if (location != null) {
                params.setLocation(location);
            }
        }
    }

    public JSONObject toJSON() {
        JSONObject object = new JSONObject();

        try {
            JSONObject app = new JSONObject().put("advertiserId", advertiserId)
                    .put("keyCheck", keyCheck).put("name", appName)
                    .put("version", appVersion).put("installDate", installDate)
                    .put("installReferrer", installReferrer)
                    .put("installer", installer)
                    .put("referralSource", referralSource)
                    .put("referralUrl",  referralUrl)
                    .put("package", packageName);

            JSONObject device = new JSONObject().put("altitude", altitude)
                    .put("connectionType", connectionType)
                    .put("country", countryCode)
                    .put("deviceBrand", deviceBrand)
                    .put("deviceCarrier", deviceCarrier)
                    .put("deviceCpuType", deviceCpuType)
                    .put("deviceModel", deviceModel).put("language", language)
                    .put("latitude", latitude).put("longitude", longitude)
                    .put("mcc", mcc).put("mnc", mnc).put("os", "Android")
                    .put("osVersion", osVersion).put("timezone", timeZone)
                    .put("userAgent", userAgent);

            JSONObject ids = new JSONObject();
            ids.put("androidId", androidId);
            ids.put("gaid", googleAdId);
            ids.put("googleAdTrackingDisabled", googleIsLATEnabled);
            ids.put("matId", matId);

            JSONObject screen = new JSONObject().put("density", screenDensity)
                    .put("height", screenHeight).put("width", screenWidth);

            JSONObject sizes = new JSONObject();
            JSONObject portrait, landscape;
            if (mOrientation.equals(TuneAdOrientation.ALL)) {
                portrait = new JSONObject().put("width", adWidthPortrait).put(
                        "height", adHeightPortrait);
                landscape = new JSONObject().put("width", adWidthLandscape).put(
                        "height", adHeightLandscape);
                sizes.put("portrait", portrait).put("landscape", landscape);
            } else if (mOrientation.equals(TuneAdOrientation.PORTRAIT_ONLY)) {
                portrait = new JSONObject().put("width", adWidthPortrait).put(
                        "height", adHeightPortrait);
                sizes.put("portrait", portrait);
            } else if (mOrientation.equals(TuneAdOrientation.LANDSCAPE_ONLY)) {
                landscape = new JSONObject().put("width", adWidthLandscape).put(
                        "height", adHeightLandscape);
                sizes.put("landscape", landscape);
            }

            JSONObject user = new JSONObject();
            if (birthDate != null) {
                user.put("birthDate", Long.toString(birthDate.getTime() / 1000));
            }
            user.put("facebookUserId", facebookUserId);
            user.put("gender", gender);
            user.put("googleUserId", googleUserId);
            if (keywords != null) {
                // Create JSONArray for keywords
                JSONArray keywordArr = new JSONArray();
                for (String keyword : keywords) {
                    keywordArr.put(keyword);
                }
                user.put("keywords", keywordArr);
            }
            user.put("payingUser", payingUser);
            user.put("twitterUserId", twitterUserId);
            user.put("userEmailMd5", userEmailMd5);
            user.put("userEmailSha1", userEmailSha1);
            user.put("userEmailSha256", userEmailSha256);
            if (userId != null && userId.length() != 0) {
                user.put("userId", userId);
            }
            user.put("userNameMd5", userNameMd5);
            user.put("userNameSha1", userNameSha1);
            user.put("userNameSha256", userNameSha256);
            user.put("userPhoneMd5", userPhoneMd5);
            user.put("userPhoneSha1", userPhoneSha1);
            user.put("userPhoneSha256", userPhoneSha256);

            object.put("currentOrientation", currentOrientation);
            object.put("debugMode", debugMode);
            object.put("sdkVersion", sdkVersion);
            object.put("plugin", pluginName);
            object.put("lastOpenLogId", lastOpenLogId);
            object.put("app", app);
            object.put("device", device);
            object.put("ids", ids);
            object.put("screen", screen);
            object.put("sizes", sizes);
            object.put("user", user);
            object.put("targets", customTargets);
            object.put("refs", refs);
            object.put("placement", mPlacement);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return object;
    }
    
    public void setRefs(JSONObject refs) {
        this.refs = refs;
    }
    
    public JSONObject getRefs() {
        return refs;
    }
}
