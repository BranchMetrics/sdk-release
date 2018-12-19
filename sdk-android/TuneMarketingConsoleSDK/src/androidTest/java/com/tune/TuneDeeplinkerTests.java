package com.tune;

import android.support.test.runner.AndroidJUnit4;

import com.tune.mocks.MockUrlRequester;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.ArrayList;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/**
 * Created by audrey on 10/26/16.
 */

@RunWith(AndroidJUnit4.class)
public class TuneDeeplinkerTests  extends TuneUnitTest {

    private MockUrlRequester mockUrlRequester;
    private final List<String> receivedDeeplink = new ArrayList<>();
    private final List<String> failedDeeplink = new ArrayList<>();

    @Before
    public void setUp() throws Exception {
        super.setUp();

        resetReceivedDeeplinkChecks();

        mockUrlRequester = new MockUrlRequester();
        mockUrlRequester.setRequestUrlShouldSucceed(false);
        mockUrlRequester.clearFakeResponse();
        tune.setUrlRequester(mockUrlRequester);
        tune.registerDeeplinkListener(new TuneDeeplinkListener() {
            @Override
            public void didReceiveDeeplink(String deeplink) {
                receivedDeeplink.add(deeplink);
            }

            @Override
            public void didFailDeeplink(String error) {
                failedDeeplink.add(error);
            }
        });
        sleep(TuneTestConstants.PARAMTEST_SLEEP);
        resetReceivedDeeplinkChecks(); // clear out responses from initial register listener callbacks
    }

    private void resetReceivedDeeplinkChecks() {
        receivedDeeplink.clear();
        failedDeeplink.clear();
    }

    @Test
    public void testIsTuneLinkForTlnkio() {
        assertTrue(tune.isTuneLink("http://tlnk.io"));
        assertTrue(tune.isTuneLink("http://12345.tlnk.io"));
        assertTrue(tune.isTuneLink("http://tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://12345.tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://tlnk.io"));
        assertTrue(tune.isTuneLink("https://12345.tlnk.io"));
        assertTrue(tune.isTuneLink("https://tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://12345.tlnk.io/path/to/something?withargs=shorething&other=things"));

        assertFalse(tune.isTuneLink("fake://tlnk.io"));
        assertFalse(tune.isTuneLink("http://talink.io"));
        assertFalse(tune.isTuneLink("http://foobar.com.nope"));
        assertFalse(tune.isTuneLink("http://randomize.it"));
        assertFalse(tune.isTuneLink("myapp://isthebest/yes/it/is"));
    }

    @Test
    public void testIsTuneLinkForBranch() {
        assertTrue(tune.isTuneLink("http://app.link"));
        assertTrue(tune.isTuneLink("http://12345.app.link"));
        assertTrue(tune.isTuneLink("http://app.link/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://12345.app.link/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://app.link"));
        assertTrue(tune.isTuneLink("https://12345.app.link"));
        assertTrue(tune.isTuneLink("https://app.link/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://12345.app.link/path/to/something?withargs=shorething&other=things"));

        assertFalse(tune.isTuneLink("fake://app.link"));
    }

    @Test
    public void testIsTuneLinkForBadValues() {
        assertFalse(tune.isTuneLink("faketlnk.io"));
        assertFalse(tune.isTuneLink("      nope      "));
        assertFalse(tune.isTuneLink("http://"));
        assertFalse(tune.isTuneLink(null));
        assertFalse(tune.isTuneLink(""));
        assertFalse(tune.isTuneLink("http://randomize.it   "));
        assertFalse(tune.isTuneLink("      myapp://isthebest/yes/it/is"));
    }

    @Test
    public void testIsTuneLink() {
        tune.registerCustomTuneLinkDomain("foobar.com");
        assertTrue(tune.isTuneLink("http://foobar.com"));
        assertTrue(tune.isTuneLink("http://wow.foobar.com"));
        assertTrue(tune.isTuneLink("http://foobar.com/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://wow.foobar.com/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://tlnk.io"));
        assertTrue(tune.isTuneLink("http://12345.tlnk.io"));
        assertTrue(tune.isTuneLink("http://tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://12345.tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://tlnk.io"));
        assertTrue(tune.isTuneLink("https://12345.tlnk.io"));
        assertTrue(tune.isTuneLink("https://tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://12345.tlnk.io/path/to/something?withargs=shorething&other=things"));

        assertFalse(tune.isTuneLink("fake://tlnk.io"));
        assertFalse(tune.isTuneLink("myapp://isthebest/yes/it/is"));
        assertFalse(tune.isTuneLink("http://wow.foobarz.com"));
        assertFalse(tune.isTuneLink("http://foobar.co.uk"));
        assertFalse(tune.isTuneLink("http://foobar.com.nope"));
        assertFalse(tune.isTuneLink("http://randomize.it"));
        assertFalse(tune.isTuneLink("http://foobar.co.uk/path/to/something/?withfakearg=foobar.com"));
        assertFalse(tune.isTuneLink("http://wow.foobarz.com/path/to/something?withargs=shorething&other=things"));
        assertFalse(tune.isTuneLink("http://foobar.co.uk/path/to/something?withargs=shorething&other=things"));
        assertFalse(tune.isTuneLink("http://foobar.com.nope/path/to/something?withargs=shorething&other=things"));
        assertFalse(tune.isTuneLink("http://randomize.it/path/to/something?withargs=shorething&other=things"));
    }

