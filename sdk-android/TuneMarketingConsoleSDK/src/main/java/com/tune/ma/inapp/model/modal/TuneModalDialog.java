package com.tune.ma.inapp.model.modal;

import android.app.Activity;
import android.app.Dialog;
import android.view.Window;

import com.tune.R;

/**
 * Created by johng on 6/6/17.
 */

public class TuneModalDialog extends Dialog {
    private Activity activity;
    private TuneModalLayout layout;

    public TuneModalDialog(Activity activity, TuneModalLayout layout) {
        super(activity, R.style.TuneModalTheme);

        this.activity = activity;
        this.layout = layout;

        setCanceledOnTouchOutside(false);
        getWindow().requestFeature(Window.FEATURE_NO_TITLE);

        setContentView(this.layout);
    }

    public Activity getActivity() {
        return this.activity;
    }

    public TuneModalLayout getLayout() {
        return this.layout;
    }
}
