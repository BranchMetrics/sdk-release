package com.tune;

import android.content.Context;
import android.net.Uri;
import android.support.annotation.NonNull;

import com.tune.http.UrlRequester;

import java.util.HashSet;
import java.util.Set;

public class TuneDeeplinker {
    public static final String TLNK_IO = "tlnk.io";

    private final Set<String> registeredTuneLinkDomains;

    private final String advertiserId;
    private final String conversionKey;
    private String packageName;
    private String googleAdvertisingId;
    private int isLimitAdTrackingEnabled;
    private String androidId;
    private String userAgent;
    private TuneDeeplinkListener listener;
    private boolean haveRequestedDeferredDeeplink;

    public TuneDeeplinker(String advertiserId, String conversionKey, String packageName) {
        this.advertiserId = advertiserId;
        this.conversionKey = conversionKey;
        this.packageName = packageName;
        registeredTuneLinkDomains = new HashSet<>();
        registeredTuneLinkDomains.add(TLNK_IO);
    }

    public void setPackageName(String packageName) {
        this.packageName = packageName;
    }

    public void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }

    public String getUserAgent() {
        return userAgent;
    }
    
    public void setGoogleAdvertisingId(String googleAdvertisingId, int isLATEnabled) {
        this.googleAdvertisingId = googleAdvertisingId;
        this.isLimitAdTrackingEnabled = isLATEnabled;
    }
    
    public void setAndroidId(String androidId) {
        this.androidId = androidId;
    }

    public void setListener(TuneDeeplinkListener listener) {
        this.listener = listener;
    }

    public void requestDeferredDeeplink(String userAgent, final Context context, final UrlRequester urlRequester) {
        setUserAgent(userAgent);
        checkForDeferredDeeplink(context, urlRequester);
    }

    public String buildDeferredDeepLinkRequestURL() {
        // Construct deeplink endpoint url
        Uri.Builder uri = new Uri.Builder();
        uri.scheme("https")
                .authority(advertiserId + "." + TuneConstants.DEEPLINK_DOMAIN)
                .appendPath("v1")
                .appendPath("link.txt")
                .appendQueryParameter("platform", "android")
                .appendQueryParameter("advertiser_id", advertiserId)
                .appendQueryParameter("ver", TuneConstants.SDK_VERSION)
                .appendQueryParameter("package_name", packageName)
                .appendQueryParameter("ad_id", ((googleAdvertisingId != null) ? googleAdvertisingId : androidId))
                .appendQueryParameter("user_agent", getUserAgent());

        if (googleAdvertisingId != null) {
            uri.appendQueryParameter("google_ad_tracking_disabled", Integer.toString(isLimitAdTrackingEnabled));
        }

        return uri.build().toString();
    }

    private void checkForDeferredDeeplink(final Context context, final UrlRequester urlRequester) {
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
        if (googleAdvertisingId == null && androidId == null) {
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

    public void handleFailedExpandedTuneLink(String errorMessage) {
        if (listener != null) {
            listener.didFailDeeplink(errorMessage);
        }
    }

    public void handleExpandedTuneLink(String invokeUrl) {
        if (listener != null) {
            listener.didReceiveDeeplink(invokeUrl);
        }
    }

    public void registerCustomTuneLinkDomain(String domain) {
        if (domain != null) {
            registeredTuneLinkDomains.add(domain);
        }
    }

    public boolean isTuneLink(@NonNull String appLinkUrl) {
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
