package com.tune.ma.configuration;

import android.content.Context;

import com.tune.TuneConstants;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneConnectedModeTurnedOn;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneJsonUtils;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * Created by kristine on 1/20/16.
 */
public class TuneConfigurationManager {
    private static final String CONNECTED_MODE_ON = "1";

    private boolean debugLoggingOn;
    private boolean debugMode;

    private String playlistHostPort;
    private String configurationHostPort;
    private String analyticsHostPort;
    private String connectedModeHostPort;
    private String staticContentHostPort;

    private boolean echoAnalytics;
    private boolean echoFiveline;
    private boolean echoPlaylists;
    private boolean echoConfigurations;
    private boolean echoPushes;
    private boolean usePlaylistPlayer;
    private List<String> playlistPlayerFilenames;
    private boolean useConfigurationPlayer;
    private List<String> configurationPlayerFilenames;

    private boolean enabledTMA;
    private boolean gotFirstConfiguration;

    private boolean shouldAutoCollectDeviceLocation;
    private boolean shouldSendScreenViews;
    private boolean pollForPlaylist;

    //analytics properties
    private int analyticsDispatchPeriod;
    private int analyticsMessageStorageLimit;
    private int playlistRequestPeriod;

    private List<String> PIIFiltersAsStrings;
    private List<Pattern> PIIFiltersAsPatterns;
    private String pluginName;

    TuneSharedPrefsDelegate sharedPrefs;
    ExecutorService executorService;


    public TuneConfigurationManager(Context context, TuneConfiguration localConfig) {
        this.sharedPrefs = new TuneSharedPrefsDelegate(context, TuneConstants.PREFS_TUNE);

        if (localConfig == null) {
            //create TuneConfiguration object to get defaults
            localConfig = new TuneConfiguration();
        }
        setupConfiguration(localConfig);

        executorService = Executors.newSingleThreadExecutor();
    }

    public void onEvent(TuneAppForegrounded event) {
        // Update configuration from app foreground event only if TMA is enabled
        // as configuration update will be handled from TuneActivity.onStart if disabled
        if (!isTMADisabled()) {
            updateConfigurationFromServer();
        }
    }

    public void setupConfiguration(TuneConfiguration configuration) {
        JSONObject storedConfig = TuneManager.getInstance().getFileManager().readConfiguration();

        if (storedConfig != null) {
            updateConfigurationFromTuneConfigurationObject(configuration);
            updateConfigurationFromJson(storedConfig);
        } else {
            updateConfigurationFromTuneConfigurationObject(configuration);
        }
    }

    public void getConfigurationIfDisabled() {
        if (isTMADisabled() && !isTMAPermanentlyDisabled() && !gotFirstConfiguration) {
            updateConfigurationFromServer();
        }
    }

    private static class GetConfigurationTask implements Runnable {
        TuneConfigurationManager tuneConfiguration;
        public GetConfigurationTask(TuneConfigurationManager tuneConfiguration) {
            this.tuneConfiguration = tuneConfiguration;
        }

        @Override
        public void run() {
            JSONObject response = TuneManager.getInstance().getApi().getConfiguration();
            if (response == null) {
                TuneDebugLog.w("Configuration response did not have any JSON");
            } else if (response.length() == 0) {
                /*
                 *  IMPORTANT:
                 *     An empty configuration is a signal from the server to not process anything
                 */

                TuneDebugLog.w("Received empty configuration from the server -- not updating");
            } else {
                if (tuneConfiguration.echoConfigurations) {
                    TuneDebugLog.alwaysLog("Got configuration:\n" + TuneJsonUtils.getPrettyJson(response));
                }
                TuneManager.getInstance().getFileManager().writeConfiguration(response);
                tuneConfiguration.updateConfigurationFromRemoteJson(response);
            }
        }
    }

