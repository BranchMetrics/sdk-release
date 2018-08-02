package com.tune;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.content.Context;

import com.tune.location.TuneLocationListener;
import com.tune.utils.TuneSharedPrefsDelegate;

import org.json.JSONObject;
import org.mockito.Mockito;

import java.util.concurrent.ExecutorService;

public class TuneTestWrapper extends TuneInternal {
    // copied from TuneConstants
    private static final String PREFS_LOG_ID_OPEN = "mat_log_id_open";
    private static final String PREFS_TUNE = "com.mobileapptracking";
    
    private static boolean online = false; //true;
    
    private static TuneTestWrapper tune = null;

    private static AccountManager mockAccountManager;
    
    private TuneTestWrapper(Context context) {
        super(context);
    }

    private boolean retainSharedPrefs;

    public static TuneTestWrapper init(final Context context, final String advertiserId, final String key, String packageName) {
        tune = new TuneTestWrapper(context);
        TuneInternal.initAll(tune, advertiserId, key, packageName);

        Account email = new Account("testing@tune.com", TuneConstants.GOOGLE_ACCOUNT_TYPE);
        Account[] emails = new Account[]{ email };
        mockAccountManager = Mockito.mock(AccountManager.class);
        Mockito.when(mockAccountManager.getAccountsByType(TuneConstants.GOOGLE_ACCOUNT_TYPE)).thenReturn(emails);
        Mockito.when(mockAccountManager.getAccounts()).thenReturn(emails);

        tune.locationListener = new TuneLocationListener(context);
        tune.eventQueue = new TuneTestQueue(context, tune);

        tune.disableLocationAutoCollection();

        // make fake open id
        String logId = "1234567812345678-201401-" + TuneTestConstants.advertiserId;
        new TuneSharedPrefsDelegate(context, PREFS_LOG_ID_OPEN).putString(PREFS_TUNE, logId);

        return tune;
    }

    @Override
    public AccountManager getAccountManager(Context context) {
        return mockAccountManager;
    }

    public void shutDown() {
        super.shutDown();

        tune.clearSharedPrefs();
        tune = null;
    }

    public ExecutorService getPubQueue() {
        return super.getPubQueue();
    }

    public synchronized void setOnline( boolean toBeOnline ) {
        online = toBeOnline;
    }

    @Override
    protected synchronized boolean isOnline() {
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

    private void clearSharedPrefs() {
        if (!retainSharedPrefs) {
            new TuneSharedPrefsDelegate(mApplicationReference.get(), PREFS_TUNE).clearSharedPreferences();
        }
    }
    
    public String readUserIdKey(String key) {
        return new TuneSharedPrefsDelegate(mApplicationReference.get(), PREFS_TUNE).getString(key);
    }

    public void setTimeLastMeasuredSession(long time) {
        this.timeLastMeasuredSession = time;
    }

    public void setIsFirstInstall(boolean isFirstInstall) {
        tune.isFirstInstall = isFirstInstall;
    }

    public void retainSharedPrefs(boolean retain) {
        this.retainSharedPrefs = retain;
    }
}
