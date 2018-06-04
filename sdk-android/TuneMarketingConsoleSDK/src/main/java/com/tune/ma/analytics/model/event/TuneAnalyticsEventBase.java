package com.tune.ma.analytics.model.event;

import com.tune.TuneParameters;
import com.tune.TuneUtils;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsEventItem;
import com.tune.ma.analytics.model.TuneAnalyticsSubmitter;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneEventType;
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
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public abstract class TuneAnalyticsEventBase {
    protected static final String APPLICATION_CATEGORY = "Application";
    static final String CUSTOM_CATEGORY = "Custom";

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

    private TuneAnalyticsSubmitter submitter;
    private TuneEventType eventType;

    private String action;
    private String appId;
    private String category;
    private String control;
    private String controlEvent;
    private String eventId;

    private Set<TuneAnalyticsVariable> tags;
    private List<TuneAnalyticsEventItem> items;
    private List<TuneAnalyticsVariable> profile;

    private double sessionTime = -1;
    private long timeStamp = -1L;

    public TuneAnalyticsEventBase() {
        this.timeStamp = System.currentTimeMillis() / 1000L;

        if (TuneManager.getInstance() != null) {
            if (TuneManager.getInstance().getProfileManager() != null) {
                this.submitter = new TuneAnalyticsSubmitter(TuneManager.getInstance().getProfileManager());
                this.appId = TuneManager.getInstance().getProfileManager().getAppId();
                this.profile = TuneManager.getInstance().getProfileManager().getCopyOfNonRedactedVars(TuneParameters.getRedactedKeys());
            }
            if (TuneManager.getInstance().getSessionManager() != null) {
                this.sessionTime = TuneManager.getInstance().getSessionManager().getSecondsSinceSessionStart();
            }
        }

        this.items = new ArrayList<>();
        this.tags = new HashSet<>();
    }

    public String getAction() {
        return action;
    }

    protected void setAction(String action) {
        this.action = action;
    }

    public String getCategory() {
        return category;
    }

    protected void setCategory(String category) {
        this.category = category;
    }

    public String getControl() {
        return control;
    }

    protected void setControl(String control) {
        this.control = control;
    }

    public String getControlEvent() {
        return controlEvent;
    }

    protected void setControlEvent(String controlEvent) {
        this.controlEvent = controlEvent;
    }

    public String getEventId() {
        return eventId;
    }

    protected void setEventId(String id) {
        this.eventId = id;
    }

    public TuneEventType getEventType() {
        return eventType;
    }

    protected void setEventType(TuneEventType eventType) { this.eventType = eventType; }

    public List<TuneAnalyticsEventItem> getItems() {
        return items;
    }

    protected void setItems(List<TuneAnalyticsEventItem> items) {
        this.items = items;
    }
    protected void addItem(TuneAnalyticsEventItem item) { this.items.add(item); }

    public Set<TuneAnalyticsVariable> getTags() {
        return tags;
    }

    public void setTags(Set<TuneAnalyticsVariable> tags) {
        this.tags = tags;
    }
    protected void addTag(TuneAnalyticsVariable tag) {
        this.tags.add(tag);
    }
    protected void addTags(Set<TuneAnalyticsVariable> tags) {
        this.tags.addAll(tags);
    }

    public long getTimeStamp() {
        return timeStamp;
    }

    protected void setTimeStamp(long timeStamp) {
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

    public String getFiveline() {
        StringBuilder builder = new StringBuilder();

        if (category != null) {
            builder.append(category);
        }

        builder.append("|");

        if (controlEvent != null) {
            builder.append(controlEvent);
        }

        builder.append("|");

        if (control != null) {
            builder.append(control);
        }

        builder.append("|");

        if (action != null) {
            builder.append(action);
        }

        builder.append("|");

        if (eventType != null) {
            builder.append(eventType);
        }

        return builder.toString();
    }

    public String getEventMd5() {
        return TuneUtils.md5(getFiveline());
    }
}
