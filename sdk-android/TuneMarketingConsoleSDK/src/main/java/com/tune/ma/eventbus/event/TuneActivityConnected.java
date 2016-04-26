package com.tune.ma.eventbus.event;

import android.app.Activity;

/**
 * Created by kristine on 1/7/16.
 */
public class TuneActivityConnected {
    private Activity activity;

    public TuneActivityConnected(Activity activity) {
        this.activity = activity;
    }

    public Activity getActivity() {
        return activity;
    }
}
