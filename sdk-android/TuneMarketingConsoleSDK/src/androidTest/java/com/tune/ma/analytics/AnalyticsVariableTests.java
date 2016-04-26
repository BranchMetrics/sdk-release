package com.tune.ma.analytics;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.TuneHashType;
import com.tune.ma.analytics.model.TuneVariableType;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;

/**
 * Created by johng on 1/11/16.
 */
public class AnalyticsVariableTests extends TuneAnalyticsTest {

    private void isValidVersionString(String version) {
        boolean isValid = TuneAnalyticsVariable.validateVersion(version);
        assertTrue("Version " + version + " should be valid.", isValid);
    }

    private void isNotValidVersionString(String version) {
        boolean isValid = TuneAnalyticsVariable.validateVersion(version);
        assertFalse("Version " + version + " should not be valid.", isValid);
    }

    /**
     * Test validateVersion accepts and rejects the correct versions
     */
    public void testValidVersion() {
        isValidVersionString("2.4.8");
        isValidVersionString("2.4.8-SNAPSHOT");
        isValidVersionString("2.4.8-1234");
        isValidVersionString("2.4");
        isValidVersionString("2.4-Weee");
        isValidVersionString("2.4-8");
        isValidVersionString("2");
        isValidVersionString("2-too");
        isValidVersionString("2-2");
        isValidVersionString("2-");
        isValidVersionString("2.4-");
        isValidVersionString("2.4.8-");
        isValidVersionString("29999.4");
        isValidVersionString(null);
        isValidVersionString("2-4-6-8");
        isValidVersionString("0.9");
        isValidVersionString("0.0");

        isNotValidVersionString("2b2b2b2b");
        isNotValidVersionString("1.2.3.4.5.6.7..8.9.0.10");
        isNotValidVersionString("2FAKEFAKEFAKE");
        isNotValidVersionString("FAKEFAKEFAKE");
        isNotValidVersionString("8_3");
        isNotValidVersionString("6/8/15");
        isNotValidVersionString("6\\8\\15");
        isNotValidVersionString("   2.4.8   ");
        isNotValidVersionString("   ");
        isNotValidVersionString("{twotee}");
        isNotValidVersionString("99%");
    }

    /**
     * Test that validateVersion accepts and rejects the correct Maven versions
     */
    public void testValidateVersionUsingApacheMavenExamples() {
        // these values are numerically comparable
        isValidVersionString("1");
        isValidVersionString("1.2");
        isValidVersionString("1.2.3");
        isValidVersionString("1.2.3-1");
        isValidVersionString("1.2.3-alpha-1");
        isValidVersionString("1.2-alpha-1");
        isValidVersionString("1.2-alpha-1-20050205.060708-1");
        isValidVersionString("2.0-1");
        isValidVersionString("2.0-01");

        // MA chooses not to accept these values
        isNotValidVersionString("1.1.2.beta1");
        isNotValidVersionString("1.7.3.b");

        // these values are NOT numerically comparable
        isValidVersionString("1.2.3-200705301630");
        isNotValidVersionString("RELEASE");
        isNotValidVersionString("02");
        isNotValidVersionString("0.09");
        isNotValidVersionString("0.2.09");
        isNotValidVersionString("1.0.1b");
        isNotValidVersionString("1.0M2");
        isNotValidVersionString("1.0RC2");
        isNotValidVersionString("1.7.3.0");
        isNotValidVersionString("1.7.3.0-1");
        isNotValidVersionString("PATCH-1193602");
        isNotValidVersionString("5.0.0alpha-2006020117");
        isNotValidVersionString("1.0.0.-SNAPSHOT");
        isNotValidVersionString("1..0-SNAPSHOT");
        isNotValidVersionString("1.0.-SNAPSHOT");
        isNotValidVersionString(".1.0-SNAPSHOT");
        isNotValidVersionString("1.2.3.200705301630");
    }

