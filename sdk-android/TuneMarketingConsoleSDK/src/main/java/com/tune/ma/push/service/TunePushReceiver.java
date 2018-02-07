package com.tune.ma.push.service;

import android.content.Context;
import android.content.Intent;

import com.google.android.gms.gcm.GcmReceiver;
import com.tune.ma.utils.TuneDebugLog;

/**
 * TunePushReceiver
 * @deprecated as of Tune Android SDK v5.0.0 you do not need to use this class directly, but can instead use {@link com.google.android.gms.gcm.GcmReceiver} directly
 */
@Deprecated
public class TunePushReceiver extends GcmReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        TuneDebugLog.d("TunePushReceiver - onReceive");
    }
}