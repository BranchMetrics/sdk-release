//
//  TuneSwizzleBlacklist.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/26/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneSwizzleBlacklist.h"
#import "TuneManager.h"
#import "TuneFileManager.h"
#import "TuneConfigurationKeys.h"
#import "TuneSkyhookCenter.h"
#import "TuneState.h"
#import "TuneUserDefaultsUtils.h"

NSString *const TMABlacklistedViewControllerClassesKey = @"TMABlacklistedViewControllerClasses";

@implementation TuneSwizzleBlacklist

#pragma mark - Initialization

+ (TuneSwizzleBlacklist *)sharedBlacklist {
    static TuneSwizzleBlacklist *blacklist = nil;
    if (!blacklist) {
        blacklist = [[TuneSwizzleBlacklist alloc] init];
    }
    return blacklist;
}

- (id)init {
    if (self = [super init]) {
        [self _reset];
    }
    return self;
}

+ (void)reset {
    [[TuneSwizzleBlacklist sharedBlacklist] _reset];
}

- (void)_reset {
    @try {
        [self buildBaseBlacklistsFromPlist];
        [self updateBlacklistsFromUserDefaults];
    } @catch (NSException *exception) {
        ErrorLog(@"Coudn't build Class BlackList %@", exception.description);
    }
}

+ (BOOL)classIsOnBlackList:(NSString *)className {
    return [[TuneSwizzleBlacklist sharedBlacklist] classIsOnBlackList:className];
}

- (BOOL)classIsOnBlackList:(NSString *)className {
    // Underscore denote Apple classes. Ignore those as well as anything on the blacklist.
    return [className hasPrefix:@"_"] || [_blackList containsObject:className];
}

#pragma mark - Building

- (void)buildBaseBlacklistsFromPlist {
    // Look in the plist for more blacklisted methods
    NSDictionary *localConfiguration = [TuneState localConfiguration];
    
    if (localConfiguration == nil) {
        localConfiguration = @{};
    }
    
    NSMutableSet *blackList = [NSMutableSet setWithArray:[self buildBaseBlacklist]];
    
    if (localConfiguration[TMABlacklistedViewControllerClassesKey]) {
        NSArray *blackListedClasses = localConfiguration[TMABlacklistedViewControllerClassesKey];
        [blackList addObjectsFromArray:blackListedClasses];
    }

    _blackList = [NSSet setWithSet:blackList];
}

- (void)updateBlacklistsFromUserDefaults {
    NSMutableSet *blacklist = _blackList.mutableCopy;
    
    if ([TuneUserDefaultsUtils userDefaultValueforKey:TUNE_SWIZZLE_BLACKLIST_ADDITIONS]!=nil) {
        NSArray *additions = [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_SWIZZLE_BLACKLIST_ADDITIONS];
        [blacklist addObjectsFromArray:additions];
    }
    
    if ([TuneUserDefaultsUtils userDefaultValueforKey:TUNE_SWIZZLE_BLACKLIST_REMOVALS]!=nil) {
        NSArray *removals = [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_SWIZZLE_BLACKLIST_REMOVALS];
        [blacklist minusSet:[NSSet setWithArray:removals]];
    }
    
    _blackList = [NSSet setWithSet:blacklist];
}


#pragma mark - Default Blacklist

