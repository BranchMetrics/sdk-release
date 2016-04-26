package com.tune.ma.analytics.model.event.tracer;

import android.text.TextUtils;

import com.tune.ma.eventbus.event.userprofile.TuneCustomProfileVariablesCleared;

/**
 * Created by johng on 1/27/16.
 */
public class TuneClearVariablesEvent extends TuneTracerEvent {
    public TuneClearVariablesEvent(TuneCustomProfileVariablesCleared event) {
        super();
        action = CLEAR_VARIABLES;
        category = TextUtils.join(",", event.getVars());
    }
}
