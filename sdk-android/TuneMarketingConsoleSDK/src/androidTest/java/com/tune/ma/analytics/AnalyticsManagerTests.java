package com.tune.ma.analytics;

import android.support.test.runner.AndroidJUnit4;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.analytics.model.event.tracer.TuneTracerEvent;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.HashSet;
import java.util.Set;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

/**
 * Created by kristine on 2/10/16.
 */
@RunWith(AndroidJUnit4.class)
public class AnalyticsManagerTests extends TuneAnalyticsTest {

    @Test
    public void testSessionVariableToSetEventProfileSaveType() {
        assertEquals(0, analyticsManager.getSessionVariables().size());

        TuneEventBus.post(new TuneSessionVariableToSet("variableName", "variableValue", TuneSessionVariableToSet.SaveTo.PROFILE));

        assertEquals(0, analyticsManager.getSessionVariables().size());
    }

    @Test
    public void testSessionVariableToSetEventTagSaveType() {
        assertEquals(0, analyticsManager.getSessionVariables().size());

        TuneEventBus.post(new TuneSessionVariableToSet("variableName1", "variableValue1", TuneSessionVariableToSet.SaveTo.TAGS));
        TuneEventBus.post(new TuneSessionVariableToSet("variableName2", "variableValue2", TuneSessionVariableToSet.SaveTo.BOTH));
        Set<TuneAnalyticsVariable> sessionVariables = analyticsManager.getSessionVariables();

        assertEquals(2, sessionVariables.size());

        boolean hasVar1 = false;
        boolean hasVar2 = false;
        for (TuneAnalyticsVariable var: sessionVariables) {
            if ("variableName1".equals(var.getName()) && "variableValue1".equals(var.getValue())) {
                hasVar1 = true;
            }

            if ("variableName2".equals(var.getName()) && "variableValue2".equals(var.getValue())) {
                hasVar2 = true;
            }
        }
        assertTrue(hasVar1);
        assertTrue(hasVar2);
    }

    @Test
    public void testAddSessionVariablesToEvent() {
        Set<TuneAnalyticsVariable> tags = new HashSet<TuneAnalyticsVariable>();
        tags.add(new TuneAnalyticsVariable("tagName1", "tagValue1"));
        tags.add(new TuneAnalyticsVariable("tagName2", "tagValue2"));
        analyticsManager.registerSessionVariable("sessionVariableName1", "sessionVariableValue1");
        analyticsManager.registerSessionVariable("sessionVariableName2", "sessionVariableValue2");

        TuneAnalyticsEventBase event = new TuneTracerEvent();
        event.setTags(tags);
        analyticsManager.addSessionVariablesToEvent(event);
        assertEquals(4, event.getTags().size());

        Set<TuneAnalyticsVariable> resultSet = new HashSet<TuneAnalyticsVariable>();
        resultSet.addAll(tags);
        resultSet.addAll(analyticsManager.getSessionVariables());

        assertEquals(event.getTags(), resultSet);
        assertTrue(event.getTags().containsAll(resultSet));
    }
}
