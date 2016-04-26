package com.tune.ma.analytics.model.event;

import com.tune.TuneEvent;
import com.tune.TuneEventItem;
import com.tune.TuneUrlKeys;
import com.tune.ma.analytics.model.TuneAnalyticsEventItem;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.TuneEventType;

/**
 * Created by johng on 1/26/16.
 * Base class for all custom analytics events.
 */
public class TuneCustomEvent extends TuneAnalyticsEventBase {
    public TuneCustomEvent(TuneEvent event) {
        super();

        category = CUSTOM_CATEGORY;
        eventType = TuneEventType.EVENT;

        if (event.getEventId() != 0) {
            action = Integer.toString(event.getEventId());
        } else {
            action = event.getEventName();
        }

        // Convert TuneEventItems to TuneAnalyticsEventItems
        if (event.getEventItems() != null) {
            for (TuneEventItem item : event.getEventItems()) {
                items.add(new TuneAnalyticsEventItem(item));
            }
        }

        // Populate tags from TuneEvent values
        if (!event.getTags().isEmpty()) {
            tags.addAll(event.getTags());
        }
        if (event.getEventId() != 0) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.EVENT_ID, event.getEventId()));
        }
        if (event.getRevenue() != 0) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.REVENUE, event.getRevenue()));
        }
        if (event.getCurrencyCode() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.CURRENCY_CODE, event.getCurrencyCode()));
        }
        if (event.getRefId() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.REF_ID, event.getRefId()));
        }
        if (event.getReceiptData() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.RECEIPT_DATA, event.getReceiptData()));
        }
        if (event.getReceiptSignature() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.RECEIPT_SIGNATURE, event.getReceiptSignature()));
        }
        if (event.getContentType() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.CONTENT_TYPE, event.getContentType()));
        }
        if (event.getContentId() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.CONTENT_ID, event.getContentId()));
        }
        if (event.getDate1() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.DATE1, event.getDate1()));
        }
        if (event.getDate2() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.DATE2, event.getDate2()));
        }
        if (event.getLevel() != 0) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.LEVEL, event.getLevel()));
        }
        if (event.getQuantity() != 0) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.QUANTITY, event.getQuantity()));
        }
        if (event.getRating() != 0) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.RATING, event.getRating()));
        }
        if (event.getSearchString() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.SEARCH_STRING, event.getSearchString()));
        }
        if (event.getAttribute1() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.ATTRIBUTE1, event.getAttribute1()));
        }
        if (event.getAttribute2() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.ATTRIBUTE2, event.getAttribute1()));
        }
        if (event.getAttribute3() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.ATTRIBUTE3, event.getAttribute1()));
        }
        if (event.getAttribute4() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.ATTRIBUTE4, event.getAttribute1()));
        }
        if (event.getAttribute5() != null) {
            tags.add(new TuneAnalyticsVariable(TuneUrlKeys.ATTRIBUTE5, event.getAttribute1()));
        }
    }
}
