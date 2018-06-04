package com.tune.ma.eventbus.event;

/**
 * Created by johng on 2/16/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneActivityResumed {
    private String name;

    public TuneActivityResumed(String activityName) {
        this.name = activityName;
    }

    public String getActivityName() {
        return name;
    }
}
