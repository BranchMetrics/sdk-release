package com.mobileapptracker;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import android.net.Uri;
import android.util.Log;

class MATUrlRequester {
    public void requestDeeplink(MATDeferredDplinkr dplinkr) {
        String deeplink = "";
        InputStream is = null;
        
        // Construct deeplink endpoint url
        Uri.Builder uri = new Uri.Builder();
        uri.scheme("https")
           .authority(dplinkr.getAdvertiserId() + "." + MATConstants.DEEPLINK_DOMAIN)
           .appendPath("v1")
           .appendPath("link.txt")
           .appendQueryParameter("platform", "android")
           .appendQueryParameter("advertiser_id", dplinkr.getAdvertiserId())
           .appendQueryParameter("ver", MATConstants.SDK_VERSION)
           .appendQueryParameter("package_name", dplinkr.getPackageName())
           .appendQueryParameter("ad_id", ((dplinkr.getGoogleAdvertisingId() != null) ? dplinkr.getGoogleAdvertisingId() : dplinkr.getAndroidId()))
           .appendQueryParameter("user_agent", dplinkr.getUserAgent());
        
        if (dplinkr.getGoogleAdvertisingId() != null) {
            uri.appendQueryParameter("google_ad_tracking_disabled", Integer.toString(dplinkr.getGoogleAdTrackingLimited()));
        }
        
        try {
            URL myurl = new URL(uri.build().toString());
            HttpURLConnection conn = (HttpURLConnection) myurl.openConnection();
            // Set TUNE conversion key in request header
            conn.setRequestProperty("X-MAT-Key", dplinkr.getConversionKey());
            conn.setRequestMethod("GET");
            conn.setDoInput(true);
            
            conn.connect();
            
            boolean error = false;
            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                is = conn.getInputStream();
            } else {
                error = true;
                is = conn.getErrorStream();
            }
            
            deeplink = MATUtils.readStream(is);
            MATDeeplinkListener listener = dplinkr.getListener();
            if (listener != null) {
                if (error) {
                    // Notify listener of error
                    listener.didFailDeeplink(deeplink);
                } else {
                    // Notify listener of deeplink url
                    listener.didReceiveDeeplink(deeplink);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                is.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Does an HTTP request to the given url, GET or POST based on whether json was passed or not
     * @param url the url to hit
     * @param json JSONObject with event item and IAP verification json, if not null or empty then will POST to url
     * @return JSONObject of the server response, null if request failed
     */
    protected static JSONObject requestUrl(String url, JSONObject json, boolean debugMode) {
        InputStream is = null;
        
        try {
            URL myurl = new URL(url);
            HttpURLConnection conn = (HttpURLConnection) myurl.openConnection();
            conn.setReadTimeout(MATConstants.TIMEOUT);
            conn.setConnectTimeout(MATConstants.TIMEOUT);
            conn.setDoInput(true);
            
            // If no JSON passed, do HttpGet
            if (json == null || json.length() == 0) {
                conn.setRequestMethod("GET");
            } else {
                // Put JSON as entity for HttpPost
                conn.setDoOutput(true);
                conn.setRequestProperty("Content-Type", "application/json");
                conn.setRequestProperty("Accept", "application/json");
                conn.setRequestMethod("POST");
                
                OutputStream os = conn.getOutputStream();
                os.write(json.toString().getBytes("UTF-8"));
                os.close();
            }
            
            conn.connect();
            int responseCode = conn.getResponseCode();
            if (debugMode) {
                Log.d(MATConstants.TAG, "Request completed with status " + responseCode);
            }
            if (responseCode == HttpURLConnection.HTTP_OK) {
                is = conn.getInputStream();
            } else {
                is = conn.getErrorStream();
            }
            
            String responseAsString = MATUtils.readStream(is);
            if (debugMode) {
                // Output server response
                Log.d(MATConstants.TAG, "Server response: " + responseAsString);
            }
            // Try to parse response and print
            JSONObject responseJson = new JSONObject();
            try {
                JSONTokener tokener = new JSONTokener(responseAsString);
                responseJson = new JSONObject(tokener);
                if (debugMode) {
                    logResponse(responseJson);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            String matResponderHeader = conn.getHeaderField("X-MAT-Responder");
            if (responseCode >= HttpURLConnection.HTTP_OK && responseCode < HttpURLConnection.HTTP_MULT_CHOICE) {
                return responseJson;
            }
            // for HTTP 400, if it's from our server, drop the request and don't retry
            else if (responseCode == HttpURLConnection.HTTP_BAD_REQUEST && matResponderHeader != null) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Request received 400 error from MAT server, won't be retried");
                }
                return null; // don't retry
            }
            // for all other codes, assume the server/connection is broken and will be fixed later
        } catch (Exception e) {
            if (debugMode) {
                Log.d(MATConstants.TAG, "Request error with URL " + url);
            }
            e.printStackTrace();
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        
        return new JSONObject(); // marks this request for retry
    }
    
    // Helper to log request success/failure/errors
    private static void logResponse(JSONObject response) {
        if (response.length() > 0) {
            try {
                // Output if any errors occurred
                if (response.has("errors") && response.getJSONArray("errors").length() != 0) {
                    String errorMsg = response.getJSONArray("errors").getString(0);
                    Log.d(MATConstants.TAG, "Event was rejected by server with error: " + errorMsg);
                } else if (response.has("log_action") && 
                           !response.getString("log_action").equals("null") && 
                           !response.getString("log_action").equals("false") &&
                           !response.getString("log_action").equals("true")) {
                    // Read whether event was accepted or rejected from log_action if exists
                    JSONObject logAction = response.getJSONObject("log_action");
                    if (logAction.has("conversion")) {
                        JSONObject conversion = logAction.getJSONObject("conversion");
                        if (conversion.has("status")) {
                            String status = conversion.getString("status");
                            if (status.equals("rejected")) {
                                String statusCode = conversion.getString("status_code");
                                Log.d(MATConstants.TAG, "Event was rejected by server: status code " + statusCode);
                            } else {
                                Log.d(MATConstants.TAG, "Event was accepted by server");
                            }
                        }
                    }
                } else {
                    // Read whether event was accepted or rejected from options if exists
                    if (response.has("options")) {
                        JSONObject options = response.getJSONObject("options");
                        if (options.has("conversion_status")) {
                            String conversionStatus = options.getString("conversion_status");
                            Log.d(MATConstants.TAG, "Event was " + conversionStatus + " by server");
                        }
                    }
                }
            } catch (JSONException e) {
                Log.d(MATConstants.TAG, "Server response status could not be parsed");
                e.printStackTrace();
            }
        }
    }
}
