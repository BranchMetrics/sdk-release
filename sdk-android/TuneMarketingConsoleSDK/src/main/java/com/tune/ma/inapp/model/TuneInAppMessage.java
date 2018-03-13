package com.tune.ma.inapp.model;

import android.app.Activity;

import com.tune.TuneDebugLog;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.campaign.TuneCampaignViewed;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageActionTaken;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageShown;
import com.tune.ma.eventbus.event.inapp.TuneInAppMessageUnspecifiedActionTaken;
import com.tune.ma.inapp.model.action.TuneInAppAction;
import com.tune.ma.utils.TuneDateUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_MESSAGE_CLOSED;
import static com.tune.ma.analytics.model.event.inapp.TuneInAppMessageEvent.ANALYTICS_MESSAGE_DISMISSED_AUTOMATICALLY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.ACTIONS_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.CAMPAIGN_ID_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.CAMPAIGN_STEP_ID_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.DISPLAY_FREQUENCY_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.END_DATE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.HTML_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LENGTH_TO_REPORT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_ID_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.START_DATE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_FADE_IN;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_FROM_BOTTOM;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_FROM_LEFT;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_FROM_RIGHT;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_FROM_TOP;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRANSITION_NONE;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TRIGGER_EVENTS_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.TUNE_ACTION_SCHEME;
import static com.tune.ma.inapp.model.action.TuneInAppAction.DISMISS_ACTION;

/**
 * Created by johng on 2/21/17.
 */

/**
 * TuneInAppMessage is an abstract class that holds in-app message information from the playlist JSON
 */
public abstract class TuneInAppMessage {
    public enum Type {
        FULLSCREEN,
        MODAL,
        BANNER
    }

    public enum Transition {
        TOP,
        BOTTOM,
        LEFT,
        RIGHT,
        FADE_IN,
        NONE
    }

    private static final String FIRSTPLAYLISTDOWNLOADED_MD5 = "c1f8bd652909257485fb70e803d93915";

    private String id;
    private List<TuneTriggerEvent> triggerEvents;
    private Type type;
    private Transition transition;
    private String html;
    private Map<String, TuneInAppAction> actions;
    private TuneCampaign campaign;
    private String campaignStepId;
    private Date startDate;
    private Date endDate;

    private Date messageShownDate;
    private Date messageDismissedDate;
    private boolean isPreloaded;
    private boolean isVisible;

    public TuneInAppMessage() {
    }

    public TuneInAppMessage(JSONObject messageJson) {
        this.id = TuneJsonUtils.getString(messageJson, MESSAGE_ID_KEY);

        // Parse campaign information
        String campaignId = TuneJsonUtils.getString(messageJson, CAMPAIGN_ID_KEY);
        String variationId = this.id;
        int secondsToReport = TuneJsonUtils.getInt(messageJson, LENGTH_TO_REPORT_KEY);
        this.campaign = new TuneCampaign(campaignId, variationId, secondsToReport);

        this.campaignStepId = TuneJsonUtils.getString(messageJson, CAMPAIGN_STEP_ID_KEY);

        // Read startDate/endDate and use for display logic
        String startDateString = TuneJsonUtils.getString(messageJson, START_DATE_KEY);
        this.startDate = TuneDateUtils.parseIso8601(startDateString);

        String endDateString = TuneJsonUtils.getString(messageJson, END_DATE_KEY);
        this.endDate = TuneDateUtils.parseIso8601(endDateString);

        String triggerEventString = TuneJsonUtils.getString(messageJson, TRIGGER_EVENTS_KEY);
        JSONObject displayFrequencyJson = TuneJsonUtils.getJSONObject(messageJson, DISPLAY_FREQUENCY_KEY);

        this.triggerEvents = new ArrayList<TuneTriggerEvent>();
        TuneTriggerEvent triggerEvent = new TuneTriggerEvent(triggerEventString, displayFrequencyJson);
        this.triggerEvents.add(triggerEvent);

        JSONObject message = TuneJsonUtils.getJSONObject(messageJson, MESSAGE_KEY);
        this.html = TuneJsonUtils.getString(message, HTML_KEY);

        String transitionType = TuneJsonUtils.getString(message, TRANSITION_KEY);
        switch (transitionType) {
            case TRANSITION_FROM_TOP:
                this.transition = Transition.TOP;
                break;
            case TRANSITION_FROM_BOTTOM:
                this.transition = Transition.BOTTOM;
                break;
            case TRANSITION_FROM_LEFT:
                this.transition = Transition.LEFT;
                break;
            case TRANSITION_FROM_RIGHT:
                this.transition = Transition.RIGHT;
                break;
            case TRANSITION_FADE_IN:
                this.transition = Transition.FADE_IN;
                break;
            case TRANSITION_NONE:
            default:
                this.transition = Transition.NONE;
                break;
        }

        // Populate actions
        JSONObject actionsJson = TuneJsonUtils.getJSONObject(message, ACTIONS_KEY);

        // Convert actions JSONObject to Map<String, TuneInAppAction>
        this.actions = new HashMap<String, TuneInAppAction>();
        // Iterate through the JSONObject keys
        if (actionsJson != null) {
            Iterator<String> iter = actionsJson.keys();
            while (iter.hasNext()) {
                // Read action name
                String actionName = iter.next();
                // Read action details
                JSONObject actionJson = TuneJsonUtils.getJSONObject(actionsJson, actionName);
                if (actionJson == null) {
                    continue;
                }

                // Convert action details JSONObject to TuneInAppAction
                TuneInAppAction action = new TuneInAppAction(actionName, actionJson);

                this.actions.put(actionName, action);
            }
        }
    }

