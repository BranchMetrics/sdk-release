package com.tune.http;

import android.net.Uri;

import com.tune.Tune;
import com.tune.TuneDebugLog;
import com.tune.TuneUrlKeys;
import com.tune.TuneUtils;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsListener;
import com.tune.ma.configuration.TuneConfigurationManager;
import com.tune.ma.profile.TuneProfileKeys;
import com.tune.ma.profile.TuneUserProfile;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.ConnectException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;


/**
 * Created by johng on 1/6/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneApi implements Api {
    private static final String BOUNDARY = "thisIsMyFileBoundary";
    private static final int TIMEOUT = 60 * 1000; // 60 seconds timeout

    private static final String CONFIG_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/configuration";
    private static final String PLAYLIST_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/devices/%s/playlist";
    private static final String CONNECT_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/devices/%s/connect";
    private static final String DISCONNECT_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/devices/%s/disconnect";
    private static final String DISCOVERY_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/devices/%s/discovery";
    private static final String SYNC_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/sync";
    private static final String CONNECTED_PLAYLIST_ENDPOINT_TEMPLATE = "/sdk_api/%s/apps/%s/devices/%s/connected_playlist";

    private static final String REQUEST_METHOD_GET  = "GET";
    private static final String REQUEST_METHOD_POST = "POST";

    private static final String APP_ID_HEADER = "X-ARTISAN-APPID";
    private static final String DEVICE_ID_HEADER = "X-ARTISAN-DEVICEID";
    private static final String SDK_VERSION_HEADER = "X-TUNE-SDKVERSION";
    private static final String APP_VERSION_HEADER = "X-TUNE-APPVERSION";
    private static final String OS_VERSION_HEADER = "X-TUNE-OSVERSION";
    private static final String OS_TYPE_HEADER = "X-TUNE-OSTYPE";

    private static final String TAG = "TuneHttp";

    public TuneApi() {}

    // Request Methods
    ///////////////////

    @Override
    public JSONObject getPlaylist() {
        return getPlaylistBase(PLAYLIST_ENDPOINT_TEMPLATE);
    }

    @Override
    public JSONObject getConfiguration() {
        JSONObject response = null;
        Uri.Builder builder = new Uri.Builder();

        TuneConfigurationManager configManager = TuneManager.getInstance().getConfigurationManager();
        TuneUserProfile profileManager = TuneManager.getInstance().getProfileManager();
        builder.encodedPath(TuneStringUtils.format(CONFIG_ENDPOINT_TEMPLATE, configManager.getApiVersion(), profileManager.getAppId()));
        
        builder.appendQueryParameter("osVersion", profileManager.getProfileVariableValue(TuneUrlKeys.OS_VERSION));
        builder.appendQueryParameter("appVersion", profileManager.getProfileVariableValue(TuneUrlKeys.APP_VERSION));
        builder.appendQueryParameter("sdkVersion", profileManager.getProfileVariableValue(TuneUrlKeys.SDK_VERSION));
        builder.appendQueryParameter("matId", profileManager.getProfileVariableValue(TuneUrlKeys.MAT_ID));
        builder.appendQueryParameter("GAID", profileManager.getProfileVariableValue(TuneUrlKeys.GOOGLE_AID));
        String pathWithQuery = builder.build().toString();

        String configHostPort = TuneManager.getInstance().getConfigurationManager().getConfigurationHostPort();

        HttpURLConnection urlConnection = buildUrlConnection(configHostPort + pathWithQuery, REQUEST_METHOD_GET);
        urlConnection.setRequestProperty("Accept", "application/json");

        if (urlConnection != null) {
            response = sendRequestAndReadResponse(urlConnection);
        }
        return response;
    }

    // Returns true for a successful post, false otherwise.
    @Override
    public boolean postAnalytics(JSONObject events, TuneAnalyticsListener listener) {
        boolean result = false;
        HttpURLConnection urlConnection = null;
        String analyticsHostPort = TuneManager.getInstance().getConfigurationManager().getAnalyticsHostPort();
        try {
            byte[] data = zipAndEncodeData(events.toString(), BOUNDARY);

            urlConnection = buildUrlConnection(analyticsHostPort, REQUEST_METHOD_POST);
            if (urlConnection != null) {
                urlConnection.setDoOutput(true);
                urlConnection.setRequestProperty("Content-Type", "multipart/form-data; boundary=" + BOUNDARY);
                urlConnection.setRequestProperty("Content-Encoding", "gzip");
                urlConnection.setRequestProperty("Content-Length", Integer.toString(data.length));

                OutputStream os = urlConnection.getOutputStream();
                os.write(data);
                os.close();

                // getResponseCode sends the request
                int responseCode = urlConnection.getResponseCode();
                TuneDebugLog.d("Analytics sent with response code " + responseCode);
                // If response is 200, delete the sent events from analytics on disk
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    result = true;
                } else {
                    TuneDebugLog.e("Analytics failed w/ response code: " + responseCode);
                }

                if (listener != null) {
                    listener.didCompleteRequest(responseCode);
                }
            }
        } catch (ConnectException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return result;
    }

    @Override
    public boolean postConnectedAnalytics(JSONObject event, TuneAnalyticsListener listener) {
        boolean result = false;
        TuneConfigurationManager configManager = TuneManager.getInstance().getConfigurationManager();
        TuneUserProfile profile = TuneManager.getInstance().getProfileManager();

        Uri.Builder uriBuilder = new Uri.Builder();
        uriBuilder.encodedPath(TuneStringUtils.format(DISCOVERY_ENDPOINT_TEMPLATE, configManager.getApiVersion(), profile.getAppId(), profile.getDeviceId()));
        String path = uriBuilder.build().toString();

        HttpURLConnection urlConnection = null;
        try {
            byte[] data = event.toString().getBytes();

            urlConnection = buildUrlConnection(configManager.getConnectedModeHostPort() + path, REQUEST_METHOD_POST);
            if (urlConnection != null) {
                urlConnection.setDoOutput(true);
                urlConnection.setRequestProperty("Accept", "application/json");
                urlConnection.setRequestProperty("Content-Type", "application/json");
                urlConnection.setRequestProperty("Content-Length", Integer.toString(data.length));

                OutputStream os = urlConnection.getOutputStream();
                os.write(data);
                os.close();

                // getResponseCode sends the request
                int responseCode = urlConnection.getResponseCode();
                TuneDebugLog.d("Connected Analytics sent with response code " + responseCode);
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    result = true;
                } else {
                    TuneDebugLog.e("Connected Analytics failed w/ response code: " + responseCode);
                }

                if (listener != null) {
                    listener.didCompleteRequest(responseCode);
                }
            }
        } catch (ConnectException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return result;
    }

    @Override
    public boolean postConnect() {
        boolean result = false;
        TuneConfigurationManager configManager = TuneManager.getInstance().getConfigurationManager();
        TuneUserProfile profile = TuneManager.getInstance().getProfileManager();

        Uri.Builder uriBuilder = new Uri.Builder();
        uriBuilder.encodedPath(TuneStringUtils.format(CONNECT_ENDPOINT_TEMPLATE, configManager.getApiVersion(), profile.getAppId(), profile.getDeviceId()));
        String path = uriBuilder.build().toString();

        HttpURLConnection urlConnection = null;
        try {
            urlConnection = buildUrlConnection(configManager.getConnectedModeHostPort() + path, REQUEST_METHOD_POST);
            if (urlConnection != null) {
                urlConnection.setRequestProperty("Accept", "application/json");
                urlConnection.setRequestProperty("Content-Type", "application/json");

                // getResponseCode sends the request
                int responseCode = urlConnection.getResponseCode();
                TuneDebugLog.d("Connect sent with response code " + responseCode);

                // If response is 200
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    result = true;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return result;
    }

    @Override
    public boolean postDisconnect() {
        TuneConfigurationManager configManager = TuneManager.getInstance().getConfigurationManager();
        TuneUserProfile profile = TuneManager.getInstance().getProfileManager();

        Uri.Builder uriBuilder = new Uri.Builder();
        uriBuilder.encodedPath(TuneStringUtils.format(DISCONNECT_ENDPOINT_TEMPLATE, configManager.getApiVersion(), profile.getAppId(), profile.getDeviceId()));
        String path = uriBuilder.build().toString();

        HttpURLConnection urlConnection = null;
        try {
            urlConnection = buildUrlConnection(configManager.getConnectedModeHostPort() + path, REQUEST_METHOD_POST);
            if (urlConnection != null) {
                urlConnection.setRequestProperty("Accept", "application/json");
                urlConnection.setRequestProperty("Content-Type", "application/json");

                // getResponseCode sends the request
                int responseCode = urlConnection.getResponseCode();
                TuneDebugLog.d("Disconnect sent with response code " + responseCode);

                // If response is 200
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    return true;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return false;
    }

    @Override
    public boolean postSync(JSONObject syncObject) {
        boolean result = false;
        TuneConfigurationManager configManager = TuneManager.getInstance().getConfigurationManager();
        TuneUserProfile profile = TuneManager.getInstance().getProfileManager();

        Uri.Builder uriBuilder = new Uri.Builder();
        uriBuilder.encodedPath(TuneStringUtils.format(SYNC_ENDPOINT_TEMPLATE, configManager.getApiVersion(), profile.getAppId()));
        String path = uriBuilder.build().toString();

        HttpURLConnection urlConnection = null;
        try {
            byte[] data = syncObject.toString().getBytes();

            urlConnection = buildUrlConnection(configManager.getConnectedModeHostPort() + path, REQUEST_METHOD_POST);
            if (urlConnection != null) {
                urlConnection.setDoOutput(true);
                urlConnection.setRequestProperty("Accept", "application/json");
                urlConnection.setRequestProperty("Content-Type", "application/json");
                urlConnection.setRequestProperty("Content-Length", Integer.toString(data.length));

                OutputStream os = urlConnection.getOutputStream();
                os.write(data);
                os.close();

                // getResponseCode sends the request
                int responseCode = urlConnection.getResponseCode();
                TuneDebugLog.d("Sync sent with response code " + responseCode);
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    result = true;
                } else {
                    TuneDebugLog.e("Sync failed w/ response code: " + responseCode);
                }
            }
        } catch (ConnectException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return result;
    }

    @Override
    public JSONObject getConnectedPlaylist() {
        return getPlaylistBase(CONNECTED_PLAYLIST_ENDPOINT_TEMPLATE);
    }

    // Helper Methods
    //////////////////

    private JSONObject getPlaylistBase(String endpoint) {
        TuneConfigurationManager configManager = TuneManager.getInstance().getConfigurationManager();
        TuneUserProfile profile = TuneManager.getInstance().getProfileManager();
        JSONObject response = null;

        Uri.Builder uriBuilder = new Uri.Builder();
        uriBuilder.encodedPath(TuneStringUtils.format(endpoint, configManager.getPlaylistApiVersion(), profile.getAppId(), profile.getDeviceId()));
        String path = uriBuilder.build().toString();

        HttpURLConnection urlConnection = buildUrlConnection(configManager.getPlaylistHostPort() + path, REQUEST_METHOD_GET);
        urlConnection.setRequestProperty("Accept", "application/json");
        if (urlConnection != null) {
            response = sendRequestAndReadResponse(urlConnection);
        }
        return response;
    }

    /**
     * Sets up a HTTPUrlConnection.
     * @param hostPort url to connect to
     * @param requestMethod String representing the request method. E.g "GET", "POST", etc.
     * @return
     */
    private HttpURLConnection buildUrlConnection(String hostPort, String requestMethod) {
        HttpURLConnection urlConnection= null;
        URL url = null;
        try {
            url = new URL(hostPort);
            urlConnection = (HttpURLConnection) url.openConnection();

            urlConnection.setReadTimeout(TIMEOUT);
            urlConnection.setConnectTimeout(TIMEOUT);
            urlConnection.setDoInput(true);
            TuneUserProfile profileManager = TuneManager.getInstance().getProfileManager();

            urlConnection.setRequestProperty(DEVICE_ID_HEADER, profileManager.getDeviceId());
            urlConnection.setRequestProperty(APP_ID_HEADER, profileManager.getAppId());
            urlConnection.setRequestProperty(SDK_VERSION_HEADER, Tune.getSDKVersion());
            urlConnection.setRequestProperty(APP_VERSION_HEADER, profileManager.getProfileVariableValue(TuneUrlKeys.APP_VERSION));
            urlConnection.setRequestProperty(OS_VERSION_HEADER, profileManager.getProfileVariableValue(TuneProfileKeys.API_LEVEL));
            urlConnection.setRequestProperty(OS_TYPE_HEADER, profileManager.getProfileVariableValue(TuneProfileKeys.OS_TYPE));
            urlConnection.setRequestMethod(requestMethod);
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return urlConnection;
    }

    // Compress the analytics events
    private byte[] zipAndEncodeData(String uncompressedString, String boundary) throws IOException {
        byte[] compressed = TuneUtils.compress(uncompressedString);

        byte[] outputBuffer;
        // Wrap the compressed data in a file boundary for multi-part transmission
        outputBuffer = TuneStringUtils.format("--%s\r\n", boundary).getBytes();
        String wrapperString = TuneStringUtils.format("Content-Disposition: form-data; name=\"%s\"; filename=\"analytics.gzip\"\r\n", "analytics");
        outputBuffer = TuneUtils.concatenateByteArrays(outputBuffer, wrapperString.getBytes());
        wrapperString = "Content-Type: application/gzip\r\n\r\n";
        outputBuffer = TuneUtils.concatenateByteArrays(outputBuffer, wrapperString.getBytes());
        outputBuffer = TuneUtils.concatenateByteArrays(outputBuffer, compressed);
        wrapperString = "\r\n";
        outputBuffer = TuneUtils.concatenateByteArrays(outputBuffer, wrapperString.getBytes());
        wrapperString = TuneStringUtils.format("--%s--\r\n", boundary);
        outputBuffer = TuneUtils.concatenateByteArrays(outputBuffer, wrapperString.getBytes());
        return outputBuffer;
    }

    private JSONObject sendRequestAndReadResponse(HttpURLConnection connection) {
        String response = null;
        JSONObject responseJson = null;
        BufferedInputStream stream = null;
        try {
            // Read and print error stream if response is not 200
            int responseCode = connection.getResponseCode();
            if (responseCode != HttpURLConnection.HTTP_OK) {
                stream = new BufferedInputStream(connection.getErrorStream());
                TuneDebugLog.e(TAG, TuneStringUtils.format("Sending Request to %s failed with %s:\n%s", connection.getURL(), responseCode, TuneUtils.readStream(stream)));
                return responseJson;
            }

            stream = new BufferedInputStream(connection.getInputStream());
            response = TuneUtils.readStream(stream);
        } catch (IOException e) {
            e.printStackTrace();
            TuneDebugLog.e(TAG, TuneStringUtils.format("Sending Request to %s caused IO exception.", connection.getURL()));
        } finally {
            connection.disconnect();
        }

        if (response != null) {
            try {
                responseJson = new JSONObject(response);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        return responseJson;
    }
}
