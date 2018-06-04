package com.tune.ma.inapp.model.action;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;

import com.tune.TuneDebugLog;
import com.tune.ma.TuneManager;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.deepactions.TuneDeepActionManager;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.Map;

import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_DEEPACTION_DATA_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_DEEPACTION_ID_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_DEEPLINK_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_TYPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_TYPE_VALUE_CLOSE;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_TYPE_VALUE_DEEPACTION;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTION_TYPE_VALUE_DEEPLINK;

/**
 * Created by johng on 2/27/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneInAppAction {
    @Deprecated
    public enum Type {
        DEEPLINK,
        DEEP_ACTION,
        CLOSE
    }

    // Special action name that represents a message dismiss
    public static final String DISMISS_ACTION = "dismiss";

    // Special action names that are triggered by message lifecycle
    public static final String ONDISPLAY_ACTION = "onDisplay";
    public static final String ONDISMISS_ACTION = "onDismiss";

    protected Type type;
    protected String name;
    protected String deeplink;
    protected String deepActionId;
    protected Map<String, String> deepActionData;

    public TuneInAppAction(String name, JSONObject json) {
        this.name = name;

        String typeString = TuneJsonUtils.getString(json, ACTION_TYPE_KEY);
        if (typeString == null) {
            return;
        }

        if (typeString.equals(ACTION_TYPE_VALUE_DEEPLINK)) {
            this.type = Type.DEEPLINK;
            this.deeplink = TuneJsonUtils.getString(json, ACTION_DEEPLINK_KEY);
        } else if (typeString.equals(ACTION_TYPE_VALUE_DEEPACTION)) {
            this.type = Type.DEEP_ACTION;
            this.deepActionId = TuneJsonUtils.getString(json, ACTION_DEEPACTION_ID_KEY);
            JSONObject deepActionDataJson = TuneJsonUtils.getJSONObject(json, ACTION_DEEPACTION_DATA_KEY);
            if (deepActionDataJson != null) {
                this.deepActionData = TuneJsonUtils.JSONObjectToStringMap(deepActionDataJson);
            }
        } else if (typeString.equals(ACTION_TYPE_VALUE_CLOSE)) {
            this.type = Type.CLOSE;
        }
    }

    public Type getType() {
        return type;
    }

    public String getName() {
        return name;
    }

    public String getDeeplink() {
        return deeplink;
    }

    public String getDeepActionId() {
        return deepActionId;
    }

    public Map<String, String> getDeepActionData() {
        return deepActionData;
    }

    /**
     * Executes an in-app message action
     */
    public void execute() {
        Activity activity = TuneActivity.getLastActivity();
        switch (type) {
            case DEEPLINK:
                // Open deeplink url
                openUrl(deeplink, activity);
                break;
            case DEEP_ACTION:
                // Execute deep action
                TuneDeepActionManager deepActionManager = TuneManager.getInstance().getDeepActionManager();
                if (deepActionManager == null) {
                    return;
                }
                deepActionManager.executeDeepAction(activity, deepActionId, deepActionData);
                break;
            case CLOSE:
            default:
                break;
        }
    }

    // Handles opening store links, deeplinks, or web links
    public static void openUrl(String url, Activity activity) {
        if (activity == null) {
            TuneDebugLog.e("Activity is null, cannot open url " + url);
            return;
        }
        Uri uri = Uri.parse(url);

        // Handle store urls for Google Play and Amazon Appstore
        if (isMarketUrl(uri)) {
            processMarketUri(uri, activity);
        } else if (isAmazonUrl(uri)) {
            processAmazonUri(uri, activity);
        } else {
            // Open deeplink or regular web url
            try {
                activity.startActivity(new Intent(Intent.ACTION_VIEW, uri));
            } catch (ActivityNotFoundException e) {
                e.printStackTrace();
            }
        }
    }

    // Open app in market, default to Google Play
    protected static void processMarketUri(Uri url, Activity activity) {
        final String query = url.getQuery();
        // Try to open with market intent, fallback to Google Play url
        try {
            final Uri marketUri = Uri.parse(String.format("market://details?%s", query));
            activity.startActivity(new Intent(Intent.ACTION_VIEW, marketUri));
        } catch (ActivityNotFoundException e) {
            final Uri httpUri = Uri.parse(String.format("http://play.google.com/store/apps/details?%s", query));
            activity.startActivity(new Intent(Intent.ACTION_VIEW, httpUri));
        }
    }

    // Open app in Amazon Appstore
    protected static void processAmazonUri(Uri url, Activity activity) {
        final String query = url.getQuery();
        // Try to open with Amazon Appstore, fallback to Amazon url
        try {
            final Uri amznUri = Uri.parse(String.format("amzn://apps/android?%s", query));
            activity.startActivity(new Intent(Intent.ACTION_VIEW, amznUri));
        } catch (ActivityNotFoundException e) {
            final Uri httpUri = Uri.parse(String.format("http://www.amazon.com/gp/mas/dl/android?%s", query));
            activity.startActivity(new Intent(Intent.ACTION_VIEW, httpUri));
        }
    }

    // URL should be opened by Play app
    protected static boolean isMarketUrl(final Uri url) {
        String scheme = url.getScheme();
        String host = url.getHost();

        if (scheme == null) {
            return false;
        }
        boolean isMarketScheme = scheme.equals("market");
        boolean isPlayUrl = (scheme.equals("http") || scheme.equals("https"))
                && (host.equals("play.google.com") || host.equals("market.android.com"));

        return isMarketScheme || isPlayUrl;
    }

    // URL should be opened by Amazon Appstore
    protected static boolean isAmazonUrl(final Uri url) {
        String scheme = url.getScheme();
        String host = url.getHost();

        if (scheme == null) {
            return false;
        }
        boolean isAmznScheme = scheme.equals("amzn");
        boolean isAmznWebUrl = (scheme.equals("http") || scheme.equals("https"))
                && host.equals("www.amazon.com");

        return isAmznScheme || isAmznWebUrl;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }

        if (!(obj instanceof TuneInAppAction)) {
            return false;
        }

        TuneInAppAction that = (TuneInAppAction) obj;
        if (type != that.type) {
            return false;
        }

        if (!name.equals(that.name)) {
            return false;
        }

        if (deeplink != null && that.deeplink != null ? !deeplink.equals(that.deeplink) : deeplink != that.deeplink) {
            return false;
        }

        if (deepActionId != null && that.deepActionId != null ? !deepActionId.equals(that.deepActionId) : deepActionId != that.deepActionId) {
            return false;
        }

        return deepActionData != null && that.deepActionData != null ? deepActionData.equals(that.deepActionData) : deepActionData == that.deepActionData;
    }

    @Override
    public int hashCode() {
        int result = name != null ? name.hashCode() : 0;
        result = 31 * result + (type != null ? type.hashCode() : 0);
        result = 31 * result + (deeplink != null ? deeplink.hashCode() : 0);
        result = 31 * result + (deepActionId != null ? deepActionId.hashCode() : 0);
        result = 31 * result + (deepActionData != null ? deepActionData.toString().hashCode() : 0);
        return result;
    }
}
