package com.tune.ma.connected;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

import com.tune.ma.TuneManager;
import com.tune.ma.deepactions.model.TuneDeepAction;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneConnectedModeTurnedOn;
import com.tune.ma.eventbus.event.TunePlaylistManagerCurrentPlaylistChanged;
import com.tune.ma.inapp.TuneInAppMessageManager;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.powerhooks.model.TunePowerHookValue;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Created by johng on 1/28/16.
 */
public class TuneConnectedModeManager {
    private static final String POWER_HOOKS_KEY = "power_hooks";
    private static final String DEEP_ACTIONS_KEY = "deep_actions";
    private static final String DEVICE_INFO_KEY = "device_info";

    private Context context;
    private boolean hasConnected;
    private ExecutorService executorService;

    public TuneConnectedModeManager(Context context) {
        this.context = context;
        this.executorService = Executors.newSingleThreadExecutor();
    }

    public synchronized void onEvent(TuneConnectedModeTurnedOn event) {
        // We saw connected was just turned on from server, so time to connect
        handleConnection();
    }

    public synchronized void onEvent(TuneAppBackgrounded event) {
        // If connected mode was on, disconnect
        if (isInConnectedMode()) {
            handleDisconnection();
        }
    }

    public synchronized void onEventMainThread(TunePlaylistManagerCurrentPlaylistChanged event) {
        if (isInConnectedMode()) {
            TunePlaylist playlist = event.getNewPlaylist();
            // If we're in connected mode, show any in-app messages immediately
            if (playlist.isFromConnectedMode()) {
                if (playlist.getInAppMessages().length() > 0) {
                    TuneInAppMessageManager messageManager = TuneManager.getInstance().getInAppMessageManager();
                    Map<String, TuneInAppMessage> messages = messageManager.getMessagesByIds();
                    // Exit if no messages
                    if (messages.size() == 0) {
                        return;
                    }
                    TuneInAppMessage message = messages.entrySet().iterator().next().getValue();
                    // Exit if message is currently visible
                    if (messageManager.isMessageCurrentlyShowing(message)) {
                        return;
                    }
                    message.display();
                }
            }
        }
    }

    public void handleConnection() {
        // Set local connected status to true
        setConnectedMode(true);
        // Show a toast to let user know they're connected
        showConnectedModeAlert();
        // Send connect signal to server
        sendConnectDeviceRequest();
        // Sync power hooks and deep actions
        sendSyncRequest();

        TuneManager.getInstance().getPlaylistManager().getConnectedPlaylist();
    }

    public void handleDisconnection() {
        // Set local connected status to false
        setConnectedMode(false);
        // Send disconnect signal to server
        sendDisconnectDeviceRequest();
    }

    public void showConnectedModeAlert() {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            public void run() {
                Toast.makeText(context, "Success! This device is now in connected mode.", Toast.LENGTH_LONG).show();
            }
        });
    }

    public void sendConnectDeviceRequest() {
        executorService.execute(new Connect());
    }

    public void sendDisconnectDeviceRequest() {
        executorService.execute(new Disconnect());
    }

    public void sendSyncRequest() {
        JSONArray powerHooksJson = new JSONArray();
        JSONArray deepActionsJson = new JSONArray();

        // Validate power hooks with default value and friendly names
        for (TunePowerHookValue powerHook : TuneManager.getInstance().getPowerHookManager().getPowerHookValues()) {
            if (powerHook.getDefaultValue() != null && powerHook.getFriendlyName() != null) {
                // Serialize valid TunePowerHookValues to JSON array
                powerHooksJson.put(powerHook.toJson());
            }
        }

        // Get deep actions from DeepActionManager
        List<TuneDeepAction> deepActions = TuneManager.getInstance().getDeepActionManager().getDeepActions();
        // Serialize deep actions to json array
        for (TuneDeepAction deepAction : deepActions) {
            deepActionsJson.put(deepAction.toJson());
        }

        // TODO: build device info JSON
        JSONObject deviceInfo = new JSONObject();


        // Build JSON to send in sync request
        JSONObject combined = new JSONObject();
        try {
            combined.put(POWER_HOOKS_KEY, powerHooksJson);
            combined.put(DEEP_ACTIONS_KEY, deepActionsJson);
            combined.put(DEVICE_INFO_KEY, deviceInfo);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        // Send sync http request in background
        executorService.execute(new Sync(combined));
    }

    public boolean isInConnectedMode() {
        return hasConnected;
    }

    public void setConnectedMode(boolean connected) {
        hasConnected = connected;
    }

    private class Connect implements Runnable {
        @Override
        public void run() {
            if (TuneManager.getInstance() != null) {
                TuneManager.getInstance().getApi().postConnect();
            }
        }
    }

    private class Disconnect implements Runnable {
        @Override
        public void run() {
            if (TuneManager.getInstance() != null) {
                TuneManager.getInstance().getApi().postDisconnect();
            }
        }
    }

    private class Sync implements Runnable {
        private JSONObject syncObject;

        public Sync(JSONObject syncObject) {
            this.syncObject = syncObject;
        }

        @Override
        public void run() {
            if (TuneManager.getInstance() != null) {
                TuneManager.getInstance().getApi().postSync(syncObject);
            }
        }
    }
}
