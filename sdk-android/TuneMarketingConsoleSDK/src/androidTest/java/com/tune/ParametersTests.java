package com.tune;

import android.content.Context;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Date;

public class ParametersTests extends TuneUnitTest {
    @Override
    protected void setUp() throws Exception {
        super.setUp();

        tune.setOnline(false);
    }

    @Override
    protected void tearDown() throws Exception {
        tune.setOnline(true);

        super.tearDown();
    }

    public void testAgeValid() {
        final int age = 35;
        String expectedAge = Integer.toString( age );
        
        tune.setAge( age );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue("age", expectedAge);
    }

    public void testAgeYoung() {
        final int age = 6;
        String expectedAge = Integer.toString( age );
        
        tune.setAge( age );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "age", expectedAge );
    }

    public void testAgeOld() {
        final int age = 65536;
        String expectedAge = Integer.toString( age );
        
        tune.setAge( age );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "age", expectedAge );
    }

    public void testAgeZero() {
        final int age = 0;
        String expectedAge = Integer.toString( age );
        
        tune.setAge( age );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "age", expectedAge );
    }

    public void testAgeNegative() {
        final int age = -304;
        String expectedAge = Integer.toString( age );
        
        tune.setAge( age );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "age", expectedAge );
    }

    public void testAltitudeValid() {
        final double altitude = 43;
        String expectedAltitude = Double.toString( altitude );
        
        tune.setAltitude(altitude);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "altitude", expectedAltitude );
    }

    public void testAltitudeZero() {
        final double altitude = 0;
        String expectedAltitude = Double.toString( altitude );
        
        tune.setAltitude( altitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "altitude", expectedAltitude );
    }

    public void testAltitudeVeryLarge() {
        final double altitude = 65536;
        String expectedAltitude = Double.toString( altitude );
        
        tune.setAltitude( altitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "altitude", expectedAltitude );
    }

    public void testAltitudeVerySmall() {
        final double altitude = -6701;
        String expectedAltitude = Double.toString( altitude );
        
        tune.setAltitude( altitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "altitude", expectedAltitude );
    }
    
    public void testAndroidId() {
        final String androidId = "59a3747895bdb03d";

        sleep( 1000 );
        tune.setAndroidId(androidId);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "android_id", androidId );
    }
    
    public void testAndroidIdMd5() {
        final String androidIdMd5 = TuneUtils.md5("59a3747895bdb03d");
        
        tune.setAndroidIdMd5(androidIdMd5);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "android_id_md5", androidIdMd5 );
    }
    
    public void testAndroidIdSha1() {
        final String androidIdSha1 = TuneUtils.sha1("59a3747895bdb03d");
        
        tune.setAndroidIdSha1(androidIdSha1);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "android_id_sha1", androidIdSha1 );
    }
    
    public void testAndroidIdSha256() {
        final String androidIdSha256 = TuneUtils.sha256("59a3747895bdb03d");
        
        tune.setAndroidIdSha256(androidIdSha256);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "android_id_sha256", androidIdSha256 );
    }

    public void testCurrencyCodeValid() {
        final String currencyCode = "CAD";
        
        tune.setCurrencyCode(currencyCode);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "currency_code", currencyCode );
    }

    public void testCurrencyCodeVeryLong() {
        final String currencyCode = "supercalifragilisticexpialidocious";
        
        tune.setCurrencyCode( currencyCode );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "currency_code", currencyCode );
    }

    public void testCurrencyCodeEmpty() {
        final String currencyCode = "";
        final String expectedCurrencyCode = "USD";
        
        tune.setCurrencyCode( currencyCode );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "currency_code", expectedCurrencyCode );
    }

    public void testCurrencyCodeNull() {
        final String currencyCode = null;
        final String expectedCurrencyCode = "USD";
        
        tune.setCurrencyCode( currencyCode );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "currency_code", expectedCurrencyCode );
    }

    public void testEventParameters() {
        final double revenue = 4.99;
        final String currency = "CAD";
        final String refId = "12345";
        final String contentType = "content type";
        final String contentId = "content ID";
        final int level = 14;
        final int quantity = 63;
        final String searchString = "search string";
        final double rating = 3.14;
        final Date date1 = new Date();
        final Date date2 = new Date();
        final String attr1 = "attribute1";
        final String attr2 = "attribute2";
        final String attr3 = "attribute3";
        final String attr4 = "attribute4";
        final String attr5 = "attribute5";

        String expectedCurrency = null, 
               expectedRefId = null,
               expectedContentType = null,
               expectedContentId = null,
               expectedSearchString = null,
               expectedAttribute1 = null,
               expectedAttribute2 = null,
               expectedAttribute3 = null,
               expectedAttribute4 = null,
               expectedAttribute5 = null;
        try {
            expectedCurrency = URLEncoder.encode(currency, "UTF-8");
            expectedRefId = URLEncoder.encode(refId, "UTF-8");
            expectedContentType = URLEncoder.encode(contentType, "UTF-8");
            expectedContentId = URLEncoder.encode(contentId, "UTF-8");
            expectedSearchString = URLEncoder.encode(searchString, "UTF-8");
            expectedAttribute1 = URLEncoder.encode(attr1, "UTF-8");
            expectedAttribute2 = URLEncoder.encode(attr2, "UTF-8");
            expectedAttribute3 = URLEncoder.encode(attr3, "UTF-8");
            expectedAttribute4 = URLEncoder.encode(attr4, "UTF-8");
            expectedAttribute5 = URLEncoder.encode(attr5, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }

        TuneEvent eventData = new TuneEvent("registration")
            .withRevenue(revenue)
            .withCurrencyCode(currency)
            .withAdvertiserRefId(refId)
            .withContentType(contentType)
            .withContentId(contentId)
            .withLevel(level)
            .withQuantity(quantity)
            .withSearchString(searchString)
            .withRating(rating)
            .withDate1(date1)
            .withDate2(date2)
            .withAttribute1(attr1)
            .withAttribute2(attr2)
            .withAttribute3(attr3)
            .withAttribute4(attr4)
            .withAttribute5(attr5);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "revenue", Double.toString( revenue ));
        assertKeyValue( "currency_code", expectedCurrency );
        assertKeyValue( "advertiser_ref_id", expectedRefId );
        assertKeyValue( "content_type", expectedContentType );
        assertKeyValue( "content_id", expectedContentId );
        assertKeyValue( "level", Integer.toString( level ) );
        assertKeyValue( "quantity", Integer.toString( quantity ) );
        assertKeyValue( "search_string", expectedSearchString );
        assertKeyValue( "rating", Double.toString( rating ) );
        assertKeyValue( "date1", Long.toString( date1.getTime()/1000 ) );
        assertKeyValue( "date2", Long.toString( date2.getTime()/1000 ) );
        assertKeyValue( "attribute_sub1", expectedAttribute1 );
        assertKeyValue( "attribute_sub2", expectedAttribute2 );
        assertKeyValue( "attribute_sub3", expectedAttribute3 );
        assertKeyValue( "attribute_sub4", expectedAttribute4 );
        assertKeyValue( "attribute_sub5", expectedAttribute5 );
    }

    public void testEventParametersCleared() {
        final double revenue = 4.99;
        final String currency = "CAD";
        final String refId = "12345";
        final String contentType = "content type";
        final String contentId = "content ID";
        final int level = 14;
        final int quantity = 63;
        final String searchString = "search string";
        final double rating = 3.14;
        final Date date1 = new Date();
        final Date date2 = new Date();
        final String attr1 = "attribute1";
        final String attr2 = "attribute2";
        final String attr3 = "attribute3";
        final String attr4 = "attribute4";
        final String attr5 = "attribute5";
        
        TuneEvent eventData = new TuneEvent("purchase")
                                 .withRevenue(revenue)
                                 .withCurrencyCode(currency)
                                 .withAdvertiserRefId(refId)
                                 .withContentType(contentType)
                                 .withContentId(contentId)
                                 .withLevel(level)
                                 .withQuantity(quantity)
                                 .withSearchString(searchString)
                                 .withRating(rating)
                                 .withDate1(date1)
                                 .withDate2(date2)
                                 .withAttribute1(attr1)
                                 .withAttribute2(attr2)
                                 .withAttribute3(attr3)
                                 .withAttribute4(attr4)
                                 .withAttribute5(attr5);
        tune.measureEvent(eventData);
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        
        params = new TuneTestParams();
        tune.measureEvent("purchase");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "revenue", "0.0");
        assertKeyValue( "currency_code", "USD" );
        assertNoValueForKey("advertiser_ref_id");
        assertNoValueForKey("content_type");
        assertNoValueForKey("content_id");
        assertNoValueForKey("level");
        assertNoValueForKey("quantity");
        assertNoValueForKey("search_string");
        assertNoValueForKey("rating");
        assertNoValueForKey("date1");
        assertNoValueForKey("date2");
        assertNoValueForKey("attribute_sub1");
        assertNoValueForKey("attribute_sub2");
        assertNoValueForKey("attribute_sub3");
        assertNoValueForKey("attribute_sub4");
        assertNoValueForKey("attribute_sub5");
    }

    public void testExistingUser() {
        tune.setExistingUser( true );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "existing_user", "1" );
    }

    public void testFacebookUserId() {
        final String userId = "fakeUserId";
        
        tune.setFacebookUserId(userId);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "facebook_user_id", userId );
    }

    public void testGenderMale() {
        final TuneGender gender = TuneGender.MALE;
        final String expectedGender = "0";
        
        tune.setGender(gender);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "gender", expectedGender );
    }

    public void testGenderFemale() {
        final TuneGender gender = TuneGender.FEMALE;
        final String expectedGender = "1";
        
        tune.setGender( gender );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "gender", expectedGender );
    }

    public void testGenderUnknown() {
        final TuneGender gender = TuneGender.UNKNOWN;
        
        tune.setGender( gender );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey("gender");
    }

    public void testGoogleUserId() {
        final String userId = "fakeUserId";
        
        tune.setGoogleUserId(userId);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue("google_user_id", userId);
    }

    public void testIsPayingUser() {
        tune.setIsPayingUser(true);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "is_paying_user", "1" );
    }

    public void testIsPayingUserAutoCollect() {
        tune.setIsPayingUser( false );
        tune.measureEvent(new TuneEvent("registration").withRevenue(1.0).withCurrencyCode("USD"));
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "is_paying_user", "1" );
    }

    public void testIsPayingUserFalse() {
        tune.setIsPayingUser( false );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "is_paying_user", "0" );
    }

    public void testLatitudeValidGtZero() {
        final double latitude = 43;
        String expectedLatitude = Double.toString( latitude );
        
        tune.setLatitude(latitude);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "latitude", expectedLatitude );
    }

    public void testLatitudeValidLtZero() {
        final double latitude = -122;
        String expectedLatitude = Double.toString( latitude );
        
        tune.setLatitude( latitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "latitude", expectedLatitude );
    }

    public void testLatitudeZero() {
        final double latitude = 0;
        String expectedLatitude = Double.toString( latitude );
        
        tune.setLatitude( latitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "latitude", expectedLatitude );
    }

    public void testLatitudeVeryLarge() {
        final double latitude = 43654;
        String expectedLatitude = Double.toString( latitude );
        
        tune.setLatitude( latitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "latitude", expectedLatitude );
    }

    public void testLatitudeVerySmall() {
        final double latitude = -64645;
        String expectedLatitude = Double.toString( latitude );
        
        tune.setLatitude( latitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "latitude", expectedLatitude );
    }

    public void testAppAdTrackingTrue() {
        boolean appAdTracking = true;
        final String expectedAppAdTracking = Integer.toString( 1 );
        
        tune.setAppAdTrackingEnabled(appAdTracking);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "app_ad_tracking", expectedAppAdTracking );
    }

    public void testAppAppAdTrackingFalse() {
        boolean appAdTracking = false;
        final String expectedAppAdTracking = Integer.toString( 0 );
        
        tune.setAppAdTrackingEnabled( appAdTracking );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "app_ad_tracking", expectedAppAdTracking );
    }

    public void testTuneLocation() {
        final double latitude = 87;
        final double longitude = -122;
        String expectedLatitude = Double.toString(latitude);
        String expectedLongitude = Double.toString(longitude);

        tune.setLocation(new TuneLocation(longitude, latitude));
        tune.measureEvent("registration");
        sleep(TuneTestConstants.PARAMTEST_SLEEP );

        assertTrue("params default values failed " + params, params.checkDefaultValues());
        assertKeyValue("latitude", expectedLatitude );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testLongitudeValidGtZero() {
        final double longitude = 43;
        String expectedLongitude = Double.toString( longitude );
        
        tune.setLongitude( longitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testLongitudeValidLtZero() {
        final double longitude = -122;
        String expectedLongitude = Double.toString( longitude );
        
        tune.setLongitude( longitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testLongitudeValidLarge() {
        final double longitude = 304;
        String expectedLongitude = Double.toString( longitude );
        
        tune.setLongitude( longitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testLongitudeZero() {
        final double longitude = 0;
        String expectedLongitude = Double.toString( longitude );
        
        tune.setLongitude( longitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testLongitudeVeryLarge() {
        final double longitude = 43654;
        String expectedLongitude = Double.toString( longitude );
        
        tune.setLongitude( longitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testLongitudeVerySmall() {
        final double longitude = -64645;
        String expectedLongitude = Double.toString( longitude );
        
        tune.setLongitude( longitude );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "longitude", expectedLongitude );
    }

    public void testPackageNameDefault() {
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
    }

    public void testPackageNameAlternate() {
        final String packageName = "some.fake.package.name";
        
        tune.setPackageName( packageName );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertFalse( "params default values should have failed " + params, params.checkDefaultValues() );
        assertKeyValue( "package_name", packageName );
    }
    
    public void testPhoneNumber() {
        final String phoneNumber = "(123) 456-7890";
        // Hash will correspond to digits of number
        String phoneNumberDigits = "1234567890";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_phone" );
        assertKeyValue( "user_phone_md5", TuneUtils.md5(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha1", TuneUtils.sha1(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha256", TuneUtils.sha256(phoneNumberDigits) );
    }
    
    public void testPhoneNumberForeign() {
        String phoneNumber = "+१२३.४५६.७८९०";
        String phoneNumberDigits = "1234567890";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_phone" );
        assertKeyValue( "user_phone_md5", TuneUtils.md5(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha1", TuneUtils.sha1(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha256", TuneUtils.sha256(phoneNumberDigits) );
        
        phoneNumber = "(١٢٣)٤٥٦-٧.٨.٩ ٠";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_phone" );
        assertKeyValue( "user_phone_md5", TuneUtils.md5(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha1", TuneUtils.sha1(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha256", TuneUtils.sha256(phoneNumberDigits) );
        
        phoneNumber = "၁၂-၃၄-၅၆၇.၈၉ ၀";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_phone" );
        assertKeyValue( "user_phone_md5", TuneUtils.md5(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha1", TuneUtils.sha1(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha256", TuneUtils.sha256(phoneNumberDigits) );
        
        phoneNumber = "(１２３)４５６-７８９０";
        tune.setPhoneNumber(phoneNumber);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_phone" );
        assertKeyValue( "user_phone_md5", TuneUtils.md5(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha1", TuneUtils.sha1(phoneNumberDigits) );
        assertKeyValue( "user_phone_sha256", TuneUtils.sha256(phoneNumberDigits) );
    }

    public void testReferrer() {
        // Clear SharedPreferences referrer value
        getContext().getApplicationContext().getSharedPreferences(TuneConstants.PREFS_TUNE, Context.MODE_PRIVATE).edit().putString(TuneConstants.KEY_REFERRER, "").apply();
        
        final String referrer = "aTestReferrer";
        
        tune.setInstallReferrer( referrer );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "install_referrer", referrer );
    }

    public void testReferrerNull() {
        // Clear SharedPreferences referrer
        getContext().getApplicationContext().getSharedPreferences(TuneConstants.PREFS_TUNE, Context.MODE_PRIVATE).edit().putString(TuneConstants.KEY_REFERRER, "").apply();

        tune.setInstallReferrer( null );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values should have failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "install_referrer" );
    }

    /*public void testReferrerTracker() {
        // Clear SharedPreferences value
        getContext().getApplicationContext().getSharedPreferences(TuneTestConstants.PREFS_TUNE, Context.MODE_PRIVATE).edit().putString(TuneTestConstants.KEY_REFERRER, "").commit();

        Intent sendReferrer = new Intent("com.android.vending.INSTALL_REFERRER");
        sendReferrer.putExtra("referrer", "test_referrer_value");
        getContext().getApplicationContext().sendBroadcast(sendReferrer);
        sleep ( 20000 );

        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        String referrerResult = tune.getInstallReferrer();
        assertTrue( "referrer should have got test value, was " + referrerResult, referrerResult.equals("test_referrer_value"));
    }*/

    public void testTrusteId() {
        final String id = "testId";
        
        tune.setTRUSTeId( id );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "truste_tpid", id );
    }

    public void testTwitterUserId() {
        final String id = "testId";
        
        tune.setTwitterUserId( id );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "twitter_user_id", id );
    }

    public void testUserEmail() {
        final String email = "testUserEmail@test.com";
        tune.setUserEmail( email );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_email" );
        assertKeyValue( "user_email_md5", TuneUtils.md5(email) );
        assertKeyValue( "user_email_sha1", TuneUtils.sha1(email) );
        assertKeyValue( "user_email_sha256", TuneUtils.sha256(email) );
    }
    
    public void testUserEmailAutoCollect() {
        tune.setEmailCollection(true);
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        // TODO: this fails on emulator with no Gmail account
//        assertNoValueForKey( "user_email" );
//        assertHasValueForKey( "user_email_md5" );
//        assertHasValueForKey( "user_email_sha1" );
//        assertHasValueForKey( "user_email_sha256" );
    }

    public void testUserId() {
        final String id = "testId";
        
        tune.setUserId( id );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertKeyValue( "user_id", id );
    }

    public void testUserName() {
        final String id = "testUserName";
        tune.setUserName( id );
        tune.measureEvent("registration");
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "params default values failed " + params, params.checkDefaultValues() );
        assertNoValueForKey( "user_name" );
        assertKeyValue( "user_name_md5", TuneUtils.md5(id) );
        assertKeyValue( "user_name_sha1", TuneUtils.sha1(id) );
        assertKeyValue( "user_name_sha256", TuneUtils.sha256(id) );
    }
    
    public void testUserIdsAutoPopulated() {
        final String testId = "aTestId";
        final String testEmail = "aTestEmail";
        final String testName = "aTestUserName";
        
        tune.setUserId( testId );
        tune.setUserEmail( testEmail );
        tune.setUserName( testName );
        sleep( TuneTestConstants.PARAMTEST_SLEEP );
        
        assertTrue( "should have saved user id", testId.equals( tune.readUserIdKey( TuneConstants.KEY_USER_ID ) ) );
        assertTrue( "should have saved user email", testEmail.equals( tune.readUserIdKey( TuneConstants.KEY_USER_EMAIL ) ) );
        assertTrue( "should have saved user name", testName.equals( tune.readUserIdKey( TuneConstants.KEY_USER_NAME ) ) );

        TuneTestWrapper.init(getContext(), TuneTestConstants.advertiserId, TuneTestConstants.conversionKey);
        tune = TuneTestWrapper.getInstance();
        tune.waitForInit();
        
        assertTrue( "should have read user id", testId.equals( tune.getUserId() ) );
        assertTrue( "should have read user email", testEmail.equals( tune.getUserEmail() ) );
        assertTrue( "should have read user name", testName.equals( tune.getUserName() ) );
    }
}
