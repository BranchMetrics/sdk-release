package com.tune.ma.inapp.model.modal;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;

import com.tune.TuneUtils;

import static com.tune.ma.inapp.TuneInAppMessageConstants.DEFAULT_CORNER_RADIUS;

/**
 * Created by johng on 4/10/17.
 */

/**
 * Class for displaying WebView with rounded corners
 * Reference: http://stackoverflow.com/questions/34299652/android-custom-webview-with-rounded-corners
 */
public class TuneModalRoundedWebView extends TuneModalWebView {
    private int width;
    private int height;
    private int radius;

    public TuneModalRoundedWebView(Context context, TuneModal parentModal) {
        super(context, parentModal);
        this.radius = TuneUtils.dpToPx(context, DEFAULT_CORNER_RADIUS);
    }

    // This method gets called when the view first loads, and also whenever the
    // view changes. Use this opportunity to save the view's width and height.
    @Override
    protected void onSizeChanged(int newWidth, int newHeight, int oldWidth, int oldHeight) {
        super.onSizeChanged(newWidth, newHeight, oldWidth, oldHeight);
        width = newWidth;
        height = newHeight;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        Path path = new Path();
        path.setFillType(Path.FillType.INVERSE_WINDING);
        path.addRoundRect(new RectF(0, getScrollY(), width, getScrollY() + height), radius, radius, Path.Direction.CW);
        canvas.drawPath(path, createPorterDuffClearPaint());
    }

    private Paint createPorterDuffClearPaint() {
        Paint paint = new Paint();
        paint.setColor(Color.TRANSPARENT);
        paint.setStyle(Paint.Style.FILL);
        paint.setAntiAlias(true);
        paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        return paint;
    }
}
