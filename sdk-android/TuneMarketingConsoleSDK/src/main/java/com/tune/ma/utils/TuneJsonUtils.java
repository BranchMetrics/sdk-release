package com.tune.ma.utils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

/**
 * Created by kristine on 1/27/16.
 */
public class TuneJsonUtils {

    public static ArrayList<String> JSONArrayToStringArrayList(JSONArray jsonArray) {
        ArrayList<String> convertedList = new ArrayList<String>();
        for(int i = 0; i< jsonArray.length(); i++) {
            try {
                convertedList.add(jsonArray.getString(i));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        return convertedList;
    }

    public static String getString(final JSONObject json, final String key) {
        try {
            return json.getString(key);
        } catch (JSONException e) {
            return null;
        }
    }

    public static JSONObject getJSONObject(final JSONObject json, final String key) {
        try {
            return json.getJSONObject(key);
        } catch (JSONException e) {
            return null;
        }
    }

    public static void put(JSONObject json, final String key, final Object value) {
        try {
            if (value == null) {
                json.put(key, JSONObject.NULL);
                return;
            }

            // Handle Maps
            if (value instanceof Map) {
                Map map = (Map) value;
                // Store empty maps as null
                if (map.size() == 0) {
                    json.put(key, JSONObject.NULL);
                    return;
                }

                // Convert Map to JSONObject
                JSONObject mapJson = new JSONObject();
                Iterator entries = map.entrySet().iterator();
                while (entries.hasNext()) {
                    Map.Entry thisEntry = (Map.Entry) entries.next();
                    String mapKey = (String) thisEntry.getKey();
                    Object mapValue = thisEntry.getValue();

                    // For approved values, convert List values to JSONArray
                    if (mapValue instanceof List) {
                        List list = (List) mapValue;
                        mapJson.put(mapKey, listToJson(list));
                    } else {
                        // For default data, put the string in the JSONObject
                        mapJson.put(mapKey, mapValue);
                    }
                }
                json.put(key, mapJson);
                return;
            }

            if (value instanceof List) {
                List list = (List) value;
                // Store empty lists as null
                if (list.size() == 0) {
                    json.put(key, JSONObject.NULL);
                    return;
                }
                json.put(key, listToJson(list));
                return;
            }

            json.put(key, value);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static String getPrettyJson(JSONObject jsonObject) {
        try {
            return jsonObject.toString(2);
        } catch (JSONException e) {
            //e.printStackTrace();
            return "Error building pretty json!";
        }
    }
    
    public static JSONArray listToJson(List list) {
        JSONArray jsonArray = new JSONArray();
        for (int i = 0 ; i < list.size(); i++) {
            try {
                jsonArray.put(i, list.get(i));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return jsonArray;
    }

    /****************************************
     * Functions Related to Pretty Printing *
     ****************************************/

    private static String tabWidth = "  ";
    private static int cutOffDepth = 2;

    private static String getTabs(int level) {
        StringBuilder result = new StringBuilder();
        if (level < cutOffDepth + 1) {
            for (int i = 0; i < level; i += 1) {
                result.append(tabWidth);
            }
        }
        return result.toString();
    }

    private static String prettyPrintJson(JSONObject jsonObject, int level) throws JSONException {
        Iterator<String> keys = jsonObject.keys();
        StringBuilder result = new StringBuilder();

        List<String> list = new LinkedList<String>();
        while (keys.hasNext()) {
            list.add(keys.next());
        }
        Collections.sort(list);
        Iterator<String> iter = list.iterator();
        while (iter.hasNext()) {
            String key = iter.next();
            Object obj = jsonObject.get(key);

            if (obj instanceof JSONObject) {
                result.append(TuneStringUtils.format("%s\"%s\": ", getTabs(level), key));
                result.append(ppAnalyticsEvent((JSONObject) obj, level));
            } else if (obj instanceof JSONArray) {
                result.append(TuneStringUtils.format("%s\"%s\": ", getTabs(level), key));
                result.append(ppJSONArray((JSONArray) obj, level));
            } else {
                if (obj instanceof String) {
                    result.append(TuneStringUtils.format("%s\"%s\": \"%s\"", getTabs(level), key, obj.toString()));
                } else {
                    result.append(TuneStringUtils.format("%s\"%s\": %s", getTabs(level), key, obj.toString()));
                }
            }

            if (iter.hasNext()) {
                result.append(", ");
            }

            result.append(level > cutOffDepth ? "" : "\n");

        }

        return result.toString();
    }

    private static String prettyPrintJson(JSONArray jsonObject, int level) throws JSONException {
        StringBuilder result = new StringBuilder();

        for (int i = 0; i < jsonObject.length(); i += 1) {
            Object obj = jsonObject.get(i);

            if (obj instanceof JSONObject) {
                result.append(ppAnalyticsEvent((JSONObject) obj, level));
            } else if (obj instanceof JSONArray) {
                result.append(ppJSONArray((JSONArray)obj, level));
            } else {

                if (obj instanceof String) {
                    result.append(TuneStringUtils.format("%s\"%s\"", getTabs(level), obj.toString()));
                } else {
                    result.append(TuneStringUtils.format("%s%s", getTabs(level), obj.toString()));
                }
            }


            if (i < jsonObject.length()) {
                result.append(", ");
            }

            result.append(level > cutOffDepth ? "" : "\n");

        }

        return result.toString();
    }

    public static String ppAnalyticsEvent(JSONObject o, int level) throws JSONException {
        StringBuilder result = new StringBuilder();
        String r = prettyPrintJson(o, level+1);
        result.append(TuneStringUtils.format("%s{%s", getTabs(level), level >= cutOffDepth || r.length() == 0 ? "" : "\n"));
        result.append(r);
        result.append(TuneStringUtils.format("%s}", level >= cutOffDepth || r.length() == 0  ? "" : getTabs(level)));

        return result.toString();
    }

    private static String ppJSONArray(JSONArray o, int level) throws JSONException {
        StringBuilder result = new StringBuilder();
        String r = prettyPrintJson(o, level+1);
        result.append(TuneStringUtils.format("[%s", level >= cutOffDepth || r.length() == 0  ? "" : "\n"));
        result.append(r);
        result.append(TuneStringUtils.format("%s]", level >= cutOffDepth || r.length() == 0  ? "" : getTabs(level)));

        return result.toString();
    }
}
