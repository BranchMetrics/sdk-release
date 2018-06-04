package com.tune.ma.utils;

import android.content.Context;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by kristine on 2/2/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneJSONPlayer {

    private int counter;
    private List<JSONObject> files;
    private Context context;

    public TuneJSONPlayer(Context context) {
        this.context = context;
        counter = -1;
    }

    public JSONObject getNext() {
        incrementDownload();
        return files.get(counter);
    }

    public void setFiles(List<String> filenames) {
        files = buildListWithFilenames(filenames);
    }

    private void incrementDownload() {
        if (files.size() > 0) {
            if (counter + 1 < files.size()) {
                counter++;
            }
        }
    }

    private List<JSONObject> buildListWithFilenames(List<String> filenames) {
        List<JSONObject> fileArray = new ArrayList<JSONObject>();
        for (String filename: filenames) {
            try {
                fileArray.add(TuneFileUtils.readFileFromAssetsIntoJsonObject(context, filename));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return fileArray;
    }

}
