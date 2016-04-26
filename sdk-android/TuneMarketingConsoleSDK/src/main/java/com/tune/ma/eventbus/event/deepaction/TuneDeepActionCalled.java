package com.tune.ma.eventbus.event.deepaction;

import android.app.Activity;

import java.util.Map;

/**
 * Created by charlesgilliam on 2/5/16.
 */
public class TuneDeepActionCalled {
    String deepActionId;
    Map<String, String> deepActionParams;
    Activity activity;

    public TuneDeepActionCalled(String deepActionId, Map<String, String> deepActionParams, Activity activity) {
        this.deepActionId = deepActionId;
        this.deepActionParams = deepActionParams;
        // TODO: We may want to manually release this
        this.activity = activity;
    }

    public Map<String, String> getDeepActionParams() {
        return deepActionParams;
    }

    public String getDeepActionId() {
        return deepActionId;
    }

    public Activity getActivity() {
        return activity;
    }
}
