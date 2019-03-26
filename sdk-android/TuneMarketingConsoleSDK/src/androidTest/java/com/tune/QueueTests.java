package com.tune;

import android.support.test.runner.AndroidJUnit4;

import com.tune.mocks.MockUrlRequester;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.security.InvalidParameterException;
import java.util.ArrayList;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

@RunWith(AndroidJUnit4.class)
public class QueueTests extends TuneUnitTest implements ITuneListener {
    private ArrayList<JSONObject> successResponses;
    private MockUrlRequester mockUrlRequester;
    private String receivedDeeplink;

    @Before
    public void setUp() throws Exception {
        super.setUp();

        mockUrlRequester = new MockUrlRequester();
        tune.setUrlRequester(mockUrlRequester);
    }

    @Test
    public void testOnlineCapability() {
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );

        tune.setOnline( false );
        assertFalse( "should be offline", TuneInternal.getInstance().isOnline() );
        tune.setOnline( true );
        assertTrue( "should be online", TuneInternal.getInstance().isOnline() );
    }

    @Test
    public void testOfflineFailureQueued() {
        tune.setOnline(false);
        tune.measureEvent("registration");
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued one request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1);
    }

    @Test
    public void testOfflineFailureQueuedRetried() {
        tune.setOnline( false );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "should have enqueued one request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1 );

        tune.setOnline( true );
        //Intent onlineIntent = new Intent( ConnectivityManager.CONNECTIVITY_ACTION );
        //getContext().getApplicationContext().sendBroadcast( onlineIntent );
        // Trigger dumpQueue since we can't send CONNECTIVITY_CHANGE intent
        tune.dumpQueue();
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        assertTrue( "should have dequeued request", queue.getQueueSize() == 0 );
    }

    @Test
    public void testEmptyEventNotEnqueued() {
        Tune.setDebugMode(false);
        tune.setOnline( false );

        // This should not throw an exception, because debug mode is off
        String nullString = null;
        tune.measureEvent(nullString);

        // Turning on debug mode will cause it to throw
        Tune.setDebugMode(true);
        try {
            tune.measureEvent("");
            assertFalse(true);
        } catch (InvalidParameterException e) {
            // This is expected
        }

        // In either case, nothing will be queued.
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "should have enqueued zero requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 0 );
        Tune.setDebugMode(false);
    }

    @Test
    public void testEnqueue2() {
        tune.setOnline( false );
        tune.measureEvent("registration");
        tune.measureEvent( "testActionName" );
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "should have enqueued two requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 2 );
    }

    @Test
    public void testEnqueue2Retried() {
        tune.setOnline(false);
        tune.measureEvent("registration");
        tune.measureEvent("testActionName");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued two requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 2);

        tune.setOnline(true);
        //Intent onlineIntent = new Intent( ConnectivityManager.CONNECTIVITY_ACTION );
        //getContext().getApplicationContext().sendBroadcast( onlineIntent );
        // Trigger dumpQueue since we can't send CONNECTIVITY_CHANGE intent
        tune.dumpQueue();
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        assertTrue( "should have dequeued requests", queue.getQueueSize() == 0 );
    }

    @Test
    public void testEnqueue2RetriedOrder() {
        successResponses = new ArrayList<>();
        tune.setListener( this );
        Tune.setDebugMode( true );

        tune.setOnline( false );
        tune.measureEvent( "event1" );
        params = new TuneTestParams();
        tune.measureEvent( "event2" );

        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "should have enqueued two requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 2 );

        tune.setOnline( true );
        //Intent onlineIntent = new Intent( ConnectivityManager.CONNECTIVITY_ACTION );
        //getContext().getApplicationContext().sendBroadcast( onlineIntent );
        // Trigger dumpQueue since we can't send CONNECTIVITY_CHANGE intent
        tune.dumpQueue();
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        assertTrue( "should have dequeued all requests, found " + queue.getQueueSize() + " remaining", queue.getQueueSize() == 0 );

        assertTrue( "should have two success responses, found " + successResponses.size(), successResponses.size() == 2 );
    }

    @Test
    public void testEnqueueCountClear() {
        // Run the test that enqueues two requests (and makes sure they are there)
        testEnqueue2();

        // Clear the queue.  The count of items should go to zero
        queue.clearQueue();
        assertTrue("should have enqueued two requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 0);
    }

    @Test
    public void test400FailureDropped() {
        // This first test goes from offline -> online, triggering a dump. Sleep to let that complete
        tune.setOnline(true);
        sleep( 1000 );

        // hit our failure endpoint, assert that the queue is empty
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "queue should be empty, but found " + queue.getQueueSize(), queue.getQueueSize() == 0 );

        String request = "http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&sdk_retry_attempt=0&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request&headers%5BX-MAT-Responder%5D=someserver";
        tune.addEventToQueue(request, "", new JSONObject(), false);
        sleep( 500 );
        assertTrue( "queue should have one item, but found " + queue.getQueueSize(), queue.getQueueSize() == 1 );

        tune.dumpQueue();
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        assertTrue( "queue should be empty, but found " + queue.getQueueSize(), queue.getQueueSize() == 0 );
    }

    @Test
    public void test500FailureRequeued() {
        // hit our failure endpoint, assert that the request gets requeued
        tune.setOnline(true);
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "queue should be empty, but found " + queue.getQueueSize(), queue.getQueueSize() == 0 );

        mockUrlRequester.setRequestUrlShouldSucceed(false);

        String request = "http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&sdk_retry_attempt=0&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error";
        tune.addEventToQueue(request, "", new JSONObject(), false);
        sleep( 50 );
        assertTrue( "queue should have one item, but found " + queue.getQueueSize(), queue.getQueueSize() == 1 );

        tune.dumpQueue();
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        assertTrue( "queue should still have one item, but found " + queue.getQueueSize(), queue.getQueueSize() == 1 );

        try {
            JSONObject item = queue.getQueueItem( 1 );
            String link = item.getString("link");
            assertTrue( "item in queue should be our request, but found " + link, link.contains( "statusCode%5Bcode%5D=500" ) );
            assertFalse( "retry index should have been incremented", link.contains( "&sdk_retry_attempt=0&" ) );
            assertTrue( "retry index should have been incremented", link.contains( "&sdk_retry_attempt=1&" ) );
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue( "failed parsing queue item", false );
        }
    }

    @Test
    public void testInvokeIdLookupBypassesQueue() {
        final Object waitObject = new Object();

        // hit our failure endpoint, assert that the request gets requeued
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "queue should be empty, but found " + queue.getQueueSize(), queue.getQueueSize() == 0 );

        TuneDeeplinkListener deeplinkListener = new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                receivedDeeplink = deeplink;
                synchronized(waitObject) {
                    waitObject.notify();
                }
            }

            @Override
            public void didFailDeeplink(String error) {
                // This isn't exactly what we are looking for, but it will help move things along.
                receivedDeeplink = "Error: " + error;
            }
        };
        tune.registerDeeplinkListener(deeplinkListener);

        // It takes some amount of time to receive the deeplink callback...
        int retryCount = 3;
        while (receivedDeeplink == null && retryCount-- > 0) {
            synchronized (waitObject) {
                try {
                    waitObject.wait(TuneTestConstants.SERVERTEST_SLEEP);
                } catch (InterruptedException e) {
                    TuneDebugLog.d("registerDeeplinkListener() Interrupted", e);
                }
            }
        }

        tune.measureSessionInternal();
        tune.setReferralUrl("https://tty-o.tlnk.io/serve?action=click&publisher_id=169564&site_id=68756&invoke_id=289304");
        assertTrue(waitForTuneNotification(TuneTestConstants.PARAMTEST_SLEEP));

        assertTrue("queue should be empty, but found " + queue.getQueueSize(), queue.getQueueSize() == 0);
        assertEquals("testing://allthethings?success=yes", receivedDeeplink);
    }

    @Test
    public void testFailureRequeuedOrderMaintained() {
        // TODO: add request to our failure endpoint, add a second request, assert that the failed request is still first in the queue and blocks the second request
    }

    @Override
    public void enqueuedRequest(String url, JSONObject postData) {
        Log("enqueued with url " + url + ", postData " + postData.toString());
    }

    @Override
    public void didSucceedWithData (String url, JSONObject data) {
        successResponses.add( data );
        Log("succeed with data " + data);
    }

    @Override
    public void didFailWithError(String url, JSONObject error) {
        Log("fail with error " + error);
    }
}
