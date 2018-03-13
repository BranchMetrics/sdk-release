package com.tune;

import com.tune.ma.TuneManager;

/**
 * Created by johng on 8/1/16.
 */
public class TuneDebugUtilities {
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

        TuneDebugLog.w("forceSetUserInSegmentId is set, do not release with this enabled!!");
        TuneManager.getInstance().getPlaylistManager().forceSetUserInSegmentId(segmentId, isInSegment);
    }
}
