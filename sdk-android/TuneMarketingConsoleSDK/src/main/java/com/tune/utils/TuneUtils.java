package com.tune.utils;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.support.v4.content.ContextCompat;
import android.support.v4.content.PermissionChecker;
import android.text.TextUtils;

import com.tune.TuneConstants;
import com.tune.TuneDebugLog;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

public class TuneUtils {

    /**
     * Reads an InputStream and converts it to a String.
     * @param stream InputStream to read
     * @return String of stream contents
     * @throws IOException Reader was closed when trying to be read
     * @throws UnsupportedEncodingException UTF-8 encoding could not be found
     */
    public static String readStream(InputStream stream) throws IOException {
        if (stream != null) {
            BufferedReader reader = new BufferedReader(new InputStreamReader(stream, "UTF-8"));
            StringBuilder builder = new StringBuilder();
            for (String line; (line = reader.readLine()) != null;) {
                builder.append(line).append("\n");
            }
            reader.close();
            return builder.toString();
        }
        return "";
    }
    
    /**
     * Convert a byte array to a Hex String.
     * @param data Byte array to convert to hex
     * @return Hex string
     */
    public static String bytesToHex(byte[] data) {
        if (data == null) {
            return null;
        }

        int len = data.length;
        StringBuilder str = new StringBuilder();
        for (byte dataByte : data) {
            if ((dataByte & 0xFF) < 16) {
                str.append("0").append(Integer.toHexString(dataByte & 0xFF));
            } else {
                str.append(Integer.toHexString(dataByte & 0xFF));
            }
        }
        return str.toString();
    }

    /**
     * Convert a Hex String to a byte array.
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
     * Create an MD5 Hash from a String.
     * @param s String to MD5 hash
     * @return MD5 hashed string
     */
    public static String md5(String s) {
        if (TextUtils.isEmpty(s)) {
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
     * Create a SHA1 hash from a String.
     * @param s String to SHA-1 hash
     * @return SHA-1 hashed string
     */
    public static String sha1(String s) {
        if (TextUtils.isEmpty(s)) {
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
     * Create a SHA-256 hash from a String.
     * @param s String to SHA-256 hash
     * @return SHA-256 hashed string
     */
    public static String sha256(String s) {
        if (TextUtils.isEmpty(s)) {
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

    /**
     * Compress a String to GZIP data.
     * @param string String to compress
     * @return Byte array of compressed String
     * @throws IOException if an I/O error has occurred
     */
    public static byte[] compress(String string) throws IOException {
        ByteArrayOutputStream os = new ByteArrayOutputStream(string.length());
        GZIPOutputStream gos = new GZIPOutputStream(os);
        gos.write(string.getBytes());
        gos.close();
        byte[] compressed = os.toByteArray();
        os.close();
        return compressed;
    }

    /**
     * Decompress GZIP data to a String.
     * @param compressed Data to decompress
     * @return String of compressed data
     * @throws IOException if an I/O error has occurred
     */
    public static String decompress(byte[] compressed) throws IOException {
        final int BUFFER_SIZE = 32;
        ByteArrayInputStream is = new ByteArrayInputStream(compressed);
        GZIPInputStream gis = new GZIPInputStream(is, BUFFER_SIZE);
        StringBuilder string = new StringBuilder();
        byte[] data = new byte[BUFFER_SIZE];
        int bytesRead;
        while ((bytesRead = gis.read(data)) != -1) {
            string.append(new String(data, 0, bytesRead));
        }
        gis.close();
        is.close();
        return string.toString();
    }

    /**
     * Concatenates two byte arrays.
     * From: http://stackoverflow.com/questions/5368704/appending-byte-to-the-end-of-another-byte
     * @param a Byte array a
     * @param b Byte array b
     * @return a and b concatenated
     */
    public static byte[] concatenateByteArrays(byte[] a, byte[] b) {
        byte[] result = new byte[a.length + b.length];
        System.arraycopy(a, 0, result, 0, a.length);
        System.arraycopy(b, 0, result, a.length, b.length);
        return result;
    }

    /**
     * Check to see if a permission has already been granted.
     * @param context Context
     * @param permission Permission
     * @return true if the permission has already been granted
     */
    public static boolean hasPermission(Context context, String permission) {
        // For API 23+, permissions should be checked at runtime, not manifest level
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            int targetSdkVersion = 0;
            try {
                final PackageInfo info = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
                targetSdkVersion = info.applicationInfo.targetSdkVersion;
            } catch (PackageManager.NameNotFoundException e) {
                e.printStackTrace();
            }
            if (targetSdkVersion >= Build.VERSION_CODES.M) {
                // targetSdkVersion >= Android M, we can use ContextCompat#checkSelfPermission
                return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED;
            } else {
                // targetSdkVersion < Android M, we have to use PermissionChecker
                return PermissionChecker.checkSelfPermission(context, permission) == PermissionChecker.PERMISSION_GRANTED;
            }
        }

        // SDK-732 -- Some devices/versions have been observed to throw an exception when calling
        // checkCallingOrSelfPermission()
        boolean hasPermission = false;
        try {
            hasPermission = context.checkCallingOrSelfPermission(permission) == PackageManager.PERMISSION_GRANTED;
        } catch (Exception e) {
            TuneDebugLog.w("Unable to check permission: " + permission);
        }
        return hasPermission;
    }

    public static boolean convertToBoolean(String booleanString) {
        return (TuneConstants.PREF_SET.equalsIgnoreCase(booleanString) || "yes".equalsIgnoreCase(booleanString) || "true".equalsIgnoreCase(booleanString));
    }
}
