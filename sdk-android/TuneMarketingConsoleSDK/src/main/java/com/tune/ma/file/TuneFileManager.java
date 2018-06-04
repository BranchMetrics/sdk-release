package com.tune.ma.file;

import android.content.Context;

import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.utils.TuneFileUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * Created by gowie on 1/28/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneFileManager implements FileManager {

    private Context context;

    private static final String ANALYTICS_FILE_NAME = "tune_analytics.txt";
    private static final String CONFIGURATION_FILE_NAME = "tune_configuration.json";
    private static final String PLAYLIST_FILE_NAME = "tune_playlist.json";

    private static final Object ANALYTICS_LOCK = new Object();
    private static final Object CONFIGURATION_LOCK = new Object();
    private static final Object PLAYLIST_LOCK = new Object();

    public TuneFileManager(Context context) {
        this.context = context;
    }

    // Configuration Filea
    ///////////////////////

    @Override
    public void writeConfiguration(final JSONObject configuration) {
       TuneFileUtils.writeFile(configuration.toString(), CONFIGURATION_FILE_NAME, CONFIGURATION_LOCK, context);
    }

    @Override
    public JSONObject readConfiguration() {
        return TuneFileUtils.readJsonFile(CONFIGURATION_FILE_NAME, CONFIGURATION_LOCK, context);
    }

    @Override
    public void deleteConfiguration() {
        TuneFileUtils.deleteFile(CONFIGURATION_FILE_NAME, CONFIGURATION_LOCK, context);
    }


    // Playlist File
    //////////////////

    @Override
    public JSONObject readPlaylist() {
        return TuneFileUtils.readJsonFile(PLAYLIST_FILE_NAME, PLAYLIST_LOCK, context);
    }

    @Override
    public void writePlaylist(final JSONObject playlist) {
        TuneFileUtils.writeFile(playlist.toString(), PLAYLIST_FILE_NAME, PLAYLIST_LOCK, context);
    }

    // Analytics File
    //////////////////

    /**
     * Write analytics event to disk.
     * @param event TuneAnalyticsEvent to save to disk
     */
    @Override
    public void writeAnalytics(final TuneAnalyticsEventBase event) {
        synchronized (ANALYTICS_LOCK) {
            FileOutputStream outputStream = null;
            try {
                // Write the event JSON string to file as a new line
                outputStream = context.openFileOutput(ANALYTICS_FILE_NAME, Context.MODE_APPEND);
                outputStream.write(event.toJson().toString().getBytes());
                outputStream.write("\n".getBytes());
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (outputStream != null) {
                    try {
                        outputStream.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    /**
     * Read analytics events from disk.
     * @return Analytics events on disk as JSONArray
     */
    @Override
    public JSONArray readAnalytics() {
        synchronized (ANALYTICS_LOCK) {
            JSONArray analyticsArray = new JSONArray();
            File analyticsFile = new File(context.getFilesDir(), ANALYTICS_FILE_NAME);
            if (analyticsFile.exists()) {
                FileInputStream fis = null;
                InputStreamReader isr = null;
                BufferedReader bufferedReader = null;
                try {
                    fis = new FileInputStream(analyticsFile);
                    isr = new InputStreamReader(fis);
                    bufferedReader = new BufferedReader(isr);
                    String line;
                    while ((line = bufferedReader.readLine()) != null) {
                        // Create JSONObject for each line
                        line = line.trim();
                        try {
                            JSONObject analyticsEvent = new JSONObject(line);
                            analyticsArray.put(analyticsEvent);
                        } catch (JSONException e) {
                            // Could not create JSONObject from a line
                            e.printStackTrace();
                        }
                    }
                } catch (FileNotFoundException e) {
                    e.printStackTrace();
                } catch (IOException e) {
                    e.printStackTrace();
                } finally {
                    if (fis != null) {
                        try {
                            fis.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                    if (isr != null) {
                        try {
                            isr.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                    if (bufferedReader != null) {
                        try {
                            bufferedReader.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
            return analyticsArray;
        }
    }

    @Override
    public void deleteAnalytics() {
        TuneFileUtils.deleteFile(ANALYTICS_FILE_NAME, ANALYTICS_LOCK, context);
    }

    /**
     * Delete first numEventsToDelete lines of analytics events file from disk.
     * @param numEventsToDelete Number of events that were dispatched and should be deleted
     */
    @Override
    public void deleteAnalytics(int numEventsToDelete) {
        StringBuilder eventsToSave = new StringBuilder();
        synchronized (ANALYTICS_LOCK) {
            // If no events to delete, exit
            if (numEventsToDelete == 0) {
                return;
            }

            File analyticsFile = new File(context.getFilesDir(), ANALYTICS_FILE_NAME);
            // If file is not there for some reason, exit
            if (!analyticsFile.exists()) {
                return;
            }

            int lineCount = 1;
            FileInputStream fis = null;
            InputStreamReader isr = null;
            BufferedReader bufferedReader = null;
            // StringBuilder to write new file contents without deleted events
            try {
                fis = new FileInputStream(analyticsFile);
                isr = new InputStreamReader(fis);
                bufferedReader = new BufferedReader(isr);

                String line;
                while ((line = bufferedReader.readLine()) != null) {
                    // If the line is not in the lines to delete, add it to the events to save
                    if (lineCount > numEventsToDelete) {
                        eventsToSave.append(line + "\n");
                    }
                    lineCount++;
                }
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        if (eventsToSave.length() != 0) {
            TuneFileUtils.writeFile(eventsToSave.toString(), ANALYTICS_FILE_NAME, ANALYTICS_LOCK, context);
        } else {
            TuneFileUtils.deleteFile(ANALYTICS_FILE_NAME, ANALYTICS_LOCK, context);
        }
    }

}
