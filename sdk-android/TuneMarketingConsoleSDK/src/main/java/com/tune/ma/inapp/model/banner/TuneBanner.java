package com.tune.ma.inapp.model.banner;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Build;
import android.os.Handler;
import android.support.annotation.RequiresApi;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import com.tune.Tune;
import com.tune.TuneUtils;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.inapp.TuneScreenUtils;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.net.URLEncoder;

import static com.tune.ma.inapp.TuneInAppMessageConstants.DURATION_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.INDEFINITE_DURATION_VALUE;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LOCATION_TOP;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_LOCATION_KEY;

/**
 * Created by johng on 3/6/17.
 */

public class TuneBanner extends TuneInAppMessage {
    public enum Location {
        TOP,
        BOTTOM
    }

    private TuneBannerLayout bannerLayout;
    private Location location;
    private int duration;
    private long startTime;

    private Handler handler;
    private DismissRunnable dismissRunnable;

    /**
     * Runnable to dismiss the banner after duration has passed
     * Gets cancelled if the banner is clicked or reloaded
     */
    public class DismissRunnable implements Runnable {
        @Override
        public void run() {
            processDismissAfterDuration();
            animateClose(TuneActivity.getLastActivity());
        }
    }

    public TuneBanner(JSONObject messageJson) {
        super(messageJson);
        setType(Type.BANNER);

        // Parse banner location from JSON
        location = Location.BOTTOM;
        JSONObject message = TuneJsonUtils.getJSONObject(messageJson, MESSAGE_KEY);
        String messageLocation = TuneJsonUtils.getString(message, MESSAGE_LOCATION_KEY);
        if (messageLocation != null) {
            if (messageLocation.equals(LOCATION_TOP)) {
                location = Location.TOP;
            }
        }

        duration = TuneJsonUtils.getInt(message, DURATION_KEY);

        dismissRunnable = new DismissRunnable();
    }

    public TuneBannerLayout getLayout() {
        return bannerLayout;
    }

    public Location getLocation() {
        return location;
    }

    public void setLocation(Location location) {
        this.location = location;
    }

    public int getDuration() {
        return duration;
    }

    public void setDuration(int duration) {
        this.duration = duration;
    }

    @Override
    public synchronized void load(Activity activity) {
        if (!Tune.getInstance().isOnline(activity)) {
            TuneDebugLog.e("Device is offline, cannot load banner message");
            return;
        }

        // Create new banner layout if it's null or not attached to current Activity
        if (bannerLayout == null || bannerLayout.getActivity() != activity) {
            bannerLayout = setupBannerLayout(activity);
        }

        // Load HTML in WebView
        try {
            bannerLayout.getWebView().loadData(URLEncoder.encode(getHtml(), "utf-8").replaceAll("\\+", " "), "text/html", "utf-8");
        } catch (Exception e) {
            e.printStackTrace();
        }

        setPreloaded(true);
    }

