package com.tune.ma.inapp;

import android.app.Activity;

import com.tune.ma.campaign.model.TuneCampaign;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.inapp.model.TuneTriggerEvent;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;

import static com.tune.ma.inapp.TuneInAppMessageConstants.LIFETIME_MAXIMUM_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.LIMIT_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.SCOPE_VALUE_INSTALL;

/**
 * Created by johng on 4/26/17.
 */

public class TestInAppMessage extends TuneInAppMessage {
    private CountDownLatch displayLatch;
    private AtomicInteger displayCount;

    public TestInAppMessage(JSONObject messageJson) {
        super(messageJson);
    }

    public TestInAppMessage(List<TuneTriggerEvent> triggerEvents) {
        this.setCampaign(new TuneCampaign("123", "abc", 604800));
        this.setTriggerEvents(triggerEvents);
    }

    public TestInAppMessage(List<TuneTriggerEvent> triggerEvents, CountDownLatch displayLatch) {
        this(triggerEvents);
        this.displayCount = new AtomicInteger(0);
        this.displayLatch = displayLatch;
    }

    public TestInAppMessage(String campaignId, String campaignStepId, TuneTriggerEvent triggerEvent) {
        this(campaignId, campaignStepId, "", triggerEvent);
    }

    public TestInAppMessage(String campaignId, String campaignStepId, String id, TuneTriggerEvent triggerEvent) {
        this.setCampaign(new TuneCampaign(campaignId, "abc", 604800));
        this.setCampaignStepId(campaignStepId);
        this.setId(id);
        List<TuneTriggerEvent> triggerEvents = new ArrayList<>();
        triggerEvents.add(triggerEvent);
        this.setTriggerEvents(triggerEvents);
    }

    public TestInAppMessage(TuneTriggerEvent triggerEvent, CountDownLatch displayLatch) {
        this(triggerEvent, "123", displayLatch);
    }

    public TestInAppMessage(TuneTriggerEvent triggerEvent, String campaignId, CountDownLatch displayLatch) {
        this.displayCount = new AtomicInteger(0);
        this.setCampaign(new TuneCampaign(campaignId, "abc", 604800));
        List<TuneTriggerEvent> triggerEvents = new ArrayList<>();
        triggerEvents.add(triggerEvent);
        this.setTriggerEvents(triggerEvents);
        this.displayLatch = displayLatch;
    }

    public TestInAppMessage(String triggerEvent, CountDownLatch displayLatch) {
        this(triggerEvent, "123", displayLatch);
    }

    public TestInAppMessage(String triggerEvent, String campaignId, CountDownLatch displayLatch) {
        this.displayCount = new AtomicInteger(0);
        this.setCampaign(new TuneCampaign(campaignId, "abc", 604800));

        List<TuneTriggerEvent> triggerEvents = new ArrayList<>();
        JSONObject frequencyJson = new JSONObject();
        try {
            frequencyJson.put(LIFETIME_MAXIMUM_KEY, 0);
            frequencyJson.put(LIMIT_KEY, 0);
            frequencyJson.put(SCOPE_KEY, SCOPE_VALUE_INSTALL);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        triggerEvents.add(new TuneTriggerEvent(triggerEvent, frequencyJson));

        this.setTriggerEvents(triggerEvents);
        this.displayLatch = displayLatch;
    }

    @Override
    public synchronized void display() {
        if (this.displayCount != null) {
            this.displayCount.incrementAndGet();
        }
        this.displayLatch.countDown();
        this.setVisible(true);
    }

    @Override
    public synchronized void dismiss() {
        this.setVisible(false);
    }

    @Override
    public void load(Activity activity) {
    }

    public synchronized int getDisplayCount() {
        return this.displayCount.get();
    }

    public synchronized void setDisplayLatch(CountDownLatch latch) {
        this.displayLatch = latch;
    }
}