    @Test
    public void testRegisterManyTuneLinkDomains() {
        tune.registerCustomTuneLinkDomain("blah.org");
        tune.registerCustomTuneLinkDomain("taptap.it");
        tune.registerCustomTuneLinkDomain("my.veryspecial.link");
        tune.registerCustomTuneLinkDomain("foobar.com");

        assertTrue(tune.isTuneLink("http://foobar.com"));
        assertTrue(tune.isTuneLink("http://blah.org"));
        assertTrue(tune.isTuneLink("http://taptap.it"));
        assertTrue(tune.isTuneLink("http://my.veryspecial.link"));
        assertTrue(tune.isTuneLink("http://wow.foobar.com"));
        assertTrue(tune.isTuneLink("http://foobar.com/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://wow.foobar.com/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://tlnk.io"));
        assertTrue(tune.isTuneLink("http://12345.tlnk.io"));
        assertTrue(tune.isTuneLink("http://tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("http://12345.tlnk.io/path/to/something?withargs=shorething&other=things"));
        assertTrue(tune.isTuneLink("https://tlnk.io"));
        assertTrue(tune.isTuneLink("https://12345.tlnk.io"));
        assertTrue(tune.isTuneLink("https://tlnk.io/path/to/something?withargs=shorething&other=things"));

        assertFalse(tune.isTuneLink("myapp://isthebest/yes/it/is"));
        assertFalse(tune.isTuneLink("http://wow.foobarz.com"));
        assertFalse(tune.isTuneLink("http://foobar.co.uk"));
        assertFalse(tune.isTuneLink("http://foobar.com.nope"));
        assertFalse(tune.isTuneLink("http://randomize.it"));
        assertFalse(tune.isTuneLink("http://foobar.co.uk/path/to/something/?withfakearg=foobar.com"));
        assertFalse(tune.isTuneLink("http://wow.foobarz.com/path/to/something?withargs=shorething&other=things"));
        assertFalse(tune.isTuneLink("http://foobar.co.uk/path/to/something?withargs=shorething&other=things"));
        assertFalse(tune.isTuneLink("http://foobar.com.nope/path/to/something?withargs=shorething&other=things"));
        assertFalse(tune.isTuneLink("http://randomize.it/path/to/something?withargs=shorething&other=things"));
    }

    @Test
    public void testIsInvokeUrlInReferralUrl() {
        String expectedInvokeUrl = "testapp://path/to/a/thing?with=yes&params=ok";
        String invokeUrl = tune.invokeUrlFromReferralUrl("https://12sfci8ss.tlnk.io/something?withparams=yes&invoke_url=testapp%3A%2F%2Fpath%2Fto%2Fa%2Fthing%3Fwith%3Dyes%26params%3Dok&seomthingelse=2").get();
        assertEquals(expectedInvokeUrl, invokeUrl);
    }

    @Test
    public void testIsInvokeUrlInReferralUrlWhenNotPresent() {
        assertFalse(tune.invokeUrlFromReferralUrl("https://12sfci8ss.tlnk.io/something?withparams=yes&seomthingelse=2").isPresent());
        assertFalse(tune.invokeUrlFromReferralUrl(null).isPresent());
        assertFalse(tune.invokeUrlFromReferralUrl("").isPresent());
        assertFalse(tune.invokeUrlFromReferralUrl("somestringnoturl").isPresent());
    }

    @Test
    public void testSetReferralUrlShortcutsIfInvokeUrlPresent() throws Exception {
        String expectedInvokeUrl = "testapp://path/to/a/thing?with=yes&params=ok";
        mockUrlRequester.includeInFakeResponse(TuneConstants.KEY_INVOKE_URL, "some other response");
        mockUrlRequester.setRequestUrlShouldSucceed(true);
        resetReceivedDeeplinkChecks();

        tune.setReferralUrl("https://12sfci8ss.tlnk.io/something?withparams=yes&invoke_url=testapp%3A%2F%2Fpath%2Fto%2Fa%2Fthing%3Fwith%3Dyes%26params%3Dok&seomthingelse=2");
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertEquals(expectedInvokeUrl, receivedDeeplink.get(0));
        assertEquals(0, failedDeeplink.size());
    }

    @Test
    public void testSetReferralUrlDoesNotShortcutsIfNoInvokeUrlParameter() throws Exception {
        String expectedInvokeUrl = "testapp://path/to/a/thing?with=yes&params=ok";
        mockUrlRequester.includeInFakeResponse(TuneConstants.KEY_INVOKE_URL, expectedInvokeUrl);
        mockUrlRequester.setRequestUrlShouldSucceed(true);
        resetReceivedDeeplinkChecks();

        tune.setReferralUrl("https://12sfci8ss.tlnk.io/something?withparams=yes&seomthingelse=2");
        sleep(TuneTestConstants.PARAMTEST_SLEEP);

        assertEquals(0, failedDeeplink.size());
        assertEquals(1, receivedDeeplink.size());
        assertEquals(expectedInvokeUrl, receivedDeeplink.get(0));
    }
}
