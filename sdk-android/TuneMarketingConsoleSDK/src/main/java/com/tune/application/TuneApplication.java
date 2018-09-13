package com.tune.application;

import android.app.Application;

public class TuneApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        registerActivityLifecycleCallbacks(new TuneActivityLifecycleCallbacks());
    }
}
