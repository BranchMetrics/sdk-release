package com.tune.ma.push.model;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;

import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.InputStream;
import java.net.URL;
import java.util.UUID;

/**
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePushMessage {
    // This is the key that the push message will be stored under in the intent
    public static final String TUNE_EXTRA_MESSAGE = "com.tune.ma.EXTRA_MESSAGE";

    private static final String BUNDLE_APP_ID = "app_id";
    private static final String BUNDLE_ALERT_KEY = "alert";
    private static final String BUNDLE_PAYLOAD_KEY = "payload";
    private static final String BUNDLE_PUSH_ID_KEY = "ARTPID";
    private static final String BUNDLE_CAMPAIGN_ID = "CAMPAIGN_ID";
    private static final String BUNDLE_LENGTH_TO_REPORT = "LENGTH_TO_REPORT";
    private static final String BUNDLE_SILENT_PUSH_KEY = "silent_push";
    private static final String BUNDLE_CHANNEL_ID_KEY = "channel_id";
    // This is added in the receiver so it won't be in the bundle we originally get
    private static final String JSON_APP_NAME = "appName";
    // This is created when the message is created from a bundle, so won't appear in it
    private static final String JSON_MESSAGE_ID = "local_message_id";
    private static final String TUNE_TEST_MESSAGE = "TEST_MESSAGE";

    // Optional push notification style fields
    private static final String BUNDLE_STYLE = "style";
    private static final String BUNDLE_IMAGE = "image";
    private static final String BUNDLE_BIG_TEXT = "big_text";
    private static final String BUNDLE_TITLE = "title";
    private static final String BUNDLE_SUMMARY = "summary";

    private String appId;
    private String alertMessage;
    private TunePushPayload payload;
    private String appName;
    private TuneCampaign campaign;
    private String messageIdentifier;
    private String channelId;

    private String style;
    private Bitmap image;
    private String title;
    private String summary;
    private String bigText;

    private boolean silentPush;

    // This constructor is purely for getting push id into the fiveline to match with in-app message trigger events
    public static TunePushMessage initForTriggerEvent(String pushId) {
        TunePushMessage message = new TunePushMessage();
        message.campaign = new TuneCampaign("", pushId, 0);
        return message;
    }

    private TunePushMessage() {
    }

    public TunePushMessage(String jsonString) throws JSONException {
        JSONObject json = new JSONObject(jsonString);

        // Optional
        if (json.has(JSON_APP_NAME)) {
            appName = json.getString(JSON_APP_NAME);
        }

        appId = json.getString(BUNDLE_APP_ID);
        alertMessage = json.getString(BUNDLE_ALERT_KEY);

        String campaignId = json.getString(BUNDLE_CAMPAIGN_ID);
        String variationId = json.getString(BUNDLE_PUSH_ID_KEY);
        Integer secondsToReport = json.getInt(BUNDLE_LENGTH_TO_REPORT);
        campaign = new TuneCampaign(campaignId, variationId, secondsToReport);

        if (json.has(BUNDLE_PAYLOAD_KEY)) {
            payload = new TunePushPayload(json.getString(BUNDLE_PAYLOAD_KEY));
        }

        messageIdentifier = json.getString(JSON_MESSAGE_ID);

        if (json.has(BUNDLE_CHANNEL_ID_KEY)) {
            channelId = json.getString(BUNDLE_CHANNEL_ID_KEY);
        }
    }

    public TunePushMessage(Bundle extras, String appName) throws Exception {
        this.appName = appName;

        if (extras.containsKey(BUNDLE_SILENT_PUSH_KEY)) {
            silentPush = extras.getString(BUNDLE_SILENT_PUSH_KEY).equalsIgnoreCase("true");
        }

        appId = checkGet(extras, BUNDLE_APP_ID);
        alertMessage = checkGet(extras, BUNDLE_ALERT_KEY);

        if (extras.containsKey(BUNDLE_CHANNEL_ID_KEY)) {
            channelId = extras.getString(BUNDLE_CHANNEL_ID_KEY);
        }

        String pushId = checkGet(extras, BUNDLE_PUSH_ID_KEY);
        String campaignId = checkGet(extras, BUNDLE_CAMPAIGN_ID);
        // GCM seems to automatically convert all the fields into strings.
        Integer secondsToReport = Integer.parseInt(checkGet(extras, BUNDLE_LENGTH_TO_REPORT));

        campaign = new TuneCampaign(campaignId, pushId, secondsToReport);

        if (extras.containsKey(BUNDLE_PAYLOAD_KEY) && extras.getString(BUNDLE_PAYLOAD_KEY) != null) {
            payload = new TunePushPayload(extras.getString(BUNDLE_PAYLOAD_KEY));
        }

        messageIdentifier = UUID.randomUUID().toString();

        if (extras.containsKey(BUNDLE_STYLE)) {
            style = extras.getString(BUNDLE_STYLE);

            // Don't need to parse extra fields for regular notifications
            if (style.equals(TunePushStyle.REGULAR)) {
                return;
            }

            // Parse for fields based on style
            if (style.equals(TunePushStyle.IMAGE)) {
                try {
                    image = BitmapFactory.decodeStream((InputStream) new URL(checkGet(extras, BUNDLE_IMAGE)).getContent());
                } catch (Exception e) {
                    e.printStackTrace();
                }
            } else if (style.equals(TunePushStyle.BIG_TEXT)) {
                bigText = checkGet(extras, BUNDLE_BIG_TEXT);
            }
            title = extras.getString(BUNDLE_TITLE);
            summary = extras.getString(BUNDLE_SUMMARY);
        }
    }

    private String checkGet(Bundle extras, String toGet) throws Exception {
        String result = extras.getString(toGet);
        if (result == null) {
            throw new Exception(TuneStringUtils.format("Push messages should have an '%s' field.", toGet));
        }
        return result;
    }

    public boolean isOpenActionDeepAction() {
        return getPayload() != null && getPayload().isOpenActionDeepAction();
    }

    public boolean isOpenActionDeepLink() {
        return getPayload() != null && getPayload().isOpenActionDeepLink();
    }

    public boolean isAutoCancelNotification() {
        boolean autoCancel = true;
        if (payload != null && payload.getOnOpenAction() != null) {
            autoCancel = payload.getOnOpenAction().isAutoCancelNotification();
        }
        return autoCancel;
    }

    public boolean isTestMessage() {
        if(this.campaign == null || this.campaign.getVariationId() == null) {
            return false;
        }
        return this.campaign.getVariationId().equals(TUNE_TEST_MESSAGE);
    }

    public boolean isSilentPush() {
        return silentPush;
    }

    public String getAlertMessage() {
        return alertMessage;
    }

    public TunePushPayload getPayload() {
        return payload;
    }

    public TuneCampaign getCampaign() {
        return campaign;
    }

    public String getTicker() {
        // TODO ask the marketing user for a real ticker message
        return alertMessage;
    }

    public String getTitle() {
        // TODO ask the marketer user for a real title for the message
        return appName;
    }

    public String getAppId() {
        return appId;
    }

    /**
     * The notification ID should be unique for the app, otherwise a new notifications is going to replace the old one in the notification area.
     * Generally the notification id is going to be the same as the Tune push id, except when it isn't numeric.
     *
     * @return numeric identifier for this message
     */
    public int getTunePushIdAsInt() {
        int messageIdInt = 0;
        if (campaign.getVariationId() != null) {
            // push Ids are alphanumeric, and we need an int
            messageIdInt = campaign.getVariationId().hashCode();
        }
        return messageIdInt;
    }

    public String getChannelId() {
        return channelId;
    }

    public String getMessageIdentifier() {
        return messageIdentifier;
    }

    public String getStyle() {
        return style;
    }

    public Bitmap getImage() {
        return image;
    }

    public String getExpandedTitle() {
        return title;
    }

    public String getExpandedText() {
        return bigText;
    }

    public String getSummary() {
        return summary;
    }

    public String toJson() {
        JSONObject object = new JSONObject();
        try {
            object.put(JSON_APP_NAME, appName);
            object.put(BUNDLE_APP_ID, appId);
            object.put(BUNDLE_ALERT_KEY, alertMessage);
            object.put(BUNDLE_PUSH_ID_KEY, campaign.getVariationId());
            object.put(BUNDLE_CAMPAIGN_ID, campaign.getCampaignId());
            object.put(BUNDLE_LENGTH_TO_REPORT, campaign.getNumberOfSecondsToReportAnalytics());

            if (payload != null) {
                object.put(BUNDLE_PAYLOAD_KEY, payload.toJson().toString());
            }

            object.put(JSON_MESSAGE_ID, messageIdentifier);
            object.put(BUNDLE_CHANNEL_ID_KEY, channelId);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return object.toString();
    }
}