package com.tune.ma;

import android.content.Context;

import com.tune.Tune;
import com.tune.http.Api;
import com.tune.http.TuneApi;
import com.tune.ma.analytics.TuneAnalyticsManager;
import com.tune.ma.campaign.TuneCampaignStateManager;
import com.tune.ma.configuration.TuneConfiguration;
import com.tune.ma.configuration.TuneConfigurationManager;
import com.tune.ma.connected.TuneConnectedModeManager;
import com.tune.ma.deepactions.TuneDeepActionManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneManagerInitialized;
import com.tune.ma.experiments.TuneExperimentManager;
import com.tune.ma.file.FileManager;
import com.tune.ma.file.TuneFileManager;
import com.tune.ma.playlist.TunePlaylistManager;
import com.tune.ma.powerhooks.TunePowerHookManager;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.push.TunePushManager;
import com.tune.ma.session.TuneSessionManager;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneJSONPlayer;
import com.tune.ma.utils.TuneStringUtils;

/**
 * Created by johng on 1/20/16.
 */
public class TuneManager {
    private TuneAnalyticsManager analyticsManager;
    private TuneUserProfile profileManager;
    private TuneSessionManager sessionManager;
    private TuneConfigurationManager configurationManager;
    private TuneConnectedModeManager connectedModeManager;
    private TunePowerHookManager powerHookManager;
    private TunePlaylistManager playlistManager;
    private FileManager fileManager;
    private Api api;
    private TuneDeepActionManager deepActionManager;
    private TunePushManager pushManager;
    private TuneCampaignStateManager campaignStateManager;
    private TuneJSONPlayer configurationPlayer;
    private TuneJSONPlayer playlistPlayer;
    private TuneExperimentManager experimentManager;

    private static TuneManager instance = null;

    private TuneManager() {
    }

    public static TuneManager init(Context context, TuneConfiguration configuration) {
//        if (ArtisanManager.ARTISAN_PERMANENTLY_DISABLED) {
//            return;
//        }
        if (instance == null) {
            instance = new TuneManager();
            // We need the filemanager to init the ConfigurationManager
            instance.fileManager = new TuneFileManager(context);
            instance.api = new TuneApi();
            instance.configurationManager = new TuneConfigurationManager(context, configuration);
            if (instance.configurationManager.useConfigurationPlayer()) {
                TuneJSONPlayer configurationPlayer = new TuneJSONPlayer(context);
                configurationPlayer.setFiles(instance.configurationManager.getConfigurationPlayerFilenames());
                instance.configurationPlayer = configurationPlayer;
            }

            // WARNING: We need the following managers spun up even if we are disabled because the user
            //          can potentially interact with them through the Tune.java API.  I decided against
            //          adding the logic for handling what happens if we are disabled to Tune.java because
            //          of delegation of responsibility. Consider the 'onFirstPlaylistDownloadCallback' which
            //          has non-trivial logic -- we don't want to split logic for handling it between Tune.java
            //          and TunePlaylistManager.java.
            instance.powerHookManager = new TunePowerHookManager();
            instance.profileManager = new TuneUserProfile(context);
            instance.playlistManager = new TunePlaylistManager();
            instance.experimentManager = new TuneExperimentManager();

            if (!instance.configurationManager.isTMADisabled()) {
                instance.sessionManager = TuneSessionManager.init(context);
                instance.analyticsManager = new TuneAnalyticsManager(context);
                instance.connectedModeManager = new TuneConnectedModeManager(context);
                instance.deepActionManager = new TuneDeepActionManager();
                instance.pushManager = new TunePushManager(context);
                instance.campaignStateManager = new TuneCampaignStateManager(context);

                if (instance.configurationManager.usePlaylistPlayer()) {
                    TuneJSONPlayer playlistPlayer = new TuneJSONPlayer(context);
                    playlistPlayer.setFiles(instance.configurationManager.getPlaylistPlayerFilenames());
                    instance.playlistPlayer = playlistPlayer;
                }

                // Campaign state needs the highest priority because it sets session variables at the start of each session
                TuneEventBus.register(instance.campaignStateManager, TuneEventBus.PRIORITY_FIRST);
                // Session needs priority over analytics in order to start session
                TuneEventBus.register(instance.sessionManager, TuneEventBus.PRIORITY_SECOND);
                // User profile needs priority over analytics so that the session variables are updated correctly first
                TuneEventBus.register(instance.profileManager, TuneEventBus.PRIORITY_THIRD);

                TuneEventBus.register(instance.analyticsManager, TuneEventBus.PRIORITY_IRRELEVANT);
                TuneEventBus.register(instance.configurationManager, TuneEventBus.PRIORITY_IRRELEVANT);
                TuneEventBus.register(instance.connectedModeManager, TuneEventBus.PRIORITY_IRRELEVANT);
                TuneEventBus.register(instance.playlistManager, TuneEventBus.PRIORITY_IRRELEVANT);
                TuneEventBus.register(instance.deepActionManager);
                TuneEventBus.register(instance.powerHookManager, TuneEventBus.PRIORITY_IRRELEVANT);
                TuneEventBus.register(instance.experimentManager, TuneEventBus.PRIORITY_IRRELEVANT);
                TuneEventBus.register(instance.pushManager);

                // After everything has been registered, post that the TuneManager is initialized
                TuneEventBus.post(new TuneManagerInitialized());
            } else {
                if (!instance.getConfigurationManager().isTMAPermanentlyDisabled()) {
                    // When we are disabled, but not permanently disabled, we still want to see if we should become enabled again.
                    instance.configurationManager.onEvent(new TuneAppForegrounded("not used", 1L));
                }
                // If we are off then we aren't going to be using the eventbus at all.
                TuneEventBus.disable();
            }
        }
        return instance;
    }

