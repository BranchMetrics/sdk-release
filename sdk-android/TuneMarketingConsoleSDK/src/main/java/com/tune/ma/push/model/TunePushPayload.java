package com.tune.ma.push.model;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Iterator;

/**
 * model for TMA push payloads:
 * { "ANA": {"DA":"<deepaction name>","DAD":{"<parameter name 1>":"<parameter value 1>", "<parameter name 2>":"<parameter value 2>"}}}
 * == OR ==
 * { "ANA": {"URL":"<deep link URL>"} }
 */
public class TunePushPayload {
    private static final String JSON_OPEN_ACTION = "ANA";

    private TunePushOpenAction onOpenAction;
    private JSONObject userExtraPayloadParams;

    public TunePushPayload(String json) throws JSONException {
        JSONObject object = new JSONObject(json);

        // In test pushes we are not guaranteed to have an open action field
        if (object.has(JSON_OPEN_ACTION)) {
            onOpenAction = new TunePushOpenAction(object.getJSONObject(JSON_OPEN_ACTION));
            // The extra payload params the user sets is everything but our 'ANA' field
            object.remove(JSON_OPEN_ACTION);
        }
        userExtraPayloadParams = object;
    }

    public TunePushOpenAction getOnOpenAction() {
        return onOpenAction;
    }

    public JSONObject getUserExtraPayloadParams() {
        return userExtraPayloadParams;
    }

    public boolean isOpenActionDeepAction() {
        return getOnOpenAction() != null && getOnOpenAction().getDeepActionId() != null;
    }

    public boolean isOpenActionDeepLink() {
        return getOnOpenAction() != null && getOnOpenAction().getDeepLinkURL() != null;
    }

    public boolean isNeitherDeepActionOrDeepLink() {
        return getOnOpenAction() == null || getOnOpenAction().isNeitherPowerHookNorDeepLink();
    }

    @Override
    public String toString() {
        return toJson().toString();
    }

    public JSONObject toJson() {
        JSONObject object = new JSONObject();
        try {
            if (onOpenAction != null) {
                object.put(JSON_OPEN_ACTION, onOpenAction.toJson());
            }

            Iterator<String> userParams = userExtraPayloadParams.keys();
            while (userParams.hasNext()) {
                String keyName = userParams.next();
                object.put(keyName, userExtraPayloadParams.get(keyName));
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return object;
    }
}
