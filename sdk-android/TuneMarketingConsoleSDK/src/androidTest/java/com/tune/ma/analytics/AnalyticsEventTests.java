package com.tune.ma.analytics;

import com.tune.TuneEvent;
import com.tune.TuneUrlKeys;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.event.TuneCustomEvent;

import java.util.Date;

/**
 * Created by johng on 1/13/16.
 */
public class AnalyticsEventTests extends TuneAnalyticsTest {
    /**
     * Test that TuneAnalyticsEventBase gets converted from TuneEvent correctly
     */
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
                assertEquals(1.99, Double.parseDouble(var.getValue()));
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

    public void testConvertingIdEventToTuneAnalyticsEvent() {
        TuneEvent eventToConvert = new TuneEvent(123);
        TuneCustomEvent event = new TuneCustomEvent(eventToConvert);

        assertEquals("Custom", event.getCategory());
        assertEquals("123", event.getAction());
    }

    /**
     * Test that TuneEvent saves tags correctly when converted to TuneAnalyticsEventBase
     */
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
}
