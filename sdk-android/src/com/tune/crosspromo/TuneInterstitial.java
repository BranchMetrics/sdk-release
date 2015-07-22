package com.tune.crosspromo;

import java.net.SocketException;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.os.Handler;
import android.util.Log;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

/**
 * Interstitial ad class
 */
public class TuneInterstitial implements TuneAd {
    private static final String TAG = TuneAdUtils.TAG;

    private TuneAdUtils utils;
    private Context mContext;

    private TuneAdParams mAdParams;
    private Handler mHandler;
    private TuneAdListener mListener;
    private TuneAdOrientation mOrientation;
    private int mLastOrientation;

    private boolean nativeCloseButton;
    private boolean mShowOnLoad;

    /**
     * Interstitial ad constructor
     * @param context Activity context
     */
    public TuneInterstitial(Context context) {
        this(context, TuneAdOrientation.ALL);
    }
    
    /**
     * Interstitial ad constructor with forced orientation
     * @param context Activity context
     * @param forceOrientation Only get ads of this orientation
     */
    public TuneInterstitial(Context context, TuneAdOrientation forceOrientation) {
        mContext = context;

        mHandler = new Handler(mContext.getMainLooper());
        utils = TuneAdUtils.getInstance();
        utils.init(context, null, null);
        
        mOrientation = forceOrientation;
        // Get current orientation
        mLastOrientation = ((Activity)context).getWindow().getDecorView().getResources().getConfiguration().orientation;
        
        // If orientation was not specified by user, check if activity orientation was set
        if (mOrientation == TuneAdOrientation.ALL) {
            // Activity's set orientation, if any, overrides default ALL
            int forcedOrientation = ((Activity)context).getRequestedOrientation();
            if (forcedOrientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT) {
                mOrientation = TuneAdOrientation.PORTRAIT_ONLY;
            } else if (forcedOrientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
                mOrientation = TuneAdOrientation.LANDSCAPE_ONLY;
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private WebView initializeWebView(final Context context, final String placement) {
        WebView webView = new WebView(context);
        FrameLayout.LayoutParams wvLayout = new FrameLayout.LayoutParams(
                LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        wvLayout.gravity = Gravity.CENTER;
        webView.setLayoutParams(wvLayout);

        webView.setBackgroundColor(Color.TRANSPARENT);
        // Not default before API level 11
        webView.setScrollBarStyle(WebView.SCROLLBARS_INSIDE_OVERLAY);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);

        WebViewClient webViewClient = new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                ViewGroup parent = (ViewGroup) view.getParent();
                parent.removeView(view);

                processClick(url, placement);

                ((Activity) utils.getAdContext()).finish();

                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                // Notify of load if webview isn't being cleared to about:blank
                if (!url.equals("about:blank")) {
                    notifyOnLoad(placement);
                }
            }
        };
        webView.setWebViewClient(webViewClient);

        return webView;
    }

    private void loadWebView(final String placement, final String data) {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                getCurrentAd(placement).loadView(data);
            }
        });
    }

    private void loadAd(String placement, TuneAdMetadata metadata) {
        long startTime = System.currentTimeMillis();
        // If we don't have a device identifier yet, try waiting 500ms for it
        while (utils.getParams().getGoogleAdvertisingId() == null || utils.getParams().getAndroidId() == null) {
            // We've exceeded timeout, stop waiting
            if ((System.currentTimeMillis() - startTime) > 500) {
                break;
            }
            
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        mAdParams = new TuneAdParams(placement, utils.getParams(), metadata, mOrientation, mLastOrientation);
        requestAd(placement, 0);
    }

    // Recursive ad request function that will retry requests for certain failures
    private void requestAd(String placement, int retryCount) {
        if (mAdParams.debugMode) {
            Log.d(TAG, "Requesting interstitial with: " + mAdParams.toJSON().toString());
        }
        try {
            String response = TuneAdClient.requestInterstitialAd(mAdParams);
            if (response != null) {
                // If response json is empty, probably no ads available
                if (!response.equals("")) {
                    try {
                        JSONObject responseJson = new JSONObject(response);
                        if (responseJson.has("error") && responseJson.has("message")) {
                            Log.d(TAG, responseJson.optString("error") + ": " + responseJson.optString("message"));
                            if (mAdParams.debugMode) {
                                Log.d(TAG, "Debug request url: " + responseJson.optString("requestUrl"));
                            }
                            notifyOnFailed(placement, responseJson.optString("message"));
                        } else {
                            String data = responseJson.optString("html");
                            if (!data.equals("")) {
                                // Save request id and publisher params for logging impression/click later
                                TuneAdView currentAd = getCurrentAd(placement);
                                currentAd.requestId = responseJson.optString("requestId");
                                
                                mAdParams.setRefs(responseJson.optJSONObject("refs"));
                                
                                if (responseJson.has("close")) {
                                    nativeCloseButton = responseJson.optString("close").equals("native");
                                }
                                loadWebView(placement, data);
                            } else {
                                notifyOnFailed(placement, "Unknown error");
                            }
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else {
                    notifyOnFailed(placement, "Unknown error");
                }
            } else {
                notifyOnFailed(placement, "Network error");
            }
        } catch (TuneBadRequestException e) {
            // Retry up to 5 times for 400 error
            if (retryCount == 4) {
                notifyOnFailed(placement, "Bad request");
            } else {
                requestAd(placement, retryCount + 1);
            }
        } catch (TuneServerErrorException e) {
            // Retry up to 5 times for 500 error
            if (retryCount == 4) {
                notifyOnFailed(placement, "Server error");
            } else {
                requestAd(placement, retryCount + 1);
            }
        } catch (SocketException e) {
            // Retry up to 5 times for timeout
            if (retryCount == 4) {
                notifyOnFailed(placement, "Request timed out");
            } else {
                requestAd(placement, retryCount + 1);
            }
        }
    }

    @Override
    public void show(String placement, TuneAdMetadata metadata) {
        // Check for null or empty placement
        if (placement == null || placement.isEmpty() || placement.equals("null")) {
            throw new IllegalArgumentException("Placement must not be null or empty");
        }
        // Create TuneAdViewSet for this placement if doesn't exist
        if (!utils.hasViewSet(placement)) {
            initAdViewSet(placement, metadata);
        }
        
        TuneAdView currentAd = getCurrentAd(placement);
        currentAd.metadata = metadata;
        if (currentAd.loaded) {
            displayInterstitial(currentAd);
        } else if (!currentAd.loading) {
            // If not cached, cache first and use mShowOnLoad flag to show on load
            cache(placement, metadata);
            mShowOnLoad = true;
        }
    }
    
    /**
     * Display the current interstitial on the screen
     */
    @Override
    public void show(String placement) {
        show(placement, new TuneAdMetadata());
    }
    
    public void cache(final String placement, final TuneAdMetadata metadata) {
        // Check for null or empty placement
        if (placement == null || placement.isEmpty() || placement.equals("null")) {
            throw new IllegalArgumentException("Placement must not be null or empty");
        }
        // Create TuneAdViewSet for this placement if doesn't exist
        if (!utils.hasViewSet(placement)) {
            initAdViewSet(placement, metadata);
        }
        
        TuneAdView currentAd = getCurrentAd(placement);
        currentAd.metadata = metadata;
        currentAd.loaded = false;
        currentAd.loading = true;
        
        utils.getAdThread().execute(new Runnable() {
            @Override
            public void run() {
                loadAd(placement, metadata);
            }
        });
    }

    public void cache(String placement) {
        cache(placement, new TuneAdMetadata());
    }

    @Override
    public void setListener(TuneAdListener listener) {
        mListener = listener;
    }

    @Override
    public void destroy() {
        utils.destroyAdViews();
        utils = null;
        mListener = null;
        mContext = null;
        mOrientation = null;
        mHandler = null;
    }

    private void notifyOnLoad(String placement) {
        TuneAdView currentAd = getCurrentAd(placement);
        currentAd.loaded = true;
        currentAd.loading = false;
        
        // Show interstitial on load if show was called and ad was not pre-fetched
        if (mShowOnLoad) {
            mShowOnLoad = false;
            displayInterstitial(currentAd);
        }
        
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdLoad(TuneInterstitial.this);
                }
            }
        });
    }

    private void notifyOnFailed(String placement, final String error) {
        TuneAdView currentAd = getCurrentAd(placement);
        currentAd.loading = false;
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdLoadFailed(TuneInterstitial.this, error);
                }
            }
        });
    }

    private void notifyOnShow() {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdShown(TuneInterstitial.this);
                }
            }
        });
    }

    private void notifyOnClick() {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdClick(TuneInterstitial.this);
                }
            }
        });
    }

    private void initAdViewSet(String placement, TuneAdMetadata metadata) {
        TuneAdView adView1 = new TuneAdView(placement, metadata, initializeWebView(mContext, placement));
        TuneAdView adView2 = new TuneAdView(placement, metadata, initializeWebView(mContext, placement));
        
        TuneAdViewSet viewSet = new TuneAdViewSet(placement, adView1, adView2);
        utils.addViewSet(viewSet);
    }
    
    private void displayInterstitial(TuneAdView currentAd) {
        Activity activity = (Activity) mContext;
        Intent intent = new Intent(mContext, TuneAdActivity.class);
        intent.putExtra("INTERSTITIAL", true);
        intent.putExtra("REQUESTID", currentAd.requestId);
        intent.putExtra("ADPARAMS", mAdParams.toJSON().toString());
        intent.putExtra("NATIVECLOSEBUTTON", nativeCloseButton);
        intent.putExtra("PLACEMENT", currentAd.placement);
        intent.putExtra("ORIENTATION", mOrientation.value());
        activity.startActivity(intent);
        activity.overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        
        // Log a view upon showing
        TuneAdClient.logView(currentAd, mAdParams.toJSON());
        
        utils.changeView(currentAd.placement);
        
        notifyOnShow();
        
        cache(currentAd.placement, currentAd.metadata);
    }

    private void processClick(String url, String placement) {
        // Current ad becomes previously-loaded ad by the time click occurs
        TuneAdView previousAd = utils.getPreviousView(placement);
        if (url.contains("#close")) {
            // Don't open redirect if url went to #close
            // Log a close upon clicking
            TuneAdClient.logClose(previousAd, mAdParams.toJSON());
            return;
        }

        Intent intent = new Intent(mContext, TuneAdActivity.class);
        intent.putExtra("INTERSTITIAL", false);
        intent.putExtra("REDIRECT_URI", url);

        Activity activity = (Activity) mContext;
        activity.startActivity(intent);

        notifyOnClick();
        // Log a click upon ad click
        TuneAdClient.logClick(previousAd, mAdParams.toJSON());
    }

    private TuneAdView getCurrentAd(String placement) {
        return utils.getCurrentView(placement);
    }
    
    public TuneAdParams getParams() {
        return mAdParams;
    }
}
