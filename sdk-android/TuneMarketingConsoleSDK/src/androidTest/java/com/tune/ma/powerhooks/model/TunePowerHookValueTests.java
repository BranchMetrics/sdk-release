package com.tune.ma.powerhooks.model;

import com.tune.TuneUnitTest;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Created by gowie on 1/26/16.
 */
public class TunePowerHookValueTests extends TuneUnitTest {

    public void testRunningExperimentPowerHookReturnsExperimentValue() {
        TunePowerHookValue phook = new TunePowerHookValue("hookId", "friendlyName", "defaultValue", "experimentValue", "value", "2015-01-25T19:12:45Z", "2200-01-25T19:12:45Z",
                                                          "variationId", "experimentId", "description", null);

        assertEquals("experimentValue", phook.getValue());
    }

    public void testNonRunningExperimentReturnsValue() {
        TunePowerHookValue phook = new TunePowerHookValue("hookId", "friendlyName", "defaultValue", "experimentValue", "value",
                                                          "2100-01-25T19:12:45Z", "2200-01-25T19:12:45Z", "variationId", "experimentId", "description", null);
        assertEquals("value", phook.getValue());
    }

    public void testPlainPowerHookReturnsDefaultAsValue() {
        TunePowerHookValue phook = new TunePowerHookValue("hookId", "friendlyName", "defaultValue", "description", null);
        assertEquals("defaultValue", phook.getValue());
    }

    public void testMergeWithPlaylistJsonAssignsFields() throws JSONException {
        JSONObject phookJson = new JSONObject();
        phookJson.put(TunePowerHookValue.VALUE, "val");
        phookJson.put(TunePowerHookValue.EXPERIMENT_VALUE, "value_for_experiment");
        phookJson.put(TunePowerHookValue.START_DATE, "2015-01-25T19:12:45Z");
        phookJson.put(TunePowerHookValue.END_DATE, "2200-01-25T19:12:45Z");
        phookJson.put(TunePowerHookValue.EXPERIMENT_ID, "123");
        phookJson.put(TunePowerHookValue.VARIATION_ID, "234");

        TunePowerHookValue phook = new TunePowerHookValue("hookId", "friendlyName", "defaultValue", "description", null);
        phook.mergeWithPlaylistJson(phookJson);

        assertEquals("value_for_experiment", phook.getValue());
        assertEquals("123", phook.getExperimentId());
        assertEquals("234", phook.getVariationId());
        assertEquals(Date.class, phook.getStartDate().getClass());
        assertEquals(Date.class, phook.getEndDate().getClass());
    }

    public void testJsonSerialization() {
        List<String> approvedValues = new ArrayList<String>();
        approvedValues.add("approvedValue1");
        approvedValues.add("approvedValue2");
        TunePowerHookValue phook = new TunePowerHookValue("hookId", "friendlyName", "defaultValue", "description", approvedValues);
        JSONObject phookJson = phook.toJson();

        JSONArray expectedValues = new JSONArray();
        expectedValues.put("approvedValue1");
        expectedValues.put("approvedValue2");

        try {
            assertEquals("hookId", phookJson.getString(TunePowerHookValue.NAME));
            assertEquals("friendlyName", phookJson.getString(TunePowerHookValue.FRIENDLY_NAME));
            assertEquals("defaultValue", phookJson.getString(TunePowerHookValue.DEFAULT_VALUE));
            assertEquals("description", phookJson.getString(TunePowerHookValue.DESCRIPTION));
            assertEquals(expectedValues.toString(), phookJson.getString(TunePowerHookValue.APPROVED_VALUES));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void testJsonNullSerialization() {
        TunePowerHookValue phook = new TunePowerHookValue(null, null, null, null, null);
        JSONObject phookJson = phook.toJson();
        try {
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.NAME));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.FRIENDLY_NAME));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.DEFAULT_VALUE));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.DESCRIPTION));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.APPROVED_VALUES));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void testJsonEmptyListSerialization() {
        TunePowerHookValue phook = new TunePowerHookValue(null, null, null, null, new ArrayList<String>());
        JSONObject phookJson = phook.toJson();

        try {
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.NAME));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.FRIENDLY_NAME));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.DEFAULT_VALUE));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.DESCRIPTION));
            assertEquals(JSONObject.NULL, phookJson.get(TunePowerHookValue.APPROVED_VALUES));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

}
