package com.tune.ma.inapp.model.modal;

import android.app.Activity;
import android.support.v4.app.FragmentActivity;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;

import com.tune.Tune;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import static com.tune.ma.inapp.TuneInAppMessageConstants.BACKGROUND_MASK_BLUR;
import static com.tune.ma.inapp.TuneInAppMessageConstants.BACKGROUND_MASK_DARK;
import static com.tune.ma.inapp.TuneInAppMessageConstants.BACKGROUND_MASK_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.BACKGROUND_MASK_LIGHT;
import static com.tune.ma.inapp.TuneInAppMessageConstants.BACKGROUND_MASK_NONE;
import static com.tune.ma.inapp.TuneInAppMessageConstants.EDGE_ROUND_CORNERS;
import static com.tune.ma.inapp.TuneInAppMessageConstants.EDGE_STYLE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.HEIGHT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.WIDTH_KEY;

/**
 * Created by johng on 4/5/17.
 */

public class TuneModal extends TuneInAppMessage {
    public enum EdgeStyle {
        SQUARE,
        ROUND
    }

    public enum Background {
        LIGHT,
        DARK,
        BLUR,
        NONE
    }

    private int width;
    private int height;

    private EdgeStyle edgeStyle;
    private Background background;

    private TuneModalDialogFragment modalDialogFragment;

    public TuneModal(JSONObject messageJson) {
        super(messageJson);
        setType(Type.MODAL);

        // Read width and height
        JSONObject message = TuneJsonUtils.getJSONObject(messageJson, MESSAGE_KEY);
        width = TuneJsonUtils.getInt(message, WIDTH_KEY);
        height = TuneJsonUtils.getInt(message, HEIGHT_KEY);

        // Read edge style
        edgeStyle = EdgeStyle.SQUARE;
        String messageEdgeStyle = TuneJsonUtils.getString(message, EDGE_STYLE_KEY);
        if (messageEdgeStyle != null) {
            if (messageEdgeStyle.equals(EDGE_ROUND_CORNERS)) {
                edgeStyle = EdgeStyle.ROUND;
            }
        }

        // Read background overlay type
        background = Background.NONE;
        String messageBackground = TuneJsonUtils.getString(message, BACKGROUND_MASK_KEY);
        if (messageBackground != null) {
            switch (messageBackground) {
                case BACKGROUND_MASK_LIGHT:
                    background = Background.LIGHT;
                    break;
                case BACKGROUND_MASK_DARK:
                    background = Background.DARK;
                    break;
                case BACKGROUND_MASK_BLUR:
                    background = Background.BLUR;
                    break;
                case BACKGROUND_MASK_NONE:
                default:
                    background = Background.NONE;
                    break;
            }
        }
    }

    @Override
    public synchronized void load(Activity activity) {
        if (!Tune.getInstance().isOnline(activity)) {
            TuneDebugLog.e("Device is offline, cannot load modal message");
            return;
        }

        if (modalDialogFragment == null) {
            modalDialogFragment = TuneModalDialogFragment.newInstance(this);
        }

        setPreloaded(true);
    }

    @Override
    public synchronized void display() {
        Activity lastActivity = TuneActivity.getLastActivity();
        if (lastActivity == null) {
            TuneDebugLog.e("Last Activity is null, cannot display modal message");
            return;
        }

        if (!Tune.getInstance().isOnline(lastActivity)) {
            TuneDebugLog.e("Device is offline, cannot display modal message");
            return;
        }

        // Execute any pending transactions first
        ((FragmentActivity) lastActivity).getSupportFragmentManager().executePendingTransactions();

        if (modalDialogFragment == null) {
            modalDialogFragment = TuneModalDialogFragment.newInstance(this);
        }

        // If there's a modal already showing, don't show new one
        if (modalDialogFragment.getDialog() != null && modalDialogFragment.getDialog().isShowing()) {
            return;
        }

        modalDialogFragment.show(((FragmentActivity) lastActivity).getSupportFragmentManager(), "TUNE_MODAL_" + this.getId());

        setVisible(true);
    }

    @Override
    public synchronized void dismiss() {
        Activity lastActivity = TuneActivity.getLastActivity();
        animateClose(lastActivity);
    }

    public int getWidth() {
        return width;
    }

    public void setWidth(int width) {
        this.width = width;
    }

    public int getHeight() {
        return height;
    }

    public void setHeight(int height) {
        this.height = height;
    }

    public Background getBackground() {
        return background;
    }

    public void setBackground(Background background) {
        this.background = background;
    }

    public EdgeStyle getEdgeStyle() {
        return edgeStyle;
    }

    public void setEdgeStyle(EdgeStyle style) {
        this.edgeStyle = style;
    }

    /*********************
     * Animation Methods *
     *********************/

    /**
     * Play message open animation based on message transition.
     * @param activity Parent Activity
     */
    protected synchronized void animateOpen(Activity activity) {
        if (activity == null) {
            return;
        }

        // Hide the progress bar
        modalDialogFragment.hideProgressBar();

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
            modalDialogFragment.startAnimation(animation);
        }
    }

    /**
     * Play message close animation based on transition.
     * Then, dismiss modal dialog
     * @param activity  Parent Activity
     */
    protected synchronized void animateClose(final Activity activity) {
        if (activity == null) {
            return;
        }

        // On close, reset preloaded status
        setPreloaded(false);
        modalDialogFragment = (TuneModalDialogFragment)((FragmentActivity)activity).getSupportFragmentManager().findFragmentByTag("TUNE_MODAL_" + this.getId());
        // If we can't find our fragment anymore, it was either destroyed or hasn't been created yet, so we don't need to worry about closing it
        if (modalDialogFragment == null) {
            return;
        }

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
                modalDialogFragment.dismiss();
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
                    if (modalDialogFragment != null) {
                        modalDialogFragment.dismiss();
                    }
                }

                @Override
                public void onAnimationRepeat(Animation animation) {
                }
            });
            modalDialogFragment.startAnimation(animation);
        }
    }
}
