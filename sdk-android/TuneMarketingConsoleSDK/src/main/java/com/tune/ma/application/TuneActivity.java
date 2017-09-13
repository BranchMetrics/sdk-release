package com.tune.ma.application;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.support.annotation.NonNull;
import android.support.v4.app.FragmentActivity;

import com.tune.Tune;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityConnected;
import com.tune.ma.eventbus.event.TuneActivityDisconnected;
import com.tune.ma.eventbus.event.TuneActivityResumed;
import com.tune.ma.eventbus.event.TuneDeeplinkOpened;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;
import com.tune.ma.eventbus.event.deepaction.TuneDeepActionCalled;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.push.model.TunePushOpenAction;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneOptional;

import java.lang.ref.WeakReference;
import java.util.Calendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Created by johng on 12/28/15.
 */
public class TuneActivity extends FragmentActivity {
    private static WeakReference<Activity> weakLastActivity;
    private static Map<String, Set<Integer>> lastIntentCodesForDeeplinks = new HashMap<>();

    @Override
    protected void onResume() {
        super.onResume();
        if (Build.VERSION.SDK_INT < 14) {
            onResume(this);
        }
    }

    @Override
    protected void onPause() {
        if (Build.VERSION.SDK_INT < 14) {
            onPause(this);
        }
        super.onPause();
    }

    /**
     * Helper function to measure opens in Activity onResume.
     * You do not need to call this method directly unless you support API &lt; 14 and cannot leverage Tune's Application Lifecycle callbacks.
     * @param activity Activity that was opened. Should not be null.
     */
    public static void onResume(@NonNull Activity activity) {
        if (activity == null) {
            TuneDebugLog.e("WARNING: TuneActivity.onResume() called with null Activity");
            return;
        }

        TuneDebugLog.i(activity.getClass().getSimpleName(), "onResume()");

        weakLastActivity = new WeakReference<Activity>(activity);
        String deeplinkReceived = null;

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

        Intent intent = activity.getIntent();
        if (Tune.getInstance() != null && intent != null) {
            if (isDeeplinkIntent(intent)) {
                String uriString = intent.getDataString();
                Tune.getInstance().setReferralCallingPackage(activity.getCallingPackage());
                Tune.getInstance().setReferralUrl(uriString);
                deeplinkReceived = uriString;
            }

            if (shouldMeasureSession(intent)) {
                Tune.getInstance().measureSessionInternal();
            }
        }

        // Start the new session
        TuneEventBus.post(new TuneActivityConnected(activity));

        if (possibleMessage != null && possibleMessage.isPresent() && !possibleMessage.get().isTestMessage()) {
            // NOTE: Must be done after the session starts so that it is considered part of the new session
            TuneEventBus.post(new TunePushOpened(possibleMessage.get()));
        }

        // Send DeeplinkOpened event after session starts if we received a deeplink intent this session
        if (deeplinkReceived != null) {
            // This is to deal with Android not clearing intents when the same Activity is opened
            // We don't want to consider it a new deeplink open when the deeplinked Activity is opened from history or re-created on orientation change
            boolean launchedFromHistory = ((intent.getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0);

            // Check whether there are any existing Intents for this deeplink open that are the same as the current Intent
            Set<Integer> previousIntentHashCodes = lastIntentCodesForDeeplinks.get(deeplinkReceived);
            boolean differentThanPreviousIntent = false;
            // If we've never received an Intent for this deeplink before, it's a new deeplink open
            if (previousIntentHashCodes == null) {
                differentThanPreviousIntent = true;
            } else {
                // Iterate through the previous intents and look for a match
                for (Integer hashCode : previousIntentHashCodes) {
                    if (intent.hashCode() == hashCode) {
                        differentThanPreviousIntent = false;
                        break;
                    }
                    differentThanPreviousIntent = true;
                }
            }

            if (!launchedFromHistory && differentThanPreviousIntent) {
                // Add this Intent to the Set of received Intents for this deeplink url
                if (previousIntentHashCodes == null) {
                    previousIntentHashCodes = new HashSet<>();

                }
                previousIntentHashCodes.add(intent.hashCode());
                lastIntentCodesForDeeplinks.put(deeplinkReceived, previousIntentHashCodes);
                // Fire off a deeplink opened event to EventBus
                TuneEventBus.post(new TuneDeeplinkOpened(deeplinkReceived));
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
     * Helper function to track for Activity pauses.
     * You do not need to call this method directly unless you support API &lt; 14 and cannot leverage Tune's Application Lifecycle callbacks.
     * @param activity Activity that was paused. Should not be null.
     */
    public static void onPause(@NonNull Activity activity) {
        if (activity == null) {
            TuneDebugLog.e("WARNING: TuneActivity.onPause() called with null Activity");
            return;
        }

        TuneDebugLog.i(activity.getClass().getSimpleName(), "onPause()");

        weakLastActivity = null;

        TuneEventBus.post(new TuneActivityDisconnected(activity));
    }

    /**
     * Returns the last Activity that was resumed.
     * @return Last Activity that was resumed, and now visible.
     */
    public static Activity getLastActivity() {
        if (weakLastActivity == null) {
            return null;
        }
        return weakLastActivity.get();
    }
}
