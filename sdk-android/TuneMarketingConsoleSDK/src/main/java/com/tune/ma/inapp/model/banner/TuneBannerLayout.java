package com.tune.ma.inapp.model.banner;

import android.app.Activity;
import android.webkit.WebView;
import android.widget.FrameLayout;

import com.tune.ma.inapp.TuneScreenUtils;

/**
 * Created by johng on 3/7/17.
 */

/**
 * FrameLayout which contains the in-app message banner WebView.
 * Resizes to device width on rotation.
 */
public class TuneBannerLayout extends FrameLayout {
    private Activity activity;
    private int lastOrientation;
    private WebView webView;
    private TuneBanner parentBanner;

    public TuneBannerLayout(Activity activity, WebView webView, TuneBanner banner) {
        super(activity);
        this.activity = activity;
        this.lastOrientation = getResources().getConfiguration().orientation;
        this.webView = webView;
        this.parentBanner = banner;

        this.addView(webView, FrameLayout.LayoutParams.MATCH_PARENT, TuneBanner.getBannerHeightPixels(activity));
    }

    public Activity getActivity() {
        return activity;
    }

    public WebView getWebView() {
        return webView;
    }

    public int getLastOrientation() {
        return lastOrientation;
    }

    // Redraws the banner to fill the width when orientation changes
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);

        int orientation = getResources().getConfiguration().orientation;
        // Only resize banner on actual orientation change
        if (orientation != lastOrientation) {
            lastOrientation = orientation;
            int widthPx = TuneScreenUtils.getScreenWidthPixels(activity);
            int heightPx = TuneBanner.getBannerHeightPixels(activity);

            int newWidthMeasureSpec = MeasureSpec.makeMeasureSpec(widthPx, MeasureSpec.EXACTLY);
            int newHeightMeasureSpec = MeasureSpec.makeMeasureSpec(heightPx, MeasureSpec.EXACTLY);
            super.onMeasure(newWidthMeasureSpec, newHeightMeasureSpec);
            measureChildren(newWidthMeasureSpec, newHeightMeasureSpec);
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        if (parentBanner != null) {
            parentBanner.setVisible(false);
        }
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        if (parentBanner != null) {
            parentBanner.setVisible(true);
        }
    }
}
