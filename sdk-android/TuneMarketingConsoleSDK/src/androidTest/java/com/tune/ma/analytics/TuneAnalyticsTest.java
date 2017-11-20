package com.tune.ma.analytics;

import android.content.Context;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.application.TuneActivity;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;

import org.mockito.Mock;

/**
 * Created by johng on 1/11/16.
 */
public class TuneAnalyticsTest extends TuneUnitTest {
    public Context context;
    protected TuneAnalyticsManager analyticsManager;

    @Mock
    TuneActivity activity;

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        context = getContext();
        analyticsManager = TuneManager.getInstance().getAnalyticsManager();

        // Delete analytics files
        TuneManager.getInstance().getFileManager().deleteAnalytics();
    }

    @Override
    protected void tearDown() throws Exception {
        TuneEventBus.post(new TuneAppBackgrounded());

        // Delete analytics files
        if (TuneManager.getInstance() != null) {
            TuneManager.getInstance().getFileManager().deleteAnalytics();
        }

        super.tearDown();
    }
}