    public synchronized void updateConfigurationFromTuneConfigurationObject(TuneConfiguration config) {
        analyticsDispatchPeriod = config.getAnalyticsDispatchPeriod();
        analyticsMessageStorageLimit = config.getAnalyticsMessageStorageLimit();
        playlistRequestPeriod = config.getPlaylistRequestPeriod();
        shouldAutoCollectDeviceLocation = config.shouldAutoCollectDeviceLocation();
        shouldSendScreenViews = config.shouldSendScreenViews();
        pollForPlaylist = config.getPollForPlaylist();
        echoAnalytics = config.echoAnalytics();
        echoPlaylists = config.echoPlaylists();
        echoConfigurations = config.echoConfigurations();
        echoFiveline = config.echoFiveline();
        echoPushes = config.echoPushes();
        PIIFiltersAsStrings = config.getPIIFiltersAsStrings();
        buildPIIFiltersAsPatterns();

        debugLoggingOn = config.debugLoggingOn();
        if (debugLoggingOn) {
            TuneDebugLog.enableLog();
            TuneDebugLog.setLogLevel(TuneDebugLog.DEBUG);
        }
        debugMode = config.debugMode(); //TODO Show an alert if debug mode is enabled?
        playlistHostPort = config.getPlaylistHostPort();
        configurationHostPort = config.getConfigurationHostPort();
        analyticsHostPort = config.getAnalyticsHostPort();
        connectedModeHostPort = config.getConnectedModeHostPort();
        staticContentHostPort = config.getStaticContentHostPort();
        usePlaylistPlayer = config.usePlaylistPlayer();
        playlistPlayerFilenames = config.getPlaylistPlayerFilenames();
        useConfigurationPlayer = config.useConfigurationPlayer();
        configurationPlayerFilenames = config.getConfigurationPlayerFilenames();
    }

