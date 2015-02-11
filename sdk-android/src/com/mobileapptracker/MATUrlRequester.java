package com.mobileapptracker;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import org.apache.http.Header;
import org.apache.http.HttpResponse;
import org.apache.http.HttpVersion;
import org.apache.http.StatusLine;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.HTTP;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import android.net.Uri;
import android.util.Log;

class MATUrlRequester {
    // HTTP client for firing requests
    private HttpClient client;
    
    public MATUrlRequester() {
        // Set up HttpClient
        SchemeRegistry registry = new SchemeRegistry();
        registry.register(new Scheme("http", PlainSocketFactory.getSocketFactory(), 80));
        registry.register(new Scheme("https", SSLSocketFactory.getSocketFactory(), 443));
        HttpParams params = new BasicHttpParams();
        HttpProtocolParams.setVersion(params, HttpVersion.HTTP_1_1);
        HttpProtocolParams.setContentCharset(params, HTTP.UTF_8);
        HttpConnectionParams.setSocketBufferSize(params, 8192);
        HttpConnectionParams.setConnectionTimeout(params, MATConstants.TIMEOUT);
        HttpConnectionParams.setSoTimeout(params, MATConstants.TIMEOUT);
        
        ClientConnectionManager ccm = new ThreadSafeClientConnManager(params, registry);
        
        client = new DefaultHttpClient(ccm, params);
    }
    
    public String requestDeeplink(MATDeferredDplinkr dplinkr, int timeout) {
        // Set up HttpClient with deeplink timeout
        HttpParams params = new BasicHttpParams();
        HttpConnectionParams.setConnectionTimeout(params, timeout);
        HttpClient dplinkrClient = new DefaultHttpClient(params);
        
        // Construct deeplink endpoint url
        String deeplink = "";
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
            HttpGet get = new HttpGet(uri.build().toString());
            // Set MAT conversion key in request header
            get.setHeader("X-MAT-Key", dplinkr.getConversionKey());
            HttpResponse response = dplinkrClient.execute(get);
            if (response != null) {
                StatusLine statusLine = response.getStatusLine();
                if (statusLine.getStatusCode() == 200) {
                    // Parse response as text
                    BufferedReader reader = new BufferedReader(new InputStreamReader(response.getEntity().getContent(), "UTF-8"));
                    StringBuilder builder = new StringBuilder();
                    String line = null;
                    while ((line = reader.readLine()) != null) {
                        builder.append(line);
                    }
                    reader.close();
                    
                    deeplink = builder.toString();
                }
            }
        } catch (Exception e) {
        }
        return deeplink;
    }
    
    /**
     * Does an HTTP request to the given url, GET or POST based on whether json was passed or not
     * @param url the url to hit
     * @param json JSONObject with event item and iap verification json, if not null or empty then will POST to url
     * @return JSONObject of the server response, null if request failed
     */
    public JSONObject requestUrl(String url, JSONObject json, boolean debugMode) {
        HttpResponse response = null;
        
        // If no JSON passed, do HttpGet
        if (json == null || json.length() == 0) {
            try {
                response = client.execute(new HttpGet(url));
            } catch (Exception e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Request error with URL " + url);
                }
                e.printStackTrace();
            }
        } else {
            // Put JSON as entity for HttpPost
            try {
                StringEntity se = new StringEntity(json.toString(), "UTF-8");
                se.setContentType("application/json");
                
                HttpPost request = new HttpPost(url);
                request.setEntity(se);
                response = client.execute(request);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        
        if (response != null) {
            try {
                StatusLine statusLine = response.getStatusLine();
                Header matResponderHeader = response.getFirstHeader("X-MAT-Responder");
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Request completed with status " + statusLine.getStatusCode());
                }
                
                // Parse response as JSON
                BufferedReader reader = new BufferedReader(new InputStreamReader(response.getEntity().getContent(), "UTF-8"));
                StringBuilder builder = new StringBuilder();
                for (String line = null; (line = reader.readLine()) != null;) {
                    builder.append(line).append("\n");
                }
                reader.close();
                
                // Try to parse response and print
                JSONObject responseJson = new JSONObject();
                try {
                    JSONTokener tokener = new JSONTokener(builder.toString());
                    responseJson = new JSONObject(tokener);
                    if (debugMode) {
                        logResponse(responseJson);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                
                if (statusLine.getStatusCode() >= 200 && statusLine.getStatusCode() <= 299) {
                    return responseJson;
                }
                // for HTTP 400, if it's from our server, drop the request and don't retry
                else if (statusLine.getStatusCode() == 400 && matResponderHeader != null) {
                    if (debugMode) {
                        Log.d(MATConstants.TAG, "Request received 400 error from MAT server, won't be retried");
                    }
                    return null; // don't retry
                }
                // for all other codes, assume the server/connection is broken and will be fixed later
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return new JSONObject(); // marks this request for retry
    }
    
    // Helper to log request success/failure/errors
    private void logResponse(JSONObject response) {
        // Output server response and accepted/rejected status for debug mode
        Log.d(MATConstants.TAG, "Server response: " + response);
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
