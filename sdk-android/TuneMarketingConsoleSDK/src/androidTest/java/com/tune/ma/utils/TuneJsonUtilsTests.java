package com.tune.ma.utils;

import com.tune.TuneUnitTest;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by johng on 2/23/16.
 */
public class TuneJsonUtilsTests extends TuneUnitTest {
    public void testPutMap() {
        try {
            JSONObject empty = new JSONObject();
            Map<String, List<String>> approvedValues = new HashMap<String, List<String>>();
            List<String> valuesList = new ArrayList<String>();
            valuesList.add("value1");
            valuesList.add("value2");
            approvedValues.put("key", valuesList);
            TuneJsonUtils.put(empty, "approved_values", approvedValues);

            JSONObject expectedValues = new JSONObject();
            JSONArray expectedList = new JSONArray();
            expectedList.put("value1");
            expectedList.put("value2");
            expectedValues.put("key", expectedList);

            assertEquals(expectedValues.toString(), empty.getJSONObject("approved_values").toString());
            JSONObject approvedValuesJson = empty.getJSONObject("approved_values");
            assertEquals(expectedList.toString(), approvedValuesJson.getJSONArray("key").toString());
        } catch (JSONException e) {
            e.printStackTrace();
            assertFalse("JSON parsing failed", true);
        }
    }

    public void testPutList() {
        try {
            JSONObject empty = new JSONObject();
            List<String> approvedValues = new ArrayList<String>();
            approvedValues.add("value1");
            approvedValues.add("value2");
            TuneJsonUtils.put(empty, "approved_values", approvedValues);

            JSONObject expectedValues = new JSONObject();
            JSONArray expectedList = new JSONArray();
            expectedList.put("value1");
            expectedList.put("value2");
            expectedValues.put("approved_values", expectedList);

            assertEquals(expectedValues.toString(), empty.toString());
        } catch (JSONException e) {
            e.printStackTrace();
            assertFalse("JSON parsing failed", true);
        }
    }
}
