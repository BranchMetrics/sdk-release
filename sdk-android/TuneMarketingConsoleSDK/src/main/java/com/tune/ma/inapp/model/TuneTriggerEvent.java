package com.tune.ma.inapp.model;

import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import static com.tune.ma.inapp.TuneInAppMessageConstants.LIFETIME_MAXIMUM_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIMIT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_DAYS;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_EVENTS;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_INSTALL;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_SESSION;
import static com.tune.ma.inapp.model.TuneTriggerEvent.Scope.DAYS;
import static com.tune.ma.inapp.model.TuneTriggerEvent.Scope.EVENTS;
import static com.tune.ma.inapp.model.TuneTriggerEvent.Scope.INSTALL;
import static com.tune.ma.inapp.model.TuneTriggerEvent.Scope.SESSION;

/**
 * Created by johng on 4/24/17.
 */

public class TuneTriggerEvent {
    public enum Scope {
        INSTALL,
        SESSION,
        DAYS,
        EVENTS
    };

    protected String eventMd5;
    protected int lifetimeMaximum;
    protected int limit;
    protected Scope scope;

    public TuneTriggerEvent(String eventMd5, JSONObject frequencyJson) {
        this.eventMd5 = eventMd5;

        this.lifetimeMaximum = TuneJsonUtils.getInt(frequencyJson, LIFETIME_MAXIMUM_KEY);
        this.limit = TuneJsonUtils.getInt(frequencyJson, LIMIT_KEY);

        String scopeString = TuneJsonUtils.getString(frequencyJson, SCOPE_KEY);
        switch (scopeString) {
            case SCOPE_VALUE_SESSION:
                this.scope = SESSION;
                break;
            case SCOPE_VALUE_DAYS:
                this.scope = DAYS;
                break;
            case SCOPE_VALUE_EVENTS:
                this.scope = EVENTS;
                break;
            case SCOPE_VALUE_INSTALL:
            default:
                this.scope = INSTALL;
                break;
        }
    }

    public String getEventMd5() {
        return eventMd5;
    }

    public int getLifetimeMaximum() {
        return lifetimeMaximum;
    }

    public int getLimit() {
        return limit;
    }

    public Scope getScope() {
        return scope;
    }

    @Override
    public String toString() {
        return "TuneTriggerEvent{" +
                "eventMd5='" + eventMd5 + '\'' +
                ", lifetimeMaximum=" + lifetimeMaximum +
                ", limit=" + limit +
                ", scope=" + scope +
                '}';
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == this) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (!TuneTriggerEvent.class.isAssignableFrom(obj.getClass())) {
            return false;
        }
        final TuneTriggerEvent other = (TuneTriggerEvent) obj;
        if ((this.eventMd5 == null) ? (other.eventMd5 != null) : !this.eventMd5.equals(other.eventMd5)) {
            return false;
        }
        if (this.lifetimeMaximum != other.lifetimeMaximum) {
            return false;
        }
        if (this.limit != other.limit) {
            return false;
        }

        return this.scope == other.scope;
    }

    @Override
    public int hashCode() {
        int result = eventMd5 != null ? eventMd5.hashCode() : 0;
        result = 31 * result + lifetimeMaximum;
        result = 31 * result + limit;
        result = 31 * result + (scope != null ? scope.hashCode() : 0);
        return result;
    }
}
