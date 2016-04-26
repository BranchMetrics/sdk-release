package com.tune.ma.analytics.model.event.tracer;

import com.tune.ma.analytics.model.TuneEventType;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;

/**
 * Created by johng on 1/26/16.
 * Base class for all tracer analytics events.
 */
public class TuneTracerEvent extends TuneAnalyticsEventBase {
    public static final String CLEAR_VARIABLES = "ClearVariables";

    public TuneTracerEvent() {
        super();
        eventType = TuneEventType.TRACER;
    }
}
