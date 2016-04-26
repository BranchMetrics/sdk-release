package com.tune;

import java.util.ArrayList;

public class EndpointTests extends TuneUnitTest {

    public void testSession() {
        tune.measureSession();
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
    }

    public void testUpdate() {
        tune.setExistingUser( true );
        tune.measureSession();
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "existing_user", "1" );
    }

    public void testEventName() {
        final String eventName = "testEvent";

        tune.measureEvent( eventName );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertKeyValue( "site_event_name", eventName );
        assertNoValueForKey( "site_event_id" );
    }

    public void testEventId() {
        final int eventId = 130;

        tune.measureEvent( eventId );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );

        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertNoValueForKey( "site_event_name" );
        assertKeyValue( "site_event_id", Integer.toString(eventId) );
    }

    public void testEventListPurchaseName() {
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
        final String iapData = "purchaseData";
        final String iapSignature = "purchaseSignature";
        
        TuneEvent eventData = new TuneEvent(eventName)
            .withEventItems(testItems)
            .withReceipt(iapData, iapSignature);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertNoValueForKey( "site_event_id" );
        assertKeyValue( "site_event_name", eventName );
        assertTrue( "data items must match", params.checkDataItems( testItems ) );
        assertKeyValue( "store_iap_data", iapData );
        assertKeyValue( "store_iap_signature", iapSignature );
    }

    public void testEventListPurchaseId() {
        final int eventId = 130;

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
        final String iapData = "purchaseData";
        final String iapSignature = "purchaseSignature";
        
        TuneEvent eventData = new TuneEvent(eventId)
            .withEventItems(testItems)
            .withReceipt(iapData, iapSignature);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertNoValueForKey( "site_event_name" );
        assertKeyValue( "site_event_id", Integer.toString(eventId) );
        assertTrue( "data items must match", params.checkDataItems( testItems ) );
        assertKeyValue( "store_iap_data", iapData );
        assertKeyValue( "store_iap_signature", iapSignature );
    }

    public void testEventRevenueCurrencyName() {
        final String eventName = "testEvent";
        final double revenue = 2.18;
        final String currencyCode = "CAD";
        
        TuneEvent eventData = new TuneEvent(eventName)
            .withRevenue(revenue)
            .withCurrencyCode(currencyCode);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertKeyValue( "site_event_name", eventName );
        assertNoValueForKey( "site_event_id" );
        assertKeyValue( "revenue", Double.toString( revenue ) );
        assertKeyValue( "currency_code", currencyCode );
    }

    public void testEventRevenueCurrencyId() {
        final int eventId = 130;
        final double revenue = 2.18;
        final String currencyCode = "CAD";
        
        TuneEvent eventData = new TuneEvent(eventId)
            .withRevenue(revenue)
            .withCurrencyCode(currencyCode);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertNoValueForKey( "site_event_name" );
        assertKeyValue( "site_event_id", Integer.toString(eventId) );
        assertKeyValue( "revenue", Double.toString( revenue ) );
        assertKeyValue( "currency_code", currencyCode );
    }

    public void testEventRevenueCurrencyReferenceName() {
        final String eventName = "testEvent";
        final double revenue = 2.18;
        final String currencyCode = "CAD";
        final String referenceId = "testReferenceId";
        
        TuneEvent eventData = new TuneEvent(eventName)
            .withRevenue(revenue)
            .withCurrencyCode(currencyCode)
            .withAdvertiserRefId(referenceId);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertKeyValue( "site_event_name", eventName );
        assertNoValueForKey( "site_event_id" );
        assertKeyValue( "revenue", Double.toString( revenue ) );
        assertKeyValue( "currency_code", currencyCode );
        assertKeyValue( "advertiser_ref_id", referenceId );
    }

    public void testEventRevenueCurrencyReferenceId() {
        final int eventId = 130;
        final double revenue = 2.18;
        final String currencyCode = "CAD";
        final String referenceId = "testReferenceId";
        
        TuneEvent eventData = new TuneEvent(eventId)
            .withRevenue(revenue)
            .withCurrencyCode(currencyCode)
            .withAdvertiserRefId(referenceId);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertNoValueForKey( "site_event_name" );
        assertKeyValue( "site_event_id", Integer.toString(eventId) );
        assertKeyValue( "revenue", Double.toString( revenue ) );
        assertKeyValue( "currency_code", currencyCode );
        assertKeyValue( "advertiser_ref_id", referenceId );
    }

    public void testEventRevenueCurrencyPurchaseName() {
        final String eventName = "testEvent";
        final double revenue = 2.18;
        final String currencyCode = "CAD";
        final String referenceId = "testReferenceId";
        final String iapData = "purchaseData";
        final String iapSignature = "purchaseSignature";
        
        TuneEvent eventData = new TuneEvent(eventName)
            .withRevenue(revenue)
            .withCurrencyCode(currencyCode)
            .withAdvertiserRefId(referenceId)
            .withReceipt(iapData, iapSignature);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertKeyValue( "site_event_name", eventName );
        assertNoValueForKey( "site_event_id" );
        assertKeyValue( "revenue", Double.toString( revenue ) );
        assertKeyValue( "currency_code", currencyCode );
        assertKeyValue( "advertiser_ref_id", referenceId );
        assertKeyValue( "store_iap_data", iapData );
        assertKeyValue( "store_iap_signature", iapSignature );
    }

    public void testEventRevenueCurrencyPurchaseId() {
        final int eventId = 130;
        final double revenue = 2.18;
        final String currencyCode = "CAD";
        final String referenceId = "testReferenceId";
        final String iapData = "purchaseData";
        final String iapSignature = "purchaseSignature";
        
        TuneEvent eventData = new TuneEvent(eventId)
            .withRevenue(revenue)
            .withCurrencyCode(currencyCode)
            .withAdvertiserRefId(referenceId)
            .withReceipt(iapData, iapSignature);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "conversion" );
        assertNoValueForKey( "site_event_name" );
        assertKeyValue( "site_event_id", Integer.toString(eventId) );
        assertKeyValue( "revenue", Double.toString( revenue ) );
        assertKeyValue( "currency_code", currencyCode );
        assertKeyValue( "advertiser_ref_id", referenceId );
        assertKeyValue( "store_iap_data", iapData );
        assertKeyValue( "store_iap_signature", iapSignature );
    }

    public void testEventInstall() {
        final String actionName = "install";
        
        tune.measureEvent( actionName );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "session" );
        assertNoValueForKey( "site_event_name" );
        assertNoValueForKey( "site_event_id" );
    }

    public void testEventUpdate() {
        final String actionName = "update";
        
        tune.measureEvent( actionName );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "session" );
        assertNoValueForKey( "site_event_name" );
        assertNoValueForKey( "site_event_id" );
    }

    public void testEventOpen() {
        final String actionName = "open";
        
        tune.measureEvent( actionName );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "session" );
        assertNoValueForKey( "site_event_name" );
        assertNoValueForKey( "site_event_id" );
    }

    public void testEventSession() {
        final String actionName = "session";
        
        tune.measureEvent( actionName );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "action", "session" );
        assertNoValueForKey( "site_event_name" );
        assertNoValueForKey( "site_event_id" );
    }

    public void testEventClose() {
        final String actionName = "close";
        
        tune.measureEvent( actionName );
        sleep( TuneTestConstants.ENDPOINTTEST_SLEEP );
        
        assertTrue( "params should be empty " + params, params.checkIsEmpty() );
    }
}
