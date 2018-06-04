package com.tune.ma.analytics;

import android.content.Context;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;

import static android.support.test.InstrumentationRegistry.getContext;

/**
 * Created by johng on 1/11/16.
 */
public class TuneAnalyticsTest extends TuneUnitTest {
    public Context context;
    protected TuneAnalyticsManager analyticsManager;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        context = getContext();
        analyticsManager = TuneManager.getInstance().getAnalyticsManager();

        // Delete analytics files
        TuneManager.getInstance().getFileManager().deleteAnalytics();
    }

    @Override
    public void tearDown() throws Exception {
        TuneEventBus.post(new TuneAppBackgrounded());

        // Delete analytics files
        if (TuneManager.getInstance() != null) {
            TuneManager.getInstance().getFileManager().deleteAnalytics();
        }

        super.tearDown();
    }
}
