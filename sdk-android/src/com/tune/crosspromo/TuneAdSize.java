package com.tune.crosspromo;

import android.content.Context;
import android.content.res.Configuration;

/**
 * Helper class for TuneBanner size
 */
public class TuneAdSize {
    public static final int FULL_WIDTH = -1;
    public static final int AUTO_HEIGHT = -2;

    public static final TuneAdSize BANNER = new TuneAdSize(320, 50);
    public static final TuneAdSize SMART_BANNER = new TuneAdSize(FULL_WIDTH,
            AUTO_HEIGHT);

    private final int width;
    private final int height;

    /**
     * Create an ad size with given width and height
     * 
     * @param width
     *            Ad width
     * @param height
     *            Ad height
     */
    public TuneAdSize(int width, int height) {
        if ((width < 0) && (width != -1)) {
            throw new IllegalArgumentException("Invalid width for MATAdSize: "
                    + width);
        }
        if ((height < 0) && (height != -2)) {
            throw new IllegalArgumentException("Invalid height for MATAdSize: "
                    + height);
        }
        this.width = width;
        this.height = height;
    }

    /**
     * Gets ad size width
     * 
     * @return width
     */
    public int getWidth() {
        return width;
    }

    /**
     * Gets ad size height
     * 
     * @return height
     */
    public int getHeight() {
        return height;
    }

    /**
     * Gets banner ad width in pixels
     * 
     * @param context
     *            Activity context
     * @return width in pixels
     */
    public int getWidthPixels(Context context) {
        // Smart banner width is device width
        if (width == -1) {
            return context.getResources().getDisplayMetrics().widthPixels;
        } else {
            return (int) (width * context.getResources().getDisplayMetrics().density);
        }
    }

    /**
     * Gets banner ad height in pixels
     * 
     * @param context
     *            Activity context
     * @return height in pixels
     */
    public int getHeightPixels(Context context) {
        // Smart banner height is determined by screen size
        if (height == -2) {
            return getSmartBannerHeight(context, context.getResources().getDisplayMetrics().heightPixels);
        } else {
            return (int) (height * context.getResources().getDisplayMetrics().density);
        }
    }
    
    public int getWidthPixelsPortrait(Context context, int orientation) {
        // Smart banner width is device width
        if (width == -1) {
            if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                return context.getResources().getDisplayMetrics().heightPixels;
            } else {
                return context.getResources().getDisplayMetrics().widthPixels;
            }
        } else {
            return (int) (width * context.getResources().getDisplayMetrics().density);
        }
    }
    
    public int getHeightPixelsPortrait(Context context, int orientation) {
        // Smart banner height is determined by screen size
        if (height == -2) {
            int heightPixels = context.getResources().getDisplayMetrics().heightPixels;
            // If in landscape orientation, get the portrait height as the landscape width
            if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                heightPixels = context.getResources().getDisplayMetrics().widthPixels;
            }
            
            return getSmartBannerHeight(context, heightPixels);
        } else {
            return (int) (height * context.getResources().getDisplayMetrics().density);
        }
    }
    
    public int getWidthPixelsLandscape(Context context, int orientation) {
        // Smart banner width is device width
        if (width == -1) {
            // If in portrait orientation, get the landscape height as the landscape width
            if (orientation == Configuration.ORIENTATION_PORTRAIT) {
                return context.getResources().getDisplayMetrics().heightPixels;
            } else {
                return context.getResources().getDisplayMetrics().widthPixels;
            }
        } else {
            return (int) (width * context.getResources().getDisplayMetrics().density);
        }
    }
    
    public int getHeightPixelsLandscape(Context context, int orientation) {
        // Smart banner height is determined by screen size
        if (height == -2) {
            int heightPixels = context.getResources().getDisplayMetrics().heightPixels;
            // If in landscape orientation, get the portrait height as the landscape width
            if (orientation == Configuration.ORIENTATION_PORTRAIT) {
                heightPixels = context.getResources().getDisplayMetrics().widthPixels;
            }
            
            return getSmartBannerHeight(context, heightPixels);
        } else {
            return (int) (height * context.getResources().getDisplayMetrics().density);
        }
    }
    
    private int getSmartBannerHeight(Context context, int heightPixels) {
        int i = (int) (heightPixels / context.getResources().getDisplayMetrics().density);
        if (i <= 400) {
            return (int) (32 * context.getResources().getDisplayMetrics().density);
        }
        if (i <= 720) {
            return (int) (50 * context.getResources().getDisplayMetrics().density);
        }
        return (int) (90 * context.getResources().getDisplayMetrics().density);
    }
}
