package com.tune;

import android.support.test.runner.AndroidJUnit4;

import com.tune.mocks.MockUrlRequester;

import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.ArrayList;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

@RunWith(AndroidJUnit4.class)
public class ServerTests extends TuneUnitTest implements ITuneListener {
    private class WaitObject {
        private boolean enqueuedSession;
        private boolean enqueuedEvent;
        private boolean callSuccess;
        private boolean callFailed;
        private String url;

        void reset() {
            enqueuedSession = false;
            enqueuedEvent = false;
            callSuccess = false;
            callFailed = false;
            url = null;
        }
    }

    private final WaitObject mWaitObject = new WaitObject();

    private void waitForRequest(long timeout) {
        synchronized (mWaitObject) {
            try {
                mWaitObject.wait(timeout);
            } catch (InterruptedException e) {
                Log("Interrupted: " + e);
            }
        }
    }

    @Before
    public void setUp() throws Exception  {
        super.setUp();

        Tune.setDebugMode(true);
        tune.setListener(this);
        tune.setOnline(true);

        MockUrlRequester mockUrlRequester = new MockUrlRequester();
        tune.setUrlRequester(mockUrlRequester);
    }

    @Test
    public void testSession() {
        tune.measureSessionInternal();

        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);

        assertTrue(mWaitObject.enqueuedSession);
        assertFalse(mWaitObject.enqueuedEvent);

        assertTrue("session should have succeeded", mWaitObject.callSuccess);
        assertFalse("session should not have failed", mWaitObject.callFailed);
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

    @Test
    public void testUpdate() {
        Log("testUpdate");
        tune.setExistingUser(true);
        tune.measureSessionInternal();

        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);

        assertTrue("update should have succeeded", mWaitObject.callSuccess);
        assertFalse("update should not have failed", mWaitObject.callFailed);
    }

    @Test
    public void testEventName() {
        tune.measureEvent( "testEventName" );

        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);

        assertTrue(mWaitObject.enqueuedEvent);
        assertFalse(mWaitObject.enqueuedSession);

        assertTrue("action should have succeeded", mWaitObject.callSuccess);
        assertFalse("action should not have failed", mWaitObject.callFailed);
    }

    @Test
    public void testEventNameDuplicate() {
        final String eventName = "testEventName";
        tune.measureEvent(eventName);
        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);

        assertTrue("action should have succeeded", mWaitObject.callSuccess);
        assertFalse("action should not have failed", mWaitObject.callFailed);

        mWaitObject.reset();
        tune.measureEvent( eventName );

        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);
        assertTrue("action should have succeeded", mWaitObject.callSuccess);
        assertFalse("action should not have failed", mWaitObject.callFailed);
    }

    @Test
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
        ArrayList<TuneEventItem> testItems = new ArrayList<>();
        testItems.add( item1 );
        testItems.add( item2 );

        TuneEvent eventData = new TuneEvent(eventName).withEventItems(testItems);
        tune.measureEvent(eventData);
        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);

        assertTrue("action should have succeeded", mWaitObject.callSuccess);
        assertFalse("action should not have failed", mWaitObject.callFailed);
    }

    @Test
    public void testPlatformAdvertisingIdAutoCollect() {
        tune.measureSessionInternal();
        waitForRequest(TuneTestConstants.SERVERTEST_SLEEP);

        assertTrue(mWaitObject.enqueuedSession);
        assertFalse(mWaitObject.enqueuedEvent);

        assertTrue("session should have succeeded", mWaitObject.callSuccess);
        assertFalse("session should not have failed", mWaitObject.callFailed);

        assertTrue("params default values failed " + params, params.checkDefaultValues());

        assertHasValueForKey(TuneUrlKeys.PLATFORM_AID);
        assertNotNull(tune.getPlatformAdvertisingId());

        assertHasValueForKey(TuneUrlKeys.GOOGLE_AID);
        assertNotNull(tune.getTuneParams().getGoogleAdvertisingId());
    }

    @Override
    public void enqueuedRequest(String url, JSONObject postData) {
        synchronized (mWaitObject) {
            mWaitObject.url = url;

            if (url.contains("action=session")) {
                mWaitObject.enqueuedSession = true;
            }
            if (url.contains("action=conversion")) {
                mWaitObject.enqueuedEvent = true;
            }
        }
    }

    @Override
    // Method is mocked for testing purposes; no need for data argument
    public void didSucceedWithData(String url, JSONObject data) {
        synchronized (mWaitObject) {
            mWaitObject.url = url;
            mWaitObject.callSuccess = true;
            mWaitObject.notify();
        }
    }

    @Override
    public void didFailWithError(String url, JSONObject error) {
        Log("test failed with " + error);
        synchronized (mWaitObject) {
            mWaitObject.url = url;
            mWaitObject.callFailed = true;
            mWaitObject.notify();
        }
    }
}