- (NSArray *)buildBaseBlacklist {
    return @[@"GKAlertViewController",
             @"ABContactViewController",
             @"EKRecurrenceEndEditItemViewController",
             @"MPAudioVideoRoutingViewController",
             @"EKAlarmEditItemViewController",
             @"MPAudioVideoRoutingTableViewController",
             @"MFMessageComposeViewController",
             @"SUNetworkLockoutViewController",
             @"_GKBubbleFlowOnDemandFormSheetViewController",
             @"GKBubbleFlowRootViewController",
             @"SULockoutViewController",
             @"EKEventAvailabilityEditViewController",
             @"EKEventAttendeesEditViewController",
             @"ABContactGroupPickerViewController",
             @"EKCalendarEditItemViewController",
             @"EKCalendarChooser",
             @"EKCalendarItemEditor",
             @"EKEventEditViewController",@"EKEditItemViewController",
             @"EKEventNotesEditItemViewController",
             @"EKEventDateEditItemViewController",
             @"SUReviewsListingViewController",
             @"MFGroupDetailViewController",
             @"SUComposeReviewViewController",
             @"EKRecurrenceTypeEditItemViewController",
             @"SKUIIPadSearchViewController",
             @"SKUICountdownViewController",
             @"EKEventViewController",
             @"SBFWallpaperPreviewViewController",
             @"EKEventDetailExtendedNotesViewController",
             @"EKIdentityViewController",
             @"SLTwitterComposeViewController",
             @"SKUIComposeReviewFormViewController",
             @"EKUnknownIdentityViewController",
             @"SKUIComposeReviewViewController",
             @"EKAttendeesListViewController",
             @"MKSmallCalloutViewController",
             @"ACUISetupViewController",
             @"ABAccountsAndGroupsViewController",
             @"SLComposeServiceViewController",
             @"ACUIDataclassConfigurationViewController",
             @"ACUIAddMailAccountViewController",
             @"MPAudioAndSubtitlesController",
             @"ACUIIdentityPickerViewController",
             @"ABAbstractViewController",
             @"SLSheetContainerViewController",
             @"_ABPeoplePickerNavigationController",
             @"UIWebSelectTableViewController",
             @"SKProductPageViewController",
             @"TPPortraitOnlyNavigationController",
             @"SLMicroBlogMentionsViewController",
             @"MFFromAddressViewController",
             @"SLSheetRootViewController",
             @"SLMicroBlogAccountsTableViewController",
             @"MFSearchResultsViewController",
             @"RUIPage",
             @"SKUIITunesStoreUIPageViewController",
             @"SLFacebookLoginInfoViewController",
             @"GKCollectionViewController",
             @"MFMailComposeController",
             @"PKServiceAddPassesViewController",
             @"SUPreviewOverlayStorePageViewController",
             @"PKAddPassesViewController",
             @"PKRemoteAddPassesViewController",
             @"SUPreviewOverlayViewController",
             @"GKViewController",
             @"TPStarkInCallViewController",
             @"GKNavigationController",
             @"SKUIWishlistViewController",
             @"SUMoreNavigationController",
             @"MPRotatingViewController",
             @"SUReportConcernViewController",
             @"SKUIItemGridViewController",
             @"PKCodeAcquisitionViewController",
             @"PKPassPickerViewController",
             @"SKUIItemListTableViewController",
             @"SKUIAccountButtonsViewController",
             @"SLSheetNavigationController",
             @"MPMediaPickerController",
             @"UIReferenceLibraryViewController",
             @"MPRemoteMediaPickerController",
             @"SUSKUIStorePageViewController",
             @"GKMultiplayerViewController",
             @"RemoteUIWebViewController",
             @"GKTurnBasedMatchDetailViewController",
             @"SKUIIPadChartsViewController",
             @"MPAbstractAlternateTracksViewController",
             @"_ADRemoteViewController",
             @"SUMoreListController",
             @"SKUIChartsViewController",
             @"PKPassGroupsViewController",
             @"SKUIIPhoneChartsViewController",
             @"MPMoviePlayerViewController",
             @"GKMultiplayerP2PViewController",
             @"SLMicroBlogComposeViewController",
             @"GKTurnBasedInviteViewController",
             @"SKStorePageViewController",
             @"SLWeiboComposeViewController",
             @"SKRemoteStorePageViewController",
             @"GKBubbleDetailViewController",
             @"_SBFMagicWallpaperPreviewViewController",
             @"SKUIIPhoneSlideshowViewController",
             @"SLFacebookAlbumChooserViewController",
             @"SKUIFlowcaseViewController",
             @"SKUIShowcaseViewController",
             @"SLFacebookVideoOptionsViewController",
             @"SLSheetPlaceViewController",
             @"SLComposeViewController",
             @"GKPeerPickerViewController",
             @"KeychainSyncTextEntryController",
             @"MPViewController",
             @"SKUIIncompatibleAppViewController",
             @"SLFacebookAudienceTableViewController",
             @"MPVideoViewController",
             @"UIPageViewController",
             @"MPAlternateTracksViewController",
             @"SLFacebookComposeViewController",
             @"SLRemoteComposeViewController",
             @"SKUICategoryTableViewController",
             @"UIPrintPaperViewController",
             @"PSUsageBundleDetailController",
             @"SUStorePageViewController",
             @"MPVideoChaptersViewController",
             @"SUTableViewController",
             @"UIPrintRangeViewController",
             @"SKStoreProductViewController",
             @"MCBrowserViewController",
             @"SKRemoteProductViewController",
             @"SKUIGalleryPaneViewController",
             @"SKUIGalleryViewController",
             @"SKComposeReviewViewController",
             @"SLTencentWeiboComposeViewController",
             @"SUTabBarController",
             @"SKRemoteComposeReviewViewController",
             @"SUViewController",
             @"UIPrintStatusJobsViewController",
             @"SUNavigationController",
             @"SKUIApplicationLicenseViewController",
             @"UIActivityGroupListViewController",
             @"UIPrintingProgressViewController",
             @"UITableViewController",
             @"SUStructuredPageGroupedViewController",
             @"SKUILockupSwooshViewController",
             @"SKUIBrickSwooshViewController",
             @"SKUISwooshArrayViewController",
             @"TPSetPINViewController",
             @"UIPrinterSetupDisplayPINViewController",
             @"ACUIAccountCollectionViewController",
             @"UIPrinterSetupPINViewController",
             @"SKUIIPhoneSearchViewController",
             @"UIPrinterSetupConfigureViewController",
             @"ACUIViewController",
             @"QLAirPlayViewController",
             @"ACUIAddOtherAccountsViewController",
             @"ACUIAddAccountViewController",
             @"QLArchiveTableViewController",
             @"SKUIProductPageDetailsViewController",
             @"SKUIProductPageActivityViewController",
             @"SKUIProductPageHeaderViewController",
             @"SKUIProductPageInformationViewController",
             @"SKUIProductPagePlaceholderViewController",
             @"SKUISwooshViewController",
             @"QLGenericDisplayBundle",
             @"QLWebViewDisplayBundle",
             @"SKUIDeveloperInfoViewController",
             @"UIPrintStatusViewController",
             @"UIImagePickerController",
             @"GKWelcomeViewController",
             @"SKUIReviewsFacebookViewController",
             @"UIPrintStatusTableViewController",
             @"PSEditableListController",
             @"UIPrinterBrowserViewController",
             @"SKUIReviewsHistogramViewController",
             @"UIPrintPanelTableViewController",
             @"ABVibrationPickerViewController",
             @"SUMediaPlayerViewController",
             @"PSRootController",
             @"ABVibrationPickerController",
             @"PSSetupController",
             @"SUSearchRootStorePageViewController",
             @"ABUnknownPersonViewController_Modern",
             @"ABUnknownPersonViewController",
             @"QLPreviewViewController",
             @"SUDownloadsViewController",
             @"CertInfoTrustDetailsViewController",
             @"SUDownloadsTableViewController",
             @"QLPreviewPageViewController",
             @"SUDownloadsGridViewController",
             @"QLRemotePreviewContentController",
             @"SKUIProductPageReviewsViewController",
             @"PSLargeTextController",
             @"ABTonePickerViewController",
             @"QLPreviewContentController",
             @"DevicePINController",
             @"ABTranslucentNavigationController",
             @"SUShowcaseViewController",
             @"DevicePINSetupController",
             @"QLServicePreviewContentController",
             @"ABTonePickerController",
             @"CertInfoCertificateDetailsController",
             @"SKUIProductPageTableViewController",
             @"GKRootlessActivityViewController",
             @"CertInfoSheetViewController",
             @"PSSplitViewController",
             @"GKActivityProxyRemoteViewController",
             @"SKUINetworkErrorViewController",
             @"SKUIIPhoneProductPageViewController",
             @"SKUIDismissingProductViewController",
             @"ABStarkGroupsViewController",
             @"CertInfoTrustSummaryController",
             @"SKUIViewController",
             @"GLKViewController",
             @"ABStarkContactViewController",
             @"SUActivityViewController",
             @"ABStarkContactsListViewController",
             @"ABStarkContactsBrowserViewController",
             @"SKUIOverlayContainerViewController",
             @"GKHostedMatchmakerViewController",
             @"UIPrintActivityWrapperNavigationController",
             @"GKMatchmakerViewController",
             @"GKRemoteMatchmakerViewController",
             @"SKUIMenuViewController",
             @"PSListController",
             @"UIActivityViewController",
             @"QLPreviewController",
             @"UIKeyboardCandidateGridCollectionViewController",
             @"UIWebDateTimePopoverViewController",
             @"PSViewController",
             @"ABSocialProfileServicePickerViewController",
             @"ABSocialProfileServicePickerController",
             @"SKUIScreenshotsViewController",
             @"ABSimpleTextInputViewController",
             @"QLDisplayBundle",
             @"KeychainSyncSetupController",
             @"ABServicePickerViewController",
             @"SKUISlideshowItemViewController",
             @"GKHostedAuthenticateViewController",
             @"KeychainSyncSecurityCodeController",
             @"PSDetailController",
             @"SUOverlayBackgroundViewController",
             @"GKRemoteSignInViewController",
             @"SKUIIPadProductPageViewController",
             @"SKUISlideshowViewController",
             @"SUOverlayViewController",
             @"PSListItemsController",
             @"SUSplitViewController",
             @"SKUIGiftViewController",
             @"EKShareeViewController",
             @"ABPropertyPickerViewController",
             @"SBUIEmergencyCallServiceViewController",
             @"SKUIGiftComposeViewController",
             @"SBUIStarkHomeScreenBackgroundProviderViewController",
             @"SUImageViewController",
             @"_SBUIWidgetViewController",
             @"SBUIEmergencyCallHostViewController",
             @"_SBUISwitcherPageServiceViewController",
             @"EKReminderLocationMapViewController",
             @"SBUIRemoteAlertServiceViewController",
             @"SKUIBannerViewController",
             @"KeychainSyncSMSVerificationController",
             @"SKUIGiftThemePickerViewController",
             @"KeychainSyncPhoneNumberController",
             @"PSInternationalLanguageController",
             @"UIPageController",
             @"PSAppListController",
             @"CertInfoCertificateListController",
             @"SUNativeScriptMenuViewController",
             @"EKShareePickerViewController",
             @"SUMenuViewController",
             @"TWTweetComposeViewController",
             @"SKUIGiftConfirmViewController",
             @"SUNavigationMenuViewController",
             @"PopBackListItemsController",
             @"ABPickerViewController",
             @"GKLoadableContentViewController",
             @"EKReminderLocationPicker",
             @"PSInternationalController",
             @"SUSimpleMenuViewController",
             @"PSInternationalLanguageSetupController",
             @"ABPickerController",
             @"PSLocaleController",
             @"KeychainSyncAdvancedSecurityCodeController",
             @"ABPersonViewControllerHelperNavigationController",
             @"DiagnosticDataController",
             @"ABPersonViewController",
             @"ProblemReportingController",
             @"ProblemReportingAboutDiagnosticsController",
             @"GKSignInViewController",
             @"ABPersonViewController_Modern",
             @"GKTurnBasedMatchmakerViewController",
             @"SBUISlidingFullscreenAlertController",
             @"PSAccountSecurityController",
             @"KeychainSyncDevicePINController",
             @"SBUIFullscreenAlertController",
             @"EKTimeZoneViewController",
             @"PSKeychainSyncViewController",
             @"SKUISearchViewController",
             @"GKHostedTurnBasedViewController",
             @"PSAboutTextSheetViewController",
             @"GKComposeRemoteViewController",
             @"PSAboutHTMLSheetViewController",
             @"SUItemTableViewController",
             @"GKRemoteTurnBasedViewController",
             @"GKFriendRequestComposeViewController",
             @"GKComposeHostedViewController",
             @"CalendarInvitationWrapperController",
             @"UIBookViewController",
             @"EKReminderEditor",
             @"EKEventEditor",
             @"GKRemoteUINavigationController",
             @"GKHostedViewController",
             @"CalendarPublishingActivityViewController",
             @"GKRemoteViewController",
             @"EKReminderDueDateEditViewController",
             @"GKHostedGameCenterViewController",
             @"GKGameCenterViewController",
             @"SKUIGiftResultViewController",
             @"GKRemoteGameCenterViewController",
             @"EKReminderPriorityEditViewController",
             @"GKTurnsViewController",
             @"EKCalendarEditor",
             @"SUGridViewController",
             @"ABPeoplePickerServiceViewController",
             @"ABPeoplePickerNavigationController",
             @"EKEventAttachmentEditViewController",
             @"ABAccountsAndGroupsNavigationController",
             @"SKUIStorePageViewController",
             @"SKUIGiftStepViewController",
             @"ABPeoplePickerHostViewController",
             @"EKReminderViewController",
             @"GKAchievementViewController",
             @"ABNewPersonViewController",
             @"GKLeaderboardViewController",
             @"ABNewPersonViewController_Modern",
             @"ABMultipleImagePickerViewController",
             @"MFMailComposePlaceholderViewController",
             @"MFMailComposeRemoteViewController",
             @"MPFullScreenTransitionViewController",
             @"MPAlternateTracksContainerViewController",
             @"EKICSPreviewListController",
             @"UIFallbackCompatibleViewController",
             @"UIWebFileUploadPanel",
             @"GKTabBarController",
             @"SKUIRedeemResultsViewController",
             @"SKUIRedeemViewController",
             @"UIFileUploadFallbackRootViewController",
             @"GKBasicCollectionViewController",
             @"MFMailComposeCorecipientViewController",
             @"SKUIRedeemStepViewController",
             @"SKUIRedeemInputViewController",
             @"_GKBubbleFlowPseudoModalViewController",
             @"MPInlineVideoFullscreenViewController",
             @"SKUIRedeemCameraViewController",
             @"UIStatusBarViewController",
             @"ABMembersViewController",
             @"SUStructuredPageViewController",
             @"GKSimpleComposeController",
             @"UIZoomViewController",
             @"UISplitViewController",
             @"GKGameInviteComposeController",
             @"GKHostedChallengeIssueController",
             @"MPAbstractFullScreenVideoViewController",
             @"SKUIDonationStepViewController",
             @"GKChallengeComposeController",
             @"GKRemoteChallengeIssueViewController",
             @"SKUIDonationViewController",
             @"SKUIBackdropContentViewController",
             @"UIMoreNavigationController",
             @"UIMoreListController",
             @"SKUIDonationAmountViewController",
             @"ABLabelPickerController",
             @"ABLabelPickerViewController",
             @"GKMasterDetailViewController",
             @"_GKSplitViewDetailPlaceholderViewController",
             @"SKUIDonationResultViewController",
             @"UISnapshotModalViewController",
             @"UIVideoEditorController",
             @"ABInstantMessageServicePickerViewController",
             @"UINavigationController",
             @"ABInstantMessagePickerController",
             @"UITabBarController",
             @"EKDayViewController",
             @"UICollectionViewController",
             @"GKTurnBasedMatchesViewController",
             @"SKUIGallerySwooshViewController",
             @"GKPlayerPickerViewController",
             @"UIActivityGroupViewController",
             @"UIFullScreenViewController",
             @"GKChallengesPickerViewController",
             @"GKInvitePickerViewController",
             @"MFMailComposeInternalViewController",
             @"SUPlaceholderViewController",
             @"SUAccountViewController",
             @"EKCalendarShareePicker",
             @"ABDatePickerViewController",
             @"SKUIQuicklinksViewController",
             @"MFMailComposeViewController",
             @"EKDayPreviewController",
             @"ABCountryPickerViewController",
             @"SUWebViewController",
             @"ABCountryPickerController",
             @"EKEventAttendeePicker",
             @"GKBaseComposeController",
             @"CalendarInvitationPopoverWrapperController",
             @"ABPeoplePickerNavigationController",
             @"AROverlayViewController",
             @"IIViewDeckController",
             @"ARManager",
             @"_UIAlertShimPresentingViewController"];
}

@end
