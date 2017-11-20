package com.tune.ma.inapp.model.fullscreen;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ProgressBar;

import com.tune.Tune;
import com.tune.ma.TuneManager;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.inapp.model.TuneCloseButton;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.utils.TuneDebugLog;

import org.json.JSONObject;

import java.net.URLEncoder;

/**
 * Created by johng on 2/21/17.
 */

/**
 * TuneFullScreen is a TuneInAppMessage subclass that handles displaying full screen messages
 */
public class TuneFullScreen extends TuneInAppMessage {
    public static final String ORIENTATION = "ORIENTATION";
    public static final String MESSAGE_ID = "MESSAGE_ID";
    public static final String LOADING_SCREEN_LAYOUT = "LOADING_SCREEN_LAYOUT";

    private WebView webView;
    private ProgressBar progressBar;
    private View loadingScreen;
    private TuneCloseButton closeButton;
    private boolean useCustomLoadingScreen;

    public TuneFullScreen(JSONObject messageJson) {
        super(messageJson);
        setType(Type.FULLSCREEN);
    }

    protected TuneCloseButton getCloseButton() {
        return closeButton;
    }

    protected ProgressBar getProgressBar() {
        return progressBar;
    }

    protected boolean isUsingCustomLoadingScreen() {
        return useCustomLoadingScreen;
    }

    protected View getLoadingScreen() {
        return loadingScreen;
    }

    protected WebView getWebView() {
        return webView;
    }

    @Override
    public synchronized void load(Activity activity) {
        if (!Tune.getInstance().isOnline(activity)) {
            TuneDebugLog.e("Device is offline, cannot load fullscreen message");
            return;
        }

        // Loading our templates on API 19 is broken, so don't allow it
        if (Build.VERSION.SDK_INT == Build.VERSION_CODES.KITKAT) {
            return;
        }

        webView = setupWebView(activity);

        try {
            webView.loadData(URLEncoder.encode(getHtml(), "utf-8").replaceAll("\\+", " "), "text/html", "utf-8");
        } catch (Exception e) {
            e.printStackTrace();
        }

        setPreloaded(true);
    }

    @Override
    public synchronized void display() {
        // Start TuneFullScreenActivity, passing in relevant info into the Intent
        Activity lastActivity = TuneActivity.getLastActivity();
        if (lastActivity == null) {
            TuneDebugLog.e("Last Activity is null, cannot display full screen message");
            return;
        }

        if (!Tune.getInstance().isOnline(lastActivity)) {
            TuneDebugLog.e("Device is offline, cannot display full screen message");
            return;
        }

        if (!isPreloaded()) {
            int customLoadingScreenLayoutId = TuneManager.getInstance().getInAppMessageManager().getFullScreenLoadingScreen();
            useCustomLoadingScreen = customLoadingScreenLayoutId != 0;
            if (useCustomLoadingScreen) {
                loadingScreen = lastActivity.getLayoutInflater().inflate(customLoadingScreenLayoutId, null);
            }
            progressBar = new ProgressBar(lastActivity);

            // Add close button to loading screen
            closeButton = new TuneCloseButton(lastActivity);

            webView = setupWebView(lastActivity);
        }

        Intent intent = new Intent(lastActivity, TuneFullScreenActivity.class);
        intent.putExtra(ORIENTATION, lastActivity.getRequestedOrientation());
        intent.putExtra(MESSAGE_ID, getId());

        int customLoadingScreenLayoutId = TuneManager.getInstance().getInAppMessageManager().getFullScreenLoadingScreen();
        if (customLoadingScreenLayoutId != 0) {
            intent.putExtra(LOADING_SCREEN_LAYOUT, customLoadingScreenLayoutId);
        }
        lastActivity.startActivity(intent);
        animateOpen(lastActivity);

        setVisible(true);
    }

    @Override
    public synchronized void dismiss() {
        Activity lastActivity = TuneActivity.getLastActivity();
        animateClose(lastActivity);
        setVisible(false);
    }