    /**
     * Test that cleanVariableName cleans names correctly
     */
    public void testCleanName() {
        assertTrue(TuneAnalyticsVariable.cleanVariableName(null) == null);
        assertTrue(TuneAnalyticsVariable.cleanVariableName("foobar").equals("foobar"));
        assertTrue(TuneAnalyticsVariable.cleanVariableName("foo_bar-bing").equals("foo_bar-bing"));
        assertTrue(TuneAnalyticsVariable.cleanVariableName("^foobar$").equals("foobar"));
        assertTrue(TuneAnalyticsVariable.cleanVariableName("foobar=0->9").equals("foobar0-9"));
    }

    /**
     * Test that validateName validates names correctly
     */
    public void testValidateName() {
        assertFalse(TuneAnalyticsVariable.validateName(null));
        assertFalse(TuneAnalyticsVariable.validateName(""));
        assertFalse(TuneAnalyticsVariable.validateName("&()*%%^&^"));

        assertTrue(TuneAnalyticsVariable.validateName("foobar"));
        assertTrue(TuneAnalyticsVariable.validateName("foob#%#@ar"));
        assertTrue(TuneAnalyticsVariable.validateName("foo_bar-bing"));
    }

    /**
     * Test that toJsonForLocalStorage creates the JSONObject correctly
     */
    public void testToJson() {
        TuneAnalyticsVariable var = new TuneAnalyticsVariable("key", "value");
        JSONObject varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }

        var = new TuneAnalyticsVariable("key", "value");
        varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }
    }

    public void testToJsonHashTypeStoredCorrectly() {
        TuneAnalyticsVariable var = new TuneAnalyticsVariable("key", "value", TuneVariableType.STRING, TuneHashType.NONE, false);
        JSONObject varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
            assertFalse(varJson.has("hash"));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }

        var = new TuneAnalyticsVariable("key", "value", TuneVariableType.STRING, TuneHashType.MD5, false);
        varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
            assertEquals("MD5", varJson.getString("hash").toUpperCase(Locale.US));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }

        var = new TuneAnalyticsVariable("key", "value", TuneVariableType.STRING, TuneHashType.SHA1, false);
        varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
            assertEquals("SHA1", varJson.getString("hash").toUpperCase(Locale.US));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }

        var = new TuneAnalyticsVariable("key", "value", TuneVariableType.STRING, TuneHashType.SHA256, false);
        varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
            assertEquals("SHA256", varJson.getString("hash").toUpperCase(Locale.US));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }
    }

    public void testToJsonWithShouldAutoHash() {
        TuneAnalyticsVariable var = new TuneAnalyticsVariable("key", "value", TuneVariableType.STRING, TuneHashType.NONE, false);
        JSONObject varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
            assertFalse(varJson.getBoolean("shouldAutoHash"));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }

        var = new TuneAnalyticsVariable("key", "value", TuneVariableType.STRING, TuneHashType.NONE, true);
        varJson = var.toJsonForLocalStorage();
        try {
            assertEquals("key", varJson.getString("name"));
            assertEquals("value", varJson.getString("value"));
            assertEquals("STRING", varJson.getString("type").toUpperCase(Locale.US));
            assertTrue(varJson.getBoolean("shouldAutoHash"));
        } catch (JSONException e) {
            e.printStackTrace();
            assertTrue("Couldn't get expected values from JSONObject", false);
        }
    }

    public void testDeserializeVariables() {
        TuneAnalyticsVariable var = null;
        var = TuneAnalyticsVariable.fromJson("{\"name\":\"ourName\",\"value\":\"ourValue\",\"type\":\"STRING\",\"shouldAutoHash\":false}");

        assertNotNull(var);
        assertEquals("ourName", var.getName());
        assertEquals("ourValue", var.getValue());
        assertEquals(TuneVariableType.STRING, var.getType());
        assertEquals(TuneHashType.NONE, var.getHashType());
        assertFalse(var.getShouldAutoHash());

        var = TuneAnalyticsVariable.fromJson("{\"name\":\"ourName\",\"value\":\"ourValue\",\"type\":\"STRING\",\"shouldAutoHash\":false,\"hash\":\"MD5\"}");

        assertNotNull(var);
        assertEquals("ourName", var.getName());
        assertEquals("ourValue", var.getValue());
        assertEquals(TuneVariableType.STRING, var.getType());
        assertEquals(TuneHashType.MD5, var.getHashType());
        assertFalse(var.getShouldAutoHash());
    }
}
