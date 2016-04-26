package com.tune.ma.application;

import android.app.Application;
import android.os.Build;

public class TuneApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        if (Build.VERSION.SDK_INT >= 14) {
            registerActivityLifecycleCallbacks(new TuneActivityLifecycleCallbacks());
        }
    }
}
