package com.mobileapptracker;

import java.net.URLDecoder;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/*
 * Please add this to your AndroidManifest.xml file.
 *  <receiver android:name="com.mobileapptracker.Tracker" android:exported="true">
        <intent-filter>
            <action android:name="com.android.vending.INSTALL_REFERRER" />
        </intent-filter>
    </receiver>
 *
 */
public class Tracker extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            if ((null != intent) && (intent.getAction().equals("com.android.vending.INSTALL_REFERRER"))) {
                String rawReferrer = intent.getStringExtra("referrer");
                if (rawReferrer != null) {
                    String referrer = URLDecoder.decode(rawReferrer, "UTF-8");
                    Log.d(MATConstants.TAG, "MAT received referrer " + referrer);
                    
                    // Save the referrer value in SharedPreferences
                    context.getSharedPreferences(MATConstants.PREFS_REFERRER, Context.MODE_PRIVATE).edit().putString("referrer", referrer).commit();
                    
                    // Post conversion install to update referrer
                    MobileAppTracker mat = MobileAppTracker.getInstance();
                    if (mat != null) {
                        mat.trackInstallWithReferrer();
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}