package com.tune.ma.analytics.model.event;

import com.tune.ma.analytics.model.constants.TuneEventType;

/**
 * Created by johng on 5/2/17.
 */

public class TuneDeeplinkOpenedEvent extends TuneAnalyticsEventBase {
    public TuneDeeplinkOpenedEvent(String deeplinkUrl) {
        super();

        setCategory(deeplinkUrl);
        setEventType(TuneEventType.APP_OPENED_BY_URL);
        setAction("DeeplinkOpened");
    }
}
