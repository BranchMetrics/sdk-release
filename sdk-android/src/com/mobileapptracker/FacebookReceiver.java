package com.mobileapptracker;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

/*
 * Please add this to your AndroidManifest.xml file.
 *  <receiver android:name="com.mobileapptracker.FacebookReceiver" android:exported="true">
        <intent-filter>
            <action android:name="com.facebook.application.(application id)" />
        </intent-filter>
    </receiver>
 *
 */
public class FacebookReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        SharedPreferences SP = context.getSharedPreferences(MATConstants.PREFS_FACEBOOK_INTENT, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString("action", intent.getAction());
        editor.commit(); // save the intent's action value, will be retrieved later on main activity
    }
}