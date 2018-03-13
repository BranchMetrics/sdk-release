package com.tune;

import android.net.Uri;
import android.support.annotation.NonNull;

import com.tune.http.UrlRequester;

import java.util.HashSet;
import java.util.Set;

public class TuneDeeplinker {
    private static final String TLNK_IO = "tlnk.io";

    private final Set<String> registeredTuneLinkDomains;

    private final String advertiserId;
    private final String conversionKey;
    private String packageName;
    private String platformAdvertisingId;
    private int isPlatformLimitAdTrackingEnabled;
    private String androidId;
    private String userAgent;
    private TuneDeeplinkListener listener;
    private boolean haveRequestedDeferredDeeplink;

    TuneDeeplinker(String advertiserId, String conversionKey, String packageName) {
        this.advertiserId = advertiserId;
        this.conversionKey = conversionKey;
        this.packageName = packageName;
        registeredTuneLinkDomains = new HashSet<>();
        registeredTuneLinkDomains.add(TLNK_IO);
    }

    void setPackageName(String packageName) {
        this.packageName = packageName;
    }

    private void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }

    private String getUserAgent() {
        return userAgent;
    }

    void setPlatformAdvertisingId(String advertisingId, int isLATEnabled) {
        this.platformAdvertisingId = advertisingId;
        this.isPlatformLimitAdTrackingEnabled = isLATEnabled;
    }

    void setAndroidId(String androidId) {
        this.androidId = androidId;
    }

    public void setListener(TuneDeeplinkListener listener) {
        this.listener = listener;
    }

    void requestDeferredDeeplink(String userAgent, final UrlRequester urlRequester) {
        setUserAgent(userAgent);
        checkForDeferredDeeplink(urlRequester);
    }

    private String buildDeferredDeepLinkRequestURL() {
        String advertisingId = androidId;
        if (platformAdvertisingId != null) {
            advertisingId = platformAdvertisingId;
        }

        // Construct deeplink endpoint url
        Uri.Builder uri = new Uri.Builder();
        uri.scheme("https")
                .authority(advertiserId + "." + TuneConstants.DEEPLINK_DOMAIN)
                .appendPath("v1")
                .appendPath("link.txt")
                .appendQueryParameter("platform", "android")    // Not to be confused with SDK Type
                .appendQueryParameter(TuneUrlKeys.ADVERTISER_ID, advertiserId)
                .appendQueryParameter(TuneUrlKeys.SDK_VER, Tune.getSDKVersion())
                .appendQueryParameter(TuneUrlKeys.PACKAGE_NAME, packageName)
                .appendQueryParameter("ad_id", advertisingId)
                .appendQueryParameter("user_agent", getUserAgent());

        // REVISIT: As of 20180308 this is not used by the server, however it is an open question if it will be useful in the future.
        // Reference: SDK-296
        if (platformAdvertisingId != null) {
            uri.appendQueryParameter(TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, Integer.toString(isPlatformLimitAdTrackingEnabled));
        }

        return uri.build().toString();
    }

    private void checkForDeferredDeeplink(final UrlRequester urlRequester) {
        // If we have already checked, don't check again, if no one is listening, don't check
        if (listener == null) {
            return;
        }

        if (haveRequestedDeferredDeeplink) {
            return;
        }

        // If advertiser ID, conversion key, or package name were not set, return
        if (advertiserId == null || conversionKey == null || packageName == null) {
            listener.didFailDeeplink("Advertiser ID, conversion key, or package name not set");
            return;
        }

        // If no device identifiers collected, return
        if (platformAdvertisingId == null && androidId == null) {
            listener.didFailDeeplink("No device identifiers collected");
            return;
        }

        haveRequestedDeferredDeeplink = true;

        final TuneDeeplinkListener listenerRefForNewThread = listener;
        new Thread(new Runnable() {
            @Override
            public void run() {
                urlRequester.requestDeeplink(buildDeferredDeepLinkRequestURL(), conversionKey, listenerRefForNewThread);
            }
        }).start();
    }

    void handleFailedExpandedTuneLink(String errorMessage) {
        if (listener != null) {
            listener.didFailDeeplink(errorMessage);
        }
    }

    void handleExpandedTuneLink(String invokeUrl) {
        if (listener != null) {
            listener.didReceiveDeeplink(invokeUrl);
        }
    }

    void registerCustomTuneLinkDomain(String domain) {
        if (domain != null) {
            registeredTuneLinkDomains.add(domain);
        }
    }

    boolean isTuneLink(@NonNull String appLinkUrl) {
        boolean isTuneLink = false;
        try {
            Uri appLink = Uri.parse(appLinkUrl);
            String scheme = appLink.getScheme();
            if (!("https".equals(scheme) || "http".equals(scheme))) {
                // All Tune Links are https or http
                return false;
            }
            String host = appLink.getHost();
            for (String registeredTuneDomain : registeredTuneLinkDomains) {
                if (host.endsWith(registeredTuneDomain)) {
                    isTuneLink = true;
                    break;
                }
            }
        } catch (Exception ignore) {
            // not a url or error parsing, will return false
        }
        return isTuneLink;
    }
}
