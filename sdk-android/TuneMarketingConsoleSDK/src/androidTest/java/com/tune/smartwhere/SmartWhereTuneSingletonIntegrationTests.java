package com.tune.smartwhere;

import android.content.Context;

import com.tune.Tune;
import com.tune.TuneTestWrapper;
import com.tune.TuneUnitTest;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;

import org.mockito.ArgumentMatcher;

import java.lang.reflect.Field;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.mockito.Matchers.any;
import static org.mockito.Matchers.anyString;
import static org.mockito.Matchers.argThat;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

public class SmartWhereTuneSingletonIntegrationTests extends TuneUnitTest {
    private TuneSmartWhere mockTuneSmartwhere;
    private TuneSmartwhereConfiguration mockTuneSmartwhereConfiguration;

    @Override
    public void setUp() throws Exception {
        super.setUp();
        shutdownWaitAndRecreatePubQueue();
    }

    @Override
    public void tearDown() throws Exception {
        TuneSmartWhere.instance = null;
        super.tearDown();
    }

    public void testregisterCustomProfileStringWithDefaultCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "testStringName";
        String expectedValue = "defaultString";
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().registerCustomProfileString(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testegisterCustomProfileStringWithDefaultDoesntCallsSmartWhereWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "Name";
        String expectedValue = "defaultString";

        TuneTestWrapper.getInstance().registerCustomProfileString(expectedName, expectedValue);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testregisterCustomProfileNumberIntWithDefaultCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "number name";
        int expectedValue = 10;
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().registerCustomProfileNumber(expectedName, 10);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testregisterCustomProfileNumberIntWithDefaultDoesntCallsSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "another number";

        TuneTestWrapper.getInstance().registerCustomProfileNumber(expectedName, 10);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testregisterCustomProfileNumberDoubleWithDefaultCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "double";
        double expectedValue = 10.2;
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().registerCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testregisterCustomProfileNumberDoubleWithDefaultDoesntCallsSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "no double";

        TuneTestWrapper.getInstance().registerCustomProfileNumber(expectedName, 10.4);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testregisterCustomProfileNumberFloatWithDefaultCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "registerFloat";
        float expectedValue = 99.9f;
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().registerCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testregisterCustomProfileNumberfloatWithDefaultDoesntCallsSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "shouldntbeafloat";

        TuneTestWrapper.getInstance().registerCustomProfileNumber(expectedName, 10.43f);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testsetCustomProfileStringValueCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "setString";
        String expectedValue = "stringvalue";
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().setCustomProfileStringValue(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testsetCustomProfileStringValueDoesntCallSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "dontsetstring";
        String expectedValue = "stringvalue";

        TuneTestWrapper.getInstance().setCustomProfileStringValue(expectedName, expectedValue);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testsetCustomProfileNumberIntCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "setIntNmme";
        int expectedValue = 23;
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().setCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testsetCustomProfileNumberIntDoesntCallSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "noInt";
        int expectedValue = 333;

        TuneTestWrapper.getInstance().setCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testsetCustomProfileNumberDoubleCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "setDoubleName";
        double expectedValue = 23.888;
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().setCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testsetCustomProfileNumberDoubleDoesntCallSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "dontSetDoubleName";
        double expectedValue = 333;

        TuneTestWrapper.getInstance().setCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testsetCustomProfileNumberFloatCallsSmartWhereSetAttributeValueWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "setFloatName";
        float expectedValue = 44.4f;
        TuneAnalyticsVariable expectedAnalyticsVariable = new TuneAnalyticsVariable(expectedName, expectedValue);

        TuneTestWrapper.getInstance().setCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere).setAttributeValueFromAnalyticsVariable(eq(mContext), argThat(new TuneAnalyticsVariableMatcher<TuneAnalyticsVariable>(expectedAnalyticsVariable)));
    }

    public void testsetCustomProfileNumberFloatDoesntCallSmartWhereSetAttributeValueWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "dontSetFloatName";
        float expectedValue = 323.33f;

        TuneTestWrapper.getInstance().setCustomProfileNumber(expectedName, expectedValue);

        verify(mockTuneSmartwhere, never()).setAttributeValueFromAnalyticsVariable(any(Context.class), any(TuneAnalyticsVariable.class));
    }

    public void testclearCustomProfileVariableCallsOnSmartWhereWhenAvailable() throws Exception {
        setMocksToEnableSmartWhere();

        String expectedName = "clear name";

        TuneTestWrapper.getInstance().clearCustomProfileVariable(expectedName);
        verify(mockTuneSmartwhere).clearAttributeValue(mContext, expectedName);
    }

    public void testclearCustomProfileVariableDoesntCallOnSmartWhereWhenNotAvailable() throws Exception {
        setMocksToDisableSmartWhere();

        String expectedName = "clear name";

        TuneTestWrapper.getInstance().clearCustomProfileVariable(expectedName);
        verify(mockTuneSmartwhere, never()).clearAttributeValue(any(Context.class), anyString());
    }

    //  Helper methods
    private void setMocksToEnableSmartWhere() {
        mockTuneSmartwhere = mock(TuneSmartWhere.class);
        mockTuneSmartwhereConfiguration = mock(TuneSmartwhereConfiguration.class);
        TuneSmartWhere.instance = mockTuneSmartwhere;
        doReturn(mockTuneSmartwhereConfiguration).when(mockTuneSmartwhere).getConfiguration();
        doReturn(true).when(mockTuneSmartwhereConfiguration).isPermissionGranted(TuneSmartwhereConfiguration.GRANT_SMARTWHERE_TUNE_EVENTS);
    }

    private void setMocksToDisableSmartWhere() {
        mockTuneSmartwhere = mock(TuneSmartWhere.class);
        mockTuneSmartwhereConfiguration = mock(TuneSmartwhereConfiguration.class);
        TuneSmartWhere.instance = mockTuneSmartwhere;
        doReturn(mockTuneSmartwhereConfiguration).when(mockTuneSmartwhere).getConfiguration();
        doReturn(false).when(mockTuneSmartwhereConfiguration).isPermissionGranted(TuneSmartwhereConfiguration.GRANT_SMARTWHERE_TUNE_EVENTS);
    }

    private class TuneAnalyticsVariableMatcher<T> extends ArgumentMatcher<T> {
        TuneAnalyticsVariable thisObject;

        TuneAnalyticsVariableMatcher(TuneAnalyticsVariable thisObject) {
            this.thisObject = thisObject;
        }

        @Override
        public boolean matches(Object argument) {
            return argument instanceof TuneAnalyticsVariable &&
                    thisObject.getName().equals(((TuneAnalyticsVariable) argument).getName()) &&
                    thisObject.getType().equals(((TuneAnalyticsVariable) argument).getType()) &&
                    thisObject.getValue().equals(((TuneAnalyticsVariable) argument).getValue()) &&
                    thisObject.getHashType().equals(((TuneAnalyticsVariable) argument).getHashType());
        }
    }

    private void shutdownWaitAndRecreatePubQueue() throws InterruptedException {
        tune.getPubQueue().shutdown();
        tune.getPubQueue().awaitTermination(60, TimeUnit.SECONDS);
        Field declaredField =  null;
        try {
            declaredField = Tune.class.getDeclaredField("pubQueue");
            boolean accessible = declaredField.isAccessible();

            declaredField.setAccessible(true);

            Executor exec = Executors.newSingleThreadExecutor();
            declaredField.set(tune, exec);

            declaredField.setAccessible(accessible);

        } catch (NoSuchFieldException
                | SecurityException
                | IllegalArgumentException
                | IllegalAccessException e) {
            e.printStackTrace();
        }
    }
}