    /**
     * Play message open animation based on message transition
     * @param activity
     */
    private synchronized void animateOpen(Activity activity) {
        // Use an animation when starting Activity based on transition type
        switch (getTransition()) {
            case FADE_IN:
                activity.overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
                break;
            case BOTTOM:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_bottom, com.tune.R.anim.slide_out_top);
                break;
            case TOP:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_top, com.tune.R.anim.slide_out_bottom);
                break;
            case LEFT:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_left, com.tune.R.anim.slide_out_right);
                break;
            case RIGHT:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_right, com.tune.R.anim.slide_out_left);
                break;
            case NONE:
            default:
                break;
        }
    }

    /**
     * Play message close animation based on message transition
     * @param activity
     */
    private synchronized void animateClose(Activity activity) {
        if (activity == null) {
            return;
        }

        // On close, reset preloaded status
        setPreloaded(false);

        activity.finish();

        // For close animation, use the opposite animations for the original view coming back in
        switch (getTransition()) {
            case FADE_IN:
                activity.overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
                break;
            case BOTTOM:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_top, com.tune.R.anim.slide_out_bottom);
                break;
            case TOP:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_bottom, com.tune.R.anim.slide_out_top);
                break;
            case LEFT:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_right, com.tune.R.anim.slide_out_left);
                break;
            case RIGHT:
                activity.overridePendingTransition(com.tune.R.anim.slide_in_left, com.tune.R.anim.slide_out_right);
                break;
            case NONE:
            default:
                break;
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private WebView setupWebView(Activity activity) {
        WebView webView = new WebView(activity);

        FrameLayout.LayoutParams wvLayout = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        wvLayout.gravity = Gravity.CENTER;
        webView.setLayoutParams(wvLayout);

        // Hide WebView until it's finished loading
        webView.setVisibility(View.INVISIBLE);
        webView.setBackgroundColor(Color.TRANSPARENT);
        // Turn off hardware acceleration when possible, it causes WebView loading issues
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
            } else {
                webView.setLayerType(View.LAYER_TYPE_SOFTWARE, null);
            }
        }
        // Not default before API level 11
        webView.setScrollBarStyle(WebView.SCROLLBARS_INSIDE_OVERLAY);
        WebSettings webSettings = webView.getSettings();

        /**
         * setJavaScriptEnabled(true) allows JavaScript to be run in the WebView. (This is necessary for IMv2.)
         *
         * While this technically can allow cross-site scripting and would be a vulnerability risk in the wild,
         * this WebView will only be used by TUNE's customers for HTML/JS they serve to their app via TUNE's dashboard.
         * It is a relatively low-risk usage in practice as it's customer-controlled content and part of a private method, so suppressing warn.
         */

        webSettings.setJavaScriptEnabled(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setSupportZoom(false);

        WebViewClient webViewClient = new WebViewClient() {
            @SuppressWarnings("deprecation")
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                // Process click's url
                processAction(url);

                // Finish Activity
                dismiss();
                return true;
            }

            @TargetApi(Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                // Process click's url
                processAction(request.getUrl().toString());

                // Finish Activity
                dismiss();
                return true;
            }

            @Override
            public void onPageFinished(final WebView view, String url) {
                if (url.equals("about:blank")) {
                    return;
                }

                // If message was JIT loaded, remove any loading screens and log an impression
                if (!isPreloaded()) {
                    // Remove loading screen and close button when page has finished loading
                    if (isUsingCustomLoadingScreen()) {
                        getLoadingScreen().setVisibility(View.GONE);
                    } else {
                        getProgressBar().setVisibility(View.GONE);
                    }
                    getCloseButton().setVisibility(View.GONE);

                    // Make WebView visible
                    view.setVisibility(View.VISIBLE);

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1) {
                        view.animate().alpha(1.0f);
                    }

                    // Handle impression event tracking
                    processImpression();
                }
            }
        };
        webView.setWebViewClient(webViewClient);
        webView.setWebChromeClient(new WebChromeClient() {
        });

        return webView;
    }
}
