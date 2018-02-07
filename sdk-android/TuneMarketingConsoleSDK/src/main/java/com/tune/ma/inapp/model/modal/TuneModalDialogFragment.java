package com.tune.ma.inapp.model.modal;

import android.annotation.TargetApi;
import android.app.Dialog;
import android.app.DialogFragment;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.animation.Animation;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import com.tune.TuneUtils;

import java.net.URLEncoder;

import static com.tune.ma.inapp.TuneScreenUtils.getScreenHeightPixels;
import static com.tune.ma.inapp.TuneScreenUtils.getScreenWidthPixels;
import static com.tune.ma.inapp.TuneScreenUtils.redrawWebView;

/**
 * Created by johng on 6/14/17.
 */

public class TuneModalDialogFragment extends DialogFragment {

    private static TuneModal parentModal;
    private TuneModalDialog modalDialog;

    public static TuneModalDialogFragment newInstance(TuneModal modal) {
        parentModal = modal;
        TuneModalDialogFragment fragment = new TuneModalDialogFragment();
        fragment.setRetainInstance(true);
        return fragment;
    }

    @Override
    public synchronized Dialog onCreateDialog(Bundle savedInstanceState) {
        modalDialog = setupModalDialog();
        loadHtml(parentModal.getHtml());
        return modalDialog;
    }

    @Override
    public synchronized void onDestroy() {
        modalDialog = null;
        super.onDestroy();
    }

    @Override
    public synchronized void onDestroyView() {
        Dialog dialog = getDialog();
        // Handles https://code.google.com/p/android/issues/detail?id=17423
        if (dialog != null && getRetainInstance()) {
            dialog.setDismissMessage(null);
        }
        super.onDestroyView();
    }

    public synchronized TuneModalDialog getDialog() {
        return modalDialog;
    }

    private synchronized TuneModalDialog setupModalDialog() {
        TuneModalLayout modalLayout = setupModalLayout(parentModal.getEdgeStyle());

        return new TuneModalDialog(getActivity(), modalLayout);
    }

    private synchronized TuneModalLayout setupModalLayout(TuneModal.EdgeStyle edgeStyle) {
        WebView webView = setupWebView(edgeStyle);
        // Create modal FrameLayout
        return new TuneModalLayout(getActivity(), webView, parentModal);
    }

    private synchronized WebView setupWebView(TuneModal.EdgeStyle edgeStyle) {
        // Set up WebView
        final WebView webView;
        if (edgeStyle == TuneModal.EdgeStyle.ROUND) {
            webView = new TuneModalRoundedWebView(getActivity(), parentModal);
        } else {
            webView = new TuneModalWebView(getActivity(), parentModal);
        }

        // If modal width/height is greater than screen size, use MATCH_PARENT so it doesn't go outside screen bounds
        int width = TuneUtils.dpToPx(getActivity(), parentModal.getWidth());
        int height = TuneUtils.dpToPx(getActivity(), parentModal.getHeight());

        if (width > getScreenWidthPixels(getActivity())) {
            width = FrameLayout.LayoutParams.MATCH_PARENT;
        }
        if (height > getScreenHeightPixels(getActivity())) {
            height = FrameLayout.LayoutParams.MATCH_PARENT;
        }

        FrameLayout.LayoutParams wvLayout = new FrameLayout.LayoutParams(width, height);
        wvLayout.gravity = Gravity.CENTER;
        webView.setLayoutParams(wvLayout);

        WebViewClient webViewClient = new WebViewClient() {
            @SuppressWarnings("deprecation")
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                parentModal.dismiss();

                // Process click's url
                parentModal.processAction(url);
                return true;
            }

            @TargetApi(Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                parentModal.dismiss();

                // Process click's url
                parentModal.processAction(request.getUrl().toString());
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                if (url.equals("about:blank")) {
                    return;
                }

                // Make WebView visible
                view.setVisibility(View.VISIBLE);

                redrawWebView(view);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1) {
                    view.animate().alpha(1.0f);
                }
                view.requestFocus();

                parentModal.animateOpen(getActivity());

                // Handle impression event tracking
                parentModal.processImpression();
            }
        };
        webView.setWebViewClient(webViewClient);
        webView.setWebChromeClient(new WebChromeClient() {
        });

        return webView;
    }

    protected synchronized void startAnimation(Animation animation) {
        if (getDialog() != null) {
            getDialog().getLayout().getWebView().startAnimation(animation);
        }
    }

    protected synchronized void hideProgressBar() {
        if (getDialog() != null) {
            getDialog().getLayout().getProgressBar().setVisibility(View.GONE);
        }
    }

    private synchronized void loadHtml(String html) {
        try {
            if (getDialog() != null) {
                getDialog().getLayout().getWebView().loadData(URLEncoder.encode(html, "utf-8").replaceAll("\\+", " "), "text/html", "utf-8");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