    public Map<String, TuneInAppAction> getActions() {
        return actions;
    }

    public void setCampaign(TuneCampaign campaign) {
        this.campaign = campaign;
    }

    public TuneCampaign getCampaign() {
        return campaign;
    }

    public void setCampaignStepId(String campaignStepId) {
        this.campaignStepId = campaignStepId;
    }

    public String getCampaignStepId() {
        return campaignStepId;
    }

    public String getHtml() {
        return html;
    }

    public void setHtml(String html) {
        this.html = html;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getId() {
        return id;
    }

    public Date getStartDate() {
        return startDate;
    }

    public void setStartDate(Date date) {
        this.startDate = date;
    }

    public Date getEndDate() {
        return endDate;
    }

    public void setEndDate(Date date) {
        this.endDate = date;
    }

    public Transition getTransition() {
        return transition;
    }

    public void setTransition(Transition transition) {
        this.transition = transition;
    }

    public void setTriggerEvents(List<TuneTriggerEvent> triggerEvents) {
        this.triggerEvents = triggerEvents;
    }

    public List<TuneTriggerEvent> getTriggerEvents() {
        return triggerEvents;
    }

    public void setType(Type type) {
        this.type = type;
    }

    public Type getType() {
        return type;
    }

    public void setPreloaded(boolean preloaded) {
        this.isPreloaded = preloaded;
    }

    public boolean isPreloaded() {
        return isPreloaded;
    }

    public synchronized void setVisible(boolean visible) {
        this.isVisible = visible;
    }

    public synchronized boolean isVisible() {
        return isVisible;
    }

    public boolean shouldDisplay(TuneMessageDisplayCount displayCount) {
        // Check if message startDate/endDate permits showing
        Date startDate = getStartDate();
        Date endDate = getEndDate();
        if (startDate != null && endDate != null) {
            // If message has both start and end date, now must be in between the two
            if (!TuneDateUtils.doesNowFallBetweenDates(startDate, endDate)) {
                TuneDebugLog.e("Current time not between campaign start date and end date, cannot display message");
                return false;
            }
        } else if (startDate != null) {
            // Message has only start, no end - check that start date has passed
            if (!TuneDateUtils.doesNowFallAfterDate(startDate)) {
                TuneDebugLog.e("Current time not after campaign start date, cannot display message");
                return false;
            }
        } else if (endDate != null) {
            // Message has only end, no start - check that end date has not passed
            if (!TuneDateUtils.doesNowFallBeforeDate(endDate)) {
                TuneDebugLog.e("Current time not before campaign end date, cannot display message");
                return false;
            }
        }

        // Message passes date checks, now check if frequency conditions pass.
        // If any fail, we use continue to go to the next trigger until we find one that passes (triggers are OR'd)
        for (TuneTriggerEvent triggerEvent : getTriggerEvents()) {
            // Find trigger events that have same event md5 as current event
            if (triggerEvent.getEventMd5().equals(displayCount.getTriggerEvent())) {
                // Special case: If trigger event is FirstPlaylistDownloaded, make sure it wasn't already triggered by Foregrounded this session
                if (triggerEvent.getEventMd5().equals(FIRSTPLAYLISTDOWNLOADED_MD5) && displayCount.getNumberOfTimesShownThisSession() > 0) {
                    TuneDebugLog.e("Message triggered by \"Starts App\" was already displayed this session, cannot display message");
                    continue;
                }

                // If lifetime maximum and limit are both zero, no limits apply so just show
                if (triggerEvent.getLifetimeMaximum() == 0 && triggerEvent.getLimit() == 0) {
                    return true;
                }

                // If lifetime shown count is above lifetime maximum, this trigger fails
                if (triggerEvent.getLifetimeMaximum() > 0 && displayCount.getLifetimeShownCount() >= triggerEvent.getLifetimeMaximum()) {
                    // This trigger failed, move on to the next one
                    TuneDebugLog.e("Message's lifetime shown count exceeds lifetime maximum, cannot display message");
                    continue;
                }

                // Check scope limits
                switch (triggerEvent.getScope()) {
                    case INSTALL:
                        // If message has been seen too many times, then trigger fails
                        if (triggerEvent.getLimit() > 0 && displayCount.getLifetimeShownCount() >= triggerEvent.getLimit()) {
                            TuneDebugLog.e("Message's lifetime shown count exceeds limit per install, cannot display message");
                            continue;
                        }
                        break;
                    case SESSION:
                        // If message has been seen too many times this session, then trigger fails
                        if (triggerEvent.getLimit() > 0 && displayCount.getNumberOfTimesShownThisSession() >= triggerEvent.getLimit()) {
                            TuneDebugLog.e("Message's session shown count exceeds limit per session, cannot display message");
                            continue;
                        }
                        break;
                    case DAYS:
                        if (displayCount.getLastShownDate() != null) {
                            // Get days between last shown date and today
                            int numberOfDaysSinceLastShown = TuneDateUtils.daysSinceDate(displayCount.getLastShownDate());
                            // If it hasn't been enough days since message was last shown, then trigger fails
                            if (triggerEvent.getLimit() > 0 && numberOfDaysSinceLastShown < triggerEvent.getLimit()) {
                                TuneDebugLog.e("Hasn't been enough days since message was last shown, cannot display message");
                                continue;
                            }
                        }
                        break;
                    case EVENTS:
                        // If the event hasn't happened enough times since last shown, then trigger fails
                        if (triggerEvent.getLimit() > 0 && displayCount.getEventsSeenSinceShown() < triggerEvent.getLimit()) {
                            TuneDebugLog.e("Event hasn't happened enough times since last shown, cannot display message");
                            continue;
                        }
                        break;
                    default:
                        break;
                }

                // If none of the above cases failed, then this trigger succeeded and message should be shown
                return true;
            }
        }
        return false;
    }

    public void processImpression() {
        // Record the time that message was shown
        messageShownDate = new Date();

        // Send a campaign viewed event
        TuneEventBus.post(new TuneCampaignViewed(getCampaign()));

        // Log an impression event
        TuneEventBus.post(new TuneInAppMessageShown(this));

        // Execute any onDisplay actions
        if (actions.containsKey(TuneInAppAction.ONDISPLAY_ACTION)) {
            TuneInAppAction onDisplayAction = actions.get(TuneInAppAction.ONDISPLAY_ACTION);
            onDisplayAction.execute();
        }
    }

    public void processDismiss() {
        // Record the time that message was dismissed
        messageDismissedDate = new Date();

        // Calculate seconds displayed since shown
        int secondsDisplayed = TuneDateUtils.secondsBetweenDates(messageShownDate, messageDismissedDate);

        // Log a dismiss event
        TuneEventBus.post(new TuneInAppMessageActionTaken(this, ANALYTICS_MESSAGE_CLOSED, secondsDisplayed));

        // Execute any onDisplay actions
        if (actions.containsKey(TuneInAppAction.ONDISMISS_ACTION)) {
            TuneInAppAction onDismissAction = actions.get(TuneInAppAction.ONDISMISS_ACTION);
            onDismissAction.execute();
        }
    }

    public void processDismissAfterDuration() {
        // Record the time that message was dismissed
        messageDismissedDate = new Date();

        // Calculate seconds displayed since shown
        int secondsDisplayed = TuneDateUtils.secondsBetweenDates(messageShownDate, messageDismissedDate);

        // Log a dismiss event
        TuneEventBus.post(new TuneInAppMessageActionTaken(this, ANALYTICS_MESSAGE_DISMISSED_AUTOMATICALLY, secondsDisplayed));

        // Execute any onDismiss actions
        if (actions.containsKey(TuneInAppAction.ONDISMISS_ACTION)) {
            TuneInAppAction onDismissAction = actions.get(TuneInAppAction.ONDISMISS_ACTION);
            onDismissAction.execute();
        }
    }

    /**
     * Checks if the url clicked in the WebView is a Tune action
     * If so, executes it
     * @param url Url to check whether it has a tune-action and should be executed
     */
    public void processAction(String url) {
        // Record the time that message was dismissed
        messageDismissedDate = new Date();

        // Calculate seconds displayed since shown
        int secondsDisplayed = TuneDateUtils.secondsBetweenDates(messageShownDate, messageDismissedDate);

        if (url.startsWith(TUNE_ACTION_SCHEME)) {
            // Look up action name from url
            String actionName = url.split("://")[1];

            // If action is "dismiss", treat it as a dismiss
            if (actionName.equals(DISMISS_ACTION)) {
                processDismiss();
                return;
            }

            TuneInAppAction action = actions.get(actionName);
            if (action == null) {
                // If the Tune Action name was not found in playlist, log an unspecified action event with action name
                TuneEventBus.post(new TuneInAppMessageUnspecifiedActionTaken(this, actionName, secondsDisplayed));
            } else {
                // Log a Tune Action event with action name
                TuneEventBus.post(new TuneInAppMessageActionTaken(this, actionName, secondsDisplayed));

                // Execute the action
                action.execute();
            }
        } else {
            // If the action is an external url, log an unspecified action event with url
            TuneEventBus.post(new TuneInAppMessageUnspecifiedActionTaken(this, url, secondsDisplayed));

            // Open a regular web url or deeplink without tune-action scheme
            TuneInAppAction.openUrl(url, TuneActivity.getLastActivity());
        }
    }

    // Display logic should be implemented by subclass
    public abstract void display();

    // Dismiss logic should be implemented by subclass
    public abstract void dismiss();

    public abstract void load(Activity activity);
}
