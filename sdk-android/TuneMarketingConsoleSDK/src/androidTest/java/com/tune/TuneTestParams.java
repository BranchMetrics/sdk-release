package com.tune;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Iterator;

public class TuneTestParams extends java.lang.Object {
    private Hashtable<String, Object> params;

    private final String kDataItemKey = "testBodyDataItems";

    public TuneTestParams() {
        params = new Hashtable<String, Object>();
    }

    @Override
    public String toString() {
        if (params == null)
            return "(null)";
        return params.toString();
    }

    public boolean extractParamsString(String string) {
        // Log.d( "PARAMS", "extracting from " + string );
        String[] components = string.split("&");
        for (int i = 0; i < components.length; i++) {
            if (components[i].equals(""))
                continue;

            String[] keyValue = components[i].split("=");
            if (keyValue.length != 2)
                continue;
            if (keyValue[0].equals(""))
                continue;
            if (keyValue[0].equals("da"))
                continue; // this is the encrypted data param

            if (params == null)
                params = new Hashtable<String, Object>();
            params.put(keyValue[0], keyValue[1]);
        }

        return true;
    }

    public Hashtable<String, Object> hashFromJSON(JSONObject json) {
        Hashtable<String, Object> hash = new Hashtable<String, Object>();

        Iterator<?> iter = json.keys();
        while (iter.hasNext()) {
            String key = (String) iter.next();
            try {
                Object value = json.get(key);

                if (value instanceof JSONArray) {
                    JSONArray objects = (JSONArray) value;
                    Object array[] = new Object[objects.length()];
                    for (int i = 0; i < objects.length(); i++) {
                        Object object = objects.get(i);
                        if (object instanceof JSONObject)
                            array[i] = hashFromJSON((JSONObject) object);
                        else
                            Log.w("PARAMS",
                                    "found unexpected object inside JSON array: "
                                            + object.getClass());
                    }
                    hash.put(key, array);
                } else {
                    hash.put(key, value);
                }
            } catch (JSONException e) {
                e.printStackTrace();
                return null;
            }
        }

        return hash;
    }

    public boolean extractParamsJSON(JSONObject json) {
        // Log.d( "PARAMS", "extracting JSON from " + json );
        Hashtable<String, Object> values = hashFromJSON(json);

        if (params == null)
            params = new Hashtable<String, Object>();

        if (values.containsKey("data"))
            params.put(kDataItemKey, values.get("data"));

        for (Enumeration<String> keys = values.keys(); keys.hasMoreElements();) {
            String key = keys.nextElement();
            if (!key.equals("data"))
                params.put(key, values.get(key));
        }

        return true;
    }

    public String valueForKey(String key) {
        if (params == null)
            return null;
        if (params.get(key) == null)
            return null;
        return params.get(key).toString();
    }

    public boolean checkIsEmpty() {
        return (params == null || params.isEmpty());
    }

    public boolean checkKeyHasValue(String key) {
        return (!checkIsEmpty() && params.get(key) != null);
    }

    public boolean checkKeyIsEqualToValue(String key, String value) {
        return (checkKeyHasValue(key) && params.get(key).equals(value));
    }

    public boolean checkAppValues() {
        boolean retval = ((checkKeyIsEqualToValue("advertiser_id",
                TuneTestConstants.advertiserId) || checkKeyIsEqualToValue("adv",
                TuneTestConstants.advertiserId))
                && (checkKeyIsEqualToValue("package_name",
                        TuneTestConstants.appId) || checkKeyIsEqualToValue("pn",
                        TuneTestConstants.appId))
                && (checkKeyIsEqualToValue("app_version", "0") || checkKeyIsEqualToValue(
                        "av", "0")) && (checkKeyHasValue("app_name") || checkKeyHasValue("an")));
        if (!retval) {
            Log.d("PARAMS",
                    "app values: "
                            + checkKeyIsEqualToValue("advertiser_id",
                                    TuneTestConstants.advertiserId)
                            + " "
                            + checkKeyIsEqualToValue("package_name",
                                    TuneTestConstants.appId) + " "
                            + checkKeyIsEqualToValue("app_version", "0") + " "
                            + checkKeyHasValue("app_name"));
        }
        return retval;
    }

    public boolean checkSdkValues() {
        return ((checkKeyIsEqualToValue("sdk", "android") || checkKeyIsEqualToValue(
                "s", "android"))
                && checkKeyHasValue("ver")
                && (checkKeyHasValue("mat_id") || checkKeyHasValue("mi")) && checkKeyHasValue("transaction_id"));
    }

