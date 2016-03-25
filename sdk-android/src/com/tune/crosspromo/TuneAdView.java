package com.tune.crosspromo;

import java.net.URLEncoder;

import android.webkit.WebView;

/**
 * Class that contains ad and metadata information from server
 */
public class TuneAdView {
    public String placement;
    public TuneAdMetadata metadata;
    public String requestId;
    public WebView webView;
    public boolean loaded;
    public boolean loading;

    public TuneAdView(String placement, TuneAdMetadata metadata, WebView webView) {
        this.placement = placement;
        this.metadata = metadata;
        this.webView = webView;
    }

    public void loadView(String data) {
        try {
            webView.loadData(
                    URLEncoder.encode(data, "utf-8").replaceAll("\\+", " "),
                    "text/html", "utf-8");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void destroy() {
        webView = null;
    }
}
