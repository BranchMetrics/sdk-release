package com.tune;

import android.content.Context;

import com.tune.location.TuneLocationListener;
import com.tune.ma.TuneManager;
import com.tune.ma.configuration.TuneConfiguration;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class TuneTestWrapper extends Tune {
    // copied from TuneConstants
    private static final String PREFS_LOG_ID_OPEN = "mat_log_id_open";
    private static final String PREFS_TUNE = "com.mobileapptracking";
    
    private static boolean online = false; //true;
    
    private static TuneTestWrapper tune = null;
    
    public TuneTestWrapper() {
        super();
    }
    
    public static TuneTestWrapper init(final Context context, final String advertiserId, final String key) {
        TuneEventBus.disable();
        TuneEventBus.enable();
        TuneConfiguration initialConfig = new TuneConfiguration();
        // initialize TuneManager with useConfiguration set to true so that it initializes configuration player
        ArrayList<String> configurationPlayerFilenames = new ArrayList<>();
        configurationPlayerFilenames.add("configuration1.json");
        configurationPlayerFilenames.add("configuration2.json");
        initialConfig.setUseConfigurationPlayer(true);
        initialConfig.setConfigurationPlayerFilenames(configurationPlayerFilenames);
        initialConfig.setShouldSendScreenViews(true);

        tune = new TuneTestWrapper();
        Tune.initAll(tune, context, advertiserId, key, true, initialConfig);

        tune.locationListener = new TuneLocationListener(context);
        tune.eventQueue = new TuneTestQueue(context, tune);

        tune.setShouldAutoCollectDeviceLocation(false);
        tune.setPackageName(TuneTestConstants.appId);
        tune.setAdvertiserId(TuneTestConstants.advertiserId);

        // update it after initialization because remote config takes priority, so it would overwrite analyticsDispatchPeriod
        TuneManager.getInstance().getConfigurationManager().updateConfigurationFromTuneConfigurationObject(getTestingConfig(configurationPlayerFilenames));
        
        // make fake open id
        String logId = "1234567812345678-201401-" + TuneTestConstants.advertiserId;
        new TuneSharedPrefsDelegate(context, PREFS_LOG_ID_OPEN).putString(PREFS_TUNE, logId);

        return tune;
    }

    public void shutDown() {
        super.shutDown();

        tune.clearSharedPrefs();
        tune = null;
    }

    public static TuneConfiguration getTestingConfig(List<String> configurationPlayerFilenames) {
        TuneConfiguration config = new TuneConfiguration();
        config.setAnalyticsHostPort("https://analytics-qa.ma.tune.com/analytics");
        config.setPlaylistHostPort("https://qa.ma.tune.com");
        config.setConfigurationHostPort("https://qa.ma.tune.com");
        config.setConnectedModeHostPort("https://qa.ma.tune.com");
        config.setStaticContentHostPort("https://s3.amazonaws.com/uploaded-assets-qa2");
        config.setAnalyticsDispatchPeriod(TuneTestConstants.ANALYTICS_DISPATCH_PERIOD);
        config.setPlaylistRequestPeriod(TuneTestConstants.PLAYLIST_REQUEST_PERIOD);
        config.setUseConfigurationPlayer(true);
        config.setConfigurationPlayerFilenames(configurationPlayerFilenames);
        config.setShouldSendScreenViews(true);

        return config;
    }
    
    public static synchronized TuneTestWrapper getInstance() {
        return tune;
    }
    
    public ExecutorService getPubQueue() {
        return super.getPubQueue();
    }

    public void setTuneTestRequest(TuneTestRequest request) {
        tuneRequest = request;
    }

    public synchronized void setOnline( boolean toBeOnline ) {
        online = toBeOnline;
    }

    @Override
    public synchronized boolean isOnline(Context context) {
        return online;
    }

    public TuneTestQueue getEventQueue() {
        return (TuneTestQueue)eventQueue;
    }

    @Override
    public void addEventToQueue(String link, String data, JSONObject postBody, boolean firstSession) {
        super.addEventToQueue(link, data, postBody, false);
    }

    @Override
    public synchronized void dumpQueue() {
        if (online) {
            super.dumpQueue();
        }
    }

    public void removeBroadcastReceiver() {
        if( isRegistered ) {
            isRegistered = false;
            mContext.unregisterReceiver(networkStateReceiver);
            networkStateReceiver = null;
        }
    }

    public void clearSharedPrefs() {
        new TuneSharedPrefsDelegate(mContext, PREFS_TUNE).clearSharedPreferences();
    }
    
    public String readUserIdKey(String key) {
        return new TuneSharedPrefsDelegate(mContext, PREFS_TUNE).getString(key);
    }

    public void setTimeLastMeasuredSession(long time) {
        this.timeLastMeasuredSession = time;
    }

    public void setIsFirstInstall(boolean isFirstInstall) {
        tune.isFirstInstall = isFirstInstall;
    }
}
