package com.tune.utils;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.Map;

/**
 * Created by charlesgilliam on 2/3/16.
 */
public class TuneSharedPrefsDelegate {
    private final SharedPreferences prefs;

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
     * Saves an Integer to SharedPreferences
     * @param prefsKey SharedPreferences key to save under
     * @param prefsValue SharedPreferences value to save
     */
    public synchronized void saveIntegerToSharedPreferences(String prefsKey, int prefsValue) {
        prefs.edit().putInt(prefsKey, prefsValue).apply();
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
     * Retrieves an Integer from SharedPreferences
     * @param prefsKey SharedPreferences key of the value requested
     * @return SharedPreferences value for the given key or zero if it doesn't exist
     */
    public synchronized int getIntegerFromSharedPreferences(String prefsKey) {
        return prefs.getInt(prefsKey, 0);
    }

    /**
     * Retrieves an Integer from SharedPreferences
     * @param prefsKey SharedPreferences key of the value requested
     * @param defaultValue Value to return if the key does not exist
     * @return SharedPreferences value for the given key or default value if it doesn't exist
     */
    public synchronized int getIntegerFromSharedPreferences(String prefsKey, int defaultValue) {
        return prefs.getInt(prefsKey, defaultValue);
    }

    /**
     * Checks if a given key exists in the shared preferences
     * @param prefsKey SharedPreferences key of the value requested
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

    /**
     * Removes a SharedPreference by SharedPreference key
     * @param prefsKey SharedPreferences key to look up
     */
    public synchronized void remove(String prefsKey) {
        prefs.edit().remove(prefsKey).apply();
    }

    public synchronized Map<String, ?> getAll() {
        return prefs.getAll();
    }

    // === SharedPreferences Wrapper API ===========================================================

    /**
     * Retrieve an int value from the preferences.
     * @param key The name of the preference to retrieve
     * @param defaultValue Value to return if the key does not exist
     * @return SharedPreferences value for the given key or default value if it doesn't exist
     */
    public int getInt(String key, int defaultValue) {
        return getIntegerFromSharedPreferences(key, defaultValue);
    }

    /**
     * Retrieve an int value from the preferences.
     * @param key The name of the preference to retrieve
     * @return SharedPreferences value for the given key or zero if it doesn't exist
     */
    public int getInt(String key) {
        return getIntegerFromSharedPreferences(key);
    }

    /**
     * Saves a Integer to SharedPreferences
     * @param key SharedPreferences key to save under
     * @param value SharedPreferences value to save
     */
    public void putInt(String key, int value) {
        saveIntegerToSharedPreferences(key, value);
    }

    /**
     * Retrieve a boolean value from the preferences.
     * @param key The name of the preference to retrieve
     * @param defaultValue Value to return if the key does not exist
     * @return SharedPreferences value for the given key or default value if it doesn't exist
     */
    public boolean getBoolean(String key, boolean defaultValue) {
        return getBooleanFromSharedPreferences(key, defaultValue);
    }

    /**
     * Retrieve a boolean value from the preferences.
     * @param key The name of the preference to retrieve
     * @return SharedPreferences value for the given key or false if it doesn't exist
     */
    public boolean getBoolean(String key) {
        return getBooleanFromSharedPreferences(key);
    }

    /**
     * Saves a Boolean to SharedPreferences
     * @param key SharedPreferences key to save under
     * @param value SharedPreferences value to save
     */
    public void putBoolean(String key, boolean value) {
        saveBooleanToSharedPreferences(key, value);
    }

    /**
     * Retrieve a String value from the preferences.
     * @param key The name of the preference to retrieve
     * @param defaultValue Value to return if the key does not exist
     * @return SharedPreferences value for the given key or default value if it doesn't exist
     */
    public String getString(String key, String defaultValue) {
        return getStringFromSharedPreferences(key, defaultValue);
    }

    /**
     * Retrieve a String value from the preferences.
     * @param key The name of the preference to retrieve
     * @return SharedPreferences value for the given key or an empty String if it doesn't exist
     */
    public String getString(String key) {
        return getStringFromSharedPreferences(key);
    }

    /**
     * Saves a String to SharedPreferences
     * @param key SharedPreferences key to save under
     * @param value SharedPreferences value to save
     */
    public void putString(String key, String value) {
        saveToSharedPreferences(key, value);
    }
}
