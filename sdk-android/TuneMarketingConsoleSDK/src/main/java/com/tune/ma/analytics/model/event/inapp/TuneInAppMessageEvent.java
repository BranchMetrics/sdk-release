package com.tune.ma.analytics.model.event.inapp;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneEventType;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.inapp.model.TuneInAppMessage;

/**
 * Created by johng on 5/17/17.
 */

public abstract class TuneInAppMessageEvent extends TuneAnalyticsEventBase {
    public static final String ANALYTICS_CAMPAIGN_STEP_ID_KEY = "TUNE_CAMPAIGN_STEP_ID";
    public static final String ANALYTICS_SECONDS_DISPLAYED_KEY = "TUNE_IN_APP_MESSAGE_SECONDS_DISPLAYED";
    public static final String ANALYTICS_UNSPECIFIED_ACTION_KEY = "TUNE_IN_APP_MESSAGE_UNSPECIFIED_ACTION_NAME";
    public static final String ANALYTICS_ACTION_SHOWN = "TUNE_IN_APP_MESSAGE_ACTION_SHOWN";
    public static final String ANALYTICS_MESSAGE_CLOSED = "TUNE_IN_APP_MESSAGE_ACTION_CLOSE_BUTTON_PRESSED";
    public static final String ANALYTICS_MESSAGE_DISMISSED_AUTOMATICALLY = "TUNE_IN_APP_MESSAGE_ACTION_DISMISSED_AFTER_DURATION";
    public static final String ANALYTICS_UNSPECIFIED_ACTION = "TUNE_IN_APP_MESSAGE_UNSPECIFIED_ACTION";

    public TuneInAppMessageEvent(TuneInAppMessage message) {
        super();

        setCategory(message.getId());
        setEventType(TuneEventType.IN_APP_MESSAGE);

        addTag(TuneAnalyticsVariable.Builder(ANALYTICS_CAMPAIGN_STEP_ID_KEY).withValue(message.getCampaignStepId()).build());
    }
}
