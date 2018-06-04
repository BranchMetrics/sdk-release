package com.tune;

import org.json.JSONObject;

/**
 * Interface class that can be implemented to look at TUNE request statuses.
 */
public interface TuneListener {
    /**
     * Callback for when an event is enqueued, and returns the advertiser ref ID if the request, if any.
     * @param refId Advertiser ref ID of the request
     * @deprecated This method will be removed in Tune Android SDK v6.0.0. Use {@link TuneListener#enqueuedRequest(String url, JSONObject postData)}
     */
    public abstract void enqueuedActionWithRefId(String refId);

    /**
     * Callback for when an event has been enqueued and is about to be sent out.
     * @param url Full URL of the request to be made.
     * @param postData Any JSON that should be sent as POST data.
     */
    public abstract void enqueuedRequest(String url, JSONObject postData);

    /**
     * Callback for when an event has succeeded, with server response.
     * @param data TUNE server response for a successful request.
     */
    public abstract void didSucceedWithData(JSONObject data);

    /**
     * Callback for when an event has failed, with server response.
     * @param error TUNE server response for a failed request, with error data.
     */
    public abstract void didFailWithError(JSONObject error);
}
