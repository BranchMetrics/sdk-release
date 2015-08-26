package com.mobileapptracker;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import android.content.Context;

public class MATUtils {
    
    
    /**
     * Saves a String to SharedPreferences
     * @param context Context to access SharedPreferences of
     * @param prefsKey SharedPreferences key to save under
     * @param prefsValue SharedPreferences value to save
     */
    public static synchronized void saveToSharedPreferences(Context context, String prefsKey, String prefsValue) {
        context.getSharedPreferences(MATConstants.PREFS_TUNE, Context.MODE_PRIVATE).edit().putString(prefsKey, prefsValue).commit();
    }
    
    /**
     * Saves a boolean to SharedPreferences
     * @param context Context to access SharedPreferences of
     * @param prefsKey SharedPreferences key to save under
     * @param prefsValue SharedPreferences value to save
     */
    public static synchronized void saveToSharedPreferences(Context context, String prefsKey, boolean prefsValue) {
        context.getSharedPreferences(MATConstants.PREFS_TUNE, Context.MODE_PRIVATE).edit().putBoolean(prefsKey, prefsValue).commit();
    }


    /**
     * Retrieves a String from SharedPreferences
     * @param context Context to access SharedPreferences of
     * @param prefsKey SharedPreferences key of the value requested
     * @return SharedPreferences value for the given key
     */
    public static synchronized String getStringFromSharedPreferences(Context context, String prefsKey) {
        try {
            return context.getSharedPreferences(MATConstants.PREFS_TUNE, Context.MODE_PRIVATE).getString(prefsKey, "");
        } catch (ClassCastException e) {
            return "";
        }
    }
    
    /**
     * Retrieves a boolean from SharedPreferences
     * @param context Context to access SharedPreferences of
     * @param prefsKey SharedPreferences key of the value requested
     * @return SharedPreferences value for the given key
     */
    public static synchronized boolean getBooleanFromSharedPreferences(Context context, String prefsKey) {
        try {
            return context.getSharedPreferences(MATConstants.PREFS_TUNE, Context.MODE_PRIVATE).getBoolean(prefsKey, false);
        } catch (ClassCastException e) {
            return false;
        }
    }
    
    /**
     * Reads an InputStream and converts it to a String
     * @param stream InputStream to read
     * @return String of stream contents
     * @throws IOException Reader was closed when trying to be read
     * @throws UnsupportedEncodingException UTF-8 encoding could not be found
     */
    public static String readStream(InputStream stream) throws IOException, UnsupportedEncodingException {
        if (stream != null) {
            BufferedReader reader = new BufferedReader(new InputStreamReader(stream, "UTF-8"));
            StringBuilder builder = new StringBuilder();
            for (String line = null; (line = reader.readLine()) != null;) {
                builder.append(line).append("\n");
            }
            reader.close();
            return builder.toString();
        }
        return "";
    }
    
    /**
     * @param data Byte array to convert to hex
     * @return Hex string
     */
    public static String bytesToHex(byte[] data) {
        if (data == null) {
            return null;
        }

        int len = data.length;
        String str = "";
        for (int i = 0; i < len; i++) {
            if ((data[i] & 0xFF) < 16) {
                str = str + "0" + java.lang.Integer.toHexString(data[i] & 0xFF);
            } else {
                str = str + java.lang.Integer.toHexString(data[i] & 0xFF);
            }
        }
        return str;
    }

    /**
     * @param str Hex string to convert to bytes
     * @return Byte array
     */
    public static byte[] hexToBytes(String str) {
        if (str == null) {
            return null;
        } else if (str.length() < 2) {
            return null;
        } else {
            int len = str.length() / 2;
            byte[] buffer = new byte[len];
            for (int i = 0; i < len; i++) {
                buffer[i] = (byte) Integer.parseInt(str.substring(i * 2, i * 2 + 2), 16);
            }
            return buffer;
        }
    }

    /**
     * @param s String to MD5 hash
     * @return MD5 hashed string
     */
    public static String md5(String s) {
        if (s == null) {
            return "";
        }
        try {
            // Create MD5 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            digest.update(s.getBytes());
            byte[] messageDigest = digest.digest();
            return bytesToHex(messageDigest);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }
    
    /**
     * @param s String to SHA-1 hash
     * @return SHA-1 hashed string
     */
    public static String sha1(String s) {
        if (s == null) {
            return "";
        }
        try {
            // Create SHA-1 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("SHA-1");
            digest.update(s.getBytes());
            byte[] messageDigest = digest.digest();
            return bytesToHex(messageDigest);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }
    
    /**
     * @param s String to SHA-256 hash
     * @return SHA-256 hashed string
     */
    public static String sha256(String s) {
        if (s == null) {
            return "";
        }
        try {
            // Create SHA-256 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            digest.update(s.getBytes());
            byte[] messageDigest = digest.digest();
            return bytesToHex(messageDigest);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }
}
