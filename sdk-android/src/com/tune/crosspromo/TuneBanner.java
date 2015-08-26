package com.tune.crosspromo;

import java.io.UnsupportedEncodingException;
import java.net.ConnectException;
import java.net.URLEncoder;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.os.Handler;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.ViewSwitcher;

/**
 * TUNE Banner ad class
 */
public class TuneBanner extends FrameLayout implements TuneAd {
    private static final String TAG = TuneAdUtils.TAG;
    private static final int DEFAULT_REFRESH_DURATION_SEC = 60;

    private TuneAdParams mAdParams;

    private WebViewClient webViewClient;

    private String mPlacement;
    private int mDuration;
    private int mLastOrientation;
    private Context mContext;
    private Handler mHandler;
    private TuneBannerPosition mPosition;
    private TuneAdView mAdView;
    private WebView mWebView1;
    private WebView mWebView2;
    private ViewSwitcher mViewSwitcher;

    private TuneAdUtils utils;
    private TuneAdListener mListener;
    private TuneAdOrientation mOrientation;
    private TuneAdMetadata mMetadata;
    private ScheduledThreadPoolExecutor mScheduler;
    private ScheduledFuture<?> loadFuture;
    
    /**
     * Banner ad constructor for layout inflation
     * 
     * @param context
     *            Activity context
     * @param attrs
     *            XML attributes
     */
    public TuneBanner(Context context, AttributeSet attrs) {
        super(context, attrs);
        
        String advertiserId = attrs.getAttributeValue(null, "advertiserId");
        String conversionKey = attrs.getAttributeValue(null, "conversionKey");
        
        if (advertiserId != null && conversionKey != null) {
            init(context, advertiserId, conversionKey);
        } else {
            Log.e(TAG, "TuneBanner XML requires advertiserId and conversionKey");
        }
    }

    /**
     * Banner ad constructor
     * 
     * @param context
     *            Activity context
     */
    public TuneBanner(Context context) {
        super(context);
        init(context, null, null);
    }
    
