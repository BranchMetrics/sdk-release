package com.tune;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import com.android.installreferrer.api.InstallReferrerClient;
import com.android.installreferrer.api.InstallReferrerStateListener;
import com.android.installreferrer.api.ReferrerDetails;

/**
 * First Run Logic
 * During the First Run of a Tune Instance, there are a series of gates that need to be passed before
 * Tune starts to measure data.  Specifically, we would like for the <i>Install Referrer</i> and the
 * <i>Advertiser Id</i> to be present.
 * <ul>
 * <li>
 *     <b>Note</b> that there are numerous ways, and different timing when each of these values might become available.
 *     In order to accomplish this goal, this class brings all of these together into a single logical object.
 * </li>
 * <li>
 *     <b>Note</b> that beginning with v4.15.0, an additional check using the Google ReferrerDetails service will be used.
 * </li>
 * </ul>
 */
class TuneFirstRunLogic {
    private boolean gotAdvertisingId;
    private boolean gotBroadcastReferrer;
    private boolean gotGoogleReferrer;

    // Wait for the BroadCastReceiver to fire
    private final Object mBroadcastWaitObject;

    // Google Install Referrer Client
    private InstallReferrerClient mInstallReferrerClient;

    // Whether we've already notified the object to stop waiting
    private boolean notifiedWaitObject;

    TuneFirstRunLogic() {
        mBroadcastWaitObject = new Object();
    }

    /**
     * Indicate that an Advertising ID was received.
     */
    void receivedAdvertisingId() {
        gotAdvertisingId = true;
        tryNotifyWaitObject();
    }

    /**
     * Indicate that INSTALL_REFERRER was received via. the Broadcast Receiver.
     */
    void receivedInstallReferrer() {
        gotBroadcastReferrer = true;
        tryNotifyWaitObject();
    }

    /**
     * Indicate that the Google Install Referrer sequence has completed.
     * @param success True if Google Install Referrer information is available, False otherwise.
     */
    void googleInstallReferrerSequenceComplete(boolean success) {
        gotGoogleReferrer = true;
        if (success) {
            // Indicate that the path that needs the Google Referrer is also complete.
            gotBroadcastReferrer = true;
        }
        tryNotifyWaitObject();
    }

    private void tryNotifyWaitObject() {
        synchronized (mBroadcastWaitObject) {
            if (!notifiedWaitObject && gotAdvertisingId && gotGoogleReferrer && gotBroadcastReferrer) {
                mBroadcastWaitObject.notifyAll();
                notifiedWaitObject = true;

                TuneDebugLog.d("FirstRun::COMPLETE");
            }
        }
    }

    /**
     * Wait for First Run Data
     * @param context Context
     * @param timeToWait Number of milliseconds to wait
     */
    void waitForFirstRunData(Context context, int timeToWait) {
        // Start the Google API to get referrer information.
        // If it succeeds, it will unblock the BroadcastReceiver wait.
        // If it fails, we want to fallback to waiting for a BroadcastReceiver.
        TuneDebugLog.d("FirstRun::waitForFirstRunData(START)");
        startInstallReferrerClientConnection(context);

        // Wait for the Broadcast Receiver to unblock
        synchronized (mBroadcastWaitObject) {
            try {
                mBroadcastWaitObject.wait(timeToWait);
            } catch (InterruptedException e) {
                TuneDebugLog.w("FirstRun::waitForFirstRunData() interrupted", e);
            }
        }

        TuneDebugLog.d("FirstRun::waitForFirstRunData(COMPLETE)");
    }

    /**
     * @return True if the FirstRun logic is waiting for more input
     */
    boolean isWaiting() {
        return !notifiedWaitObject;
    }

    // Cancel waiting for First Run Data
    void cancel() {
        synchronized (mBroadcastWaitObject) {
            if (!notifiedWaitObject) {
                mBroadcastWaitObject.notifyAll();
                notifiedWaitObject = true;
            }
        }
    }

    private static final int InstallReferrerResponse_GeneralException = -100;
    private static final int InstallReferrerClientConnectionTimout = 5000;