    public boolean checkDeviceValues() {
        boolean retval = ((checkKeyHasValue("language") || checkKeyHasValue("l"))
                && checkKeyHasValue("locale")
                && checkKeyHasValue("screen_density")
                && checkKeyHasValue("screen_layout_size")
                && checkKeyHasValue("connection_type")
                && (checkKeyHasValue("os_version") || checkKeyHasValue("ov"))
                && checkKeyHasValue("build")
                && checkKeyHasValue("device_cpu_type")
                && (checkKeyHasValue("device_brand") || checkKeyHasValue("db"))
                && (checkKeyHasValue("device_model") || checkKeyHasValue("dm")));

        if (!retval) {
            Log.d("PARAMS", "device values: "
                    + checkKeyHasValue("language") + " "
                    + checkKeyHasValue("screen_density") + " "
                    + checkKeyHasValue("screen_layout_size") + " "
                    + checkKeyHasValue("connection_type") + " "
                    + checkKeyHasValue("os_version") + " "
                    + checkKeyHasValue("device_cpu_type") + " "
                    + checkKeyHasValue("device_brand") + " "
                    + checkKeyHasValue("device_model"));
        }
        return retval;
    }

    public boolean checkDefaultValues() {
        boolean appValuesOk = checkAppValues();
        if (!appValuesOk)
            Log.d("PARAMS", "app values check failed for " + params);
        boolean sdkValuesOk = checkSdkValues();
        if (!sdkValuesOk)
            Log.d("PARAMS", "sdk values check failed for " + params);
        boolean deviceValuesOk = checkDeviceValues();
        if (!deviceValuesOk)
            Log.d("PARAMS", "device values check failed for " + params);

        return (appValuesOk && sdkValuesOk && deviceValuesOk);
    }

    public boolean checkDataItemByName(TuneEventItem item,
            Hashtable<String, String> foundItem, String name) {
        String foundName = new String(name);
        switch (foundName) {
            case "itemname":
                foundName = "item";
                break;
            case "unitPrice":
                foundName = "unit_price";
                break;
            case "attribute1":
                foundName = "attribute_sub1";
                break;
            case "attribute2":
                foundName = "attribute_sub2";
                break;
            case "attribute3":
                foundName = "attribute_sub3";
                break;
            case "attribute4":
                foundName = "attribute_sub4";
                break;
            case "attribute5":
                foundName = "attribute_sub5";
                break;
            default:
        }

        if ((item.getAttrStringByName(name) != null && !foundItem
                .containsKey(foundName))
                || (item.getAttrStringByName(name) == null && foundItem
                        .containsKey(foundName))
                || (item.getAttrStringByName(name) != null && !item
                        .getAttrStringByName(name).equals(
                                foundItem.get(foundName).toString()))) {
            Log.i("PARAMS",
                    "item field '" + name + "' must be identical: sent '"
                            + item.getAttrStringByName(name) + "' got '"
                            + foundItem.get(foundName) + "'");
            return false;
        }
        return true;
    }

    public boolean checkDataItems(ArrayList<TuneEventItem> items) {
        if (params == null) {
            Log.e("PARAMS", "null params");
            return false;
        }

        Object[] foundItems = (Object[]) params.get(kDataItemKey);
        if (foundItems == null) {
            Log.e("PARAMS", "null foundItems");
            return false;
        }
        if (foundItems.length != items.size()) {
            Log.e("PARAMS", items.size() + " items sent, " + foundItems.length
                    + " recovered");
            return false;
        }

        for (int i = 0; i < items.size(); i++) {
            @SuppressWarnings("unchecked")
            Hashtable<String, String> foundItem = (Hashtable<String, String>) foundItems[i];
            TuneEventItem item = items.get(i);
            if (!checkDataItemByName(item, foundItem, "itemname"))
                return false;
            if (!checkDataItemByName(item, foundItem, "quantity"))
                return false;
            if (!checkDataItemByName(item, foundItem, "unitPrice"))
                return false;
            if (!checkDataItemByName(item, foundItem, "revenue"))
                return false;
            if (!checkDataItemByName(item, foundItem, "attribute1"))
                return false;
            if (!checkDataItemByName(item, foundItem, "attribute2"))
                return false;
            if (!checkDataItemByName(item, foundItem, "attribute3"))
                return false;
            if (!checkDataItemByName(item, foundItem, "attribute4"))
                return false;
            if (!checkDataItemByName(item, foundItem, "attribute5"))
                return false;
        }

        return true;
    }
}
