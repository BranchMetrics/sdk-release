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
            if (components[i].length() == 0)
                continue;

            String[] keyValue = components[i].split("=");
            if (keyValue.length != 2)
                continue;
            if (keyValue[0].length() == 0)
                continue;
            if (keyValue[0].equals("da"))
                continue; // this is the encrypted data param

            if (params == null)
                params = new Hashtable<String, Object>();
            params.put(keyValue[0], keyValue[1]);
        }

        return true;
    }

    private Hashtable<String, Object> hashFromJSON(JSONObject json) {
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

        if (values.containsKey(TuneUrlKeys.EVENT_ITEMS))
            params.put(kDataItemKey, values.get(TuneUrlKeys.EVENT_ITEMS));

        for (Enumeration<String> keys = values.keys(); keys.hasMoreElements();) {
            String key = keys.nextElement();
            if (!key.equals(TuneUrlKeys.EVENT_ITEMS))
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

    private boolean checkAppValues() {
        boolean retval = ((checkKeyIsEqualToValue(TuneUrlKeys.ADVERTISER_ID,
                TuneTestConstants.advertiserId) || checkKeyIsEqualToValue("adv",
                TuneTestConstants.advertiserId))
                && (checkKeyIsEqualToValue(TuneUrlKeys.PACKAGE_NAME,
                        TuneTestConstants.appId) || checkKeyIsEqualToValue("pn",
                        TuneTestConstants.appId))
                && (checkKeyIsEqualToValue(TuneUrlKeys.APP_VERSION, "0") || checkKeyIsEqualToValue(
                        "av", "0")) && (checkKeyHasValue(TuneUrlKeys.APP_NAME) || checkKeyHasValue("an")));
        if (!retval) {
            Log.d("PARAMS",
                    "app values: "
                            + checkKeyIsEqualToValue(TuneUrlKeys.ADVERTISER_ID,
                                    TuneTestConstants.advertiserId)
                            + " "
                            + checkKeyIsEqualToValue(TuneUrlKeys.PACKAGE_NAME,
                                    TuneTestConstants.appId) + " "
                            + checkKeyIsEqualToValue(TuneUrlKeys.APP_VERSION, "0") + " "
                            + checkKeyHasValue(TuneUrlKeys.APP_NAME));
        }
        return retval;
    }

    private boolean checkSdkValues() {
        return ((checkKeyIsEqualToValue(TuneUrlKeys.SDK, "android") || checkKeyIsEqualToValue("s", "android"))
                && checkKeyHasValue(TuneUrlKeys.SDK_VER)
                && (checkKeyHasValue(TuneUrlKeys.MAT_ID) || checkKeyHasValue("mi"))
                && checkKeyHasValue(TuneUrlKeys.TRANSACTION_ID));
    }

    private boolean checkDeviceValues() {
        boolean retval = ((checkKeyHasValue(TuneUrlKeys.LANGUAGE) || checkKeyHasValue("l"))
                && checkKeyHasValue(TuneUrlKeys.LOCALE)
                && checkKeyHasValue(TuneUrlKeys.SCREEN_DENSITY)
                && checkKeyHasValue(TuneUrlKeys.SCREEN_LAYOUT_SIZE)
                && checkKeyHasValue(TuneUrlKeys.CONNECTION_TYPE)
                && (checkKeyHasValue(TuneUrlKeys.OS_VERSION) || checkKeyHasValue("ov"))
                && checkKeyHasValue(TuneUrlKeys.DEVICE_BUILD)
                && checkKeyHasValue(TuneUrlKeys.DEVICE_CPU_TYPE)
                && (checkKeyHasValue(TuneUrlKeys.DEVICE_BRAND) || checkKeyHasValue("db"))
                && (checkKeyHasValue(TuneUrlKeys.DEVICE_MODEL) || checkKeyHasValue("dm")));

        if (!retval) {
            Log.d("PARAMS", "device values: "
                    + checkKeyHasValue(TuneUrlKeys.LANGUAGE) + " "
                    + checkKeyHasValue(TuneUrlKeys.SCREEN_DENSITY) + " "
                    + checkKeyHasValue(TuneUrlKeys.SCREEN_LAYOUT_SIZE) + " "
                    + checkKeyHasValue(TuneUrlKeys.CONNECTION_TYPE) + " "
                    + checkKeyHasValue(TuneUrlKeys.OS_VERSION) + " "
                    + checkKeyHasValue(TuneUrlKeys.DEVICE_CPU_TYPE) + " "
                    + checkKeyHasValue(TuneUrlKeys.DEVICE_BRAND) + " "
                    + checkKeyHasValue(TuneUrlKeys.DEVICE_MODEL));
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
                foundName = TuneEventItem.ITEM;
                break;
            case "unitPrice":
                foundName = TuneEventItem.UNIT_PRICE;
                break;
            case "attribute1":
                foundName = TuneUrlKeys.ATTRIBUTE1;
                break;
            case "attribute2":
                foundName = TuneUrlKeys.ATTRIBUTE2;
                break;
            case "attribute3":
                foundName = TuneUrlKeys.ATTRIBUTE3;
                break;
            case "attribute4":
                foundName = TuneUrlKeys.ATTRIBUTE4;
                break;
            case "attribute5":
                foundName = TuneUrlKeys.ATTRIBUTE5;
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
