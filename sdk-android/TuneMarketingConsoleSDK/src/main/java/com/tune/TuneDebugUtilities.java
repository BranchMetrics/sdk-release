package com.tune;

import com.tune.ma.TuneManager;
import com.tune.ma.utils.TuneDebugLog;

/**
 * Created by johng on 8/1/16.
 */
public class TuneDebugUtilities {
    /**
     * Turns debug mode on or off, under tag "TUNE".
     *
     * Additionally, setting this to 'true' will cause two exceptions to be thrown to aid in debugging the IAM configuration.
     * Normally IAM will log an error to the console when you misconfigure or misuse a method, but this way an exception is thrown to
     * quickly and explicitly find what is misconfigured.
     *
     *  - TuneIAMNotEnabledException: This will be thrown if you use a IAM method without IAM enabled.
     *  - TuneIAMConfigurationException: This will be thrown if the arguments passed to an IAM method are invalid. The exception message will have more details.
     *
     * @param enableDebug whether to enable debug output
     */
    public static void setDebugMode(boolean enableDebug) {
        if (Tune.getInstance() != null) {
            Tune.getInstance().setDebugMode(enableDebug);
        }
    }

    /**
     * Sets the status of the user in the given segment, for testing {@link Tune#isUserInSegmentId(String)} or {@link Tune#isUserInAnySegmentIds(java.util.List)}
     * Only affects segment status locally, for testing. Does not update segments server-side.
     * This call should be removed prior to shipping to production.
     * @param segmentId Segment to modify status for
     * @param isInSegment Status to modify of whether user is in the segment
     */
    public static void forceSetUserInSegmentId(String segmentId, boolean isInSegment) {
        if (TuneManager.getPlaylistManagerForUser("forceSetUserInSegmentId") == null) {
            return;
        }

        TuneDebugLog.w(TuneConstants.TAG, "forceSetUserInSegmentId is set, do not release with this enabled!!");
        TuneManager.getInstance().getPlaylistManager().forceSetUserInSegmentId(segmentId, isInSegment);
    }
}