    private void startInstallReferrerClientConnection(Context context) {
        mInstallReferrerClient = InstallReferrerClient.newBuilder(context).build();

        try {
            mInstallReferrerClient.startConnection(mReferrerStateListener);
        } catch (Exception e) {
            // We have observed a "SecurityException" on a few devices.  Just to be safe, catch everything
            TuneDebugLog.e("FirstRun::Exception", e);
            onInstallReferrerResponseError(InstallReferrerResponse_GeneralException);
        }

        // Create/Start a timeout handler for the case where the callback is never called.
        Handler timeoutHandler = new Handler(Looper.getMainLooper());
        timeoutHandler.postDelayed(new Runnable() {
            public void run() {
                if (!gotGoogleReferrer) {
                    TuneDebugLog.d("FirstRun::Install Referrer Service Callback Timeout");
                    googleInstallReferrerSequenceComplete(false);
                }
            }
        }, InstallReferrerClientConnectionTimout);

    }

    private InstallReferrerStateListener mReferrerStateListener = new InstallReferrerStateListener() {
        @Override
        public void onInstallReferrerSetupFinished(int responseCode) {
            // Note that this callback blocks the Main UI thread until complete.
            TuneDebugLog.d("FirstRun::onInstallReferrerSetupFinished() CODE: " + responseCode);

            if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
                // Best-case Success, Install Referrer is available via. this API.
                onInstallReferrerResponseOK(mInstallReferrerClient);
            } else {
                // Best-case Failure, No Install Referrer info, but the API handled it
                // gracefully.
                onInstallReferrerResponseError(responseCode);
            }
        }

        @Override
        public void onInstallReferrerServiceDisconnected() {
            TuneDebugLog.d("FirstRun::onInstallReferrerServiceDisconnected()");

            // Connection closed by remote service.
            // TODO: implement a retry policy.
            onInstallReferrerResponseError(InstallReferrerClient.InstallReferrerResponse.SERVICE_DISCONNECTED);
        }
    };

    private void onInstallReferrerResponseOK(InstallReferrerClient client) {
        TuneDebugLog.d("FirstRun::onInstallReferrerResponseOK()");
        try {
            ReferrerDetails details = client.getInstallReferrer();
            if (details != null) {
                TuneDebugLog.d("FirstRun::Install Referrer: " + details.getInstallReferrer());

                Tune.getInstance().setInstallReferrer(details.getInstallReferrer());

                long installBeginTimestamp = details.getInstallBeginTimestampSeconds();
                if (installBeginTimestamp != 0) {
                    Tune.getInstance().getTuneParams().setInstallBeginTimestampSeconds(details.getInstallBeginTimestampSeconds());
                }

                long referrerClickTimestamp = details.getReferrerClickTimestampSeconds();
                if (referrerClickTimestamp != 0) {
                    Tune.getInstance().getTuneParams().setReferrerClickTimestampSeconds(referrerClickTimestamp);
                }

                TuneDebugLog.d("FirstRun::Install Referrer Timestamps: [" + referrerClickTimestamp + "," + installBeginTimestamp + "]");
            }

            client.endConnection();
            googleInstallReferrerSequenceComplete(details != null);

        } catch (Exception e) {
            // While a RemoteException needs to be caught per the API signature, we have observed an "IllegalStateException"
            // from a customer.  Attribution will need to come in through the default BroadcastReceiver
            TuneDebugLog.e("FirstRun::ReferrerDetails exception", e);
            onInstallReferrerResponseError(InstallReferrerResponse_GeneralException);
        }
    }

    /**
     * Indicate that an error occurred.
     * Error code descriptions:
     * <ul>
     *     <li>SERVICE_UNAVAILABLE -- Was not possible to connect to the Google Play app service. Maybe it is updating or it's not present on current device.</li>
     *     <li>FEATURE_NOT_SUPPORTED -- Install referrer API not available on current device.  Try checking the broadcast.</li>
     *     <li>DEVELOPER_ERROR -- Error caused by incorrect usage. E.g: Already connecting to the service or Client was already closed and can't be reused.</li>
     * </ul>
     * @param responseCode Response Code
     */
    private void onInstallReferrerResponseError(int responseCode) {
        // Implementation Note:  It doesn't really matter what the error is other than for logging
        // purposes.  If there are any errors, fall back to the BroadcastReceiver for referrer info.
        //
        TuneDebugLog.d("FirstRun::onInstallReferrerResponseError(" + responseCode + ")");
        googleInstallReferrerSequenceComplete(false);
    }
}
