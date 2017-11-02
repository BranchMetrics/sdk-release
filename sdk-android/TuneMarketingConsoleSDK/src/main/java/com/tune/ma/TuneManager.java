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
import com.tune.ma.eventbus.event.TuneManagerInitialized;
import com.tune.ma.experiments.TuneExperimentManager;
import com.tune.ma.file.FileManager;
import com.tune.ma.file.TuneFileManager;
import com.tune.ma.inapp.TuneInAppMessageManager;
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
    private TuneInAppMessageManager inAppMessageManager;

    private static TuneManager instance = null;

    private TuneManager() {
    }

    public static TuneManager init(Context context, TuneConfiguration configuration) {

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
            instance.inAppMessageManager = new TuneInAppMessageManager(context);

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
                // PRIORITY_FIRST
                TuneEventBus.register(instance.campaignStateManager)
                ;
                // Session needs priority over analytics in order to start session
                // PRIORITY_SECOND
                TuneEventBus.register(instance.sessionManager);

                // User profile needs priority over analytics so that the session variables are updated correctly first
                // PRIORITY_THIRD
                TuneEventBus.register(instance.profileManager);

                // Get configuration before playlist so we know about connected mode
                // PRIORITY_FOURTH
                TuneEventBus.register(instance.configurationManager);

                // We want playlist next in priority so we can get it as soon as possible
                // PRIORITY_FIFTH
                TuneEventBus.register(instance.playlistManager);

                // In-app message manager needs priority over connected mode so we can get in-app messages ready to be shown in connected mode
                // PRIORITY_SIXTH
                TuneEventBus.register(instance.inAppMessageManager);

                // The following are either PRIORITY_IRRELEVANT or DEFAULT
                TuneEventBus.register(instance.analyticsManager);
                TuneEventBus.register(instance.connectedModeManager);
                TuneEventBus.register(instance.deepActionManager);
                TuneEventBus.register(instance.experimentManager);
                TuneEventBus.register(instance.pushManager);


                // After everything has been registered, post that the TuneManager is initialized
                TuneEventBus.post(new TuneManagerInitialized());
            } else {
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
            TuneEventBus.unregister(instance.inAppMessageManager);
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

    public TuneInAppMessageManager getInAppMessageManager() {
        return inAppMessageManager;
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

    public static TuneInAppMessageManager getInAppMessageManagerForUser(String methodName) {
        if (getInstance() == null || getInstance().getInAppMessageManager() == null) {
            handleError(methodName);
            return null;
        }

        return getInstance().getInAppMessageManager();
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
