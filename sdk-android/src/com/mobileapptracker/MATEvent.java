package com.mobileapptracker;

import java.io.Serializable;
import java.util.Date;
import java.util.List;

public class MATEvent implements Serializable {
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
    private List<MATEventItem> eventItems;
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
    
    /**
     * Initialize MATEvent with an event name
     * @param eventName Event name in TUNE system
     */
    public MATEvent(String eventName) {
        this.eventName = eventName;
    }
    
    /**
     * Initialize MATEvent with an event ID
     * @param eventId Event ID in TUNE system
     */
    public MATEvent(int eventId) {
        this.eventId = eventId;
    }
    
    /**
     * Set a revenue amount to associate with event
     * @param revenue Revenue associated with the event
     * @return MATEvent with updated revenue amount
     */
    public MATEvent withRevenue(double revenue) {
        this.revenue = revenue;
        return this;
    }
    
    /**
     * Set a currency code to associate with event
     * @param currencyCode Currency code
     * @return MATEvent with updated currency code
     */
    public MATEvent withCurrencyCode(String currencyCode) {
        this.currencyCode = currencyCode;
        return this;
    }
    
    /**
     * Set an advertiser ref ID to associate with event
     * @param refId Advertiser ref ID
     * @return MATEvent with updated ref ID
     */
    public MATEvent withAdvertiserRefId(String refId) {
        this.refId = refId;
        return this;
    }
    
    /**
     * Set event items to associate with event
     * @param items List of event items
     * @return MATEvent with updated event items
     */
    public MATEvent withEventItems(List<MATEventItem> items) {
        this.eventItems = items;
        return this;
    }
    
    /**
     * Set Google Play receipt to associate with event for purchase validation
     * @param receiptData Google Play receipt data
     * @param receiptSignature Google Play receipt signature
     * @return MATEvent with updated receipt
     */
    public MATEvent withReceipt(String receiptData, String receiptSignature) {
        this.receiptData = receiptData;
        this.receiptSignature = receiptSignature;
        return this;
    }
    
    /**
     * Set content type to associate with event
     * @param contentType Content type
     * @return MATEvent with updated content type
     */
    public MATEvent withContentType(String contentType) {
        this.contentType = contentType;
        return this;
    }
    
    /**
     * Set content id to associate with event
     * @param contentId Content id 
     * @return MATEvent with updated content id
     */
    public MATEvent withContentId(String contentId) {
        this.contentId = contentId;
        return this;
    }
    
    /**
     * Set level to associate with event
     * @param level Level (progress in game)
     * @return MATEvent with updated level 
     */
    public MATEvent withLevel(int level) {
        this.level = level;
        return this;
    }
    
    /**
     * Set quantity to associate with event
     * @param quantity Quantity
     * @return MATEvent with updated quantity
     */
    public MATEvent withQuantity(int quantity) {
        this.quantity = quantity;
        return this;
    }
    
    /**
     * Set search string to associate with event
     * @param searchString Search string used
     * @return MATEvent with updated search string
     */
    public MATEvent withSearchString(String searchString) {
        this.searchString = searchString;
        return this;
    }
    
    /**
     * Set rating to associate with event
     * @param rating Rating given
     * @return MATEvent with updated rating
     */
    public MATEvent withRating(double rating) {
        this.rating = rating;
        return this;
    }
    
    /**
     * Set first date/start date to associate with event
     * @param date1 First date or start date
     * @return MATEvent with updated date1
     */
    public MATEvent withDate1(Date date1) {
        this.date1 = date1;
        return this;
    }
    
    /**
     * Set second date/end date to associate with event
     * @param date2 Second date or end date
     * @return MATEvent with updated date2
     */
    public MATEvent withDate2(Date date2) {
        this.date2 = date2;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute1 Custom attribute
     * @return MATEvent with updated attribute1
     */
    public MATEvent withAttribute1(String attribute1) {
        this.attribute1 = attribute1;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute2 Custom attribute
     * @return MATEvent with updated attribute2
     */
    public MATEvent withAttribute2(String attribute2) {
        this.attribute2 = attribute2;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute3 Custom attribute
     * @return MATEvent with updated attribute3
     */
    public MATEvent withAttribute3(String attribute3) {
        this.attribute3 = attribute3;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute4 Custom attribute
     * @return MATEvent with updated attribute4
     */
    public MATEvent withAttribute4(String attribute4) {
        this.attribute4 = attribute4;
        return this;
    }
    
    /**
     * Set custom attribute to associate with event
     * @param attribute5 Custom attribute
     * @return MATEvent with updated attribute5
     */
    public MATEvent withAttribute5(String attribute5) {
        this.attribute5 = attribute5;
        return this;
    }
    
    /**
     * Set device form (phone/tablet/wearable)
     * @param deviceForm Type of device
     * @return MATEvent with updated device form
     */
    public MATEvent withDeviceForm(String deviceForm) {
        this.deviceForm = deviceForm;
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

    public List<MATEventItem> getEventItems() {
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
}
