package com.tune.crosspromo;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ConnectException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import org.json.JSONObject;

import android.net.Uri;
import android.net.Uri.Builder;

import com.mobileapptracker.MATUtils;
import com.mobileapptracker.MobileAppTracker;

/**
 * Http client class for ad requests
 */
public class TuneAdClient {
    private final static int TIMEOUT = 60 * 1000; // 60 seconds timeout

    // Staging server
    private static final String API_URL_STAGE = "aa.stage.tuneapi.com/api/v1/ads";
    private static final String API_URL_PROD = "aa.tuneapi.com/api/v1/ads";
    private static String advertiserId;
    private static String apiUrl;
    private static boolean customMode;

    private static TuneAdUtils utils;
    
    /**
     * Initialize the client for making network calls
     * @param advertiserId TUNE advertiser ID
     */
    public static void init(String advertiserId) {
        apiUrl = API_URL_PROD;
        utils = TuneAdUtils.getInstance();
        TuneAdClient.advertiserId = advertiserId;
    }
    
    /**
     * Disables the SSL certificate checking for new instances of {@link HttpsURLConnection}
     * This is to aid testing on a local box or staging, not for use on production.
     */
    private static void disableSSLCertificateChecking() {
        TrustManager[] trustAllCerts = new TrustManager[] {
            new X509TrustManager() {
                @Override
                public void checkClientTrusted(java.security.cert.X509Certificate[] x509Certificates, String s) throws CertificateException {
                }

                @Override
                public void checkServerTrusted(java.security.cert.X509Certificate[] x509Certificates, String s) throws CertificateException {
                }

                @Override
                public X509Certificate[] getAcceptedIssuers() {
                    return null;
                }
            }
        };

        try {
            // Install all-trusting host verifier
            HttpsURLConnection.setDefaultHostnameVerifier(new HostnameVerifier() {
                @Override
                public boolean verify(String s, SSLSession sslSession) {
                    return true;
                }
            });
            // Install all-trusting trust manager
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, trustAllCerts, new java.security.SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        } catch (KeyManagementException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
    }
    
    public static void setStaging(boolean staging) {
        if (staging) {
            apiUrl = API_URL_STAGE;
            disableSSLCertificateChecking();
        } else {
            apiUrl = API_URL_PROD;
        }
    }
    
    public static void setAddress(String address) {
        customMode = true;
        apiUrl = address;
    }

    public static String requestBannerAd(TuneAdParams adParams) throws TuneBadRequestException, TuneServerErrorException, ConnectException {
        return requestAdOfType("banner", adParams);
    }

    public static String requestInterstitialAd(TuneAdParams adParams) throws TuneBadRequestException, TuneServerErrorException, ConnectException {
        return requestAdOfType("interstitial", adParams);
    }

    public static String requestNativeAd(TuneAdParams adParams) throws TuneBadRequestException, TuneServerErrorException, ConnectException {
        return requestAdOfType("native", adParams);
    }
    
    public static String requestAdOfType(String type, TuneAdParams adParams) throws TuneBadRequestException, TuneServerErrorException, ConnectException {
        String response = null;
        // Before even making any request check the internet connection
        if (MobileAppTracker.isOnline(utils.getContext())) {
            Builder builder;
            if (customMode) {
                builder = Uri.parse("http://" + apiUrl + "/api/v1/ads/request").buildUpon();
            } else {
                builder = Uri.parse("https://" + advertiserId + ".request." + apiUrl + "/request").buildUpon();
            }
            builder.encodedQuery("context[type]=" + type);
            
            response = requestAd(builder.build().toString(), adParams.toJSON());
        }
        return response;
    }
    
    public static void logView(final TuneAdView adView, final JSONObject adParams) {
        // Before even making any request check the internet connection
        if (MobileAppTracker.isOnline(utils.getContext())) {
            utils.getLogThread().execute(new Runnable() {
                @Override
                public void run() {
                    Builder builder;
                    if (customMode) {
                        builder = Uri.parse("http://" + apiUrl + "/api/v1/ads/event").buildUpon();
                    } else {
                        builder = Uri.parse("https://" + advertiserId + ".event." + apiUrl + "/event").buildUpon();
                    }
                    builder.appendQueryParameter("action", "view")
                           .appendQueryParameter("requestId", adView.requestId);
                    
                    logEvent(builder.build().toString(), adParams);
                }
            });
        }
    }

    public static void logClick(final TuneAdView adView, final JSONObject adParams) {
        // Before even making any request check the internet connection
        if (MobileAppTracker.isOnline(utils.getContext())) {
            utils.getLogThread().execute(new Runnable() {
                @Override
                public void run() {
                    Builder builder;
                    if (customMode) {
                        builder = Uri.parse("http://" + apiUrl + "/api/v1/ads/click").buildUpon();
                    } else {
                        builder = Uri.parse("https://" + advertiserId + ".click." + apiUrl + "/click").buildUpon();
                    }
                    builder.appendQueryParameter("action", "click")
                           .appendQueryParameter("requestId", adView.requestId);
                    
                    logEvent(builder.build().toString(), adParams);
                }
            });
        }
    }

    public static void logClose(final TuneAdView adView, final JSONObject adParams) {
        // Before even making any request check the internet connection
        if (MobileAppTracker.isOnline(utils.getContext())) {
            utils.getLogThread().execute(new Runnable() {
                @Override
                public void run() {
                    Builder builder;
                    if (customMode) {
                        builder = Uri.parse("http://" + apiUrl + "/api/v1/ads/event").buildUpon();
                    } else {
                        builder = Uri.parse("https://" + advertiserId + ".event." + apiUrl + "/event").buildUpon();
                    }
                    builder.appendQueryParameter("action", "close")
                           .appendQueryParameter("requestId", adView.requestId);
                    
                    logEvent(builder.build().toString(), adParams);
                }
            });
        }
    }

    private static void checkStatusCode(int code, String entity) throws TuneBadRequestException, TuneServerErrorException {
        if (code >= 400 && code < 500) {
            throw new TuneBadRequestException(entity);
        } else if (code >= 500) {
            throw new TuneServerErrorException(entity);
        }
    }

    public static String requestAd(String url, JSONObject adParams) throws TuneBadRequestException, TuneServerErrorException, ConnectException {
        InputStream is = null;
        
        try {
            URL myurl = new URL(url);
            HttpURLConnection conn = (HttpURLConnection) myurl.openConnection();
            conn.setReadTimeout(TIMEOUT);
            conn.setConnectTimeout(TIMEOUT);
            conn.setDoInput(true);
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Accept", "application/json");
            conn.setRequestMethod("POST");

            OutputStream os = conn.getOutputStream();
            os.write(adParams.toString().getBytes("UTF-8"));
            os.close();
            
            conn.connect();
            
            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                is = conn.getInputStream();
                return MATUtils.readStream(conn.getInputStream());
            } else {
                is = conn.getErrorStream();
                checkStatusCode(responseCode, MATUtils.readStream(is));
            }
        } catch (ConnectException e) {
            e.printStackTrace();
            throw new ConnectException();
        } catch (IOException e) {
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
        return null;
    }

    private static void logEvent(String url, JSONObject adParams) {
        InputStream is = null;
        
        try {
            URL myurl = new URL(url);
            HttpURLConnection conn = (HttpURLConnection) myurl.openConnection();
            conn.setReadTimeout(TIMEOUT);
            conn.setConnectTimeout(TIMEOUT);
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Accept", "application/json");
            conn.setRequestMethod("POST");

            OutputStream os = conn.getOutputStream();
            os.write(adParams.toString().getBytes("UTF-8"));
            os.close();
            
            // Fire and forget
            conn.connect();
        } catch (IOException e) {
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
    }
}
