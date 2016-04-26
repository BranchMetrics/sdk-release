package com.tune.ma.analytics.model.event;

import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsEventItem;
import com.tune.ma.analytics.model.TuneAnalyticsSubmitter;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.TuneEventType;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Base class for all analytics events.
 */
public abstract class TuneAnalyticsEventBase {
    public static final String APPLICATION_CATEGORY = "Application";
    public static final String CUSTOM_CATEGORY = "Custom";

    private static final String SCHEMA_VERSION_VALUE = "2.0";

    // Event JSON keys
    private static final String ACTION = "action";
    private static final String APP_ID = "appId";
    private static final String CATEGORY = "category";
    private static final String CONTROL = "control";
    private static final String CONTROL_EVENT = "controlEvent";
    private static final String EVENT_TYPE = "type";
    private static final String ITEMS = "items";
    private static final String PROFILE = "profile";
    private static final String SCHEMA_VERSION = "schemaVersion";
    private static final String SESSION_TIME = "sessionTime";
    private static final String SUBMITTER = "submitter";
    private static final String TAGS = "tags";
    private static final String TIMESTAMP = "timestamp";

    protected TuneAnalyticsSubmitter submitter;
    protected TuneEventType eventType;

    protected String action;
    protected String appId;
    protected String category;
    protected String control;
    protected String controlEvent;
    protected String eventId;

    protected Set<TuneAnalyticsVariable> tags;
    protected List<TuneAnalyticsEventItem> items;
    protected List<TuneAnalyticsVariable> profile;

    protected double sessionTime = -1;
    protected double timeStamp = -1;

    public TuneAnalyticsEventBase() {
        this.timeStamp = System.currentTimeMillis() / 1000.0;

        this.submitter = new TuneAnalyticsSubmitter(TuneManager.getInstance().getProfileManager());

        this.appId = TuneManager.getInstance().getProfileManager().getAppId();

        this.profile = TuneManager.getInstance().getProfileManager().getCopyOfVars();

        this.sessionTime = TuneManager.getInstance().getSessionManager().getSecondsSinceSessionStart();

        this.items = new ArrayList<TuneAnalyticsEventItem>();

        this.tags = new HashSet<TuneAnalyticsVariable>();
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getControl() {
        return control;
    }

    public void setControl(String control) {
        this.control = control;
    }

    public String getControlEvent() {
        return controlEvent;
    }

    public void setControlEvent(String controlEvent) {
        this.controlEvent = controlEvent;
    }

    public String getEventId() {
        return eventId;
    }

    public void setEventId(String id) {
        this.eventId = id;
    }

    public TuneEventType getEventType() {
        return eventType;
    }

    public List<TuneAnalyticsEventItem> getItems() {
        return items;
    }

    public void setItems(List<TuneAnalyticsEventItem> items) {
        this.items = items;
    }

    public Set<TuneAnalyticsVariable> getTags() {
        return tags;
    }

    public void setTags(Set<TuneAnalyticsVariable> tags) {
        this.tags = tags;
    }

    public double getTimeStamp() {
        return timeStamp;
    }

    public void setTimeStamp(long timeStamp) {
        this.timeStamp = timeStamp;
    }

    public JSONObject toJson() {
        JSONObject object = new JSONObject();
        try {
            object.put(SCHEMA_VERSION, SCHEMA_VERSION_VALUE);

            // Add submitter info to JSON
            JSONObject submitterJson = new JSONObject();
            TuneJsonUtils.put(submitterJson, TuneAnalyticsSubmitter.SESSION_ID, submitter.getSessionId());
            TuneJsonUtils.put(submitterJson, TuneAnalyticsSubmitter.DEVICE_ID, submitter.getDeviceId());
            TuneJsonUtils.put(submitterJson, TuneAnalyticsSubmitter.GAID, submitter.getGoogleAdvertisingId());
            object.put(SUBMITTER, submitterJson);

            TuneJsonUtils.put(object, ACTION, action);
            TuneJsonUtils.put(object, APP_ID, appId);
            TuneJsonUtils.put(object, CATEGORY, category);
            TuneJsonUtils.put(object, CONTROL, control);
            TuneJsonUtils.put(object, CONTROL_EVENT, controlEvent);
            TuneJsonUtils.put(object, EVENT_TYPE, eventType.toString());
            TuneJsonUtils.put(object, SESSION_TIME, sessionTime);
            TuneJsonUtils.put(object, TIMESTAMP, timeStamp);

            // Construct JSONArray for tags
            if (tags != null) {
                JSONArray tagsArray = new JSONArray();
                // Add JSONObject for each tag
                for (TuneAnalyticsVariable tag : tags) {
                    List<JSONObject> listOfVariablesAsJson = tag.toListOfJsonObjectsForDispatch();
                    for (JSONObject tagJson : listOfVariablesAsJson) {
                        tagsArray.put(tagJson);
                    }
                }
                object.put(TAGS, tagsArray);
            }

            // Construct JSONArray for event items
            if (items != null) {
                JSONArray itemsArray = new JSONArray();
                // Add JSONObject for each item
                for (TuneAnalyticsEventItem item : items) {
                    itemsArray.put(item.toJson());
                }
                object.put(ITEMS, itemsArray);
            }

            JSONArray profileArray = new JSONArray();
            // Add JSONObject for each item
            for (TuneAnalyticsVariable p : profile) {
                List<JSONObject> listOfVariablesAsJson = p.toListOfJsonObjectsForDispatch();
                for (JSONObject pJson : listOfVariablesAsJson) {
                    profileArray.put(pJson);
                }
            }
            object.put(PROFILE, profileArray);

        } catch (JSONException e) {
            e.printStackTrace();
        }
        return object;
    }
}
