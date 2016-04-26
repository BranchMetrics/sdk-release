package com.tune;

import com.tune.mocks.MockUrlRequester;

import java.util.ArrayList;

import org.json.JSONException;
import org.json.JSONObject;

public class QueueTests extends TuneUnitTest implements TuneListener {
    private ArrayList<JSONObject> successResponses;
    private MockUrlRequester mockUrlRequester;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        mockUrlRequester = new MockUrlRequester();
        tune.setUrlRequester(mockUrlRequester);
    }

    public void testOnlineCapability() {
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );

        tune.setOnline( false );
        assertFalse( "should be offline", TuneTestWrapper.isOnline( getContext() ) );
        tune.setOnline( true );
        assertTrue( "should be online", TuneTestWrapper.isOnline( getContext() ) );
    }

    public void testOfflineFailureQueued() {
        tune.setOnline(false);
        tune.measureEvent("registration");
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
        assertNotNull("queue hasn't been initialized yet", queue);
        assertTrue("should have enqueued one request, but found " + queue.getQueueSize(), queue.getQueueSize() == 1);
    }

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

    public void testEnqueue2() {
        tune.setOnline( false );
        tune.measureEvent("registration");
        tune.measureEvent( "testActionName" );
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertNotNull( "queue hasn't been initialized yet", queue );
        assertTrue( "should have enqueued two requests, but found " + queue.getQueueSize(), queue.getQueueSize() == 2 );
    }

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

    public void testEnqueue2RetriedOrder() {
        successResponses = new ArrayList<JSONObject>();
        tune.setListener( this );
        tune.setDebugMode( true );

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
    
    public void test400FailureDropped() {
        // This first test goes from offline -> online, triggering a dump. Sleep to let that complete
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
    
    public void test500FailureRequeued() {
        // hit our failure endpoint, assert that the request gets requeued
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
    
    public void testFailureRequeuedOrderMaintained() {
        // TODO: add request to our failure endpoint, add a second request, assert that the failed request is still first in the queue and blocks the second request
    }

    @Override
    public void enqueuedActionWithRefId(String refId) {
        Log("enqueued with ref id " + refId);
    }

    @Override
    public void didSucceedWithData (JSONObject data) {
        successResponses.add( data );
        Log("succeed with data " + data);
    }

    @Override
    public void didFailWithError(JSONObject error) {
        Log("fail with error " + error);
    }
}
