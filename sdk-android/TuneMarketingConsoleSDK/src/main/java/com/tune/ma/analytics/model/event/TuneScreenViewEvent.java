package com.tune.ma.analytics.model.event;

import com.tune.ma.analytics.model.constants.TuneEventType;

/**
 * Created by johng on 2/16/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneScreenViewEvent extends TuneAnalyticsEventBase {
    public TuneScreenViewEvent(String screenName) {
        super();

        setCategory(screenName);
        setEventType(TuneEventType.PAGEVIEW);
    }
}
