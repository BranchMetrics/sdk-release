package com.tune.ma.eventbus.event;

/**
 * Created by johng on 2/16/16.
 */
public class TuneActivityResumed {
    private String name;

    public TuneActivityResumed(String activityName) {
        this.name = activityName;
    }

    public String getActivityName() {
        return name;
    }
}
