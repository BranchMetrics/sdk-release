package com.tune.ma.push.settings;

import org.json.JSONObject;

/**
 * Interface class that can be implemented to access extraPushPayload from a Tune Push Message and decide if a notification should be displayed.
 *
 */
public interface TunePushListener {

    /**
     * Implement this method to access a Tune Push Message's extraPushPayload and choose not to display a notification if necessary.
     *
     * @param isSilentPush whether the push is a silent push
     * @param extraPushPayload the extra json passed in the push request
     * @return true if a notification should be displayed, false otherwise
     */
    boolean onReceive(boolean isSilentPush, JSONObject extraPushPayload);
}
