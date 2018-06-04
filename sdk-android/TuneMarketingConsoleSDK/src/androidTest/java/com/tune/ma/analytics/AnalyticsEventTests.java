package com.tune.ma.analytics;

import android.support.test.runner.AndroidJUnit4;

import com.tune.TuneEvent;
import com.tune.TuneUrlKeys;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.event.TuneCustomEvent;
import com.tune.ma.analytics.model.event.push.TunePushOpenedEvent;
import com.tune.ma.analytics.model.event.session.TuneForegroundEvent;
import com.tune.ma.analytics.model.event.tracer.TuneTracerEvent;
import com.tune.ma.push.model.TunePushMessage;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Date;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

/**
 * Created by johng on 1/13/16.
 */
@RunWith(AndroidJUnit4.class)
public class AnalyticsEventTests extends TuneAnalyticsTest {
    /**
     * Test that TuneAnalyticsEventBase gets converted from TuneEvent correctly
     */
    @Test
    public void testConvertingToTuneAnalyticsEvent() {
        TuneEvent eventToConvert = new TuneEvent("item1");
        eventToConvert.withRevenue(1.99);
        eventToConvert.withAttribute1("attr1");
        eventToConvert.withAttribute2("attr2");
        eventToConvert.withAttribute3("attr3");
        eventToConvert.withAttribute4("attr4");
        eventToConvert.withAttribute5("attr5");

        TuneCustomEvent event = new TuneCustomEvent(eventToConvert);

        assertEquals("Custom", event.getCategory());
        assertEquals(eventToConvert.getEventName(), event.getAction());

        for (TuneAnalyticsVariable var : event.getTags()) {
            String key = var.getName();
            assertTrue(key.equals(TuneUrlKeys.REVENUE) ||
                    key.equals(TuneUrlKeys.ATTRIBUTE1) ||
                    key.equals(TuneUrlKeys.ATTRIBUTE2) ||
                    key.equals(TuneUrlKeys.ATTRIBUTE3) ||
                    key.equals(TuneUrlKeys.ATTRIBUTE4) ||
                    key.equals(TuneUrlKeys.ATTRIBUTE5));
            if (key.equals(TuneUrlKeys.REVENUE)) {
                assertEquals(1.99, Double.parseDouble(var.getValue()), 0);
            } else if (key.equals(TuneUrlKeys.ATTRIBUTE1)) {
                assertEquals("attr1", var.getValue());
            } else if (key.equals(TuneUrlKeys.ATTRIBUTE2)) {
                assertEquals("attr2", var.getValue());
            } else if (key.equals(TuneUrlKeys.ATTRIBUTE3)) {
                assertEquals("attr3", var.getValue());
            } else if (key.equals(TuneUrlKeys.ATTRIBUTE4)) {
                assertEquals("attr4", var.getValue());
            } else if (key.equals(TuneUrlKeys.ATTRIBUTE5)) {
                assertEquals("attr5", var.getValue());
            }
        }
    }

    /**
     * Test that TuneEvent saves tags correctly when converted to TuneAnalyticsEventBase
     */
    @Test
    public void testTags() {
        TuneEvent eventToConvert = new TuneEvent("item1");
        eventToConvert.withTagAsString("tagString", "foobar");
        eventToConvert.withTagAsNumber("tagInt", 1);
        eventToConvert.withTagAsNumber("tagDouble", 0.99);
        eventToConvert.withTagAsNumber("tagFloat", 3.14f);
        eventToConvert.withTagAsDate("tagDate", new Date());

        TuneCustomEvent event = new TuneCustomEvent(eventToConvert);

        assertTrue(event.getTags().containsAll(eventToConvert.getTags()));
    }

    @Test
    public void testTagsWhenIAMNotEnabled() {
        // Enabled
        TuneEvent event = new TuneEvent("item1");
        event.withTagAsString("tagString", "foobar");
        event.withTagAsNumber("tagInt", 1);
        event.withTagAsNumber("tagDouble", 0.99);
        event.withTagAsNumber("tagFloat", 3.14f);
        event.withTagAsDate("tagDate", new Date());

        assertTrue(event.getTags().size() == 5);

        // Disabled
        TuneManager.destroy();
        event = new TuneEvent("item1");
        event.withTagAsString("tagString", "foobar");
        event.withTagAsNumber("tagInt", 1);
        event.withTagAsNumber("tagDouble", 0.99);
        event.withTagAsNumber("tagFloat", 3.14f);
        event.withTagAsDate("tagDate", new Date());

        assertTrue(event.getTags().size() == 0);

        // Disabled w/ Debug
        tune.setDebugMode(true);
        try {
            event = new TuneEvent("item1");
            event.withTagAsString("tagString", "foobar");
        } catch (Exception e) {
            return;
        }

        assertTrue("withTagAsString should have thrown an exception", false);
    }

    @Test
    public void testFiveline() throws JSONException {
        // Test custom event fiveline
        TuneEvent tuneEvent = new TuneEvent("fivelinetest");
        TuneCustomEvent customEvent = new TuneCustomEvent(tuneEvent);

        assertEquals("Custom|||fivelinetest|EVENT", customEvent.getFiveline());

        // Test session event fiveline
        TuneForegroundEvent foregroundEvent = new TuneForegroundEvent();

        assertEquals("Application|||Foregrounded|SESSION", foregroundEvent.getFiveline());

        // Test tracer event fiveline
        TuneTracerEvent tracerEvent = new TuneTracerEvent();

        assertEquals("||||TRACER", tracerEvent.getFiveline());

        // Test push event fiveline
        JSONObject pushMessageJson = new JSONObject();
        pushMessageJson.put("appName", "fiveline test");
        pushMessageJson.put("app_id", "12345");
        pushMessageJson.put("alert", "Buy coins!");
        pushMessageJson.put("CAMPAIGN_ID", "67890");
        pushMessageJson.put("ARTPID", "123");
        pushMessageJson.put("LENGTH_TO_REPORT", 9000);
        pushMessageJson.put("local_message_id", "abcd");

        TunePushMessage message = new TunePushMessage(pushMessageJson.toString());
        TunePushOpenedEvent pushOpenedEvent = new TunePushOpenedEvent(message);

        assertEquals("123|||NotificationOpened|PUSH_NOTIFICATION", pushOpenedEvent.getFiveline());
    }

    /**
     * Test that timestamp is not formatted in scientific notation when converted to String
     */
    @Test
    public void testTimestampFormattedCorrectly() throws JSONException {
        TuneEvent eventToConvert = new TuneEvent("item1");
        TuneCustomEvent event = new TuneCustomEvent(eventToConvert);
        long eventTimestamp = event.getTimeStamp();

        // Get string representation of event json
        String eventString = event.toJson().toString();

        // Get timestamp string value from event json string
        Pattern regex = Pattern.compile("\"timestamp\":([0-9]+),");
        Matcher matcher = regex.matcher(eventString);
        // Check that timestamp is all numeric
        if (matcher.find()) {
            String timestampStringValue = matcher.group(1);
            // Check that timestamp string is the same value
            assertEquals(eventTimestamp, Long.parseLong(timestampStringValue));
        } else {
            fail("Did not find all-numeric timestamp in event json");
        }
    }
}
