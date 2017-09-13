package com.tune.ma.analytics.model.event.inapp;

import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/10/17.
 */

public class TuneInAppMessageShownEvent extends TuneInAppMessageEvent {
    public TuneInAppMessageShownEvent(TuneInAppMessage message) {
        super(message);

        action = ANALYTICS_ACTION_SHOWN;
    }
}
