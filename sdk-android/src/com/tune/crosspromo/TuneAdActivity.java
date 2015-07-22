package com.tune.crosspromo;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.ActionBar;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebView;
import android.widget.FrameLayout;

/**
 * Activity to handle ad clicks and showing interstitials
 */
public class TuneAdActivity extends Activity {
    public TuneAdView adView;
    protected JSONObject adParams;
    protected TuneAdUtils utils;
    protected TuneCloseButton closeButton;
    protected WebView webView;

    // If we need to show a native close button or not
    private boolean nativeCloseButton;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        utils = TuneAdUtils.getInstance();
        boolean showInterstitial = getIntent().getBooleanExtra("INTERSTITIAL",
                false);

        if (showInterstitial) {
            // Set orientation based on user's force orientation setting
            TuneAdOrientation orientation = TuneAdOrientation
                    .forValue(getIntent().getStringExtra("ORIENTATION"));
            if (orientation == TuneAdOrientation.PORTRAIT_ONLY) {
                setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            } else if (orientation == TuneAdOrientation.LANDSCAPE_ONLY) {
                setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
            }

            String placement = getIntent().getStringExtra("PLACEMENT");
            // Get WebView with loaded interstitial for given placement
            adView = utils.getPreviousView(placement);
            webView = adView.webView;
            utils.setAdContext(this);

            // Get TuneAdView requestId
            adView.requestId = getIntent().getStringExtra("REQUESTID");

            try {
                adParams = new JSONObject(getIntent().getStringExtra("ADPARAMS"));
            } catch (JSONException e) {
                e.printStackTrace();
            }

            ViewGroup view = (ViewGroup) getWindow().getDecorView();
            view.setBackgroundColor(Color.TRANSPARENT);

            nativeCloseButton = getIntent().getBooleanExtra(
                    "NATIVECLOSEBUTTON", false);
            if (nativeCloseButton) {
                closeButton = new TuneCloseButton(this);
                FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                        LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
                closeButton.setLayoutParams(params);
                view.addView(closeButton);
            }
            
            setContentView(webView);
        } else {
            // Interstitial was clicked, handle redirect
            String url = getIntent().getStringExtra("REDIRECT_URI");

            getWindow().requestFeature(Window.FEATURE_PROGRESS);
            getWindow().setFeatureInt(Window.FEATURE_PROGRESS,
                    Window.PROGRESS_VISIBILITY_ON);
            
            if (url != null) {
                Uri uri = Uri.parse(url);
                if (isMarketUrl(uri)) {
                    processMarketUri(uri);
                } else if (isAmazonUrl(uri)) {
                    processAmazonUri(uri);
                } else {
                    try {
                        startActivity(new Intent(Intent.ACTION_VIEW, uri));
                    } catch (ActivityNotFoundException e) {
                        e.printStackTrace();
                    }
                }
            }
            // Close ad
            finish();
        }
    }

    @SuppressLint("NewApi")
    @Override
    public void onResume() {
        super.onResume();
        
        // Hide status bar
        if (Build.VERSION.SDK_INT < 16) {
            // Hide status bar on Android 4.0 and lower
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    WindowManager.LayoutParams.FLAG_FULLSCREEN);
        } else {
            // Hide status bar on Android 4.1+
            View decorView = getWindow().getDecorView();
            // Hide the status bar.
            decorView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
        }

        // Hide action bar on Android 4.0 and above
        if (Build.VERSION.SDK_INT >= 11) {
            ActionBar actionBar = getActionBar();
            if (actionBar != null) {
                actionBar.hide();
            }
        }
    }

    @Override
    public void onBackPressed() {
        if (adView != null) {
            // Log a close upon backpress
            TuneAdClient.logClose(adView, adParams);
        }
        super.onBackPressed();
    }

    @Override
    public void onDestroy() {
        // Clean up and free resources
        ViewGroup view = (ViewGroup) getWindow().getDecorView();
        if (nativeCloseButton) {
            view.removeView(closeButton);
        }
        if (webView != null && webView.getParent() != null) {
            ((ViewGroup) webView.getParent()).removeView(webView);
            // Clear webview contents
            webView.loadUrl("about:blank");
        }
        utils.setAdContext(null);
        super.onDestroy();
    }

    // Open app in market, default to Google Play
    protected void processMarketUri(Uri url) {
        final String query = url.getQuery();
        // Try to open with market intent, fallback to Google Play url
        try {
            final Uri marketUri = Uri.parse(String.format(
                    "market://details?%s", query));
            startActivity(new Intent(Intent.ACTION_VIEW, marketUri));
        } catch (ActivityNotFoundException e) {
            final Uri httpUri = Uri.parse(String.format(
                    "http://play.google.com/store/apps/details?%s", query));
            startActivity(new Intent(Intent.ACTION_VIEW, httpUri));
        }
    }

    // Open app in Amazon Appstore
    protected void processAmazonUri(Uri url) {
        final String query = url.getQuery();
        // Try to open with Amazon Appstore, fallback to Amazon url
        try {
            final Uri amznUri = Uri.parse(String.format(
                    "amzn://apps/android?%s", query));
            startActivity(new Intent(Intent.ACTION_VIEW, amznUri));
        } catch (ActivityNotFoundException e) {
            final Uri httpUri = Uri.parse(String.format(
                    "http://www.amazon.com/gp/mas/dl/android?%s", query));
            startActivity(new Intent(Intent.ACTION_VIEW, httpUri));
        }
    }

    // URL should be opened by Play app
    protected boolean isMarketUrl(final Uri url) {
        String scheme = url.getScheme();
        String host = url.getHost();

        if (scheme == null) {
            return false;
        }
        boolean isMarketScheme = scheme.equals("market");
        boolean isPlayUrl = (scheme.equals("http") || scheme.equals("https"))
                && (host.equals("play.google.com") || host
                        .equals("market.android.com"));

        return isMarketScheme || isPlayUrl;
    }

    // URL should be opened by Amazon Appstore
    protected boolean isAmazonUrl(final Uri url) {
        String scheme = url.getScheme();
        String host = url.getHost();

        if (scheme == null) {
            return false;
        }
        boolean isAmznScheme = scheme.equals("amzn");
        boolean isAmznWebUrl = (scheme.equals("http") || scheme.equals("https"))
                && host.equals("www.amazon.com");

        return isAmznScheme || isAmznWebUrl;
    }
}
