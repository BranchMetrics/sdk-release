package com.tune.ma.deepactions;

import android.app.Activity;

import com.tune.ma.deepactions.model.TuneDeepAction;
import com.tune.ma.eventbus.event.deepaction.TuneDeepActionCalled;
import com.tune.ma.model.TuneDeepActionCallback;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneStringUtils;

import org.greenrobot.eventbus.Subscribe;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by willb on 1/28/16.
 */
public class TuneDeepActionManager {

    private Map<String, TuneDeepAction> actionMap;

    public TuneDeepActionManager() {
        this.actionMap = new HashMap<>();
    }

    public synchronized void registerDeepAction(String actionId, String friendlyName, String description, Map<String, String> defaultData, Map<String, List<String>> approvedValues, TuneDeepActionCallback action) {
        if (actionId == null || friendlyName == null || defaultData == null || action == null) {
            TuneDebugLog.IAMConfigError("TUNE Deep Action IDs, friendly names, default data, and action cannot be null. This registration (actionId:" + actionId + "friendlyName:" + friendlyName + ") will be ignored.");
            return;
        }

        String scrubbedActionId = TuneStringUtils.scrubStringForMongo(actionId);

        if (this.actionMap.get(scrubbedActionId) != null) {
            TuneDebugLog.IAMConfigError("You can not register two Deep Actions with the same Action ID.");
            return;
        }

        this.actionMap.put(scrubbedActionId, new TuneDeepAction(actionId, friendlyName, description, defaultData, approvedValues, action));
    }

    public synchronized TuneDeepAction getDeepAction(String actionId) {
        String scrubbedActionId = TuneStringUtils.scrubStringForMongo(actionId);
        return this.actionMap.get(scrubbedActionId);
    }

    public synchronized List<TuneDeepAction> getDeepActions() {
        if (this.actionMap == null) {
            return null;
        }
        return new ArrayList<TuneDeepAction>(this.actionMap.values());
    }

    public synchronized void clearDeepActions() {
        this.actionMap = new HashMap<String, TuneDeepAction>();
    }

    public void executeDeepAction(Activity activity, String actionId, Map<String, String> data) {
        String scrubbedActionId = TuneStringUtils.scrubStringForMongo(actionId);
        TuneDeepAction action = getDeepAction(scrubbedActionId);
        if (action == null) {
            TuneDebugLog.e(TuneStringUtils.format("Could not execute DeepAction with id %s because it was not registered. Make sure to register your Deep Actions in Application#onCreate.", actionId));
            return;
        }
        Map<String, String> extraData = new HashMap<String, String>();
        // The defaultData should never be null
        for (Map.Entry<String, String> e : action.getDefaultData().entrySet()) {
            extraData.put(e.getKey(), e.getValue());
        }
        if (data != null) {
            for (Map.Entry<String, String> e : data.entrySet()) {
                extraData.put(e.getKey(), e.getValue());
            }
        }
        action.getAction().execute(activity, extraData);
    }

    @Subscribe
    public void onEvent(TuneDeepActionCalled event) {
        executeDeepAction(event.getActivity(), event.getDeepActionId(), event.getDeepActionParams());
    }
}
