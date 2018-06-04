package com.tune.ma.analytics.model.event.tracer;

import com.tune.ma.analytics.model.constants.TuneEventType;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;

/**
 * Created by johng on 1/26/16.
 * Base class for all tracer analytics events.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneTracerEvent extends TuneAnalyticsEventBase {
    public static final String CLEAR_VARIABLES = "ClearVariables";

    public TuneTracerEvent() {
        super();
        setEventType(TuneEventType.TRACER);
    }
}
