package com.tune;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.tune.ma.utils.TuneSharedPrefsDelegate;

import java.net.URLDecoder;

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
                    TuneDebugLog.d("TUNE received referrer " + referrer);

                    // Save the referrer value in SharedPreferences
                    new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_TUNE).putString(TuneConstants.KEY_REFERRER, referrer);

                    // Notify threadpool waiting for referrer and advertising ID
                    Tune tune = Tune.getInstance();
                    if (tune != null) {
                        tune.setInstallReferrer(referrer);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}