    public synchronized void updateConfigurationFromJson(JSONObject configuration) {
        try {
            if (configuration.has(TuneConfigurationConstants.TUNE_ANALYTICS_DISPATCH_PERIOD)) {
                analyticsDispatchPeriod = configuration.getInt(TuneConfigurationConstants.TUNE_ANALYTICS_DISPATCH_PERIOD);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_ANALYTICS_MESSAGE_LIMIT)) {
                analyticsMessageStorageLimit = configuration.getInt(TuneConfigurationConstants.TUNE_ANALYTICS_MESSAGE_LIMIT);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_PLAYLIST_REQUEST_PERIOD)) {
                playlistRequestPeriod = configuration.getInt(TuneConfigurationConstants.TUNE_PLAYLIST_REQUEST_PERIOD);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_KEY_AUTOCOLLECT_LOCATION)) {
                shouldAutoCollectDeviceLocation = configuration.getBoolean(TuneConfigurationConstants.TUNE_KEY_AUTOCOLLECT_LOCATION);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_KEY_ECHO_ANALYTICS)) {
                echoAnalytics = configuration.getBoolean(TuneConfigurationConstants.TUNE_KEY_ECHO_ANALYTICS);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_KEY_ECHO_PLAYLISTS)) {
                echoPlaylists = configuration.getBoolean(TuneConfigurationConstants.TUNE_KEY_ECHO_PLAYLISTS);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_KEY_ECHO_CONFIGURATIONS)) {
                echoConfigurations = configuration.getBoolean(TuneConfigurationConstants.TUNE_KEY_ECHO_CONFIGURATIONS);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_KEY_ECHO_FIVELINE)) {
                echoFiveline = configuration.getBoolean(TuneConfigurationConstants.TUNE_KEY_ECHO_FIVELINE);
            }
            if (configuration.has(TuneConfigurationConstants.TUNE_TMA_PII_FILTERS_STRING)) {
                JSONArray jsonArray = configuration.getJSONArray(TuneConfigurationConstants.TUNE_TMA_PII_FILTERS_STRING);
                PIIFiltersAsStrings = TuneJsonUtils.JSONArrayToStringArrayList(jsonArray);
                buildPIIFiltersAsPatterns();
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public synchronized void updateConfigurationFromRemoteJson(JSONObject configuration) {
        updateConfigurationFromJson(configuration);

        updateConnectedModeState(configuration);

        // We only want to change these settings if it is not permanently disabled -- it is permanent after all
        //     Additionally, don't update the enabled/disabled status if we are in connected mode since going into
        //     connected mode affects the enabled/disabled status
        if (!isTMAPermanentlyDisabled()) {
            updatePermanentlyDisabledState(configuration);
            updateDisabledState(configuration);
        }
    }

    public synchronized void updateConfigurationFromServer() {
        // Unlike most downloads we actually *do* want to download the configuration if Tune is off (inactive but not permakilled)
        if (isTMAPermanentlyDisabled()) {
            return;
        }

        gotFirstConfiguration = true;

        if (useConfigurationPlayer) {
            JSONObject configuration = TuneManager.getInstance().getConfigurationPlayer().getNext();
            updateConfigurationFromRemoteJson(configuration);
            if (echoConfigurations) {
                TuneDebugLog.alwaysLog("Got configuration from configuration player:\n" + TuneJsonUtils.getPrettyJson(configuration));
            }
        } else {
            executorService.execute(new GetConfigurationTask(this));
        }
    }

    public void buildPIIFiltersAsPatterns() {
        ArrayList<Pattern> filtersAsPatterns = new ArrayList<Pattern>();
        for (String pattern: PIIFiltersAsStrings) {
            try {
                Pattern p = Pattern.compile(pattern, Pattern.CASE_INSENSITIVE);
                filtersAsPatterns.add(p);
            } catch (PatternSyntaxException e) {
                e.printStackTrace();
                TuneDebugLog.e("Exception parsing " + TuneConfigurationConstants.TUNE_TMA_PII_FILTERS_STRING + " filter: " + pattern);
            }
        }
        PIIFiltersAsPatterns = filtersAsPatterns;
    }

    public void updateConnectedModeState(JSONObject config) {
        // connected_mode is sent as string "1" or "0" from server
        boolean newConnectedModeStatus = CONNECTED_MODE_ON.equals(config.optString(TuneConfigurationConstants.TUNE_TMA_CONNECTED_MODE));
        // If connected mode is true in the config and not true in our manager, then it was just turned on
        if (newConnectedModeStatus && !TuneManager.getInstance().getConnectedModeManager().isInConnectedMode()) {
            TuneEventBus.post(new TuneConnectedModeTurnedOn());
        }
    }

    public void updateDisabledState(JSONObject config) {
        try {
            if (config.has(TuneConfigurationConstants.TUNE_TMA_DISABLED)) {
                boolean newDisabledState = config.getBoolean(TuneConfigurationConstants.TUNE_TMA_DISABLED);
                sharedPrefs.saveBooleanToSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED, newDisabledState);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void updatePermanentlyDisabledState(JSONObject config) {
        try {
            if (config.has(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED)) {
                if (config.getBoolean(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED)) {
                    //Shut everything down forever on the next session
                    sharedPrefs.saveBooleanToSharedPreferences(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED, true);
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public boolean isTMADisabled() {
        if (isTMAPermanentlyDisabled()) {
            return true;
        }
        return sharedPrefs.getBooleanFromSharedPreferences(TuneConfigurationConstants.TUNE_TMA_DISABLED, false);
    }

    public boolean isTMAPermanentlyDisabled() {
        return sharedPrefs.getBooleanFromSharedPreferences(TuneConfigurationConstants.TUNE_TMA_PERMANENTLY_DISABLED);

    }

    // Getters

    public boolean debugLoggingOn() {
        return debugLoggingOn;
    }

    public boolean debugMode() {
        return debugMode;
    }

    public String getPlaylistHostPort() {
        return playlistHostPort;
    }

    public String getConfigurationHostPort() {
        return configurationHostPort;
    }

    public String getAnalyticsHostPort() {
        return analyticsHostPort;
    }

    public String getConnectedModeHostPort() {
        return connectedModeHostPort;
    }

    public String getStaticContentHostPort() {
        return staticContentHostPort;
    }

    public boolean echoAnalytics() {
        return echoAnalytics;
    }

    public boolean echoFiveline() {
        return echoFiveline;
    }

    public boolean echoPlaylists() {
        return echoPlaylists;
    }

    public boolean echoConfigurations() {
        return echoConfigurations;
    }

    public boolean echoPushes() {
        return echoPushes;
    }

    public boolean usePlaylistPlayer() {
        return usePlaylistPlayer;
    }

    public List<String> getPlaylistPlayerFilenames() {
        return playlistPlayerFilenames;
    }

    public boolean useConfigurationPlayer() {
        return useConfigurationPlayer;
    }

    public List<String> getConfigurationPlayerFilenames() {
        return configurationPlayerFilenames;
    }

    public boolean shouldAutoCollectDeviceLocation() {
        return shouldAutoCollectDeviceLocation;
    }

    public boolean shouldSendScreenViews() {
        return shouldSendScreenViews;
    }

    public boolean getPollForPlaylist() {
        return pollForPlaylist;
    }

    public int getAnalyticsDispatchPeriod() {
        return analyticsDispatchPeriod;
    }

    public int getAnalyticsMessageStorageLimit() {
        return analyticsMessageStorageLimit;
    }

    public int getPlaylistRequestPeriod() {
        return playlistRequestPeriod;
    }

    public List<Pattern> getPIIFiltersAsPatterns() {
        return PIIFiltersAsPatterns;
    }

    public String getPluginName() {
        return pluginName;
    }

    public String getApiVersion() {
        return TuneConstants.IAM_API_VERSION;
    }
}
