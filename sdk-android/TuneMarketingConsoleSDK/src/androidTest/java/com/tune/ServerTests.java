package com.tune;

import com.tune.mocks.MockUrlRequester;

import org.json.JSONObject;

import java.util.ArrayList;

public class ServerTests extends TuneUnitTest implements TuneListener {
    private boolean callSuccess;
    private boolean callFailed;
    private boolean enqueuedSession;
    private boolean enqueuedEvent;
    private JSONObject serverResponse;
    private MockUrlRequester mockUrlRequester;

    @Override
    protected void setUp() throws Exception  {
        super.setUp();

        callSuccess = false;
        callFailed = false;
        enqueuedSession = false;
        enqueuedEvent = false;

        tune.setDebugMode( true );
        tune.setListener(this);

        mockUrlRequester = new MockUrlRequester();
        tune.setUrlRequester(mockUrlRequester);
    }

    public void testSession() {
        tune.measureSessionInternal();
        
        sleep( TuneTestConstants.SERVERTEST_SLEEP );

        assertTrue(enqueuedSession);
        assertFalse(enqueuedEvent);
        
        assertTrue( "session should have succeeded", callSuccess );
        assertFalse( "session should not have failed", callFailed );
    }

    /* JAB 2/4/14: duplicates not being rejected for some reason... same in iOS tests
    public void testInstallDuplicate() {
        int success = tune.trackSession();
        sleep( 7500 );
        assertTrue( "trackInstall should have returned success", success == 1 );
        assertTrue( "install should have succeeded", callSuccess );
        assertFalse( "install should not have failed", callFailed );
        
        callSuccess = false;

        success = tune.trackSession();
        sleep( 7500 );
        assertTrue( "trackInstall should have returned success, but was " + success, success == 1 );
        assertFalse( "install should not have succeeded", callSuccess );
        assertTrue( "install should have failed", callFailed );
    }
    */

    public void testUpdate() {
        tune.setExistingUser( true );
        tune.measureSessionInternal();

        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        
        assertTrue( "update should have succeeded", callSuccess );
        assertFalse( "update should not have failed", callFailed );
    }

    public void testEventName() {
        tune.measureEvent( "testEventName" );

        sleep( TuneTestConstants.SERVERTEST_SLEEP );

        assertTrue(enqueuedEvent);
        assertFalse(enqueuedSession);
        
        assertTrue( "action should have succeeded", callSuccess );
        assertFalse( "action should not have failed", callFailed );
    }

    public void testEventNameDuplicate() {
        final String eventName = "testEventName";
        tune.measureEvent( eventName );
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        
        assertTrue( "action should have succeeded", callSuccess );
        assertFalse( "action should not have failed", callFailed );
        
        callSuccess = false;
        tune.measureEvent( eventName );
        sleep( 5000 );
        assertTrue( "action should have succeeded", callSuccess );
        assertFalse( "action should not have failed", callFailed );
    }

    public void testEventNameItems() {
        final String eventName = "testEventName";
        final TuneEventItem item1 = new TuneEventItem("testItemName")
                                       .withQuantity(42)
                                       .withUnitPrice(1.11)
                                       .withRevenue(12.34)
                                       .withAttribute1("attribute1")
                                       .withAttribute2("attribute2")
                                       .withAttribute3("attribute3")
                                       .withAttribute4("attribute4")
                                       .withAttribute5("attribute5");
        final TuneEventItem item2 = new TuneEventItem("anotherItemName")
                                       .withQuantity(13)
                                       .withUnitPrice(2.72)
                                       .withRevenue(99.99)
                                       .withAttribute1("hat1")
                                       .withAttribute2("hat2")
                                       .withAttribute3("hat3")
                                       .withAttribute4("hat4")
                                       .withAttribute5("hat5");
        ArrayList<TuneEventItem> testItems = new ArrayList<TuneEventItem>();
        testItems.add( item1 );
        testItems.add( item2 );
        
        TuneEvent eventData = new TuneEvent(eventName).withEventItems(testItems);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.SERVERTEST_SLEEP );
        
        assertTrue( "action should have succeeded", callSuccess );
        assertFalse( "action should not have failed", callFailed );
    }

    // TODO: Android emulator does not have Google AID
//    public void testGoogleAdvertisingIdAutoCollect() {
//        tune.measureSession();
//        sleep( TuneTestConstants.PARAMTEST_SLEEP );
//
//        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
//        assertNoValueForKey( "google_aid" );
//
//        sleep( TuneTestConstants.SERVERTEST_SLEEP );
//
//        assertTrue( "action should have succeeded", callSuccess );
//        assertTrue( "JSON response must have \"get\" field", serverResponse.has( "get" ) );
//        try {
//            JSONObject get = serverResponse.getJSONObject( "get" );
//            assertTrue( "JSON \"get\" must have \"google_aid\" field", get.has( "google_aid" ) );
//            Object gaidObj = get.get( "google_aid" );
//            assertTrue( "google_aid must be a string", gaidObj instanceof String );
//        } catch (JSONException e) {
//            e.printStackTrace();
//            assertTrue( false );
//        }
//    }

    @Override
    public void enqueuedActionWithRefId(String refId) {
    }

    @Override
    public void enqueuedRequest(String url, JSONObject postData) {
        if (url.contains("action=session")) {
            enqueuedSession = true;
        }
        if (url.contains("action=conversion")) {
            enqueuedEvent = true;
        }
    }

    @Override
    public void didSucceedWithData(JSONObject data) {
        Log("test succeeded");
        callSuccess = true;
        serverResponse = data;
    }

    @Override
    public void didFailWithError(JSONObject error) {
        Log("test failed with " + error);
        callFailed = true;
    }
}
