package com.tune.application;

import android.app.Activity;
import android.content.Intent;
import android.support.annotation.NonNull;

import com.tune.Tune;
import com.tune.TuneDebugLog;
import com.tune.TuneInternal;

import java.util.Calendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Created by johng on 12/28/15.
 */
public class TuneActivity extends Activity {
    private static final Map<String, Set<Integer>> lastIntentCodesForDeeplinks = new HashMap<>();

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

        String deeplinkReceived = null;

        Intent intent = activity.getIntent();
        if (Tune.getInstance() != null && intent != null) {
            if (isDeeplinkIntent(intent)) {
                String uriString = intent.getDataString();
                TuneInternal.getInstance().setReferralCallingPackage(activity.getCallingPackage());
                Tune.getInstance().setReferralUrl(uriString);
                deeplinkReceived = uriString;
            }

            if (shouldMeasureSession(intent)) {
                TuneInternal.getInstance().measureSessionInternal();
            }
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
            }
        }
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

        final long timeLastMeasuredSession = TuneInternal.getInstance().getTimeLastMeasuredSession();
        final long eightHoursInMilliseconds = 28800000; // 8 * 60 * 60 * 1000
        final boolean lastMeasuredMoreThan8HoursAgo = timeLastMeasuredSession < System.currentTimeMillis() - eightHoursInMilliseconds;

        Calendar today = Calendar.getInstance();
        Calendar lastMeasuredSessionDate = Calendar.getInstance();
        lastMeasuredSessionDate.setTimeInMillis(TuneInternal.getInstance().getTimeLastMeasuredSession());
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
    }
}
