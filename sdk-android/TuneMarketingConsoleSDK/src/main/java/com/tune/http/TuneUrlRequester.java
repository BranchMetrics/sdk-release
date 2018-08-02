package com.tune.http;

import com.tune.TuneConstants;
import com.tune.TuneDebugLog;
import com.tune.TuneDeeplinkListener;
import com.tune.utils.TuneUtils;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class TuneUrlRequester implements UrlRequester {

    @Override
    public void requestDeeplink(String deeplinkURL, String conversionKey, TuneDeeplinkListener listener) {
        if (listener == null) {
            return; // no one is listening!
        }

        BufferedInputStream is = null;
        boolean foundError = false;
        String response;

        try {
            URL myurl = new URL(deeplinkURL);
            HttpURLConnection conn = (HttpURLConnection) myurl.openConnection();
            // Set TUNE conversion key in request header
            conn.setRequestProperty("X-MAT-Key", conversionKey);
            conn.setRequestMethod("GET");
            conn.setDoInput(true);

            // This will throw an exception if there is no connection available.
            conn.connect();

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                is = new BufferedInputStream(conn.getInputStream());
            } else {
                foundError = true;
                is = new BufferedInputStream(conn.getErrorStream());
            }

            response = TuneUtils.readStream(is);
        } catch (Exception e) {
            foundError = true;
            response = e.getMessage();

            e.printStackTrace();
        } finally {
            try {
                if (is != null) {
                    is.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        // Send the callback the response.  This is wrapped in a try/catch in case the callback
        // tries to throw an exception back through this API.
        try {
            if (foundError) {
                // Notify listener of error
                listener.didFailDeeplink(response);
            } else {
                // Notify listener of deeplink url
                listener.didReceiveDeeplink(response);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * Does an HTTP request to the given url, GET or POST based on whether json was passed or not
     * @param url the url to hit
     * @param json JSONObject with event item and IAP verification json, if not null or empty then will POST to url
     * @return JSONObject of the server response, null if request failed
     */
    @Override
    public JSONObject requestUrl(String url, JSONObject json, boolean debugMode) {
        BufferedInputStream is = null;
        
        try {
            URL myurl = new URL(url);
            HttpURLConnection conn = (HttpURLConnection) myurl.openConnection();
            conn.setReadTimeout(TuneConstants.TIMEOUT);
            conn.setConnectTimeout(TuneConstants.TIMEOUT);
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
                TuneDebugLog.d("Request completed with status " + responseCode);
            }
            if (responseCode == HttpURLConnection.HTTP_OK) {
                is = new BufferedInputStream(conn.getInputStream());
            } else {
                is = new BufferedInputStream(conn.getErrorStream());
            }
            
            String responseAsString = TuneUtils.readStream(is);
            if (debugMode) {
                // Output server response
                TuneDebugLog.d("Server response: " + responseAsString);
            }

            String matResponderHeader = conn.getHeaderField("X-MAT-Responder");
            if (responseCode >= HttpURLConnection.HTTP_OK && responseCode < HttpURLConnection.HTTP_MULT_CHOICE) {
                // Try to parse response and print
                JSONTokener tokener = new JSONTokener(responseAsString);
                JSONObject responseJson = new JSONObject(tokener);
                if (debugMode) {
                    logResponse(responseJson);
                }

                return responseJson;
            }
            // for HTTP 400, if it's from our server, drop the request and don't retry
            else if (responseCode == HttpURLConnection.HTTP_BAD_REQUEST && matResponderHeader != null) {
                if (debugMode) {
                    TuneDebugLog.d("Request received 400 error from TUNE server, won't be retried");
                }
                return null; // don't retry
            }
            // for all other codes, assume the server/connection is broken and will be fixed later
        } catch (Exception e) {
            if (debugMode) {
                TuneDebugLog.d("Request error with URL " + url);
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
                    TuneDebugLog.d("Event was rejected by server with error: " + errorMsg);
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
                                TuneDebugLog.d("Event was rejected by server: status code " + statusCode);
                            } else {
                                TuneDebugLog.d("Event was accepted by server");
                            }
                        }
                    }
                } else {
                    // Read whether event was accepted or rejected from options if exists
                    if (response.has("options")) {
                        JSONObject options = response.getJSONObject("options");
                        if (options.has("conversion_status")) {
                            String conversionStatus = options.getString("conversion_status");
                            TuneDebugLog.d("Event was " + conversionStatus + " by server");
                        }
                    }
                }
            } catch (JSONException e) {
                TuneDebugLog.d("Server response status could not be parsed");
                e.printStackTrace();
            }
        }
    }
}
