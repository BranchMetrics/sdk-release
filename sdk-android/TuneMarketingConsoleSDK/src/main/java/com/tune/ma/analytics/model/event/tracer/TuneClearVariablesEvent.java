package com.tune.ma.analytics.model.event.tracer;

import android.text.TextUtils;

import com.tune.ma.eventbus.event.userprofile.TuneCustomProfileVariablesCleared;

/**
 * Created by johng on 1/27/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneClearVariablesEvent extends TuneTracerEvent {
    public TuneClearVariablesEvent(TuneCustomProfileVariablesCleared event) {
        super();
        setAction(CLEAR_VARIABLES);
        setCategory(TextUtils.join(",", event.getVars()));
    }
}
