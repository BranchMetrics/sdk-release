package com.tune.ma.analytics.model.event.push;

import com.tune.ma.analytics.model.constants.TuneEventType;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public class TunePushEnabledEvent extends TuneAnalyticsEventBase {
    public TunePushEnabledEvent(boolean status) {
        super();

        category = APPLICATION_CATEGORY;
        action = status ? "Push Enabled" : "Push Disabled";
        eventType = TuneEventType.EVENT;
    }
}
