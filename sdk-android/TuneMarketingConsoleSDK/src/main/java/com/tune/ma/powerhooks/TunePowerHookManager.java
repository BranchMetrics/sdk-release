package com.tune.ma.powerhooks;

import com.tune.TuneDebugLog;
import com.tune.ma.model.TuneCallback;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.powerhooks.model.TunePowerHookValue;
import com.tune.ma.utils.TuneJsonUtils;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Created by gowie on 1/25/16.
 */
public class TunePowerHookManager {

    private Map<String, TunePowerHookValue> phookHash;
    private TuneCallback callback;
    private ExecutorService executorService;

    /**
     * Set of Power Hook IDs explicitly registered by the user.
     */
    private Set<String> userRegisteredPowerHooks;

    public TunePowerHookManager() {
        phookHash = new HashMap<String, TunePowerHookValue>();
        callback = null;
        userRegisteredPowerHooks = new HashSet<String>();
        this.executorService = Executors.newSingleThreadExecutor();
    }

    // Updating From Playlist
    //////////////////////////

    public void updatePowerHooksFromPlaylist(TunePlaylist playlist) {
        // TODO: Check disabled

        boolean notifyPowerHooksChanged = false;

        JSONObject phookJson = playlist.getPowerHooks();
        if (phookJson == null) {
            return;
        }

        Iterator<String> phookIds = phookJson.keys();
        while (phookIds.hasNext()) {
            String hookId = phookIds.next();

            if (this.mergeInPlaylistPowerHook(hookId, TuneJsonUtils.getJSONObject(phookJson, hookId))) {
                notifyPowerHooksChanged = true;
            }
        }

        if (!playlist.isFromDisk() && notifyPowerHooksChanged) {
            this.executeOnPowerHooksChangedBlocks();
        }
    }

    private boolean mergeInPlaylistPowerHook(String hookId, JSONObject json) {
        boolean notifyChange = false;

        TunePowerHookValue existingPhook = getPowerHookValue(hookId);
        TunePowerHookValue newPhook = null;
        if (existingPhook != null) {

            try {
                newPhook = existingPhook.clone();
                newPhook.mergeWithPlaylistJson(json);

                phookHash.put(hookId, newPhook);

                // If the values are not equal send a notification out that the Phook has changed
                if (!newPhook.getValue().equals(existingPhook.getValue())) {
                    notifyChange = true;
                }
            } catch (CloneNotSupportedException e) {
                e.printStackTrace();
                TuneDebugLog.e("Failed to clone existingPhook: " + existingPhook.getHookId());
            }
        } else {

            // No Power Hook with this hookId has been registered yet. This is either due to the customer
            // removing the Power Hook from their App (fine to register since they won't use) or we're loading
            // this playlist from disk and the Application#registerPowerHooks call hasn't happened yet.
            newPhook = new TunePowerHookValue();
            newPhook.setHookId(hookId);
            newPhook.mergeWithPlaylistJson(json);
            phookHash.put(hookId, newPhook);

            notifyChange = false;
        }

        return notifyChange;
    }

    private void executeOnPowerHooksChangedBlocks() {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                if (callback != null) {
                    callback.execute();
                }
            }
        });
    }

    // Public API
    //////////////

    public synchronized void registerPowerHook(String hookId, String friendlyName, String defaultValue, String description, List<String> approvedValues) {
        if (hookId == null || friendlyName == null || defaultValue == null) {
            TuneDebugLog.IAMConfigError("TUNE Power Hook IDs, friendly names and default values cannot be null. This registration " +
                    "(hookId:" + hookId + ", friendlyName:" + friendlyName + ", defaultValue: " + defaultValue + ") will be ignored.");
            return;
        }

        String scrubbedHookId = TuneStringUtils.scrubStringForMongo(hookId);

        // do not allow an existing Power Hook ID to be overwritten
        if (userRegisteredPowerHooks.contains(scrubbedHookId)) {
            TuneDebugLog.IAMConfigError("Invalid attempt to overwrite a previously registered Power Hook for hook ID \"" + hookId + "\".");
        } else {
            userRegisteredPowerHooks.add(scrubbedHookId);

            TunePowerHookValue existingPowerHook = getPowerHookValue(hookId);
            if (existingPowerHook != null) {
                existingPowerHook.setFriendlyName(friendlyName);
                existingPowerHook.setDefaultValue(defaultValue);
                existingPowerHook.setDescription(description);
                existingPowerHook.setApprovedValues(approvedValues);
            } else {
                phookHash.put(scrubbedHookId, new TunePowerHookValue(scrubbedHookId, friendlyName, defaultValue, description, approvedValues));
            }
        }
    }

    public synchronized String getValueForHookById(String hookId) {
        String scrubbedHookId = TuneStringUtils.scrubStringForMongo(hookId);
        TunePowerHookValue phookValue = phookHash.get(scrubbedHookId);

        if (phookValue == null) {
            TuneDebugLog.IAMConfigError("No Power Hook was registered with the given Hook ID: " + hookId);
            return null;
        } else {
            return phookValue.getValue();
        }
    }

    public synchronized void setValueForHookById(String hookId, String value) {
        TunePowerHookValue phookValue = getPowerHookValue(hookId);

        if (phookValue == null) {
            TuneDebugLog.IAMConfigError("No Power Hook was registered with the given Hook ID: " + hookId);
        } else {
            phookValue.setValue(value);
        }
    }

    public synchronized void onPowerHooksChanged(TuneCallback callback) {
        this.callback = callback;
    }

    public synchronized List<TunePowerHookValue> getPowerHookValues() {
        List<TunePowerHookValue> values = new ArrayList<TunePowerHookValue>();
        for (Map.Entry<String, TunePowerHookValue> entry: phookHash.entrySet()) {
            values.add(entry.getValue());
        }
        return values;
    }

    // Helpers
    ///////////

    private TunePowerHookValue getPowerHookValue(String hookId) {
        String scrubbedHookId = TuneStringUtils.scrubStringForMongo(hookId);
        TunePowerHookValue phookValue = phookHash.get(scrubbedHookId);
        return phookValue;
    }

    protected Map<String, TunePowerHookValue> getPowerHooks() {
        return new HashMap<String, TunePowerHookValue>(phookHash);
    }

    protected void clearPowerHooks() {
        phookHash = new HashMap<String, TunePowerHookValue>();
    }

    // package private
    void setExecutorService(ExecutorService executorService) {
        this.executorService = executorService;
    }
}
