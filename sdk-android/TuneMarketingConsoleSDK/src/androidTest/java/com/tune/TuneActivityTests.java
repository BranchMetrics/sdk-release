package com.tune;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import com.tune.ma.application.TuneActivity;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneDeeplinkOpened;
import com.tune.mocks.MockUrlRequester;

import org.greenrobot.eventbus.Subscribe;
import org.json.JSONObject;
import org.mockito.Mockito;

import java.util.ArrayList;

import static org.mockito.Mockito.when;

/**
 * Created by audrey on 10/31/16.
 */

public class TuneActivityTests extends TuneUnitTest {

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
            TuneActivity.onResume(null);
            TuneActivity.onPause(null);
        } catch (Exception e) {
            exceptionOccurred = true;
        }

        // No exception should be thrown, error is logged for app developer if debug logs enabled
        assertFalse("Passing null to public API methods on TuneActivity should not cause an exception", exceptionOccurred);
    }

    public void testDeeplinkOpenSendsDeeplinkOpenedEvent() {
        TestEventBusListener listener = new TestEventBusListener();
        TuneEventBus.register(listener);

        // Mock an Activity onResume with intent data
        intent.setAction(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("myapp://isthe/best?with=links"));

        TuneActivity.onResume(activity);

        // DeeplinkOpened event should be sent since intent url was found
        assertEquals(1, listener.deeplinkOpenedCount);
        assertEquals("myapp://isthe/best?with=links", listener.deeplinkUrl);

        // Clear the intent
        when(activity.getIntent()).thenReturn(null);

        // Mock another Activity onResume, but without intent data
        TuneActivity.onResume(activity);

        // DeeplinkOpened event count should not have incremented as this onResume didn't have a url
        assertEquals(1, listener.deeplinkOpenedCount);
    }

    public void testSameIntentDoesntSendDeeplinkOpened() {
        TestEventBusListener listener = new TestEventBusListener();
        TuneEventBus.register(listener);

        Activity deeplinkActivity = Mockito.mock(Activity.class);
        Intent linkIntent = new Intent();
        linkIntent.setAction(Intent.ACTION_VIEW);
        linkIntent.setData(Uri.parse("myapp://isthe/best?with=links"));
        when(deeplinkActivity.getIntent()).thenReturn(linkIntent);

        TuneActivity.onResume(deeplinkActivity);

        // EventBus should have sent a DeeplinkOpened event
        assertEquals(1, listener.deeplinkOpenedCount);

        TuneActivity.onResume(deeplinkActivity);

        // Since the Intent is the same, EventBus should not have sent another
        assertEquals(1, listener.deeplinkOpenedCount);

        // Change the mock Intent that's returned
        linkIntent = new Intent();
        linkIntent.setAction(Intent.ACTION_VIEW);
        linkIntent.setData(Uri.parse("myapp://isthe/best?with=links"));
        when(deeplinkActivity.getIntent()).thenReturn(linkIntent);

        TuneActivity.onResume(deeplinkActivity);

        // Since the Intent changed, EventBus should send it again
        assertEquals(2, listener.deeplinkOpenedCount);
    }

    // This tests the case where a deeplink is opened, then a different deeplink is opened, then the original deeplinked Activity is reopened
    // It should not count as a new deeplink open
    public void testSameIntentDoesntSendDeeplinkOpenedWithDifferentIntentInBetween() {
        TestEventBusListener listener = new TestEventBusListener();
        TuneEventBus.register(listener);

        Activity deeplinkActivity = Mockito.mock(Activity.class);
        Intent linkIntent = new Intent();
        linkIntent.setAction(Intent.ACTION_VIEW);
        linkIntent.setData(Uri.parse("myapp://isthe/best?with=links"));
        when(deeplinkActivity.getIntent()).thenReturn(linkIntent);

        TuneActivity.onResume(deeplinkActivity);

        // EventBus should have sent a DeeplinkOpened event
        assertEquals(1, listener.deeplinkOpenedCount);

        // Change the mock Intent that's returned
        Intent linkIntent2 = new Intent();
        linkIntent2.setAction(Intent.ACTION_VIEW);
        linkIntent2.setData(Uri.parse("some://other/deeplink"));
        when(deeplinkActivity.getIntent()).thenReturn(linkIntent2);

        TuneActivity.onResume(deeplinkActivity);

        // Since the Intent changed, EventBus should send it
        assertEquals(2, listener.deeplinkOpenedCount);

        // Change the mock Intent that's returned back to the original Intent
        when(deeplinkActivity.getIntent()).thenReturn(linkIntent);

        TuneActivity.onResume(deeplinkActivity);

        // Since the Intent for this deeplink was the same as before, EventBus should not send it
        assertEquals(2, listener.deeplinkOpenedCount);
    }

    public class TestEventBusListener {
        public int deeplinkOpenedCount;
        public String deeplinkUrl;

        public TestEventBusListener() {
            deeplinkOpenedCount = 0;
        }

        @Subscribe
        public void onEvent(TuneDeeplinkOpened event) {
            deeplinkOpenedCount++;
            deeplinkUrl = event.getDeeplinkUrl();
        }
    }
}
