package com.tune.smartwhere;

import android.app.IntentService;
import android.content.Intent;

import com.tune.TuneUtils;

import java.lang.reflect.Method;

/**
 * Created by gordon stewart on 8/18/16.
 *
 * @author gordon@smartwhere.com
 */

public class TuneSmartWhereNotificationService extends IntentService {

    public static final String TUNE_SMARTWHERE_INTENT_ACTION = "proximity-notification";
    public static final String TUNE_SMARTWHERE_INTENT_EXTRA = "proximityNotification";
    public static final String TUNE_SMARTWHERE_METHOD_GET_TITLE = "getTitle";

    public TuneSmartWhereNotificationService() {
        super("TuneSmartWhereNotificationService");
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        TuneUtils.log("TuneSmartWhereNotificationService: onHandleIntent");
        if (intent != null && intent.getAction() != null && intent.getAction().equals(TUNE_SMARTWHERE_INTENT_ACTION)) {
            Object proximityNotification = intent.hasExtra(TUNE_SMARTWHERE_INTENT_EXTRA) ? intent.getSerializableExtra(TUNE_SMARTWHERE_INTENT_EXTRA) : null;
            String title = proximityNotification != null ? getTitleFromProximityNotification(proximityNotification) : null;
            TuneUtils.log("TuneSmartWhereNotificationService: proximityNotification = " + title);
        }
    }

    private String getTitleFromProximityNotification(Object proximityNotification) {
        String title = null;

        try {
            Method getTitle = proximityNotification.getClass().getMethod(TUNE_SMARTWHERE_METHOD_GET_TITLE);
            title = (String) getTitle.invoke(proximityNotification);
        } catch (Exception e) {
            // empty
        }

        return title;
    }
}
