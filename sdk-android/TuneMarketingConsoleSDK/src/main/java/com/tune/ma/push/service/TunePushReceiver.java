package com.tune.ma.push.service;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.support.v4.content.WakefulBroadcastReceiver;

import com.tune.ma.push.service.TunePushService;
import com.tune.ma.utils.TuneDebugLog;

public class TunePushReceiver extends WakefulBroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        TuneDebugLog.d("TunePushReceiver - onReceive");

        // Read: http://porcupineprogrammer.blogspot.com/2014/02/when-do-you-absolutely-need.html
        //       http://stackoverflow.com/questions/22543582/does-a-gcm-app-really-need-a-wakelock
        //       https://www.pubnub.com/blog/2015-06-24-sending-receiving-android-push-notifications-with-gcm-google-cloud-messaging/
        //       The wake lock seems needed so that we can create pushes while the screen is turned off.
        //       Also looks like our competitors require a wake lock as well.
        // IMPORTANT: If we compact these together we'll want to use https://developers.google.com/android/reference/com/google/android/gms/gcm/GcmListenerService
        //            Which would require people to import google play services.

        // Explicitly specify that TunePushService will handle the intent.
        ComponentName comp = new ComponentName(context.getPackageName(), TunePushService.class.getName());

        // Start the service, keeping the device awake while it is launching.
        startWakefulService(context, (intent.setComponent(comp)));
        setResultCode(Activity.RESULT_OK);
    }
}