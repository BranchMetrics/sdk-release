package com.tune;

import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.utils.TuneDebugLog;

import java.io.Serializable;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class TuneEvent implements Serializable {
    private static final long serialVersionUID = -7616393848331704848L;
    
    public static final String DEVICE_FORM_WEARABLE = "wearable";
    
    public static final String REGISTRATION = "registration";
    public static final String LOGIN = "login";
    public static final String ADD_TO_WISHLIST = "add_to_wishlist";
    public static final String ADD_TO_CART = "add_to_cart";
    public static final String ADDED_PAYMENT_INFO = "added_payment_info";
    public static final String RESERVATION = "reservation";
    public static final String CHECKOUT_INITIATED = "checkout_initiated";
    public static final String PURCHASE = "purchase";
    public static final String SEARCH = "search";
    public static final String CONTENT_VIEW = "content_view";
    public static final String TUTORIAL_COMPLETE = "tutorial_complete";
    public static final String LEVEL_ACHIEVED = "level_achieved";
    public static final String ACHIEVEMENT_UNLOCKED = "achievement_unlocked";
    public static final String SPENT_CREDITS = "spent_credits";
    public static final String INVITE = "invite";
    public static final String RATED = "rated";
    public static final String SHARE = "share";
    
    private String eventName;
    private int eventId;
    private double revenue;
    private String currencyCode;
    private String refId;
    private List<TuneEventItem> eventItems;
    private String receiptData;
    private String receiptSignature;
    
    private String contentType;
    private String contentId;
    private int level;
    private int quantity;
    private String searchString;
    private double rating;
    private Date date1;
    private Date date2;
    private String attribute1;
    private String attribute2;
    private String attribute3;
    private String attribute4;
    private String attribute5;
    
    private String deviceForm;

    private Set<TuneAnalyticsVariable> tags = new HashSet<TuneAnalyticsVariable>();
    private Set<String> addedTags = new HashSet<String>();

    private static final List<String> invalidTags = Arrays.asList(
            TuneUrlKeys.EVENT_ID,
            TuneUrlKeys.REVENUE,
            TuneUrlKeys.CURRENCY_CODE,
            TuneUrlKeys.REF_ID,
            TuneUrlKeys.EVENT_ITEMS,
            TuneUrlKeys.RECEIPT_DATA,
            TuneUrlKeys.RECEIPT_SIGNATURE,
            TuneUrlKeys.CONTENT_TYPE,
            TuneUrlKeys.CONTENT_ID,
            TuneUrlKeys.LEVEL,
            TuneUrlKeys.QUANTITY,
            TuneUrlKeys.SEARCH_STRING,
            TuneUrlKeys.RATING,
            TuneUrlKeys.DATE1,
            TuneUrlKeys.DATE2,
            TuneUrlKeys.ATTRIBUTE1,
            TuneUrlKeys.ATTRIBUTE2,
            TuneUrlKeys.ATTRIBUTE3,
            TuneUrlKeys.ATTRIBUTE4,
            TuneUrlKeys.ATTRIBUTE5
    );
    
    /**
     * Initialize TuneEvent with an event name
     * @param eventName Event name in TUNE system
     */
    public TuneEvent(String eventName) {
        this.eventName = eventName;
    }
    
    /**
     * Initialize TuneEvent with an event ID
     * @param eventId Event ID in TUNE system
     */
    public TuneEvent(int eventId) {
        this.eventId = eventId;
    }
    
    /**
     * Set a revenue amount to associate with event
     * @param revenue Revenue associated with the event
     * @return TuneEvent with updated revenue amount
     */
    public TuneEvent withRevenue(double revenue) {
        this.revenue = revenue;
        return this;
    }
    
    /**
     * Set a currency code to associate with event
     * @param currencyCode Currency code
     * @return TuneEvent with updated currency code
     */
    public TuneEvent withCurrencyCode(String currencyCode) {
        this.currencyCode = currencyCode;
        return this;
    }
    
    /**
     * Set an advertiser ref ID to associate with event
     * @param refId Advertiser ref ID
     * @return TuneEvent with updated ref ID
     */
    public TuneEvent withAdvertiserRefId(String refId) {
        this.refId = refId;
        return this;
    }
    
    /**
     * Set event items to associate with event
     * @param items List of event items
     * @return TuneEvent with updated event items
     */
    public TuneEvent withEventItems(List<TuneEventItem> items) {
        this.eventItems = items;
        return this;
    }
    
    /**
     * Set Google Play receipt to associate with event for purchase validation
     * @param receiptData Google Play receipt data
     * @param receiptSignature Google Play receipt signature
     * @return TuneEvent with updated receipt
     */
    public TuneEvent withReceipt(String receiptData, String receiptSignature) {
        this.receiptData = receiptData;
        this.receiptSignature = receiptSignature;
        return this;
    }
    
    /**
     * Set content type to associate with event
     * @param contentType Content type
     * @return TuneEvent with updated content type
     */
    public TuneEvent withContentType(String contentType) {
        this.contentType = contentType;
        return this;
    }
    
    /**
     * Set content id to associate with event
     * @param contentId Content id 
     * @return TuneEvent with updated content id
     */
    public TuneEvent withContentId(String contentId) {
        this.contentId = contentId;
        return this;
    }
    
    /**
     * Set level to associate with event
     * @param level Level (progress in game)
     * @return TuneEvent with updated level
     */
    public TuneEvent withLevel(int level) {
        this.level = level;
        return this;
    }
    
    /**
     * Set quantity to associate with event
     * @param quantity Quantity
     * @return TuneEvent with updated quantity
     */
    public TuneEvent withQuantity(int quantity) {
        this.quantity = quantity;
        return this;
    }
    
    /**
     * Set search string to associate with event
     * @param searchString Search string used
     * @return TuneEvent with updated search string
     */
    public TuneEvent withSearchString(String searchString) {
        this.searchString = searchString;
        return this;
    }
    
    /**
     * Set rating to associate with event
     * @param rating Rating given
     * @return TuneEvent with updated rating
     */
    public TuneEvent withRating(double rating) {
        this.rating = rating;
        return this;
    }
    
    /**
     * Set first date/start date to associate with event
     * @param date1 First date or start date
     * @return TuneEvent with updated date1
     */
    public TuneEvent withDate1(Date date1) {
        this.date1 = date1;
        return this;
    }
    
    /**
     * Set second date/end date to associate with event
     * @param date2 Second date or end date
     * @return TuneEvent with updated date2
     */
    public TuneEvent withDate2(Date date2) {
        this.date2 = date2;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute1 Custom attribute
     * @return TuneEvent with updated attribute1
     */
    public TuneEvent withAttribute1(String attribute1) {
        this.attribute1 = attribute1;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute2 Custom attribute
     * @return TuneEvent with updated attribute2
     */
    public TuneEvent withAttribute2(String attribute2) {
        this.attribute2 = attribute2;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute3 Custom attribute
     * @return TuneEvent with updated attribute3
     */
    public TuneEvent withAttribute3(String attribute3) {
        this.attribute3 = attribute3;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute4 Custom attribute
     * @return TuneEvent with updated attribute4
     */
    public TuneEvent withAttribute4(String attribute4) {
        this.attribute4 = attribute4;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute5 Custom attribute
     * @return TuneEvent with updated attribute5
     */
    public TuneEvent withAttribute5(String attribute5) {
        this.attribute5 = attribute5;
        return this;
    }
    
    /**
     * Set device form (phone/tablet/wearable)
     * @param deviceForm Type of device
     * @return TuneEvent with updated device form
     */
    public TuneEvent withDeviceForm(String deviceForm) {
        this.deviceForm = deviceForm;
        return this;
    }

    // Methods for tagging key-value pairs to events

    /**
     * Add a String tag
     * @param name Tag name
     * @param value Tag value
     * @return TuneEvent with updated String tag
     */
    public TuneEvent withTagAsString(String name, String value) {
        if (TuneManager.getProfileForUser("withTagAsString") == null) {
            return this;
        }
        return addTag(new TuneAnalyticsVariable(name, value));
    }

    /**
     * Add an int tag
     * @param name Tag name
     * @param value Tag value
     * @return TuneEvent with updated int tag
     */
    public TuneEvent withTagAsNumber(String name, int value) {
        if (TuneManager.getProfileForUser("withTagAsNumber") == null) {
            return this;
        }
        return addTag(new TuneAnalyticsVariable(name, value));
    }

    /**
     * Add a double tag
     * @param name Tag name
     * @param value Tag value
     * @return TuneEvent with updated double tag
     */
    public TuneEvent withTagAsNumber(String name, double value) {
        if (TuneManager.getProfileForUser("withTagAsNumber") == null) {
            return this;
        }
        return addTag(new TuneAnalyticsVariable(name, value));
    }

    /**
     * Add a float tag
     * @param name Tag name
     * @param value Tag value
     * @return TuneEvent with updated float tag
     */
    public TuneEvent withTagAsNumber(String name, float value) {
        if (TuneManager.getProfileForUser("withTagAsNumber") == null) {
            return this;
        }
        return addTag(new TuneAnalyticsVariable(name, value));
    }

    /**
     * Add a date tag
     * @param name Tag name
     * @param value Tag value
     * @return TuneEvent with updated Date tag
     */
    public TuneEvent withTagAsDate(String name, Date value) {
        if (TuneManager.getProfileForUser("withTagAsDate") == null) {
            return this;
        }
        return addTag(new TuneAnalyticsVariable(name, value));
    }

    /**
     * Add a location tag
     * @param name Tag name
     * @param value Tag value
     * @return TuneEvent with updated location tag
     */
    public TuneEvent withTagAsGeolocation(String name, TuneLocation value) {
        if (TuneManager.getProfileForUser("withTagAsGeolocation") == null) {
            return this;
        }
        return addTag(new TuneAnalyticsVariable(name, value));
    }

    private TuneEvent addTag(TuneAnalyticsVariable tag) {
        // Do validation on tag name
        if (TuneAnalyticsVariable.validateName(tag.getName())) {
            String prettyName = TuneAnalyticsVariable.cleanVariableName(tag.getName());
            // Don't allow tags that would duplicate event data keys
            if (invalidTags.contains(prettyName)) {
                TuneDebugLog.IAMConfigError(prettyName + " is a property, please use the appropriate setter instead.");
                return this;
            }

            if (prettyName.startsWith("TUNE_")) {
                TuneDebugLog.IAMConfigError("Tags starting with 'TUNE_' are reserved, not registering " + prettyName);
                return this;
            }

            if (addedTags.contains(prettyName)) {
                TuneDebugLog.IAMConfigError("The tag " + prettyName + " has already been added to this event, not adding duplicate tag");
                return this;
            }

            // Add tag
            this.addedTags.add(prettyName);
            this.tags.add(tag);
        }
        return this;
    }
    
    public String getEventName() {
        return eventName;
    }

    public int getEventId() {
        return eventId;
    }

    public double getRevenue() {
        return revenue;
    }

    public String getCurrencyCode() {
        return currencyCode;
    }

    public String getRefId() {
        return refId;
    }

    public List<TuneEventItem> getEventItems() {
        return eventItems;
    }

    public String getReceiptData() {
        return receiptData;
    }

    public String getReceiptSignature() {
        return receiptSignature;
    }

    public String getContentType() {
        return contentType;
    }

    public String getContentId() {
        return contentId;
    }

    public int getLevel() {
        return level;
    }

    public int getQuantity() {
        return quantity;
    }

    public String getSearchString() {
        return searchString;
    }

    public double getRating() {
        return rating;
    }

    public Date getDate1() {
        return date1;
    }

    public Date getDate2() {
        return date2;
    }

    public String getAttribute1() {
        return attribute1;
    }

    public String getAttribute2() {
        return attribute2;
    }

    public String getAttribute3() {
        return attribute3;
    }

    public String getAttribute4() {
        return attribute4;
    }

    public String getAttribute5() {
        return attribute5;
    }
    
    public String getDeviceForm() {
        return deviceForm;
    }

    public Set<TuneAnalyticsVariable> getTags() {
        return tags;
    }
}
