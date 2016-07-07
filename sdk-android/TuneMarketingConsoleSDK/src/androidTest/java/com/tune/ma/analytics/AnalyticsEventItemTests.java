package com.tune.ma.analytics;

import com.tune.TuneEventItem;
import com.tune.ma.analytics.model.TuneAnalyticsEventItem;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by johng on 1/11/16.
 */
public class AnalyticsEventItemTests extends TuneAnalyticsTest {
    /**
     * Test that TuneAnalyticsEventItem gets converted from TuneEventItem correctly
     */
    public void testConvertingToTuneAnalyticsEventItem() {
        TuneEventItem itemToConvert = new TuneEventItem("item1");
        itemToConvert.quantity = 2;
        itemToConvert.attribute1 = "attr1";

        TuneAnalyticsEventItem item = new TuneAnalyticsEventItem(itemToConvert);

        assertEquals(itemToConvert.itemname, item.item);
        assertEquals(itemToConvert.quantity, Integer.parseInt(item.quantity));

        TuneAnalyticsVariable variableFromItem = null;
        for (TuneAnalyticsVariable var : item.attributes) {
            variableFromItem = var;
        }

        assertNotNull(variableFromItem);
        assertEquals("attribute_sub1", variableFromItem.getName());
        assertEquals(itemToConvert.attribute1, variableFromItem.getValue());
    }

    /**
     * Test that TuneAnalyticsEventItem toJsonWithHashType produces the expected JSON
     */
    public void testConvertingToTuneAnalyticsEventItemJson() {
        TuneEventItem itemToConvert = new TuneEventItem("item1");
        itemToConvert.quantity = 2;
        itemToConvert.attribute1 = "attr1";

        JSONObject expectedJson = new JSONObject();
        try {
            expectedJson.put("item", itemToConvert.itemname);
            expectedJson.put("unitPrice", Double.toString(itemToConvert.unitPrice));
            expectedJson.put("quantity", Integer.toString(itemToConvert.quantity));
            expectedJson.put("revenue", Double.toString(itemToConvert.revenue));

            JSONArray attributes = new JSONArray();
            attributes.put(new TuneAnalyticsVariable("attribute_sub1", itemToConvert.attribute1).toListOfJsonObjectsForDispatch().get(0));
            expectedJson.put("attributes", attributes);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        JSONObject itemJson = new TuneAnalyticsEventItem(itemToConvert).toJson();

        assertEquals(expectedJson.toString(), itemJson.toString());
    }
}
