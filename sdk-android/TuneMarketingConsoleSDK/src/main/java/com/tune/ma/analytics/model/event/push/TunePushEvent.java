package com.tune.ma.analytics.model.event.push;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.TuneEventType;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.push.model.TunePushMessage;

/**
 * Created by charlesgilliam on 2/10/16.
 */
public abstract class TunePushEvent extends TuneAnalyticsEventBase {
    public TunePushEvent(TunePushMessage message) {
        super();

        eventType = TuneEventType.PUSH_NOTIFICATION;
        category = message.getCampaign().getVariationId();

        // TODO: Verify that these are the only tags we want to add -- looks that way but we are
        //       trying to send a lot of things that don't exist
        tags.add(TuneAnalyticsVariable.Builder("ARTPID").withValue(message.getCampaign().getVariationId()).build());
        tags.addAll(message.getCampaign().toAnalyticVariables());
    }
}
