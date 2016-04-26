package com.tune.ma.analytics.model.event.session;

import com.tune.ma.analytics.model.TuneEventType;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;

/**
 * Created by johng on 1/26/16.
 * Base class for all session analytics events.
 */
public abstract class TuneSessionEvent extends TuneAnalyticsEventBase {
    public static final String FOREGROUNDED = "Foregrounded";
    public static final String BACKGROUNDED = "Backgrounded";
    public static final String FIRST_PLAYLIST_DOWNLOADED = "FirstPlaylistDownloaded";

    public TuneSessionEvent() {
        super();

        category = APPLICATION_CATEGORY;
        eventType = TuneEventType.SESSION;
    }

}
