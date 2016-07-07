package com.tune.ma.analytics.model;

import android.text.TextUtils;

import com.tune.TuneEventItem;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Created by johng on 1/7/16.
 */
public class TuneAnalyticsEventItem {
    public String item;
    public String unitPrice;
    public String quantity;
    public String revenue;
    public Set<TuneAnalyticsVariable> attributes;

    public TuneAnalyticsEventItem(TuneEventItem eventItem) {
        this.item = eventItem.itemname;
        this.unitPrice = Double.toString(eventItem.unitPrice);
        this.quantity = Integer.toString(eventItem.quantity);
        this.revenue = Double.toString(eventItem.revenue);
        this.attributes = new HashSet<TuneAnalyticsVariable>();

        // Convert event item attributes to TuneAnalyticsVariables
        if (!TextUtils.isEmpty(eventItem.attribute1)) {
            this.attributes.add(new TuneAnalyticsVariable(TuneEventItem.ATTRIBUTE1, eventItem.attribute1));
        }
        if (!TextUtils.isEmpty(eventItem.attribute2)) {
            this.attributes.add(new TuneAnalyticsVariable(TuneEventItem.ATTRIBUTE2, eventItem.attribute2));
        }
        if (!TextUtils.isEmpty(eventItem.attribute3)) {
            this.attributes.add(new TuneAnalyticsVariable(TuneEventItem.ATTRIBUTE3, eventItem.attribute3));
        }
        if (!TextUtils.isEmpty(eventItem.attribute4)) {
            this.attributes.add(new TuneAnalyticsVariable(TuneEventItem.ATTRIBUTE4, eventItem.attribute4));
        }
        if (!TextUtils.isEmpty(eventItem.attribute5)) {
            this.attributes.add(new TuneAnalyticsVariable(TuneEventItem.ATTRIBUTE5, eventItem.attribute5));
        }
    }

    public JSONObject toJson() {
        JSONObject object = new JSONObject();
        try {
            object.put(TuneEventItem.ITEM, item);
            object.put(TuneEventItem.UNIT_PRICE_CAMEL, unitPrice);
            object.put(TuneEventItem.QUANTITY, quantity);
            object.put(TuneEventItem.REVENUE, revenue);

            // Create JSONArray for attributes
            if (attributes != null) {
                JSONArray attributesArray = new JSONArray();
                // Add JSONObject for each item
                for (TuneAnalyticsVariable attribute : attributes) {
                    List<JSONObject> listOfVariablesAsJson = attribute.toListOfJsonObjectsForDispatch();
                    for (JSONObject attributeJson : listOfVariablesAsJson) {
                        attributesArray.put(attributeJson);
                    }
                }
                object.put("attributes", attributesArray);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return object;
    }
}
