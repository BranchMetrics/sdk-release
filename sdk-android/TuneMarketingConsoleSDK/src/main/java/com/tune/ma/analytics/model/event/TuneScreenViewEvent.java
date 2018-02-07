package com.tune.ma.analytics.model.event;

import com.tune.ma.analytics.model.constants.TuneEventType;

/**
 * Created by johng on 2/16/16.
 */
public class TuneScreenViewEvent extends TuneAnalyticsEventBase {
    public TuneScreenViewEvent(String screenName) {
        super();

        setCategory(screenName);
        setEventType(TuneEventType.PAGEVIEW);
    }
}
