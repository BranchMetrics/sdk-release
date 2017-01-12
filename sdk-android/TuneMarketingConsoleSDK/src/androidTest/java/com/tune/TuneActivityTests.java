package com.tune;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import com.tune.ma.application.TuneActivity;
import com.tune.mocks.MockUrlRequester;

import org.json.JSONObject;
import org.mockito.Mockito;

import java.util.ArrayList;

import static org.mockito.Mockito.when;

/**
 * Created by audrey on 10/31/16.
 */

public class TuneActivityTests extends TuneUnitTest {

    private ArrayList<JSONObject> successResponses;
    private MockUrlRequester mockUrlRequester;
    private Intent intent;

    private Activity activity;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        activity = Mockito.mock(Activity.class);

        intent = new Intent();

        when(activity.getIntent()).thenReturn(intent);

        mockUrlRequester = new MockUrlRequester();
        tune.setUrlRequester(mockUrlRequester);
        tune.setTimeLastMeasuredSession(0);

        tune.setOnline(false); // let the measure requests queue up
    }

    public void testOnResumeFromMainLaunch() throws Exception {
        intent.setAction(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);
        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        // should measure session
        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued one measure session request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1);
    }

    public void testOnResumeFromMainLaunchIsMeasuredEveryTime() throws Exception {
        intent.setAction(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);

        TuneActivity.onResume(activity);
        TuneActivity.onResume(activity);
        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued three measure session requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 3);
    }

    public void testOnResumeFromDeeplinkOpen() {
        intent.setAction(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("myapp://isthe/best?with=links"));

        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued one measure session request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1);
    }

    public void testOnResumeFromDeeplinkOpenEveryTime() {
        intent.setAction(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("myapp://isthe/best?with=links"));

        TuneActivity.onResume(activity);
        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued two measure session requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 2);
    }

    public void testOnResumeAfterNineHoursSinceLastMeasureSession() {
        tune.setTimeLastMeasuredSession(System.currentTimeMillis() - (9 * 60 * 60 * 1000));
        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued one measure session request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1);
    }

    public void testOnResumeAfterMoreThanADaySinceLastMeasureSession() {
        tune.setTimeLastMeasuredSession(System.currentTimeMillis() - 86400002);
        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued one measure session request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1);
    }

    public void testOnResumeAfterLessThanEightHoursSinceLastMeasureSession() {
        // pretend that we just tracked a measureSession five hours ago
        tune.setTimeLastMeasuredSession(System.currentTimeMillis() - (5 * 60 * 60 * 1000));

        TuneActivity.onResume(activity);
        sleep(TuneTestConstants.PARAMTEST_SLEEP * 2);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should NOT have enqueued a request, but found " + queue.getQueueSize(), queue.getQueueSize() == 0);
    }

    public void testOnResumeForDifferentKindsOfIntents() {
        Activity linkActivity = Mockito.mock(Activity.class);
        Intent linkIntent = new Intent();
        linkIntent.setAction(Intent.ACTION_VIEW);
        linkIntent.setData(Uri.parse("myapp://isthe/best?with=links"));
        when(linkActivity.getIntent()).thenReturn(linkIntent);

        Activity launchActivity = Mockito.mock(Activity.class);
        Intent launchIntent = new Intent();
        launchIntent.setAction(Intent.ACTION_MAIN);
        launchIntent.addCategory(Intent.CATEGORY_LAUNCHER);
        when(launchActivity.getIntent()).thenReturn(launchIntent);

        Activity plainActivity = Mockito.mock(Activity.class);
        Intent plainIntent = new Intent();
        when(plainActivity.getIntent()).thenReturn(plainIntent);

        TuneActivity.onResume(linkActivity);
        TuneActivity.onResume(launchActivity);
        TuneActivity.onResume(plainActivity); // will not be measured
        TuneActivity.onResume(plainActivity); // will not be measured
        TuneActivity.onResume(plainActivity); // will not be measured
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued two measure session requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 2);
    }

    public void testPassNullToActivityMethods() {
        boolean exceptionOccurred = false;
        try {
            TuneActivity.onStart(null);
            TuneActivity.onResume(null);
            TuneActivity.onStop(null);
        } catch (Exception e) {
            exceptionOccurred = true;
        }

        // No exception should be thrown, error is logged for app developer if debug logs enabled
        assertFalse("Passing null to public API methods on TuneActivity should not cause an exception", exceptionOccurred);
    }
}
