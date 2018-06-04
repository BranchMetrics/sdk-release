package com.tune.ma.eventbus.event.userprofile;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;

/**
 * Created by charlesgilliam on 1/14/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneUpdateUserProfile {
    TuneAnalyticsVariable var;

    public TuneUpdateUserProfile(TuneAnalyticsVariable analyticsVariable) {
        var = analyticsVariable;
    }

    public TuneAnalyticsVariable getVariable() {
        return var;
    }
}
