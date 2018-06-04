package com.tune.ma.inapp.model.fullscreen;

import android.annotation.SuppressLint;
import android.app.ActionBar;
import android.content.pm.ActivityInfo;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebView;
import android.widget.FrameLayout;

import com.tune.ma.TuneManager;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.inapp.TuneInAppMessageManager;

import java.net.URLEncoder;

/**
 * Created by johng on 2/21/17.
 * TuneFullScreenActivity loads and displays a WebView with HTML in-app message content
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneFullScreenActivity extends FragmentActivity {
    private TuneFullScreen message;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);

        // Set orientation based on the orientation of the parent Activity
        int orientation = getIntent().getIntExtra(TuneFullScreen.ORIENTATION, ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        String messageId = getIntent().getStringExtra(TuneFullScreen.MESSAGE_ID);

        // If the in-app message manager is null, we cannot show the in-app message
        TuneInAppMessageManager messageManager = TuneManager.getInstance().getInAppMessageManager();
        if (messageManager == null) {
            finish();
            return;
        }
        // Load the html for this message id from the TuneInAppMessageManager's messages
        message = (TuneFullScreen)messageManager.getMessagesByIds().get(messageId);

        // If message doesn't exist, we can't display anything, so close the activity
        if (message == null) {
            finish();
            return;
        }

        setRequestedOrientation(orientation);

        WebView webView = message.getWebView();
        setContentView(webView);

        // If message is preloaded, log an impression upon display
        if (message.isPreloaded()) {
            webView.setVisibility(View.VISIBLE);

            // Handle impression event tracking
            message.processImpression();
        } else {
            // Message is not preloaded, show a loading screen or progress bar and start loading HTML
            FrameLayout.LayoutParams loadingLayout = new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            loadingLayout.gravity = Gravity.CENTER;

            // Show the custom loading screen or progress bar while the WebView is still loading content
            if (message.isUsingCustomLoadingScreen()) {
                if (message.getLoadingScreen().getParent() == null) {
                    addContentView(message.getLoadingScreen(), loadingLayout);
                }
            } else {
                if (message.getProgressBar().getParent() == null) {
                    addContentView(message.getProgressBar(), loadingLayout);
                }
            }

            // Add close button to loading screen
            if (message.getCloseButton().getParent() == null) {
                FrameLayout.LayoutParams closeButtonLayout = new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
                addContentView(message.getCloseButton(), closeButtonLayout);
            }

            // Load HTML in WebView
            try {
                webView.loadData(URLEncoder.encode(message.getHtml(), "utf-8").replaceAll("\\+", " "), "text/html", "utf-8");
            } catch (Exception e) {
                e.printStackTrace();
            }
        }


    }

    @SuppressLint("NewApi")
    @Override
    public void onResume() {
        super.onResume();

        if (Build.VERSION.SDK_INT < 14) {
            TuneActivity.onResume(this);
        }

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
    public void onPause() {
        if (Build.VERSION.SDK_INT < 14) {
            TuneActivity.onPause(this);
        }
        super.onPause();
    }

    @Override
    public void onBackPressed() {
        // Handle dismiss event tracking
        message.processDismiss();

        message.dismiss();

        super.onBackPressed();
    }

    @Override
    public void onDestroy() {
        // Clean up and free resources
        if (message != null) {
            WebView webView = message.getWebView();
            if (webView != null && webView.getParent() != null) {
                ((ViewGroup) webView.getParent()).removeView(webView);
                // Clear webview contents
                webView.loadUrl("about:blank");
            }
        }
        super.onDestroy();
    }
}
