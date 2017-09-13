package com.tune.ma.inapp;

/**
 * Created by johng on 3/1/17.
 */

public class TuneInAppMessageConstants {
    // Message types
    public static final String MESSAGE_TYPE_BANNER = "TuneMessageTypeSlideIn";
    public static final String MESSAGE_TYPE_MODAL = "TuneMessageTypePopUp";
    public static final String MESSAGE_TYPE_FULLSCREEN = "TuneMessageTypeTakeOver";

    // Message animation styles
    public static final String TRANSITION_FROM_TOP = "TuneMessageTransitionFromTop";
    public static final String TRANSITION_FROM_BOTTOM = "TuneMessageTransitionFromBottom";
    public static final String TRANSITION_FROM_LEFT = "TuneMessageTransitionFromLeft";
    public static final String TRANSITION_FROM_RIGHT = "TuneMessageTransitionFromRight";
    public static final String TRANSITION_FADE_IN = "TuneMessageTransitionFadeIn";
    public static final String TRANSITION_NONE = "TuneMessageTransitionNone";

    // Message locations (banner only)
    public static final String LOCATION_TOP = "TuneMessageLocationTop";
    public static final String LOCATION_BOTTOM = "TuneMessageLocationBottom";

    // Message edge styles (modal only)
    public static final String EDGE_SQUARE_CORNERS = "TunePopUpMessageSquareCorners";
    public static final String EDGE_ROUND_CORNERS = "TunePopUpMessageRoundedCorners";

    // Message overlay styles (modal only)
    public static final String BACKGROUND_MASK_LIGHT = "TuneMessageBackgroundMaskTypeLight";
    public static final String BACKGROUND_MASK_DARK = "TuneMessageBackgroundMaskTypeDark";
    public static final String BACKGROUND_MASK_BLUR = "TuneMessageBackgroundMaskTypeBlur";
    public static final String BACKGROUND_MASK_NONE = "TuneMessageBackgroundMaskTypeNone";

    // JSON keys for parsing in-app message from playlist
    public static final String CAMPAIGN_ID_KEY = "campaignID";
    public static final String CAMPAIGN_STEP_ID_KEY = "campaignStepID";
    public static final String LENGTH_TO_REPORT_KEY = "lengthOfTimeToReport";
    public static final String START_DATE_KEY = "startDate";
    public static final String END_DATE_KEY = "endDate";

    public static final String MESSAGE_TYPE_KEY = "messageType";
    public static final String MESSAGE_ID_KEY = "messageID";
    public static final String TRIGGER_EVENTS_KEY = "triggerEvent";
    public static final String DISPLAY_FREQUENCY_KEY = "displayFrequency";
    public static final String MESSAGE_KEY = "message";
    public static final String HTML_KEY = "html";
    public static final String TRANSITION_KEY = "transition";
    public static final String ACTIONS_KEY = "actions";
    // Banner only
    public static final String MESSAGE_LOCATION_KEY = "messageLocationType";
    public static final String DURATION_KEY = "duration";
    public static final int INDEFINITE_DURATION_VALUE = 0;
    // Modal only
    public static final String WIDTH_KEY = "width";
    public static final String HEIGHT_KEY = "height";
    public static final String EDGE_STYLE_KEY = "edgeStyle";
    public static final String BACKGROUND_MASK_KEY = "backgroundMaskType";
    public static final int DEFAULT_CORNER_RADIUS = 10;

    // JSON keys for parsing message frequency from playlist
    public static final String LIFETIME_MAXIMUM_KEY = "lifetimeMaximum";
    public static final String LIMIT_KEY = "limit";
    public static final String SCOPE_KEY = "scope";

    public static final String SCOPE_VALUE_INSTALL = "INSTALL";
    public static final String SCOPE_VALUE_SESSION = "SESSION";
    public static final String SCOPE_VALUE_DAYS = "DAYS";
    public static final String SCOPE_VALUE_EVENTS = "EVENTS";

    // JSON keys for parsing in-app message actions from playlist
    public static final String ACTION_TYPE_KEY = "type";
    public static final String ACTION_TYPE_VALUE_CLOSE = "close";
    public static final String ACTION_TYPE_VALUE_DEEPLINK = "deeplink";
    public static final String ACTION_TYPE_VALUE_DEEPACTION = "deepAction";
    public static final String ACTION_DEEPLINK_KEY = "link";
    public static final String ACTION_DEEPACTION_ID_KEY = "id";
    public static final String ACTION_DEEPACTION_DATA_KEY = "data";

    // Url scheme to look for in HTML for Tune actions
    public static final String TUNE_ACTION_SCHEME = "tune-action:";
}
