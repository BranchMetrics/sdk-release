package com.tune.ma.application;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.support.annotation.NonNull;

import com.tune.Tune;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityConnected;
import com.tune.ma.eventbus.event.TuneActivityDisconnected;
import com.tune.ma.eventbus.event.TuneActivityResumed;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;
import com.tune.ma.eventbus.event.deepaction.TuneDeepActionCalled;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.model.TunePushOpenAction;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneOptional;

import java.util.Calendar;
import java.util.Map;

/**
 * Created by johng on 12/28/15.
 */
public class TuneActivity extends Activity {

    @Override
    protected void onStart() {
        super.onStart();
        if (Build.VERSION.SDK_INT < 14) {
            onStart(this);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (Build.VERSION.SDK_INT < 14) {
            onResume(this);
        }
    }

    @Override
    protected void onStop() {
        if (Build.VERSION.SDK_INT < 14) {
            onStop(this);
        }
        super.onStop();
    }

    /**
     * Helper function to measure Activity starts. You do not need to call this method directly unless you support API < 14 and cannot leverage Tune's Application Lifecycle callbacks.
     * @param activity Activity that was started. Should not be null.
     */
    public static void onStart(@NonNull Activity activity) {
        if (activity == null) {
            TuneDebugLog.e("WARNING: TuneActivity.onStart() called with null Activity");
            return;
        }

        TuneDebugLog.i(activity.getClass().getSimpleName(), "onStart()");

        if (TuneManager.getInstance() != null && TuneManager.getInstance().getConfigurationManager() != null) {
            TuneManager.getInstance().getConfigurationManager().getConfigurationIfDisabled();
        }

        TuneOptional<TunePushMessage> possibleMessage = null;
        if (TuneManager.getInstance() != null && TuneManager.getInstance().getPushManager() != null) {
            possibleMessage = TuneManager.getInstance().getPushManager().checkGetPushFromActivity(activity);

            if (possibleMessage.isPresent()) {
                TunePushMessage message = possibleMessage.get();
                // we don't want to log a campaign viewed or push opened (below)
                // for the test message
                if (!message.isTestMessage()) {
                    // NOTE: Must be done before the session starts so it applies to all analytics events
                    TuneEventBus.post(new TuneCampaignViewed(message.getCampaign()));
                }

                if (message.isOpenActionDeepAction()) {
                    TunePushOpenAction action = message.getPayload().getOnOpenAction();
                    String deepActionId = action.getDeepActionId();
                    Map<String, String> deepActionParams = action.getDeepActionParameters();
                    TuneEventBus.post(new TuneDeepActionCalled(deepActionId, deepActionParams, activity));
                }
            }
        }

        // Start the new session
        TuneEventBus.post(new TuneActivityConnected(activity));

        if (possibleMessage != null && possibleMessage.isPresent() && !possibleMessage.get().isTestMessage()) {
            // NOTE: Must be done after the session starts so that it is considered part of the new session
            TuneEventBus.post(new TunePushOpened(possibleMessage.get()));
        }
    }

    /**
     * Helper function to measure opens in Activity onResume. You do not need to call this method directly unless you support API < 14 and cannot leverage Tune's Application Lifecycle callbacks.
     * @param activity Activity that was opened. Should not be null.
     */
    public static void onResume(@NonNull Activity activity) {
        if (activity == null) {
            TuneDebugLog.e("WARNING: TuneActivity.onResume() called with null Activity");
            return;
        }

        TuneDebugLog.i(activity.getClass().getSimpleName(), "onResume()");

        Intent intent = activity.getIntent();
        if (Tune.getInstance() != null && intent != null) {
            String uriString = intent.getDataString();
            if (uriString != null) {
                Tune.getInstance().setReferralCallingPackage(activity.getCallingPackage());
                Tune.getInstance().setReferralUrl(uriString);
            }

            if (shouldMeasureSession(intent)) {
                Tune.getInstance().measureSessionInternal();
            }
        }

        // Get just the original activity name
        String[] splitName = activity.getClass().getSimpleName().split("TuneActivity");
        TuneEventBus.post(new TuneActivityResumed(splitName[0]));
    }

    private static boolean shouldMeasureSession(Intent intent) {
        return isDeeplinkIntent(intent) || isLaunchIntent(intent) || isTimeToMeasureSessionAgain();
    }

    private static boolean isDeeplinkIntent(Intent intent) {
        return null != intent.getDataString();
    }

    private static boolean isLaunchIntent(Intent intent) {
        return Intent.ACTION_MAIN.equals(intent.getAction());
    }

    private static boolean isTimeToMeasureSessionAgain() {
        // either the last session was measured in a different UTC day OR it was more than 8 hours ago

        final long timeLastMeasuredSession = Tune.getInstance().getTimeLastMeasuredSession();
        final long eightHoursInMilliseconds = 28800000; // 8 * 60 * 60 * 1000
        final boolean lastMeasuredMoreThan8HoursAgo = timeLastMeasuredSession < System.currentTimeMillis() - eightHoursInMilliseconds;

        Calendar today = Calendar.getInstance();
        Calendar lastMeasuredSessionDate = Calendar.getInstance();
        lastMeasuredSessionDate.setTimeInMillis(Tune.getInstance().getTimeLastMeasuredSession());
        final boolean lastMeasuredOnADifferentUTCDay = today.get(Calendar.DAY_OF_YEAR) != lastMeasuredSessionDate.get(Calendar.DAY_OF_YEAR);

        return lastMeasuredOnADifferentUTCDay || lastMeasuredMoreThan8HoursAgo;
    }

    /**
     * Helper function to track for Activity stops. You do not need to call this method directly unless you support API < 14 and cannot leverage Tune's Application Lifecycle callbacks.
     * @param activity Activity that was stopped. Should not be null.
     */
    public static void onStop(@NonNull Activity activity) {
        if (activity == null) {
            TuneDebugLog.e("WARNING: TuneActivity.onStop() called with null Activity");
            return;
        }

        TuneDebugLog.i(activity.getClass().getSimpleName(), "onStop()");

        TuneEventBus.post(new TuneActivityDisconnected(activity));
    }
}
