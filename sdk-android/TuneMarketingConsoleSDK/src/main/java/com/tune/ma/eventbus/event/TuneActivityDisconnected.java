package com.tune.ma.eventbus.event;

import android.app.Activity;

/**
 * Created by kristine on 1/7/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneActivityDisconnected {

    private Activity activity;

    public TuneActivityDisconnected(Activity activity) {
        this.activity = activity;
    }

    public Activity getActivity() {
        return activity;
    }
}
