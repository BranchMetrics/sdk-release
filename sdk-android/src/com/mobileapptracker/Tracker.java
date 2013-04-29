package com.mobileapptracker;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
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
    SharedPreferences SP;

    @Override
    public void onReceive(Context context, Intent intent) {
        String referrer = intent.getStringExtra("referrer");
        if (referrer != null) { //is it coming from android market?
            Log.d(MATConstants.TAG, "Received install referrer " + referrer);
            SP = context.getSharedPreferences(MATConstants.PREFS_REFERRER, 0);
            SharedPreferences.Editor editor = SP.edit();
            editor.putString("referrer", referrer);
            editor.commit(); // save the referrer value, will be retrieved later on main activity
        }
    }
}