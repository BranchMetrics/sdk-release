package com.tune.crosspromo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Point;
import android.os.Build;
import android.view.Display;

/**
 * Helper class for TuneBanner size
 */
class TuneBannerSize {
    public static final int FULL_WIDTH = -1;
    public static final int AUTO_HEIGHT = -2;

    /**
     * Gets banner ad width in pixels
     * 
     * @param context
     *            Activity context
     * @return width in pixels
     */
    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    public static int getScreenWidthPixels(Context context) {
        // Banner width is device screen width
        Display display = ((Activity)context).getWindowManager().getDefaultDisplay();
        Point size = new Point();
        if (Build.VERSION.SDK_INT >= 17) {
            display.getRealSize(size);
            return size.x;
        } else if (Build.VERSION.SDK_INT >= 13) {
            display.getSize(size);
            return size.x;
        } else {
            return display.getWidth();
        }
    }
    
    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    public static int getScreenHeightPixels(Context context) {
        Display display = ((Activity)context).getWindowManager().getDefaultDisplay();
        Point size = new Point();
        if (Build.VERSION.SDK_INT >= 17) {
            display.getRealSize(size);
            return size.y;
        } else if (Build.VERSION.SDK_INT >= 13) {
            display.getSize(size);
            return size.y;
        } else {
            return display.getHeight();
        }
    }

    /**
     * Gets banner ad height in pixels
     * 
     * @param context
     *            Activity context
     * @return height in pixels
     */
    public static int getBannerHeightPixels(Context context, int orientation) {
        // Banner height is determined by screen size
        return getBannerHeight(context, getScreenHeightPixels(context), orientation);
    }
    
    public static int getScreenWidthPixelsPortrait(Context context, int orientation) {
        // Banner width is device width
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            return getScreenHeightPixels(context);
        } else {
            return getScreenWidthPixels(context);
        }
    }
    
    public static int getScreenWidthPixelsLandscape(Context context, int orientation) {
        // Banner width is device width
        // If in portrait orientation, get the landscape height as the landscape width
        if (orientation == Configuration.ORIENTATION_PORTRAIT) {
            return getScreenHeightPixels(context);
        } else {
            return getScreenWidthPixels(context);
        }
    }
    
    public static int getBannerHeightPixelsPortrait(Context context, int orientation) {
        // Banner height is determined by screen size
        int screenHeightPixels = getScreenHeightPixels(context);
        // If in landscape orientation, get the portrait height as the landscape width
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            screenHeightPixels = getScreenWidthPixels(context);
        }
        
        return getBannerHeight(context, screenHeightPixels, Configuration.ORIENTATION_PORTRAIT);
    }
    
    public static int getBannerHeightPixelsLandscape(Context context, int orientation) {
        // Banner height is determined by screen size
        int screenHeightPixels = getScreenHeightPixels(context);
        // If in landscape orientation, get the portrait height as the landscape width
        if (orientation == Configuration.ORIENTATION_PORTRAIT) {
            screenHeightPixels = getScreenWidthPixels(context);
        }
        
        return getBannerHeight(context, screenHeightPixels, Configuration.ORIENTATION_LANDSCAPE);
    }
    
    private static int getBannerHeight(Context context, int screenHeightPixels, int orientation) {
        // Use separate logic for portrait vs landscape
        if (orientation == Configuration.ORIENTATION_PORTRAIT) {
            // 50 x density is the rule for portrait
            return (int) (50 * context.getResources().getDisplayMetrics().density);
        } else {
            // AdMob specs x density is the rule for landscape: https://developers.google.com/admob/android/banner
            int i = (int) (screenHeightPixels / context.getResources().getDisplayMetrics().density);
            if (i <= 400) {
                return (int) (32 * context.getResources().getDisplayMetrics().density);
            }
            if (i <= 720) {
                return (int) (50 * context.getResources().getDisplayMetrics().density);
            }
            return (int) (90 * context.getResources().getDisplayMetrics().density);
        }
    }
}