    public static void destroy() {
        if (instance != null) {
            TuneEventBus.unregister(instance.campaignStateManager);
            TuneEventBus.unregister(instance.sessionManager);
            TuneEventBus.unregister(instance.analyticsManager);
            TuneEventBus.unregister(instance.configurationManager);
            TuneEventBus.unregister(instance.connectedModeManager);
            TuneEventBus.unregister(instance.profileManager);
            TuneEventBus.unregister(instance.playlistManager);
            TuneEventBus.unregister(instance.powerHookManager);
            TuneEventBus.unregister(instance.deepActionManager);
            TuneEventBus.unregister(instance.experimentManager);
            TuneEventBus.unregister(instance.pushManager);
        }
        instance = null;
    }

    public static TuneManager getInstance() {
        return instance;
    }

    public Api getApi() {
        return api;
    }

    public void setApi(Api api) {
        this.api = api;
    }

    public TuneAnalyticsManager getAnalyticsManager() {
        return analyticsManager;
    }

    public TuneUserProfile getProfileManager() {
        return profileManager;
    }

    public TuneSessionManager getSessionManager() {
        return sessionManager;
    }

    public void setFileManager(FileManager fileManager) {
        this.fileManager = fileManager;
    }

    public FileManager getFileManager() {
        return fileManager;
    }

    public TunePlaylistManager getPlaylistManager() {
        return playlistManager;
    }

    public TuneConfigurationManager getConfigurationManager() {
        return configurationManager;
    }

    public TuneConnectedModeManager getConnectedModeManager() {
        return connectedModeManager;
    }

    public TunePowerHookManager getPowerHookManager() {
        return powerHookManager;
    }

    public TuneDeepActionManager getDeepActionManager() {
        return deepActionManager;
    }

    public TunePushManager getPushManager() {
        return pushManager;
    }

    public TuneJSONPlayer getConfigurationPlayer() {
        return configurationPlayer;
    }

    public TuneJSONPlayer getPlaylistPlayer() {
        return playlistPlayer;
    }

    public TuneExperimentManager getExperimentManager() {
        return experimentManager;
    }

    /*
     * NOTE: The following methods are helpers for checking if IAM in enabled when the user calls a IAM only method.
     */

    public static TunePowerHookManager getPowerHookManagerForUser(String methodName) {
        if (getInstance() == null || getInstance().getPowerHookManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getPowerHookManager();
    }

    public static TuneDeepActionManager getDeepActionManagerForUser(String methodName) {
        if (getInstance() == null || getInstance().getDeepActionManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getDeepActionManager();
    }

    public static TuneExperimentManager getExperimentManagerForUser(String methodName) {
        if (getInstance() == null || getInstance().getExperimentManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getExperimentManager();
    }

    public static TunePlaylistManager getPlaylistManagerForUser(String methodName) {
        if (getInstance() == null || getInstance().getPlaylistManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getPlaylistManager();
    }

    public static TuneUserProfile getProfileForUser(String methodName) {
        if (getInstance() == null || getInstance().getProfileManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getProfileManager();
    }

    public static TunePushManager getPushManagerForUser(String methodName) {
        if (getInstance() == null || getInstance().getPushManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getPushManager();
    }

    public static void handleError(String methodName) {
        String message = TuneStringUtils.format("In order to use the method '%s' you must have IAM enabled. See: https://developers.mobileapptracking.com/requirements-for-in-app-marketing/", methodName);
        if (Tune.getInstance().isInDebugMode()) {
            throw new TuneIAMNotEnabledException(message);
        } else {
            TuneDebugLog.e(message);
        }
    }
}
