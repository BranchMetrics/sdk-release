package com.tune.crosspromo;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.graphics.drawable.BitmapDrawable;
import android.util.Base64;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.TouchDelegate;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;

class TuneCloseButton extends FrameLayout {
    private ImageButton close;

    private TuneAdActivity adActivity;

    @SuppressWarnings("deprecation")
    public TuneCloseButton(Context context) {
        super(context);

        adActivity = (TuneAdActivity) context;
        close = new ImageButton(context);

        DisplayMetrics dm = getResources().getDisplayMetrics();

        // TODO: set drawable based on density
        // MDPI=160, DEFAULT=160, DENSITY_HIGH=240, DENSITY_MEDIUM=160,
        // DENSITY_TV=213, DENSITY_XHIGH=320
        /*
         * if (dm.densityDpi == DisplayMetrics.DENSITY_DEFAULT || dm.densityDpi
         * == DisplayMetrics.DENSITY_HIGH || dm.densityDpi ==
         * DisplayMetrics.DENSITY_MEDIUM || dm.densityDpi ==
         * DisplayMetrics.DENSITY_TV || dm.densityDpi ==
         * DisplayMetrics.DENSITY_XHIGH) { }
         */

        // Create the close button from base64 string and set as background
        byte[] decodedString = Base64.decode(TuneAdUtils.closeButton,
                Base64.DEFAULT);
        Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0,
                decodedString.length);
        BitmapDrawable bd = new BitmapDrawable(getResources(), decodedByte);

        close.setBackgroundDrawable(bd);

        final float density = dm.density;

        // Convert 36dp to px
        int btnSize = (int) ((36 * density) + 0.5);
        // Convert 8dp (minimum UI space size) to px
        int marginSize = (int) ((8 * density) + 0.5);

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(btnSize,
                btnSize);
        params.gravity = Gravity.RIGHT | Gravity.TOP;
        params.setMargins(0, marginSize, marginSize, 0);
        close.setLayoutParams(params);

        close.setOnClickListener(closeListener);

        addView(close);

        // Add touch delegate to close button to expand clickable area to
        // minimum button size (48dp)
        post(new Runnable() {
            public void run() {
                final Rect delegateArea = new Rect();
                close.getHitRect(delegateArea);
                int touchPadding = (int) ((12 * density) + 0.5);
                delegateArea.top -= touchPadding;
                delegateArea.left -= touchPadding;
                delegateArea.bottom += touchPadding;
                delegateArea.right += touchPadding;

                TouchDelegate expandedArea = new TouchDelegate(delegateArea,
                        close);
                if (View.class.isInstance(close.getParent())) {
                    ((View) close.getParent()).setTouchDelegate(expandedArea);
                }
            }
        });

    }

    View.OnClickListener closeListener = new View.OnClickListener() {
        public void onClick(View v) {
            // Log a close upon clicking
            TuneAdClient.logClose(adActivity.adView, adActivity.adParams);
            adActivity.finish();
        }
    };
}
