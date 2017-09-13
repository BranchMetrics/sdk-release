package com.tune.ma.analytics.model.event.inapp;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/10/17.
 */

public class TuneInAppMessageActionTakenEvent extends TuneInAppMessageEvent {
    public TuneInAppMessageActionTakenEvent(TuneInAppMessage message, String actionName, int secondsDisplayed) {
        super(message);

        action = actionName;

        tags.add(TuneAnalyticsVariable.Builder(ANALYTICS_SECONDS_DISPLAYED_KEY).withValue(secondsDisplayed).build());
    }
}
