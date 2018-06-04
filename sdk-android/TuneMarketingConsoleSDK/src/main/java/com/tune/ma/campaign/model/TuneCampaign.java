package com.tune.ma.campaign.model;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Date;
import java.util.HashSet;
import java.util.Set;

/**
 * Created by charlesgilliam on 2/9/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneCampaign {
    public static final String TUNE_CAMPAIGN_IDENTIFIER = "TUNE_CAMPAIGN_ID";
    public static final String TUNE_CAMPAIGN_VARIATION_IDENTIFIER = "TUNE_CAMPAIGN_VARIATION_ID";

    private String campaignId;
    private String variationId;
    private Integer numberOfSecondsToReportAnalytics;
    private Date lastViewed;
    private Date timestampToStopReportingAnalytics;
    // TODO: These two params seems specific to deeplinks
    //[encoder encodeObject:self.campaignSource forKey:@"campaignSource"];
    //[encoder encodeObject:self.sharedUserId forKey:@"sharedUserId"];

    public TuneCampaign(String campaignId, String variationId, Integer numberOfSecondsToReportAnalytics) {
        // TODO: None of this should be null (or 0 for the Integer)
        this.campaignId = campaignId;
        this.variationId = variationId;
        this.numberOfSecondsToReportAnalytics = numberOfSecondsToReportAnalytics;
    }

    public Set<TuneAnalyticsVariable> toAnalyticVariables() {
        Set<TuneAnalyticsVariable> result = new HashSet<TuneAnalyticsVariable>();
        result.add(new TuneAnalyticsVariable(TUNE_CAMPAIGN_IDENTIFIER, campaignId));
        result.add(new TuneAnalyticsVariable(TUNE_CAMPAIGN_VARIATION_IDENTIFIER, variationId));
        return result;
    }

    public boolean hasCampaignId() {
        return campaignId != null && campaignId.length() > 0;
    }

    public boolean hasVariationId() {
        return variationId != null && variationId.length() > 0;
    }

    public String getCampaignId() {
        return campaignId;
    }

    public String getVariationId() {
        return variationId;
    }

    public Integer getNumberOfSecondsToReportAnalytics() {
        return numberOfSecondsToReportAnalytics;
    }

    private void calculateTimestampToStopReportingAnalytics() {
        if (numberOfSecondsToReportAnalytics != null && lastViewed != null) {
            timestampToStopReportingAnalytics = new Date(lastViewed.getTime() + (1000*numberOfSecondsToReportAnalytics));
        }
    }

    public void markCampaignViewed() {
        lastViewed = new Date();
        calculateTimestampToStopReportingAnalytics();
    }

    public boolean needToReportCampaignAnalytics() {
        if (timestampToStopReportingAnalytics != null) {
            // is timestampToStopReportingAnalytics in the past?
            return timestampToStopReportingAnalytics.before(new Date());
        } else {
            return false;
        }
    }

    private static final String JSON_CAMPAIGN_ID = "campaignId";
    private static final String JSON_VARIATION_ID = "variationId";
    private static final String JSON_LAST_VIEWED = "lastViewed";
    private static final String JSON_NUMBER_OF_SECONDS_TO_REPORT = "numberOfSecondsToReportAnalytics";

    public String toStorage() throws JSONException {
        JSONObject result = new JSONObject();
        result.put(JSON_CAMPAIGN_ID, campaignId);
        result.put(JSON_VARIATION_ID, variationId);
        result.put(JSON_LAST_VIEWED, lastViewed.getTime());
        result.put(JSON_NUMBER_OF_SECONDS_TO_REPORT, numberOfSecondsToReportAnalytics);

        return result.toString();
    }

    public static TuneCampaign fromStorage(String json) throws JSONException {
        JSONObject jsonObject = new JSONObject(json);

        String campaignId = jsonObject.getString(JSON_CAMPAIGN_ID);
        String variationId = jsonObject.getString(JSON_VARIATION_ID);
        Integer secondsToReport = jsonObject.getInt(JSON_NUMBER_OF_SECONDS_TO_REPORT);

        TuneCampaign result = new TuneCampaign(campaignId, variationId, secondsToReport);
        result.lastViewed = new Date(jsonObject.getInt(JSON_LAST_VIEWED));
        result.calculateTimestampToStopReportingAnalytics();

        return result;
    }
}
