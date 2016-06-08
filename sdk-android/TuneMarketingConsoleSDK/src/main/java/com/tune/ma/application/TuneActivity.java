package com.tune.ma.application;

import android.app.Activity;
import android.os.Build;

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
     * Helper function to listen for Activity starts
     * @param activity Activity that was started
     */
    public static void onStart(Activity activity) {
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
     * Helper function to measure opens in Activity onResume
     * @param activity Activity that was opened
     */
    public static void onResume(Activity activity) {
        TuneDebugLog.i(activity.getClass().getSimpleName(), "onResume()");

        // Get just the original activity name
        String[] splitName = activity.getClass().getSimpleName().split("TuneActivity");
        TuneEventBus.post(new TuneActivityResumed(splitName[0]));
    }

    /**
     * Helper function to listen for Activity stops
     * @param activity Activity that was stopped
     */
    public static void onStop(Activity activity) {
        TuneDebugLog.i(activity.getClass().getSimpleName(), "onStop()");

        TuneEventBus.post(new TuneActivityDisconnected(activity));
    }
}
