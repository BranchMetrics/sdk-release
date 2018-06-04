package com.tune.ma.analytics.model.event.inapp;

import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/10/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneInAppMessageShownEvent extends TuneInAppMessageEvent {
    public TuneInAppMessageShownEvent(TuneInAppMessage message) {
        super(message);

        setAction(ANALYTICS_ACTION_SHOWN);
    }
}
