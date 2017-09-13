package com.tune.ma.analytics.model.event;

import com.tune.ma.analytics.model.constants.TuneEventType;

/**
 * Created by johng on 5/2/17.
 */

public class TuneDeeplinkOpenedEvent extends TuneAnalyticsEventBase {
    public TuneDeeplinkOpenedEvent(String deeplinkUrl) {
        super();

        category = deeplinkUrl;
        eventType = TuneEventType.APP_OPENED_BY_URL;
        action = "DeeplinkOpened";
    }
}
