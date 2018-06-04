package com.tune.ma.analytics.model.event.inapp;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/10/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneInAppMessageActionTakenEvent extends TuneInAppMessageEvent {
    public TuneInAppMessageActionTakenEvent(TuneInAppMessage message, String actionName, int secondsDisplayed) {
        super(message);

        setAction(actionName);

        addTag(TuneAnalyticsVariable.Builder(ANALYTICS_SECONDS_DISPLAYED_KEY).withValue(secondsDisplayed).build());
    }
}
