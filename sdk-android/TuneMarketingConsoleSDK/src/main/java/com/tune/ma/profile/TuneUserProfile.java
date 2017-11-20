package com.tune.ma.profile;

import android.content.Context;

import com.tune.Tune;
import com.tune.TuneUrlKeys;
import com.tune.TuneUtils;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.eventbus.event.userprofile.TuneCustomProfileVariablesCleared;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneSharedPrefsDelegate;

import org.greenrobot.eventbus.Subscribe;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.TimeZone;

/**
 * Created by charlesgilliam on 1/14/16.
 */
public class TuneUserProfile {
    public static final String PREFS_TMA_PROFILE = "com.tune.ma.profile";
    public static final String PREFS_CUSTOM_VARIABLES_KEY = "custom_variables";
    private Context context;

    TuneSharedPrefsDelegate sharedPrefs;
    private HashMap<String, TuneAnalyticsVariable> variables;
    // This is a set of all *registered* profile variables.
    private Set<String> customVariables;
    private Set<TuneAnalyticsVariable> sessionVariables;

    // Note: ADVERTISER_ID and PACKAGE_NAME should not be stored in `variablesToSave` so that they do not get loaded on init
    private static final Set<String> variablesToSave = new HashSet<>(Arrays.asList(
            TuneUrlKeys.USER_ID,
            TuneUrlKeys.IS_PAYING_USER,
            TuneUrlKeys.MAT_ID,
            TuneUrlKeys.OPEN_LOG_ID,
            TuneUrlKeys.USER_EMAIL_MD5,
            TuneUrlKeys.USER_EMAIL_SHA1,
            TuneUrlKeys.USER_EMAIL_SHA256,
            TuneUrlKeys.USER_NAME_MD5,
            TuneUrlKeys.USER_NAME_SHA1,
            TuneUrlKeys.USER_NAME_SHA256,
            TuneUrlKeys.USER_PHONE_MD5,
            TuneUrlKeys.USER_PHONE_SHA1,
            TuneUrlKeys.USER_PHONE_SHA256,

            TuneProfileKeys.SESSION_ID,
            TuneProfileKeys.IS_FIRST_SESSION,
            TuneProfileKeys.SESSION_LAST_DATE,
            TuneProfileKeys.SESSION_COUNT,
            TuneProfileKeys.SESSION_CURRENT_DATE,
            
            TuneProfileKeys.DEVICE_TOKEN,
            TuneProfileKeys.IS_PUSH_ENABLED
    ));

