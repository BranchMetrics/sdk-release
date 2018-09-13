package com.tune;

import org.json.JSONObject;

/**
 * Interface class that can be implemented to look at TUNE request statuses.
 * This class is used exclusively for testing purposes.
 */
public interface ITuneListener {
    /**
     * Callback for when an event has been enqueued and is about to be sent out.
     * @param url Full URL of the request to be made.
     * @param postData Any JSON that should be sent as POST data.
     */
    void enqueuedRequest(String url, JSONObject postData);

    /**
     * Callback for when an event has succeeded, with server response.
     * @param url Full URL of the request that was made.
     * @param data TUNE server response for a successful request.
     */
    void didSucceedWithData(String url, JSONObject data);

    /**
     * Callback for when an event has failed, with server response.
     * @param url Full URL of the request that was made.
     * @param error TUNE server response for a failed request, with error data.
     */
    void didFailWithError(String url, JSONObject error);
}
