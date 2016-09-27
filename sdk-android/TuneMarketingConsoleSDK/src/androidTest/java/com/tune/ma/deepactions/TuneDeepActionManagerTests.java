package com.tune.ma.deepactions;

import android.app.Activity;

import com.tune.TuneUnitTest;
import com.tune.ma.TuneManager;
import com.tune.ma.deepactions.model.TuneDeepAction;
import com.tune.ma.model.TuneDeepActionCallback;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by willb on 2/1/16.
 */
public class TuneDeepActionManagerTests extends TuneUnitTest {

    private TuneDeepActionManager deepActionManager;

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        deepActionManager = TuneManager.getInstance().getDeepActionManager();
    }

    @Override
    protected void tearDown() throws Exception {
        super.tearDown();

        deepActionManager.clearDeepActions();
    }

    public void testRegisterWithoutRequired() {
        tune.registerDeepAction(null, null, null, null);
        assertEquals(0, deepActionManager.getDeepActions().size());

        // missing name
        tune.registerDeepAction(null, "friendly name", getDefaultData(), getAction());
        assertEquals(0, deepActionManager.getDeepActions().size());

        // missing friendly name
        tune.registerDeepAction("name", null, getDefaultData(), getAction());
        assertEquals(0, deepActionManager.getDeepActions().size());

        // missing default data
        tune.registerDeepAction("name", "friendly name", null, getAction());
        assertEquals(0, deepActionManager.getDeepActions().size());

        // missing action
        tune.registerDeepAction("name", "friendly name", getDefaultData(), null);
        assertEquals(0, deepActionManager.getDeepActions().size());
    }

    public void testRegisterDeepAction() {
        tune.registerDeepAction("Watsky", "nice Watsky", getDefaultData(), getAction());

        TuneDeepAction action = deepActionManager.getDeepAction("Watsky");
        assertNotNull(action);

        assertEquals("nice Watsky", action.getFriendlyName());
        assertEquals("Watsky", action.getActionId());
        assertEquals("vicious", action.getDefaultData().get("flow"));
        assertEquals("MAXVALUE", action.getDefaultData().get("swagger"));
    }

    public void testManagerReturnsList() {
        tune.registerDeepAction("thing1", "oldest thing", getDefaultData(), getAction());
        assertEquals(1, deepActionManager.getDeepActions().size());
        tune.registerDeepAction("thing2", "younger thing", getDefaultData(), getAction());
        assertEquals(2, deepActionManager.getDeepActions().size());
        deepActionManager.clearDeepActions();
        assertEquals(0, deepActionManager.getDeepActions().size());
    }

    public void testExecuteDeepActionInvalidActionName() {
        SomeDeepActionCallbackImplementation callback = new SomeDeepActionCallbackImplementation();
        assertEquals(0, callback.executionCount);

        tune.registerDeepAction("action1", "a deep action", getDefaultData(), callback);

        tune.executeDeepAction(null, "incorrectAction2",  null);
        assertEquals(0, callback.executionCount);
    }

    public void testExecuteDeepActionNullData() {
        SomeDeepActionCallbackImplementation callback = new SomeDeepActionCallbackImplementation();
        assertEquals(0, callback.executionCount);

        tune.registerDeepAction("action1", "a deep action", getDefaultData(), callback);

        tune.executeDeepAction(null, "action1", null);
        assertEquals(1, callback.executionCount);
    }

    public void testExecuteDeepActionEmptyData() {
        SomeDeepActionCallbackImplementation callback = new SomeDeepActionCallbackImplementation();
        assertEquals(0, callback.executionCount);

        tune.registerDeepAction("action1", "a deep action", getDefaultData(), callback);

        tune.executeDeepAction(null, "action1", new HashMap<String, String>());
        assertEquals(1, callback.executionCount);
    }

    public void testExecuteDeepActionNormalStringData() {
        SomeDeepActionCallbackImplementation callback = new SomeDeepActionCallbackImplementation();
        assertEquals(0, callback.executionCount);

        tune.registerDeepAction("action1", "a deep action", getDefaultData(), callback);

        Map<String, String> data = new HashMap<>();
        data.put("key", "def");
        assertEquals("abc", callback.value.toString());
        tune.executeDeepAction(null, "action1", data);
        assertEquals(1, callback.executionCount);
        assertEquals("abcdef", callback.value.toString());
    }

    public void testExecuteDeepActionDataOverride() {
        SomeDeepActionCallbackImplementation callback = new SomeDeepActionCallbackImplementation();
        assertEquals(0, callback.executionCount);

        Map<String, String> defaultData = new HashMap<>();
        defaultData.put("prefix", "abc");
        defaultData.put("key", "key");
        defaultData.put("suffix", "xyz");

        tune.registerDeepAction("action1", "a deep action", defaultData, callback);

        Map<String, String> data = new HashMap<>();
        data.put("suffix", "def");
        assertEquals("abc", callback.value.toString());
        tune.executeDeepAction(null, "action1", data);
        assertEquals(1, callback.executionCount);
        assertEquals("abcabckeydef", callback.value.toString());
    }

    // helper methods //
    private Map<String, String> getDefaultData() {
        Map<String, String> defaultData = new HashMap<>();
        defaultData.put("flow", "vicious");
        defaultData.put("swagger", "MAXVALUE");
        return defaultData;
    }

    private TuneDeepActionCallback getAction() {
        return new SomeDeepActionCallbackImplementation();
    }

    private class SomeDeepActionCallbackImplementation implements TuneDeepActionCallback {
        public int executionCount = 0;
        public StringBuilder value = new StringBuilder("abc");

        @Override
        public void execute(Activity activity, Map<String, String> extraData) {
            ++executionCount;
            if (null != extraData && extraData.containsKey("key")) {
                value.append(extraData.get("key"));
            }

            if (null != extraData && extraData.containsKey("prefix")) {
                value.insert(0, extraData.get("prefix"));
            }

            if (null != extraData && extraData.containsKey("suffix")) {
                value.append(extraData.get("suffix"));
            }
        }
    }
}
