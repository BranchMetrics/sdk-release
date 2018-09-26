package com.tune.utils;

import android.content.Context;

import com.tune.TuneDebugLog;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Created by johng on 1/5/16.
 */
public class TuneFileUtils {

    private static final String TAG = "FileUtils";

    public static void writeFile(final String content, final String fileName, final Object lock, Context context) {
        synchronized (lock) {
            FileOutputStream outputStream = null;
            File file = new File(context.getFilesDir(), fileName);
            try {
                outputStream = new FileOutputStream(file, false);
                outputStream.write(content.getBytes());
            } catch (Exception e) {
                TuneDebugLog.d(TAG, "error writing file with fileName: " + fileName, e);
            } finally {
                if (outputStream != null) {
                    try {
                        outputStream.close();
                    } catch (IOException e) {
                        TuneDebugLog.d(TAG, "writeFile() IO exception", e);
                    }
                }
            }
        }
    }

    public static JSONObject readJsonFile(final String fileName, final Object lock, Context context) {
        JSONObject result = null;
        String fileContent = TuneFileUtils.readFile(fileName, lock, context);

        if (fileContent != null) {
            try {
                result = new JSONObject(fileContent);
            } catch (JSONException e) {
                TuneDebugLog.d(TAG, "readJsonFile() JSON exception", e);
            }
        }

        return result;
    }

    public static String readFile(final String fileName, final Object lock, Context context) {
         synchronized (lock) {
             String result = null;
             File file = new File(context.getFilesDir(), fileName);

             if (file.exists()) {
                 try {
                     FileInputStream fis = new FileInputStream(file);
                     int size = fis.available();
                     byte[] buffer = new byte[size];
                     fis.read(buffer);
                     fis.close();
                     result = new String(buffer, "UTF-8");
                 } catch (IOException e) {
                     TuneDebugLog.d(TAG, "readFile() IO exception", e);
                 }
             }
             return result;
        }
    }

    public static JSONObject readFileFromAssetsIntoJsonObject(Context context, String fileName) throws JSONException {
        String json = null;
        try {
            BufferedInputStream is = new BufferedInputStream(context.getAssets().open(fileName));
            int size = is.available();
            byte[] buffer = new byte[size];
            is.read(buffer);
            is.close();
            json = new String(buffer, "UTF-8");
        } catch (IOException e) {
            TuneDebugLog.d(TAG, "readFileFromAssetsIntoJsonObject() IO exception", e);
            return null;
        }
        return new JSONObject(json);
    }

    public static void deleteFile(final String fileName, final Object lock, Context context) {
        synchronized (lock) {
            File fileToDelete = new File(context.getFilesDir(), fileName);
            if (fileToDelete != null && fileToDelete.exists()) {
                fileToDelete.delete();
            }
        }
    }
}
