package com.tune.ma.inapp.model.modal;

import android.app.Activity;
import android.graphics.Color;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.WebView;
import android.widget.FrameLayout;
import android.widget.ProgressBar;

/**
 * Created by johng on 4/6/17.
 */

public class TuneModalLayout extends FrameLayout {
    // Use 0.65 opacity, 0.65 * 255 in hex is A6 for first two values
    private static final int BACKGROUND_LIGHT = 0xA6FFFFFF;
    private static final int BACKGROUND_DARK = 0xA6000000;

    private ProgressBar progressBar;
    private WebView webView;

    public TuneModalLayout(Activity activity, WebView webView, TuneModal parentModal) {
        super(activity);

        this.progressBar = new ProgressBar(activity);
        this.webView = webView;

        // Set background color based on Background enum value
        int backgroundColor = Color.TRANSPARENT;
        TuneModal.Background background = parentModal.getBackground();
        if (background == TuneModal.Background.LIGHT) {
            backgroundColor = BACKGROUND_LIGHT;
        } else if (background == TuneModal.Background.DARK) {
            backgroundColor = BACKGROUND_DARK;
        }
        this.setBackgroundColor(backgroundColor);

        // Start showing progress bar with 1/4 size layout params as webview
        FrameLayout.LayoutParams progressBarLayoutParams = new FrameLayout.LayoutParams(webView.getLayoutParams().width/4, webView.getLayoutParams().height/4);
        progressBarLayoutParams.gravity = Gravity.CENTER;

        this.addView(progressBar, progressBarLayoutParams);
        this.addView(webView);

        // Disable touch for everything behind the modal layout overlay
        this.setOnTouchListener(new OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                return true;
            }
        });
    }

    public ProgressBar getProgressBar() {
        return this.progressBar;
    }

    public WebView getWebView() {
        return this.webView;
    }
}