    public TuneUserProfile(Context context) {
        this.context = context;
        this.sharedPrefs = new TuneSharedPrefsDelegate(context, PREFS_TMA_PROFILE);
        this.variables = new HashMap<>();
        this.customVariables = new HashSet<>();
        this.sessionVariables = new HashSet<>();

        for (String v: variablesToSave) {
            TuneAnalyticsVariable p = getProfileVariableFromPrefs(v);
            if (p != null) {
                storeProfileVariable(p, false);
            }
        }

        storeProfileVariable(new TuneAnalyticsVariable(TuneUrlKeys.SDK_VERSION, Tune.getSDKVersion(), TuneVariableType.VERSION));
        Integer minutesFromGMT = (TimeZone.getDefault().getRawOffset() / 1000) / 60;
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.MINUTES_FROM_GMT, minutesFromGMT));
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.OS_TYPE, "android"));

        SystemInfo sysInfo = new SystemInfo(context);
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.HARDWARE_TYPE, sysInfo.getModel()));
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.APP_BUILD, sysInfo.getAppBuild()));
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.API_LEVEL, sysInfo.getApiLevel()));
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.INTERFACE_IDIOM, sysInfo.getTabletOrPhone()));
    }

    public String getAppId() {
        // Initialize advertiser id and package name to profile variable values
        String advertiserId = getProfileVariableValue(TuneUrlKeys.ADVERTISER_ID);
        String packageName = getProfileVariableValue(TuneUrlKeys.PACKAGE_NAME);

        // If values are null, then user profile was not initialized because EventBus was disabled (TMA getting config from disabled state)
        // So get values from SharedPreferences from the last time they were set
        // These values should not be stored in `variablesToSave` so that they do not get loaded on init
        if (advertiserId == null) {
            advertiserId = sharedPrefs.getStringFromSharedPreferences(TuneUrlKeys.ADVERTISER_ID);
        }
        if (packageName == null) {
            packageName = sharedPrefs.getStringFromSharedPreferences(TuneUrlKeys.PACKAGE_NAME);
        }

        StringBuilder sb = new StringBuilder();
        sb.append(advertiserId);
        sb.append("|");
        sb.append(packageName);
        sb.append("|");
        sb.append("android");

        return TuneUtils.md5(sb.toString());
    }

    public String getDeviceId() {
        String GAID = getProfileVariableValue(TuneUrlKeys.GOOGLE_AID);
        String fireAid = getProfileVariableValue(TuneUrlKeys.FIRE_AID);
        String androidId = getProfileVariableValue(TuneUrlKeys.ANDROID_ID);
        if (GAID != null) {
            return GAID;
        } else if (fireAid != null) {
            return fireAid;
        } else if (androidId != null) {
            return androidId;
        } else {
            return getProfileVariableValue(TuneUrlKeys.MAT_ID);
        }
    }

    public String getSessionId() {
        return getProfileVariableValue(TuneProfileKeys.SESSION_ID);
    }

    public Set<TuneAnalyticsVariable> getSessionVariables() {
        return sessionVariables;
    }

    public void deleteSharedPrefs() {
        sharedPrefs.clearSharedPreferences();
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_THIRD)
    public synchronized void onEvent(TuneAppForegrounded event) {
        // TODO: Check to see if TMA is disabled for the first session check
        TuneAnalyticsVariable storedIsFirstSession = getProfileVariableFromPrefs(TuneProfileKeys.IS_FIRST_SESSION);
        TuneAnalyticsVariable.TuneAnalyticsVariableBuilder isFirstSession = TuneAnalyticsVariable.Builder(TuneProfileKeys.IS_FIRST_SESSION);
        if (storedIsFirstSession == null) {
            storeProfileVariable(isFirstSession.withValue(true).build());
        } else if (storedIsFirstSession.getValue().equalsIgnoreCase("1")){
            storeProfileVariable(isFirstSession.withValue(false).build());
        }

        TuneAnalyticsVariable.TuneAnalyticsVariableBuilder sessionCount = TuneAnalyticsVariable.Builder(TuneProfileKeys.SESSION_COUNT);
        if (getProfileVariableFromPrefs(TuneProfileKeys.SESSION_COUNT) == null) {
            sessionCount.withValue(1);
        } else {
            int count = Integer.parseInt(getProfileVariableFromPrefs(TuneProfileKeys.SESSION_COUNT).getValue());
            sessionCount.withValue(count + 1);
        }

        TuneAnalyticsVariable.TuneAnalyticsVariableBuilder lastSession = TuneAnalyticsVariable.Builder(TuneProfileKeys.SESSION_LAST_DATE);
        if (getProfileVariableFromPrefs(TuneProfileKeys.SESSION_LAST_DATE) == null) {
            lastSession.withType(TuneVariableType.DATETIME);
        } else {
            Date previousSession = TuneAnalyticsVariable.stringToDate(getProfileVariableFromPrefs(TuneProfileKeys.SESSION_CURRENT_DATE).getValue());
            lastSession.withValue(previousSession);
        }

        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.SESSION_ID, event.getSessionId()));
        storeProfileVariable(sessionCount.build());
        storeProfileVariable(lastSession.build());
        storeProfileVariable(new TuneAnalyticsVariable(TuneProfileKeys.SESSION_CURRENT_DATE, new Date(event.getSessionStartTime())));

        // Restore custom profile variable names from SharedPreferences on foreground
        try {
            String customVariablesJsonStr = sharedPrefs.getStringFromSharedPreferences(PREFS_CUSTOM_VARIABLES_KEY, "[]");
            JSONArray customVariablesJson = new JSONArray(customVariablesJsonStr);

            // Iterate through stored variable names and add to customVariables set
            for (int i = 0; i < customVariablesJson.length(); i++) {
                customVariables.add(customVariablesJson.getString(i));
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        // Restore custom profile variables for stored names
        for (String variableName : customVariables) {
            TuneAnalyticsVariable storedVar = getProfileVariableFromPrefs(variableName);
            storeProfileVariable(storedVar, false);
        }
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_THIRD)
    public synchronized void onEvent(TuneAppBackgrounded event) {
        // Save custom profile variable names to SharedPreferences on background
        JSONArray customVariablesJson = new JSONArray(customVariables);
        sharedPrefs.saveToSharedPreferences(PREFS_CUSTOM_VARIABLES_KEY, customVariablesJson.toString());
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_THIRD)
    public void onEvent(TuneUpdateUserProfile event) {
        TuneAnalyticsVariable var = event.getVariable();
        storeProfileVariable(var);
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_THIRD)
    public synchronized void onEvent(TuneSessionVariableToSet event) {
        String variableName = event.getVariableName();
        String variableValue = event.getVariableValue();

        if (event.saveToProfile()) {
            sessionVariables.add(new TuneAnalyticsVariable(variableName, variableValue));
        }
    }

    public synchronized TuneAnalyticsVariable getProfileVariable(String key) {
        return variables.get(key);
    }

    public String getProfileVariableValue(String key) {
        TuneAnalyticsVariable result = getProfileVariable(key);
        if (result != null) {
            return result.getValue();
        } else {
            return null;
        }
    }

    public synchronized TuneAnalyticsVariable getProfileVariableFromPrefs(String key) {
        String json = sharedPrefs.getStringFromSharedPreferences(key, null);

        if (json == null) {
            return null;
        } else {
            return TuneAnalyticsVariable.fromJson(json);
        }
    }

    private void storeProfileVariable(TuneAnalyticsVariable value) {
        storeProfileVariable(value, true);
    }

    private synchronized void storeProfileVariable(TuneAnalyticsVariable value, boolean updatePrefs) {
        String name = value.getName();
        variables.put(name, value);
        if (updatePrefs && (variablesToSave.contains(name) || customVariables.contains(name))) {
            sharedPrefs.saveToSharedPreferences(name, value.toJsonForLocalStorage().toString());
        }
    }

    public synchronized JSONArray toJson() {
        JSONArray result = new JSONArray();

        for (TuneAnalyticsVariable var : variables.values()) {
            List<JSONObject> variableJsonList = var.toListOfJsonObjectsForDispatch();
            for (JSONObject variableJson: variableJsonList) {
                if (variableJson != null) {
                    result.put(variableJson);
                }
            }
        }

        for (TuneAnalyticsVariable sessionVariable : sessionVariables) {
            List<JSONObject> objects = sessionVariable.toListOfJsonObjectsForDispatch();
            for(JSONObject object: objects) {
                result.put(object);
            }
        }
        return result;
    }

    public synchronized List<TuneAnalyticsVariable> getCopyOfVars() {
        List<TuneAnalyticsVariable> result = new LinkedList<>();
        for (TuneAnalyticsVariable var: variables.values()) {
            result.add(new TuneAnalyticsVariable(var));
        }

        for (TuneAnalyticsVariable sessionVariable: sessionVariables) {
            result.add(sessionVariable);
        }
        return result;
    }

    /*

    Custom profile variable stuff

     */

    public synchronized void registerCustomProfileVariable(TuneAnalyticsVariable var) {
        if (TuneAnalyticsVariable.validateName(var.getName())) {
            String prettyName = TuneAnalyticsVariable.cleanVariableName(var.getName());

            if (TuneProfileKeys.isSystemVariable(prettyName)) {
                TuneDebugLog.IAMConfigError("The variable '" + prettyName + "' is a system variable, and cannot be registered in this manner. Please use another name.");
                return;
            }

            if (prettyName.startsWith("TUNE_")) {
                TuneDebugLog.IAMConfigError("Profile variables starting with 'TUNE_' are reserved. Not registering: " + prettyName);
                return;
            }

            customVariables.add(prettyName);

            TuneAnalyticsVariable storedVar = getProfileVariableFromPrefs(prettyName);
            if (storedVar != null && storedVar.getType() == var.getType()) {
                if (storedVar.didHaveValueManuallySet()) {
                    // If we have a stored custom variable and it is of the matching type use the stored value
                    storeProfileVariable(
                            TuneAnalyticsVariable.Builder(prettyName)
                                    .withValue(storedVar.getValue())
                                    .withType(storedVar.getType())
                                    .withValueManuallySet(true)
                                    .build());
                } else {
                    storeProfileVariable(
                            TuneAnalyticsVariable.Builder(prettyName)
                                    .withValue(var.getValue())
                                    .withType(storedVar.getType())
                                    .build());
                }
            } else {
                storeProfileVariable(
                        TuneAnalyticsVariable.Builder(prettyName)
                                .withValue(var.getValue())
                                .withType(var.getType())
                                .build());
            }
        }
    }

    public synchronized void setCustomProfileVariable(TuneAnalyticsVariable var) {
        if (TuneAnalyticsVariable.validateName(var.getName())) {
            String prettyName = TuneAnalyticsVariable.cleanVariableName(var.getName());

            if (customVariables.contains(prettyName)) {
                TuneAnalyticsVariable storedVar = getProfileVariableFromPrefs(prettyName);
                if (storedVar == null || storedVar.getType() == var.getType()) {
                    storeProfileVariable(
                            TuneAnalyticsVariable.Builder(prettyName)
                                    .withValue(var.getValue())
                                    .withType(var.getType())
                                    .withValueManuallySet(true)
                                    .build());
                } else {
                    TuneDebugLog.IAMConfigError("Attempting to set the variable '" + prettyName + "', registered as a " + storedVar.getType() + ", with the " + var.getType() + " setter. Please use the appropriate setter.");
                }
            } else {
                TuneDebugLog.IAMConfigError("In order to set a value for '" + prettyName + "' it must be registered first.");
            }
        }
    }

    public synchronized TuneAnalyticsVariable getCustomProfileVariable(String name) {
        TuneAnalyticsVariable result = null;
        if (TuneAnalyticsVariable.validateName(name)) {
            String prettyName = TuneAnalyticsVariable.cleanVariableName(name);

            if (customVariables.contains(prettyName)) {
               result = getProfileVariable(prettyName);
            } else {
               TuneDebugLog.IAMConfigError("In order to get a value for '" + prettyName + "' it must be registered first.");
            }
        }

        return result;
    }

    public void clearCertainCustomProfileVariable(String key) {
        List<String> clearedVariables = clearCustomProfileVariables(Arrays.asList(key));

        // Factored this out here because we will end up in deadlock because this post will create a
        // tracer that will require the lock.
        if (clearedVariables.size() > 0) {
            TuneEventBus.post(new TuneCustomProfileVariablesCleared(clearedVariables));
        }
    }

    public void clearAllCustomProfileVariables() {
        // NOTE: I don't think we'll have a problem with 'customVariables' outside of the lock
        List<String> clearedVariables = clearCustomProfileVariables(customVariables);

        if (clearedVariables.size() > 0) {
            TuneEventBus.post(new TuneCustomProfileVariablesCleared(clearedVariables));
        }
    }

    private synchronized List<String> clearCustomProfileVariables(Iterable<String> toRemove) {
        List<String> clearedVariables = new LinkedList<>();

        for (String key: toRemove) {
            if (TuneAnalyticsVariable.validateName(key)) {
                String prettyName = TuneAnalyticsVariable.cleanVariableName(key);
                if (customVariables.contains(prettyName)) {
                    variables.remove(prettyName);
                    sharedPrefs.remove(prettyName);
                    clearedVariables.add(prettyName);
                }
            }
        }

        return clearedVariables;
    }
}