    @Override
    public synchronized void display() {
        Activity lastActivity = TuneActivity.getLastActivity();
        if (lastActivity == null) {
            TuneDebugLog.e("Last Activity is null, cannot display banner message");
            return;
        }

        if (!Tune.getInstance().isOnline(lastActivity)) {
            TuneDebugLog.e("Device is offline, cannot display banner message");
            return;
        }

        // Create new banner layout if it's null or not attached to current Activity
        if (bannerLayout == null || bannerLayout.getActivity() != lastActivity) {
            bannerLayout = setupBannerLayout(lastActivity);
        }

        // Only add banner to parent layout if it hasn't already been added
        if (bannerLayout.getParent() == null) {
            // Add the banner to the last Activity's parent layout
            FrameLayout parent = (FrameLayout) lastActivity.getWindow().getDecorView().findViewById(android.R.id.content);
            parent.addView(bannerLayout);
        }

        // If message was preloaded, process open upon display - normally we wait for WebView to finish loading
        if (isPreloaded()) {
            processOpen(lastActivity);
        } else {
            // TODO: should we always refresh WebView if display is called when a banner is visible? This will re-trigger animations
            // Load HTML in WebView
            try {
                bannerLayout.getWebView().loadData(URLEncoder.encode(getHtml(), "utf-8").replaceAll("\\+", " "), "text/html", "utf-8");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        setVisible(true);
    }

    @Override
    public synchronized void dismiss() {
        Activity lastActivity = TuneActivity.getLastActivity();
        animateClose(lastActivity);
        setVisible(false);
    }

    /**
     * Helper method for performing operations that need to happen on message open
     */
    private void processOpen(Activity activity) {
        positionAd();
        animateOpen(activity);
        startDurationTimeout();
        processImpression();
    }

    private TuneBannerLayout setupBannerLayout(Activity activity) {
        WebView webView = setupWebView(activity);
        // Create banner FrameLayout
        return new TuneBannerLayout(activity, webView, this);
    }

    @SuppressLint("SetJavaScriptEnabled")
    private WebView setupWebView(Activity activity) {
        // Set up WebView
        final WebView webView = new WebView(activity);
        FrameLayout.LayoutParams wvLayout = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        wvLayout.gravity = Gravity.CENTER;
        webView.setLayoutParams(wvLayout);

        webView.setBackgroundColor(Color.TRANSPARENT);
        // Turn off hardware acceleration when possible, it causes WebView loading issues
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
            } else {
                webView.setLayerType(View.LAYER_TYPE_SOFTWARE, null);
            }
        }
        webView.setVisibility(View.GONE);
        // Not default before API level 11
        webView.setScrollBarStyle(WebView.SCROLLBARS_INSIDE_OVERLAY);
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        WebSettings settings = webView.getSettings();

        /**
         * setJavaScriptEnabled(true) allows JavaScript to be run in the WebView. (This is necessary for IMv2.)
         *
         * While this technically can allow cross-site scripting and would be a vulnerability risk in the wild,
         * this WebView will only be used by TUNE's customers for HTML/JS they serve to their app via TUNE's dashboard.
         * It is a relatively low-risk usage in practice as it's customer-controlled content and part of a private method, so suppressing warn.
         */

        settings.setJavaScriptEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setSupportZoom(false);

        WebViewClient webViewClient = new WebViewClient() {
            @SuppressWarnings("deprecation")
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                animateClose(TuneActivity.getLastActivity());

                // Cancel the duration timeout operations
                stopDurationTimeout();

                // Process click's url
                processAction(url);
                return true;
            }

            @RequiresApi(Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                animateClose(TuneActivity.getLastActivity());

                // Cancel the duration timeout operations
                stopDurationTimeout();

                // Process click's url
                processAction(request.getUrl().toString());
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                // Make WebView visible
                webView.setVisibility(View.VISIBLE);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1) {
                    webView.animate().alpha(1.0f);
                }

                if (!isPreloaded()) {
                    processOpen(TuneActivity.getLastActivity());
                }
            }
        };
        webView.setWebViewClient(webViewClient);
        webView.setWebChromeClient(new WebChromeClient() {
        });

        return webView;
    }

    /**
     * Removes the banner from UI after duration in milliseconds has elapsed
     */
    private synchronized void startDurationTimeout() {
        // If duration == 0, it should be shown indefinitely and not removed
        if (duration == INDEFINITE_DURATION_VALUE) {
            return;
        }
        // Calculate time elapsed to make sure duration time has fully passed
        startTime = System.currentTimeMillis();

        // Cancel any pending DismissRunnables
        if (handler != null) {
            handler.removeCallbacks(dismissRunnable);
        }
        handler = new Handler();
        handler.postDelayed(dismissRunnable, duration * 1000);
    }

    private synchronized void stopDurationTimeout() {
        // If duration == 0, it should be shown indefinitely so no timeout needs to be cancelled
        if (duration == INDEFINITE_DURATION_VALUE) {
            return;
        }

        // Cancel the DismissRunnable from running so that it doesn't send a dismissed after duration event
        if (handler != null) {
            handler.removeCallbacks(dismissRunnable);
        }
    }

    /*********************
     * Animation Methods *
     *********************/

    /**
     * Play message open animation based on message transition
     * @param activity
     */
    private synchronized void animateOpen(Activity activity) {
        if (activity == null) {
            return;
        }

        int animationId = 0;
        switch (getTransition()) {
            case FADE_IN:
                animationId = android.R.anim.fade_in;
                break;
            case BOTTOM:
                animationId = com.tune.R.anim.slide_in_bottom;
                break;
            case TOP:
                animationId = com.tune.R.anim.slide_in_top;
                break;
            case LEFT:
                animationId = com.tune.R.anim.slide_in_left;
                break;
            case RIGHT:
                animationId = com.tune.R.anim.slide_in_right;
                break;
            case NONE:
            default:
                return;
        }

        if (animationId != 0) {
            Animation animation = AnimationUtils.loadAnimation(activity, animationId);
            animation.setStartOffset(0);
            bannerLayout.startAnimation(animation);
        }
    }

    /**
     * Play message close animation based on transition
     * Then, remove TuneBannerLayout from parent layout
     * @param activity
     */
    private synchronized void animateClose(final Activity activity) {
        if (activity == null) {
            return;
        }

        // On close, reset preloaded status
        setPreloaded(false);
        setVisible(false);

        int animationId = 0;
        switch (getTransition()) {
            case FADE_IN:
                animationId = android.R.anim.fade_out;
                break;
            case BOTTOM:
                animationId = com.tune.R.anim.slide_out_bottom;
                break;
            case TOP:
                animationId = com.tune.R.anim.slide_out_top;
                break;
            case LEFT:
                animationId = com.tune.R.anim.slide_out_left;
                break;
            case RIGHT:
                animationId = com.tune.R.anim.slide_out_right;
                break;
            case NONE:
            default:
                FrameLayout parent = (FrameLayout) activity.getWindow().getDecorView().findViewById(android.R.id.content);
                parent.removeView(bannerLayout);
                return;
        }

        if (animationId != 0) {
            Animation animation = AnimationUtils.loadAnimation(activity, animationId);
            animation.setStartOffset(0);
            animation.setAnimationListener(new Animation.AnimationListener() {
                @Override
                public void onAnimationStart(Animation animation) {
                }

                @Override
                public void onAnimationEnd(Animation animation) {
                    Handler h = new Handler();
                    h.postAtTime(new Runnable() {
                        @Override
                        public void run() {
                            bannerLayout.getWebView().setVisibility(View.GONE);

                            if (bannerLayout.getParent() instanceof ViewGroup) {
                                ((ViewGroup) bannerLayout.getParent()).removeView(bannerLayout);
                            }
                        }
                    }, 100);
                }

                @Override
                public void onAnimationRepeat(Animation animation) {
                }
            });
            bannerLayout.startAnimation(animation);
        }
    }

    /******************************
     * Banner Positioning Methods *
     ******************************/

    /**
     * This method sets the banner container size and position, making it visible.
     */
    private synchronized void positionAd() {
        ViewGroup.LayoutParams params = bannerLayout.getLayoutParams();
        if (params != null) {
            Activity lastActivity = TuneActivity.getLastActivity();
            if (lastActivity != null) {
                int orientation = lastActivity.getResources().getConfiguration().orientation;
                params.width = TuneScreenUtils.getScreenWidthPixels(lastActivity);
                // For landscape orientation, account for soft key bar
                if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                    params.width -= getSoftButtonsBarHeight(lastActivity, orientation);
                }
                params.height = getBannerHeightPixels(lastActivity);
            }
        }

        // Set the position based on message location
        FrameLayout.LayoutParams newFrameParams = new FrameLayout.LayoutParams(params.width, params.height);

        switch (location) {
            case TOP:
                newFrameParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.TOP;
                break;
            case BOTTOM:
            default:
                newFrameParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM;
                break;
        }
        params = newFrameParams;

        bannerLayout.setLayoutParams(params);
        bannerLayout.bringToFront();
    }

    /**
     * Gets the height of the soft buttons bar (Nexus, Pixel, etc)
     * @param activity Activity
     * @param orientation orientation of the Activity
     * @return height of the soft buttons bar
     */
    private int getSoftButtonsBarHeight(Activity activity, int orientation) {
        // getRealMetrics is only available with API 17 and +
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            int usableHeight;
            int realHeight;
            DisplayMetrics metrics = new DisplayMetrics();
            if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                activity.getWindowManager().getDefaultDisplay().getMetrics(metrics);
                usableHeight = metrics.widthPixels;
                activity.getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
                realHeight = metrics.widthPixels;
            } else {
                activity.getWindowManager().getDefaultDisplay().getMetrics(metrics);
                usableHeight = metrics.heightPixels;
                activity.getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
                realHeight = metrics.heightPixels;
            }

            if (realHeight > usableHeight) {
                return realHeight - usableHeight;
            }
            return 0;
        }
        return 0;
    }

    /**
     * Gets banner height in pixels
     * @param activity Activity
     * @return height that banner should be, in pixels
     */
    public static int getBannerHeightPixels(Activity activity) {
        // Banner height is determined by screen size
        return getBannerHeight(activity, TuneScreenUtils.getScreenHeightPixels(activity));
    }

    private static int getBannerHeight(Activity activity, int screenHeightPixels) {
        // AdMob specs x density is the rule for landscape: https://developers.google.com/admob/android/banner
        int screenHeightWithDensity = (int) (screenHeightPixels / TuneScreenUtils.getScreenDensity(activity));
        if (screenHeightWithDensity <= 400) {
            return TuneUtils.dpToPx(activity, 32);
        }
        if (screenHeightWithDensity <= 720) {
            return TuneUtils.dpToPx(activity, 50);
        }
        return TuneUtils.dpToPx(activity, 90);
    }
}
