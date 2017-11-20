package com.tune.ma.profile;

import com.tune.TuneLocation;
import com.tune.TuneTestConstants;
import com.tune.TuneTestWrapper;
import com.tune.TuneUnitTest;
import com.tune.TuneUrlKeys;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.constants.TuneVariableType;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.userprofile.TuneCustomProfileVariablesCleared;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;

import org.greenrobot.eventbus.Subscribe;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.Arrays;
import java.util.Date;
import java.util.Locale;

/**
 * Created by charlesgilliam on 1/25/16.
 */
public class TuneUserProfileTests extends TuneUnitTest {
    Integer clearCalledCount = 0;
    TuneUserProfile profile;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        profile = TuneManager.getInstance().getProfileManager();
        clearCalledCount = 0;
        TuneEventBus.register(this);

        profile.deleteSharedPrefs();
    }

    @Override
    public void tearDown() throws Exception {
        super.tearDown();
        TuneEventBus.unregister(this);
    }

    @Subscribe
    public void onEvent(TuneCustomProfileVariablesCleared event) {
        clearCalledCount += 1;
    }

    public void testRegisterCustomProfileVariableShouldAddToUserProfile() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", "initial"));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("initial".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testSetCustomVariableValueShouldUpdateValue() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", (String)null));
        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", "updated"));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("updated".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", "latest"));

        var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("latest".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }


    public void testSetCustomVariableValueToNullIsOkay() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", "not null"));
        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", (String)null));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.STRING);
    }


    public void testCannotChangeCustomVariableTypeOnceRegistered() {
        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("test", 2));
        profile.setCustomProfileVariable(new TuneAnalyticsVariable("test", "Not a number!"));

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("test");

        assertTrue(var != null);
        assertTrue("test".equalsIgnoreCase(var.getName()));
        assertTrue("2".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.FLOAT);
    }

    public void testDefaultValueShouldBeNull() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.STRING);

        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate");

        var = profile.getCustomProfileVariable("testDate");

        assertTrue(var != null);
        assertTrue("testDate".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.DATETIME);

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber");

        var = profile.getCustomProfileVariable("testNumber");

        assertTrue(var != null);
        assertTrue("testNumber".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.FLOAT);

        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation");

        var = profile.getCustomProfileVariable("testLocation");

        assertTrue(var != null);
        assertTrue("testLocation".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.GEOLOCATION);

        // NOTE: We aren't exposing these setter types yet, so we are setting them directly.

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testBoolean", null, TuneVariableType.BOOLEAN));

        var = profile.getCustomProfileVariable("testBoolean");

        assertTrue(var != null);
        assertTrue("testBoolean".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.BOOLEAN);

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testVersion", null, TuneVariableType.VERSION));

        var = profile.getCustomProfileVariable("testVersion");

        assertTrue(var != null);
        assertTrue("testVersion".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.VERSION);
    }

    public void testRegisterWithDefault() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        Date d = new Date(0);
        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate", d);

        var = profile.getCustomProfileVariable("testDate");

        assertTrue(var != null);
        assertTrue("testDate".equalsIgnoreCase(var.getName()));
        assertTrue(TuneAnalyticsVariable.dateToString(d).equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.DATETIME);

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber", 7.999);

        var = profile.getCustomProfileVariable("testNumber");

        assertTrue(var != null);
        assertTrue("testNumber".equalsIgnoreCase(var.getName()));
        assertTrue("7.999".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.FLOAT);

        TuneLocation l = new TuneLocation(7.00, 8.00);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation", l);

        var = profile.getCustomProfileVariable("testLocation");

        assertTrue(var != null);
        assertTrue("testLocation".equalsIgnoreCase(var.getName()));
        assertTrue(TuneAnalyticsVariable.geolocationToString(l).equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.GEOLOCATION);

        // NOTE: We aren't exposing these setter types yet, so we are setting them directly.

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testBoolean", true));

        var = profile.getCustomProfileVariable("testBoolean");

        assertTrue(var != null);
        assertTrue("testBoolean".equalsIgnoreCase(var.getName()));
        assertTrue("1".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.BOOLEAN);

        profile.registerCustomProfileVariable(new TuneAnalyticsVariable("testVersion", "1.0.1", TuneVariableType.VERSION));

        var = profile.getCustomProfileVariable("testVersion");

        assertTrue(var != null);
        assertTrue("testVersion".equalsIgnoreCase(var.getName()));
        assertTrue("1.0.1".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.VERSION);
    }

    public void testRegisterWithWeirdName() {
        TuneTestWrapper.getInstance().registerCustomProfileString("&&&foo***()bar", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("foobar");

        assertTrue(var != null);
        assertTrue("foobar".equalsIgnoreCase(var.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testRegisterWithSpaces() {
        TuneTestWrapper.getInstance().registerCustomProfileString("I HAVE SPACES", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("IHAVESPACES");

        assertTrue(var != null);
        assertTrue("IHAVESPACES".equalsIgnoreCase(var.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testRegisterStringWithNonUSNumbers() {
        TuneTestWrapper.getInstance().registerCustomProfileString("bingbang", "١٢٣٤٥٦-٧.٨.٩ ٠");

        TuneAnalyticsVariable var = profile.getProfileVariableFromPrefs("bingbang");

        assertTrue(var != null);
        assertTrue("bingbang".equalsIgnoreCase(var.getName()));
        assertTrue("١٢٣٤٥٦-٧.٨.٩ ٠".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testRegisterLocationWithNonUSLocale() {
        // Spoof a locale, e.g. Arabic
        Locale locale = new Locale("ar");
        Locale.setDefault(locale);
        mContext.getResources().getConfiguration().locale = locale;

        TuneLocation location = new TuneLocation(111.11, -222.22);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("location", location);
        TuneAnalyticsVariable var = profile.getProfileVariableFromPrefs("location");

        assertTrue(var != null);
        assertTrue("location".equalsIgnoreCase(var.getName()));
        assertTrue("111.110000000,-222.220000000".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.GEOLOCATION);

        // Revert to US locale
        locale = new Locale("us");
        Locale.setDefault(locale);
        mContext.getResources().getConfiguration().locale = locale;
    }

    public void testRegisterWithOnlyWeirdChars() {
        TuneTestWrapper.getInstance().registerCustomProfileString("$()*())#$()", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("$()*())#$()");

        assertTrue(var == null);
        assertTrue(var2 == null);
    }

    public void testRegisterWithGreekChars() {
        String key = "Greek";
        String defaultValue = "Εμπρός";

        tune.registerCustomProfileString(key, defaultValue);
        String test = tune.getCustomProfileString(key);

        assertEquals(defaultValue, test);
    }

    public void testSetWithWeirdName() {
        TuneTestWrapper.getInstance().registerCustomProfileString("foobar");
        TuneTestWrapper.getInstance().setCustomProfileStringValue(")*(#&(*foobar*)(*()", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("foobar");

        assertTrue(var != null);
        assertTrue("foobar".equalsIgnoreCase(var.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testSetWithOnlyWeirdChars() {
        TuneTestWrapper.getInstance().registerCustomProfileString("foobar");
        TuneTestWrapper.getInstance().setCustomProfileStringValue(")*(#&(**)(*()", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("foobar");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("");

        assertTrue(var != null);
        assertTrue("foobar".equalsIgnoreCase(var.getName()));
        assertTrue(var.getValue() == null);
        assertTrue(var.getType() == TuneVariableType.STRING);

        assertTrue(var2 == null);
    }

    public void testRegisterSystemVariable() {
        TuneTestWrapper.getInstance().registerCustomProfileString("google_aid", "not null");

        // NOTE: Since we clear out the sharedprefs before running this should be null
        TuneAnalyticsVariable var = profile.getProfileVariable("google_aid");

        assertFalse(var.getValue().equals("not null"));
    }

    public void testSetSystemVariable() {
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));
        TuneTestWrapper.getInstance().setCustomProfileStringValue("google_aid", "not null");

        TuneAnalyticsVariable var = profile.getProfileVariable("google_aid");

        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    // Test to make sure checks of custom variables are case-insensitive when registring them
    public void testPreventsCollisionOfCustomVariableWithProfileVariable() {
        TuneTestWrapper.getInstance().registerCustomProfileString("Language", "Dravanian");
        TuneTestWrapper.getInstance().registerCustomProfileString("Device Token", "Knicknack");
        TuneTestWrapper.getInstance().registerCustomProfileString("Butterfly", "Monarch");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("Language");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("Device Token");
        TuneAnalyticsVariable var3 = profile.getCustomProfileVariable("DeviceToken");
        TuneAnalyticsVariable var4 = profile.getCustomProfileVariable("Butterfly");

        assertNull(var);
        assertNull(var2);
        assertNull(var3);
        assertEquals("Butterfly", var4.getName());
        assertEquals("Monarch", var4.getValue());
    }

    public void testPreventAddingCustomProfileVariablesStartingWithTUNE() {
        TuneTestWrapper.getInstance().registerCustomProfileString("TUNE_whatever", "bingbang");
        TuneTestWrapper.getInstance().registerCustomProfileString("Tune_whatever", "bingbang");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("TUNE_whatever");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("Tune_whatever");

        assertTrue(var == null);
        assertTrue(var2 != null);
        assertTrue("Tune_whatever".equalsIgnoreCase(var2.getName()));
        assertTrue("bingbang".equalsIgnoreCase(var2.getValue()));
        assertTrue(var2.getType() == TuneVariableType.STRING);
    }

    public void testPublicGettersNoDefault() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("testString"));

        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileDate("testDate"));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileNumber("testNumber"));

        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation");
        assertNull(TuneTestWrapper.getInstance().getCustomProfileGeolocation("testLocation"));
    }

    public void testPublicGettersWithDefault() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "default");
        assertTrue("default".equalsIgnoreCase(TuneTestWrapper.getInstance().getCustomProfileString("testString")));

        Date d = new Date(0);
        TuneTestWrapper.getInstance().registerCustomProfileDate("testDate", d);
        assertTrue(d.equals(TuneTestWrapper.getInstance().getCustomProfileDate("testDate")));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("testNumber", 7.987);
        assertTrue(TuneTestWrapper.getInstance().getCustomProfileNumber("testNumber").doubleValue() == 7.987);

        TuneLocation l = new TuneLocation(9, 8);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("testLocation", l);
        TuneLocation gotten = TuneTestWrapper.getInstance().getCustomProfileGeolocation("testLocation");
        assertTrue(gotten != null);
        assertTrue(l.getLatitude() == gotten.getLatitude());
        assertTrue(l.getLongitude() == gotten.getLongitude());
    }

    public void testPublicGettersBeforeRegistration() {
        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("testString"));
    }

    public void testPublicSetters() {
        TuneTestWrapper.getInstance().registerCustomProfileNumber("int", 1);
        TuneAnalyticsVariable varInt = profile.getCustomProfileVariable("int");
        assertTrue("int".equalsIgnoreCase(varInt.getName()));
        assertTrue(varInt.getType() == TuneVariableType.FLOAT);
        assertEquals(1, Integer.parseInt(varInt.getValue()));

        TuneTestWrapper.getInstance().setCustomProfileNumber("int", 5);
        varInt = profile.getCustomProfileVariable("int");
        assertTrue("int".equalsIgnoreCase(varInt.getName()));
        assertTrue(varInt.getType() == TuneVariableType.FLOAT);
        assertEquals(5, Integer.parseInt(varInt.getValue()));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("double", 0.99);
        TuneAnalyticsVariable varDouble = profile.getCustomProfileVariable("double");
        assertTrue("double".equalsIgnoreCase(varDouble.getName()));
        assertTrue(varDouble.getType() == TuneVariableType.FLOAT);
        assertEquals(0.99, Double.parseDouble(varDouble.getValue()));

        TuneTestWrapper.getInstance().setCustomProfileNumber("double", 1.99);
        varDouble = profile.getCustomProfileVariable("double");
        assertTrue("double".equalsIgnoreCase(varDouble.getName()));
        assertTrue(varDouble.getType() == TuneVariableType.FLOAT);
        assertEquals(1.99, Double.parseDouble(varDouble.getValue()));

        TuneTestWrapper.getInstance().registerCustomProfileNumber("float", 0.99f);
        TuneAnalyticsVariable varFloat = profile.getCustomProfileVariable("float");
        assertTrue("float".equalsIgnoreCase(varFloat.getName()));
        assertTrue(varFloat.getType() == TuneVariableType.FLOAT);
        assertEquals(0.99f, Float.parseFloat(varFloat.getValue()));

        TuneTestWrapper.getInstance().setCustomProfileNumber("float", 1.99f);
        varFloat = profile.getCustomProfileVariable("float");
        assertTrue("float".equalsIgnoreCase(varFloat.getName()));
        assertTrue(varFloat.getType() == TuneVariableType.FLOAT);
        assertEquals(1.99f, Float.parseFloat(varFloat.getValue()));

        Date expectedDate = new Date();
        TuneTestWrapper.getInstance().registerCustomProfileDate("date", expectedDate);
        TuneAnalyticsVariable varDate = profile.getCustomProfileVariable("date");
        assertTrue("date".equalsIgnoreCase(varDate.getName()));
        assertTrue(varDate.getType() == TuneVariableType.DATETIME);
        assertEquals(TuneAnalyticsVariable.dateToString(expectedDate), varDate.getValue());

        Date expectedDate2 = new Date();
        TuneTestWrapper.getInstance().setCustomProfileDate("date", expectedDate2);
        varDate = profile.getCustomProfileVariable("date");
        assertTrue("date".equalsIgnoreCase(varDate.getName()));
        assertTrue(varDate.getType() == TuneVariableType.DATETIME);
        assertEquals(TuneAnalyticsVariable.dateToString(expectedDate2), varDate.getValue());

        TuneLocation expectedLocation = new TuneLocation(1, 2);
        TuneTestWrapper.getInstance().registerCustomProfileGeolocation("location", expectedLocation);
        TuneAnalyticsVariable varLocation = profile.getCustomProfileVariable("location");
        assertTrue("location".equalsIgnoreCase(varLocation.getName()));
        assertTrue(varLocation.getType() == TuneVariableType.GEOLOCATION);
        assertEquals(TuneAnalyticsVariable.geolocationToString(expectedLocation), varLocation.getValue());

        TuneLocation expectedLocation2 = new TuneLocation(3, 4);
        TuneTestWrapper.getInstance().setCustomProfileGeolocation("location", expectedLocation2);
        varLocation = profile.getCustomProfileVariable("location");
        assertTrue("location".equalsIgnoreCase(varLocation.getName()));
        assertTrue(varLocation.getType() == TuneVariableType.GEOLOCATION);
        assertEquals(TuneAnalyticsVariable.geolocationToString(expectedLocation2), varLocation.getValue());
    }

    public void testClearVariableAndSet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");
        TuneAnalyticsVariable var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        TuneTestWrapper.getInstance().clearCustomProfileVariable("testString");
        var = profile.getCustomProfileVariable("testString");

        assertTrue(var == null);

        TuneTestWrapper.getInstance().setCustomProfileStringValue("testString", "new");
        var = profile.getCustomProfileVariable("testString");

        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("new".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testCantClearSystemVariables() {
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));
        TuneTestWrapper.getInstance().clearCustomProfileVariable("google_aid");

        TuneAnalyticsVariable var = profile.getProfileVariable("google_aid");

        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);
    }

    public void testClearCustomVariables() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");
        TuneTestWrapper.getInstance().registerCustomProfileString("testString2", "defaultString2");
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));

        TuneAnalyticsVariable var = profile.getProfileVariable("testString");
        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("testString2");
        assertTrue(var != null);
        assertTrue("testString2".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString2".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("google_aid");
        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        // Remove a valid custom variable, an unregistered variable, and a non-custom variable.
        TuneTestWrapper.getInstance().clearCustomProfileVariable("testString");
        TuneTestWrapper.getInstance().clearCustomProfileVariable("not_valid");
        TuneTestWrapper.getInstance().clearCustomProfileVariable("google_aid");

        var = profile.getCustomProfileVariable("testString");
        assertNull(var);

        var = profile.getCustomProfileVariable("testString2");
        assertNotNull(var);

        var = profile.getProfileVariable("google_aid");
        assertNotNull(var);

        assertTrue(clearCalledCount == 1);
    }

    public void testClearCustomVariableThenGet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");

        TuneTestWrapper.getInstance().clearCustomProfileVariable("testString");

        String s = TuneTestWrapper.getInstance().getCustomProfileString("testString");
        assertNull(s);
    }

    public void testClearCustomVariablesInvalidName() {
        TuneTestWrapper.getInstance().registerCustomProfileString("valid__valid", "foobar");

        TuneAnalyticsVariable var = profile.getProfileVariable("valid__valid");
        assertTrue(var != null);
        assertTrue("valid__valid".equalsIgnoreCase(var.getName()));
        assertTrue("foobar".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        TuneTestWrapper.getInstance().clearCustomProfileVariable("$$#$&^");
        TuneTestWrapper.getInstance().clearCustomProfileVariable("valid_$#$_valid");

        var = profile.getCustomProfileVariable("valid__valid");
        assertNull(var);

        assertTrue(clearCalledCount == 1);
    }

    public void testAllowCustomVariableValuesToBeSetRegardlessOfNameCase() {
        TuneTestWrapper.getInstance().registerCustomProfileString("Cat", "Tabby");
        TuneTestWrapper.getInstance().registerCustomProfileString("cat", "Siamese");

        TuneAnalyticsVariable var = profile.getCustomProfileVariable("Cat");
        TuneAnalyticsVariable var2 = profile.getCustomProfileVariable("cat");

        TuneTestWrapper.getInstance().setCustomProfileStringValue("Cat", "Mink");
        TuneTestWrapper.getInstance().setCustomProfileStringValue("cat", "Burmese");

        TuneAnalyticsVariable var3 = profile.getCustomProfileVariable("Cat");
        TuneAnalyticsVariable var4 = profile.getCustomProfileVariable("cat");

        assertEquals("Cat", var.getName());
        assertEquals("Tabby", var.getValue());
        assertEquals("cat", var2.getName());
        assertEquals("Siamese", var2.getValue());

        assertEquals("Cat", var3.getName());
        assertEquals("Mink", var3.getValue());
        assertEquals("cat", var4.getName());
        assertEquals("Burmese", var4.getValue());
    }

    public void testClearCustomProfile() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultString");
        TuneTestWrapper.getInstance().registerCustomProfileString("testString2", "defaultString2");
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("google_aid", "99111")));

        TuneAnalyticsVariable var = profile.getProfileVariable("testString");
        assertTrue(var != null);
        assertTrue("testString".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("testString2");
        assertTrue(var != null);
        assertTrue("testString2".equalsIgnoreCase(var.getName()));
        assertTrue("defaultString2".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        var = profile.getProfileVariable("google_aid");
        assertTrue(var != null);
        assertTrue("google_aid".equalsIgnoreCase(var.getName()));
        assertTrue("99111".equalsIgnoreCase(var.getValue()));
        assertTrue(var.getType() == TuneVariableType.STRING);

        // Remove a valid custom variable, an unregistered variable, and a non-custom variable.
        TuneTestWrapper.getInstance().clearAllCustomProfileVariables();

        var = profile.getCustomProfileVariable("testString");
        assertNull(var);

        var = profile.getCustomProfileVariable("testString2");
        assertNull(var);

        var = profile.getProfileVariable("google_aid");
        assertNotNull(var);

        assertTrue(clearCalledCount == 1);
    }

    public boolean checkJSON(JSONArray json, String name, String value) throws JSONException {
        for (int i = 0; i < json.length(); i++) {
            TuneAnalyticsVariable var = TuneAnalyticsVariable.fromJson(json.get(i).toString());
            if (var.getName().equalsIgnoreCase(name) &&
                    ((var.getValue() == null && var.getValue() == value) || (var.getValue() != null && var.getValue().equalsIgnoreCase(value)))) {
                return true;
            }
        }
        return false;
    }

    public void testToJson() throws JSONException {
        TuneTestWrapper.getInstance().registerCustomProfileString("in1", "foobar");
        TuneTestWrapper.getInstance().registerCustomProfileString("in2", null);
        TuneTestWrapper.getInstance().registerCustomProfileString("in3");

        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("profileVar1", "not_empty")));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("profileVar2", "")));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable("profileVar3", (String) null)));
        JSONArray output = profile.toJson();

        assertTrue(checkJSON(output, "in1", "foobar"));
        assertTrue(checkJSON(output, "in2", null));
        assertTrue(checkJSON(output, "in3", null));

        assertTrue(checkJSON(output, "profileVar1", "not_empty"));
        assertTrue(checkJSON(output, "profileVar2", ""));
        assertTrue(checkJSON(output, "profileVar3", null));
    }

    public void testReRegisterCustomVariablesNotSet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("my_name");

        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("my_name"));

        TuneManager.destroy();
        TuneManager.init(getContext(), TuneTestWrapper.getTestingConfig(Arrays.asList("")));

        TuneTestWrapper.getInstance().registerCustomProfileString("my_name", "has default now");

        assertEquals("has default now", TuneTestWrapper.getInstance().getCustomProfileString("my_name"));
    }

    public void testReRegisterCustomVariablesSet() {
        TuneTestWrapper.getInstance().registerCustomProfileString("my_name");

        assertNull(TuneTestWrapper.getInstance().getCustomProfileString("my_name"));

        TuneTestWrapper.getInstance().setCustomProfileStringValue("my_name", "new value");

        TuneManager.destroy();
        TuneManager.init(getContext(), TuneTestWrapper.getTestingConfig(Arrays.asList("")));

        TuneTestWrapper.getInstance().registerCustomProfileString("my_name", "has default now");

        assertEquals("new value", TuneTestWrapper.getInstance().getCustomProfileString("my_name"));
    }

    public void testUserEmailNotStored() {
        TuneTestWrapper.getInstance().setUserEmail("test_email");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertNull(profile.getProfileVariable(TuneProfileKeys.USER_EMAIL));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_EMAIL_MD5));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_EMAIL_SHA1));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_EMAIL_SHA256));
    }

    public void testUserNameNotStored() {
        TuneTestWrapper.getInstance().setUserName("test_username");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertNull(profile.getProfileVariable(TuneProfileKeys.USER_NAME));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_NAME_MD5));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_NAME_SHA1));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_NAME_SHA256));
    }

    public void testPhoneNumberNotStored() {
        TuneTestWrapper.getInstance().setPhoneNumber("test_phone_number");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertNull(profile.getProfileVariable(TuneProfileKeys.USER_PHONE));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_PHONE_MD5));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_PHONE_SHA1));
        assertNotNull(profile.getProfileVariable(TuneUrlKeys.USER_PHONE_SHA256));
    }

    public void testCustomProfileVariablesPersistBetweenSessions() {
        TuneTestWrapper.getInstance().registerCustomProfileString("testString", "defaultStringValue");

        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        // Trigger a save of the custom variable names
        TuneEventBus.post(new TuneAppBackgrounded());

        sleep( TuneTestConstants.SERVERTEST_SLEEP );

        // Re-init TuneManager and TuneUserProfile, to simulate app getting killed and started
        TuneManager.destroy();
        // The eventbus always starts out enabled then becomes disabled
        TuneEventBus.enable();
        TuneManager.init(getContext(), TuneTestWrapper.getTestingConfig(Arrays.asList("configuration_enabled.json")));

        TuneEventBus.post(new TuneAppForegrounded("123", 0L));

        // Check that custom profile variable is repopulated after app foreground
        assertEquals("defaultStringValue", profile.getCustomProfileVariable("testString").getValue());
    }

    public void testBooleanValuesSetCorrectly() {
        // Test setExistingUser sends "1" when set to true
        TuneTestWrapper.getInstance().setExistingUser(true);
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertEquals("1", profile.getProfileVariableValue(TuneUrlKeys.EXISTING_USER));


        // Test setIsPayingUser sends "1" when set to true
        TuneTestWrapper.getInstance().setIsPayingUser(true);
        sleep( TuneTestConstants.PARAMTEST_SLEEP );

        assertEquals("1", profile.getProfileVariableValue(TuneUrlKeys.IS_PAYING_USER));
    }

    /*

- (void)testHashedString {
    [[TuneManager currentManager].userProfile registerString:@"c1" withDefault:@"foobar" hashed:YES];
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"c1"];

    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashNone);
    XCTAssertTrue(var.shouldAutoHash);
}

- (void)testPreHashedVariablesOnlyHashedOnce {
    [[TuneManager currentManager].userProfile setUserName:@"Jim Rogers"];

    NSArray *output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];

    XCTAssertTrue([self getDictionary:output key:TUNE_KEY_USER_NAME_MD5].count == 1);
    NSDictionary *var = [self getDictionary:output key:TUNE_KEY_USER_NAME_MD5][0];
    XCTAssertTrue([var[@"hash"] isEqualToString:@"md5"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"4518c3ca8d0dcb253e66a5ab16495ec2"]);

    XCTAssertTrue([self getDictionary:output key:TUNE_KEY_USER_NAME_SHA1].count == 1);
    var = [self getDictionary:output key:TUNE_KEY_USER_NAME_SHA1][0];
    XCTAssertTrue([var[@"hash"] isEqualToString:@"sha1"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"15dc14109c5f7d263f2aebf8d0ebfb7ae2d9a118"]);

    XCTAssertTrue([self getDictionary:output key:TUNE_KEY_USER_NAME_SHA256].count == 1);
    var = [self getDictionary:output key:TUNE_KEY_USER_NAME_SHA256][0];
    XCTAssertTrue([var[@"hash"] isEqualToString:@"sha256"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"53149a84ca2e85a9c853b7fb017c58c16cdc48fed3759be89b008d73d1b6d834"]);
}

- (void)testVariationIdsAreAddedCorrectly {
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableValue:@"variation1", TunePayloadSessionVariableName: @"TUNE_ACTIVE_VARIATION_ID", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeProfile}];

    NSArray *output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    NSDictionary *var = [self getDictionary:output key:@"TUNE_ACTIVE_VARIATION_ID"][0];
    XCTAssertTrue([var[@"type"] isEqualToString:@"string"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"variation1"]);


    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableValue:@"variation2", TunePayloadSessionVariableName: @"TUNE_ACTIVE_VARIATION_ID", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeProfile}];

    output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    XCTAssertTrue([self getDictionary:output key:@"TUNE_ACTIVE_VARIATION_ID"].count == 2);

    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableValue:@"variation2", TunePayloadSessionVariableName: @"TUNE_ACTIVE_VARIATION_ID", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeProfile}];

    output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    XCTAssertTrue([self getDictionary:output key:@"TUNE_ACTIVE_VARIATION_ID"].count == 2);
}

- (void)testSetVersionVariableValueShouldUpdateValue {
    [[TuneManager currentManager].userProfile registerVersion:@"apiVersion"];

    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"apiVersion"];

    XCTAssertTrue([var.name isEqualToString:@"apiVersion"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value should be set");
    XCTAssertEqual(var.type, TuneAnalyticsVariableVersionType, @"variable type should be set");

    [[TuneManager currentManager].userProfile setVersionValue:@"2.4.15" forVariable:@"apiVersion"];

    var = [[TuneManager currentManager].userProfile getProfileVariable:@"apiVersion"];

    XCTAssertTrue([var.name isEqualToString:@"apiVersion"], @"variable name should be set");
    XCTAssertTrue([var.value isEqualToString:@"2.4.15"], @"variable value should be updated");
    XCTAssertEqual(var.type, TuneAnalyticsVariableVersionType, @"variable type should be set");
}
     */
}