    private void init(Context context, String advertiserId, String conversionKey) {
        mContext = context;
        mHandler = new Handler(context.getMainLooper());
        
        mLastOrientation = getResources().getConfiguration().orientation;
        mOrientation = TuneAdOrientation.ALL;
        
        // Activity's set orientation, if any, overrides the last detected
        int forcedOrientation = ((Activity)context).getRequestedOrientation();
        if (forcedOrientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT) {
            mOrientation = TuneAdOrientation.PORTRAIT_ONLY;
        } else if (forcedOrientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
            mOrientation = TuneAdOrientation.LANDSCAPE_ONLY;
        }
        
        utils = TuneAdUtils.getInstance();
        utils.init(context, advertiserId, conversionKey);

        mDuration = DEFAULT_REFRESH_DURATION_SEC;
        mPosition = TuneBannerPosition.BOTTOM_CENTER;
        mScheduler = new ScheduledThreadPoolExecutor(1);
        
        webViewClient = new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                processClick(url);
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                notifyOnLoad();

                if (mViewSwitcher != null) {
                    mViewSwitcher.setVisibility(View.VISIBLE);
                    if (mViewSwitcher.getCurrentView() == mWebView1) {
                        // onPageFinished doesn't guarantee that WebView is showing new
                        // content, so add a slight delay to ensure we're not showing previously loaded ad
                        mHandler.postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                if (mViewSwitcher != null) {
                                    mViewSwitcher.showNext();
                                }
                            }
                        }, 50);
                    } else {
                        mHandler.postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                if (mViewSwitcher != null) {
                                    mViewSwitcher.showPrevious();
                                }
                            }
                        }, 50);
                    }
                    // Log a view upon showing
                    TuneAdClient.logView(mAdView, mAdParams.toJSON());

                    positionAd();

                    notifyOnShow();
                }
            }
        };
        
        buildViewSwitcher();
        bringToFront();
    }

    private void buildViewSwitcher() {
        mWebView1 = buildWebView(mContext);
        mWebView2 = buildWebView(mContext);

        mViewSwitcher = new ViewSwitcher(mContext);
        mViewSwitcher.setVisibility(View.GONE);

        ViewSwitcher.LayoutParams webViewParams = new ViewSwitcher.LayoutParams(
                ViewSwitcher.LayoutParams.MATCH_PARENT,
                ViewSwitcher.LayoutParams.MATCH_PARENT);

        mViewSwitcher.addView(mWebView1, webViewParams);
        mViewSwitcher.addView(mWebView2, webViewParams);

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        addView(mViewSwitcher, params);
    }

    @SuppressLint("SetJavaScriptEnabled")
    private WebView buildWebView(Context context) {
        WebView view = new WebView(context);
        view.setWebViewClient(webViewClient);
        view.setBackgroundColor(Color.TRANSPARENT);
        // Not default before API level 11
        view.setScrollBarStyle(WebView.SCROLLBARS_INSIDE_OVERLAY);
        view.setVerticalScrollBarEnabled(false);
        view.setHorizontalScrollBarEnabled(false);
        WebSettings settings = view.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);

        return view;
    }

    /**
     * This method sets the Banner ad container size and position, making it
     * visible.
     */
    private void positionAd() {
        ViewGroup.LayoutParams params = (ViewGroup.LayoutParams) getLayoutParams();
        if (params != null) {
            params.width = TuneBannerSize.getScreenWidthPixels(mContext);
            params.height = TuneBannerSize.getBannerHeightPixels(mContext, getResources().getConfiguration().orientation);
        }

        // Set the position based on mPosition
        // Only for FrameLayout and RelativeLayout
        if (params instanceof FrameLayout.LayoutParams) {
            FrameLayout.LayoutParams newFrameParams = new FrameLayout.LayoutParams(
                    params.width, params.height);
            switch (mPosition) {
                case TOP_CENTER:
                    newFrameParams.gravity = Gravity.CENTER_HORIZONTAL
                            | Gravity.TOP;
                    break;
                case BOTTOM_CENTER:
                default:
                    newFrameParams.gravity = Gravity.CENTER_HORIZONTAL
                            | Gravity.BOTTOM;
                    break;
            }
            params = newFrameParams;
        } else if (params instanceof RelativeLayout.LayoutParams) {
            RelativeLayout.LayoutParams newRelativeParams = new RelativeLayout.LayoutParams(
                    params.width, params.height);
            switch (mPosition) {
                case TOP_CENTER:
                    newRelativeParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
                    newRelativeParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
                    break;
                case BOTTOM_CENTER:
                default:
                    newRelativeParams
                            .addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
                    newRelativeParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
                    break;
            }
            params = newRelativeParams;
        }

        setLayoutParams(params);
    }

    /**
     * Gets the banner position as TuneBannerPosition object
     * 
     * @return The TuneBannerPosition of the banner, TOP_CENTER or BOTTOM_CENTER
     */
    public TuneBannerPosition getPosition() {
        return mPosition;
    }

    /**
     * Sets up a Banner according to TuneBannerPosition. Only works if parent ViewGroup
     * is either RelativeLayout or FrameLayout.
     * 
     * @param position
     *            The TuneBannerPosition of the banner, TOP_CENTER or
     *            BOTTOM_CENTER
     */
    public void setPosition(TuneBannerPosition position) {
        mPosition = position;
    }

    private class RefreshTask implements Runnable {
        @Override
        public void run() {
            loadAd();
        }
    }

    /**
     * Start banner ad refresh.
     */
    public void resume() {
        if (loadFuture != null && loadFuture.isCancelled()) {
            if (mDuration > 0) {
                loadFuture = mScheduler.scheduleAtFixedRate(new RefreshTask(), 0, mDuration, TimeUnit.SECONDS);
            }
        }
    }

    /**
     * Stop banner ad refresh.
     */
    public void pause() {
        if (loadFuture != null) {
            loadFuture.cancel(true);
        }
    }

    /**
     * Restart the banner load with new duration interval
     */
    private void restartWithDuration(int duration) {
        if (loadFuture != null) {
            loadFuture.cancel(false);
        }
        if (duration > 0) {
            loadFuture = mScheduler.scheduleAtFixedRate(new RefreshTask(), duration, duration, TimeUnit.SECONDS);
        }
    }

    private void notifyOnLoad() {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdLoad(TuneBanner.this);
                }
            }
        });
    }

    private void notifyOnFailed(final String error) {
        if (mAdParams.debugMode) {
            Log.d(TAG, "Request failed with error: " + error);
        }
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdLoadFailed(TuneBanner.this, error);
                }
            }
        });
    }

    private void notifyOnShow() {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdShown(TuneBanner.this);
                }
            }
        });
    }

    private void notifyOnClick() {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                if (mListener != null) {
                    mListener.onAdClick(TuneBanner.this);
                }
            }
        });
    }

    @Override
    public void setListener(TuneAdListener listener) {
        mListener = listener;
    }

    @Override
    public void show(String placement, TuneAdMetadata metadata) {
        // Check for null or empty placement
        if (placement == null || placement.isEmpty() || placement.equals("null")) {
            throw new IllegalArgumentException("Placement must not be null or empty");
        }
        if (mAdView == null) {
            mAdView = new TuneAdView(placement, metadata, (WebView) mViewSwitcher.getCurrentView());
        }
        // TODO: check if enough space for banner
        mPlacement = placement;
        mMetadata = metadata;
        if (loadFuture != null) {
            loadFuture.cancel(true);
        }
        if (mDuration > 0) {
            loadFuture = mScheduler.scheduleAtFixedRate(new RefreshTask(), 0, mDuration, TimeUnit.SECONDS);
        }
    }

    @Override
    public void show(String placement) {
        if (mMetadata == null) {
            mMetadata = new TuneAdMetadata();
        }
        show(placement, mMetadata);
    }

    private void loadAd() {
        long startTime = System.currentTimeMillis();
        // If we don't have a device identifier yet, try waiting up to 500ms for it
        while (utils.getParams().getGoogleAdvertisingId() == null && utils.getParams().getAndroidId() == null) {
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

        mAdParams = new TuneAdParams(mPlacement, utils.getParams(), mMetadata, mOrientation, mLastOrientation);
        // Set the banner ad portrait and landscape dimensions separately
        int orientation = getResources().getConfiguration().orientation;
        mAdParams.adWidthPortrait = TuneBannerSize.getScreenWidthPixelsPortrait(mContext, orientation);
        mAdParams.adHeightPortrait = TuneBannerSize.getBannerHeightPixelsPortrait(mContext, orientation);
        mAdParams.adWidthLandscape = TuneBannerSize.getScreenWidthPixelsLandscape(mContext, orientation);
        mAdParams.adHeightLandscape = TuneBannerSize.getBannerHeightPixelsLandscape(mContext, orientation);

        if (mAdParams.debugMode) {
            Log.d(TAG, "Requesting banner with: " + mAdParams.toJSON().toString());
        }
        try {
            String response = TuneAdClient.requestBannerAd(mAdParams);
            if (response != null) {
                // If response json is empty, no ads available
                if (!response.equals("")) {
                    try {
                        JSONObject responseJson = new JSONObject(response);
                        if (responseJson.has("error") && responseJson.has("message")) {
                            Log.d(TAG, responseJson.optString("error") + ": " + responseJson.optString("message"));
                            if (mAdParams.debugMode) {
                                Log.d(TAG, "Debug request url: " + responseJson.optString("requestUrl"));
                            }
                            notifyOnFailed(responseJson.optString("message"));
                        } else {
                            final String data = responseJson.optString("html");
                            if (!data.equals("")) {
                                int duration = Integer.parseInt(responseJson.getString("duration"));
                                // If response duration differs from current duration,
                                // stop scheduler and restart with new duration
                                if (duration != mDuration) {
                                    mDuration = duration;
                                    restartWithDuration(duration);
                                }

                                // Save request id and publisher params for
                                // logging impression/click later
                                mAdView.requestId = responseJson.optString("requestId");
                                mAdParams.setRefs(responseJson.optJSONObject("refs"));

                                loadWebView(data);
                            } else {
                                notifyOnFailed("Unknown error");
                            }
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else {
                    notifyOnFailed("Unknown error");
                }
            } else {
                notifyOnFailed("Network error");
            }
        } catch (TuneBadRequestException e) {
            notifyOnFailed("Bad request");
        } catch (TuneServerErrorException e) {
            notifyOnFailed("Server error");
        } catch (ConnectException e) {
            notifyOnFailed("Request timed out");
        }
    }

    private void loadWebView(final String data) {
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                WebView webView;
                if (mViewSwitcher != null) {
                    if (mViewSwitcher.getCurrentView() == mWebView1) {
                        webView = mWebView2;
                    } else {
                        webView = mWebView1;
                    }
                    try {
                        webView.loadData(URLEncoder.encode(data, "utf-8")
                                .replaceAll("\\+", " "), "text/html", "utf-8");
                    } catch (UnsupportedEncodingException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

    private void processClick(final String url) {
        Intent intent = new Intent(getContext(), TuneAdActivity.class);
        intent.putExtra("INTERSTITIAL", false);
        intent.putExtra("REDIRECT_URI", url);

        Activity activity = (Activity) getContext();
        activity.startActivity(intent);

        notifyOnClick();
        // Log a click upon ad click
        TuneAdClient.logClick(mAdView, mAdParams.toJSON());
    }
    
    public TuneAdView getCurrentAd() {
        return mAdView;
    }
    
    public TuneAdParams getParams() {
        return mAdParams;
    }
    
    @Override
    public void destroy() {
        pause();
        mScheduler.shutdown();
        setListener(null);
        if (mViewSwitcher != null) {
            mViewSwitcher.removeAllViews();
            removeView(mViewSwitcher);
        }
        mViewSwitcher = null;
        if (mWebView1 != null) {
            mWebView1.destroy();
        }
        if (mWebView2 != null) {
            mWebView2.destroy();
        }
        mWebView1 = null;
        mWebView2 = null;
        utils.destroyAdViews();
        utils = null;
        mOrientation = null;
        mMetadata = null;
    }
    
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        
        int orientation = getResources().getConfiguration().orientation;
        // Only resize banner on actual orientation change
        if (orientation != mLastOrientation) {
            mLastOrientation = orientation;
            int widthPx = TuneBannerSize.getScreenWidthPixels(mContext);
            int heightPx = TuneBannerSize.getBannerHeightPixels(mContext, orientation);
            
            int newWidthMeasureSpec = MeasureSpec.makeMeasureSpec(widthPx, MeasureSpec.EXACTLY);
            int newHeightMeasureSpec = MeasureSpec.makeMeasureSpec(heightPx, MeasureSpec.EXACTLY);
            super.onMeasure(newWidthMeasureSpec, newHeightMeasureSpec);
            measureChildren(newWidthMeasureSpec, newHeightMeasureSpec);
        }
    }
}