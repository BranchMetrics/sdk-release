package com.tune.ma.utils;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.Map;

/**
 * Created by charlesgilliam on 2/3/16.
 */
public class TuneSharedPrefsDelegate {
    private SharedPreferences prefs;

    public TuneSharedPrefsDelegate(Context context, String name) {
        this.prefs = context.getSharedPreferences(name, Context.MODE_PRIVATE);
    }

    /**
     * Saves a String to SharedPreferences
     * @param prefsKey SharedPreferences key to save under
     * @param prefsValue SharedPreferences value to save
     */
    public synchronized void saveToSharedPreferences(String prefsKey, String prefsValue) {
        prefs.edit().putString(prefsKey, prefsValue).apply();
    }

    /**
     * Saves a Boolean to SharedPreferences
     * @param prefsKey SharedPreferences key to save under
     * @param prefsValue SharedPreferences value to save
     */
    public synchronized void saveBooleanToSharedPreferences(String prefsKey, boolean prefsValue) {
        prefs.edit().putBoolean(prefsKey, prefsValue).apply();
    }

    /**
     * Retrieves a String from SharedPreferences
     * @param prefsKey SharedPreferences key of the value requested
     * @return SharedPreferences value for the given key or an empty string if it doesn't exist
     */
    public synchronized String getStringFromSharedPreferences(String prefsKey) {
        return getStringFromSharedPreferences(prefsKey, "");
    }

    /**
     * Retrieves a String from SharedPreferences
     * @param prefsKey SharedPreferences key of the value requested
     * @param defaultValue Value to return if the key does not exist
     * @return SharedPreferences value for the given key or the default value if it doesn't exist
     */
    public synchronized String getStringFromSharedPreferences(String prefsKey, String defaultValue) {
        try {
            return prefs.getString(prefsKey, defaultValue);
        } catch (ClassCastException e) {
            return defaultValue;
        }
    }

    /**
     * Retrieves a boolean from SharedPreferences
     * @param prefsKey SharedPreferences key of the value requested
     * @return SharedPreferences value for the given key or false if it doesn't exist
     */
    public synchronized boolean getBooleanFromSharedPreferences(String prefsKey) {
        return getBooleanFromSharedPreferences(prefsKey, false);
    }

    /**
     * Retrieves a boolean from SharedPreferences
     * @param prefsKey SharedPreferences key of the value requested
     * @param defaultValue Value to return if the key does not exist
     * @return SharedPreferences value for the given key or default value if it doesn't exist
     */
    public synchronized boolean getBooleanFromSharedPreferences(String prefsKey, boolean defaultValue) {
        return prefs.getBoolean(prefsKey, defaultValue);
    }

    /**
     * Checks if a given key exists in the shared preferences
     * @return true if the key exists otherwise false
     */
    public synchronized boolean contains(String prefsKey) {
        return prefs.contains(prefsKey);
    }

    /**
     * Removes all keys from shared preferences
     */
    public synchronized void clearSharedPreferences() {
        prefs.edit().clear().apply();
    }

    public synchronized void remove(String key) {
        prefs.edit().remove(key).apply();
    }

    public synchronized Map<String, ?> getAll() {
        return prefs.getAll();
    }
}
