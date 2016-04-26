package com.tune;

import java.net.URLDecoder;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/*
 * Please add this to your AndroidManifest.xml file.
 *  <receiver android:name="com.tune.TuneTracker">
        <intent-filter>
            <action android:name="com.android.vending.INSTALL_REFERRER" />
        </intent-filter>
    </receiver>
 *
 */
public class TuneTracker extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            if ((null != intent) && (intent.getAction().equals("com.android.vending.INSTALL_REFERRER"))) {
                String rawReferrer = intent.getStringExtra("referrer");
                if (rawReferrer != null) {
                    String referrer = URLDecoder.decode(rawReferrer, "UTF-8");
                    TuneUtils.log("TUNE received referrer " + referrer);
                    
                    // Save the referrer value in SharedPreferences
                    context.getSharedPreferences(TuneConstants.PREFS_TUNE, Context.MODE_PRIVATE).edit().putString(TuneConstants.KEY_REFERRER, referrer).apply();
                    
                    // Notify threadpool waiting for referrer and GAID
                    Tune tune = Tune.getInstance();
                    if (tune != null) {
                        tune.setInstallReferrer(referrer);
                        if (tune.gotGaid && !tune.notifiedPool) {
                            synchronized (tune.pool) {
                                tune.pool.notifyAll();
                                tune.notifiedPool = true;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}