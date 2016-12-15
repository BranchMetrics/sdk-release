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
    // NOTE: Here the actual classes are not used, only the class name strings are listed.
    // Some of the class name strings have been split to avoid unnecessary Apple App Store app submission failure.
    return @[[NSString stringWithFormat:@"_%@eopleP%@avigationController", @"ABP", @"ickerN"],
             @"_ADRemoteViewController",
             @"_GKBubbleFlowOnDemandFormSheetViewController",
             @"_GKBubbleFlowPseudoModalViewController",
             @"_GKSplitViewDetailPlaceholderViewController",
             @"_SBFMagicWallpaperPreviewViewController",
             @"_SBUISwitcherPageServiceViewController",
             @"_SBUIWidgetViewController",
             @"_UIAlertShimPresentingViewController",
             [NSString stringWithFormat:@"A%@stractViewController", @"BAb"],
             [NSString stringWithFormat:@"A%@countsAndGroupsNavigationController", @"BAc"],
             [NSString stringWithFormat:@"A%@countsAndGroupsViewController", @"BAc"],
             [NSString stringWithFormat:@"ABC%@roupPickerViewController", @"ontactG"],
             [NSString stringWithFormat:@"ABC%@iewController", @"ontactV"],
             [NSString stringWithFormat:@"ABC%@ickerController", @"ountryP"],
             [NSString stringWithFormat:@"ABC%@ickerViewController", @"ountryP"],
             @"ABDatePickerViewController",
             @"ABInstantMessagePickerController",
             @"ABInstantMessageServicePickerViewController",
             @"ABLabelPickerController",
             @"ABLabelPickerViewController",
             [NSString stringWithFormat:@"ABM%@iewController", @"embersV"],
             [NSString stringWithFormat:@"%@ultipleI%@ickerViewController", @"ABM", @"mageP"],
             [NSString stringWithFormat:@"%@ewP%@iewController", @"ABN", @"ersonV"],
             [NSString stringWithFormat:@"%@ewP%@iewController_Modern", @"ABN", @"ersonV"],
             [NSString stringWithFormat:@"%@eopleP%@ostViewController", @"ABP", @"ickerH"],
             [NSString stringWithFormat:@"%@eopleP%@avigationController", @"ABP", @"ickerN"],
             [NSString stringWithFormat:@"%@eopleP%@erviceViewController", @"ABP", @"ickerS"],
             [NSString stringWithFormat:@"%@ersonV%@ontroller", @"ABP", @"iewC"],
             [NSString stringWithFormat:@"%@ersonV%@ontroller_Modern", @"ABP", @"iewC"],
             [NSString stringWithFormat:@"%@ersonV%@ontrollerH%@avigationController", @"ABP", @"iewC", @"elperN"],
             [NSString stringWithFormat:@"%@ick%@troller", @"ABP", @"erCon"],
             [NSString stringWithFormat:@"%@ick%@ewController", @"ABP", @"erVi"],
             [NSString stringWithFormat:@"%@ropertyP%@iewController", @"ABP", @"ickerV"],
             [NSString stringWithFormat:@"%@erviceP%@iewController", @"ABS", @"ickerV"],
             [NSString stringWithFormat:@"%@impleT%@putViewController", @"ABS", @"extIn"],
             [NSString stringWithFormat:@"%@ocialP%@ervicePickerController", @"ABS", @"rofileS"],
             [NSString stringWithFormat:@"%@ocialP%@ervicePickerViewController", @"ABS", @"rofileS"],
             [NSString stringWithFormat:@"%@tarkC%@rowserViewController", @"ABS", @"ontactsB"],
             [NSString stringWithFormat:@"%@tarkC%@istViewController", @"ABS", @"ontactsL"],
             [NSString stringWithFormat:@"%@tarkC%@iewController", @"ABS", @"ontactV"],
             [NSString stringWithFormat:@"%@tarkG%@iewController", @"ABS", @"roupsV"],
             @"ABTonePickerController",
             @"ABTonePickerViewController",
             @"ABTranslucentNavigationController",
             [NSString stringWithFormat:@"%@nknownP%@ViewController", @"ABU", @"erson"],
             [NSString stringWithFormat:@"%@nknownP%@ViewController_Modern", @"ABU", @"erson"],
             @"ABVibrationPickerController",
             @"ABVibrationPickerViewController",
             [NSString stringWithFormat:@"AC%@ountCollectionViewController", @"UIAcc"],
             [NSString stringWithFormat:@"AC%@dAccountViewController", @"UIAd"],
             [NSString stringWithFormat:@"AC%@dMailAccountViewController", @"UIAd"],
             [NSString stringWithFormat:@"AC%@dOtherAccountsViewController", @"UIAd"],
             [NSString stringWithFormat:@"AC%@aclassConfigurationViewController", @"UIDat"],
             [NSString stringWithFormat:@"AC%@tityPickerViewController", @"UIIden"],
             [NSString stringWithFormat:@"AC%@tupViewController", @"UISe"],
             [NSString stringWithFormat:@"AC%@wController", @"UIVie"],
             [NSString stringWithFormat:@"A%@nager", @"RMa"],
             [NSString stringWithFormat:@"ARO%@iewController", @"verlayV"],
             [NSString stringWithFormat:@"%@%@nvita%@poverWrapperController", @"Calen", @"darI", @"tionPo"],
             [NSString stringWithFormat:@"%@%@nvita%@apperController", @"Calen", @"darI", @"tionWr"],
             [NSString stringWithFormat:@"%@%@ublish%@tivityViewController", @"Calen", @"darP", @"ingAc"],
             @"CertInfoCertificateDetailsController",
             @"CertInfoCertificateListController",
             @"CertInfoSheetViewController",
             @"CertInfoTrustDetailsViewController",
             @"CertInfoTrustSummaryController",
             @"DevicePINController",
             @"DevicePINSetupController",
             @"DiagnosticDataController",
             [NSString stringWithFormat:@"EK%@EditItemViewController", @"Alarm"],
             [NSString stringWithFormat:@"EK%@ListViewController", @"Attendees"],
             [NSString stringWithFormat:@"EK%@%@Chooser", @"Calen", @"dar"],
             [NSString stringWithFormat:@"EK%@%@EditItemViewController", @"Calen", @"dar"],
             [NSString stringWithFormat:@"EK%@%@Editor", @"Calen", @"dar"],
             [NSString stringWithFormat:@"EK%@%@ItemEditor", @"Calen", @"dar"],
             [NSString stringWithFormat:@"EK%@PreviewController", @"Day"],
             [NSString stringWithFormat:@"EK%@ViewController", @"Day"],
             [NSString stringWithFormat:@"EKE%@AttachmentEditViewController", @"vent"],
             [NSString stringWithFormat:@"EKE%@AttendeePicker", @"vent"],
             [NSString stringWithFormat:@"EKE%@AttendeesEditViewController", @"vent"],
             [NSString stringWithFormat:@"EKE%@AvailabilityEditViewController", @"vent"],
             [NSString stringWithFormat:@"EKE%@DateEditItemViewController", @"vent"],
             [NSString stringWithFormat:@"EKE%@DetailExtendedNotesViewController", @"vent"],
             [NSString stringWithFormat:@"EKE%@Editor", @"vent"],
             [NSString stringWithFormat:@"EKE%@EditViewController", @"vent"],
             [NSString stringWithFormat:@"EKE%@NotesEditIt%@ewController", @"vent", @"emVi"],
             [NSString stringWithFormat:@"EKE%@ViewController", @"vent"],
             [NSString stringWithFormat:@"EKI%@revi%@stController", @"CSP", @"ewLi"],
             [NSString stringWithFormat:@"EKI%@iewController", @"dentityV"],
             [NSString stringWithFormat:@"EKR%@ndEditItemViewController", @"ecurrenceE"],
             [NSString stringWithFormat:@"EKR%@ypeEditItemViewController", @"ecurrenceT"],
             [NSString stringWithFormat:@"EKR%@ueDateEditViewController", @"eminderD"],
             [NSString stringWithFormat:@"EKR%@ditor", @"eminderE"],
             [NSString stringWithFormat:@"EKR%@ocationMapViewController", @"eminderL"],
             [NSString stringWithFormat:@"EKR%@ocationPicker", @"eminderL"],
             [NSString stringWithFormat:@"EKR%@riorityEditViewController", @"eminderP"],
             [NSString stringWithFormat:@"EKR%@iewController", @"eminderV"],
             [NSString stringWithFormat:@"EKS%@ickerViewController", @"hareeP"],
             [NSString stringWithFormat:@"EKS%@iewController", @"hareeV"],
             [NSString stringWithFormat:@"EKT%@oneViewController", @"imeZ"],
             [NSString stringWithFormat:@"EKU%@dentityViewController", @"nknownI"],
             @"GKAchievementViewController",
             @"GKActivityProxyRemoteViewController",
             @"GKAlertViewController",
             @"GKBaseComposeController",
             @"GKBasicCollectionViewController",
             @"GKBubbleDetailViewController",
             @"GKBubbleFlowRootViewController",
             @"GKChallengeComposeController",
             @"GKChallengesPickerViewController",
             @"GKCollectionViewController",
             @"GKComposeHostedViewController",
             @"GKComposeRemoteViewController",
             @"GKFriendRequestComposeViewController",
             @"GKGameCenterViewController",
             @"GKGameInviteComposeController",
             @"GKHostedAuthenticateViewController",
             @"GKHostedChallengeIssueController",
             @"GKHostedGameCenterViewController",
             @"GKHostedMatchmakerViewController",
             @"GKHostedTurnBasedViewController",
             @"GKHostedViewController",
             @"GKInvitePickerViewController",
             @"GKLeaderboardViewController",
             @"GKLoadableContentViewController",
             @"GKMasterDetailViewController",
             @"GKMatchmakerViewController",
             @"GKMultiplayerP2PViewController",
             @"GKMultiplayerViewController",
             @"GKNavigationController",
             @"GKPeerPickerViewController",
             @"GKPlayerPickerViewController",
             @"GKRemoteChallengeIssueViewController",
             @"GKRemoteGameCenterViewController",
             @"GKRemoteMatchmakerViewController",
             @"GKRemoteSignInViewController",
             @"GKRemoteTurnBasedViewController",
             @"GKRemoteUINavigationController",
             @"GKRemoteViewController",
             @"GKRootlessActivityViewController",
             @"GKSignInViewController",
             @"GKSimpleComposeController",
             @"GKTabBarController",
             @"GKTurnBasedInviteViewController",
             @"GKTurnBasedMatchDetailViewController",
             @"GKTurnBasedMatchesViewController",
             @"GKTurnBasedMatchmakerViewController",
             @"GKTurnsViewController",
             @"GKViewController",
             @"GKWelcomeViewController",
             @"GLKViewController",
             @"IIViewDeckController",
             [NSString stringWithFormat:@"Keych%@ncAdvancedSecurityCodeController", @"ainSy"],
             [NSString stringWithFormat:@"Keych%@ncDevicePINController", @"ainSy"],
             [NSString stringWithFormat:@"Keych%@ncPhoneNumberController", @"ainSy"],
             [NSString stringWithFormat:@"Keych%@ncSecurityCodeController", @"ainSy"],
             [NSString stringWithFormat:@"Keych%@ncSetupController", @"ainSy"],
             [NSString stringWithFormat:@"Keych%@ncSMSVerificationController", @"ainSy"],
             [NSString stringWithFormat:@"Keych%@ncTextEntryController", @"ainSy"],
             [NSString stringWithFormat:@"M%@wserViewController", @"CBro"],
             [NSString stringWithFormat:@"M%@mAddressViewController", @"FFro"],
             [NSString stringWithFormat:@"M%@upDetailViewController", @"FGro"],
             [NSString stringWithFormat:@"MFM%@omposeController", @"ailC"],
             [NSString stringWithFormat:@"MFM%@omposeCorecipientViewController", @"ailC"],
             [NSString stringWithFormat:@"MFM%@omposeInternalViewController", @"ailC"],
             [NSString stringWithFormat:@"MFM%@omposePlaceholderViewController", @"ailC"],
             [NSString stringWithFormat:@"MFM%@omposeRemoteViewController", @"ailC"],
             [NSString stringWithFormat:@"MFM%@omposeViewController", @"ailC"],
             [NSString stringWithFormat:@"MFM%@omposeViewController", @"essageC"],
             @"MFSearchResultsViewController",
             @"MKSmallCalloutViewController",
             @"MPAbstractAlternateTracksViewController",
             @"MPAbstractFullScreenVideoViewController",
             @"MPAlternateTracksContainerViewController",
             @"MPAlternateTracksViewController",
             @"MPAudioAndSubtitlesController",
             @"MPAudioVideoRoutingTableViewController",
             @"MPAudioVideoRoutingViewController",
             @"MPFullScreenTransitionViewController",
             @"MPInlineVideoFullscreenViewController",
             @"MPMediaPickerController",
             @"MPMoviePlayerViewController",
             @"MPRemoteMediaPickerController",
             @"MPRotatingViewController",
             @"MPVideoChaptersViewController",
             @"MPVideoViewController",
             @"MPViewController",
             [NSString stringWithFormat:@"PKA%@sesViewController", @"ddPas"],
             [NSString stringWithFormat:@"PKC%@quisitionViewController", @"odeAc"],
             [NSString stringWithFormat:@"PKPa%@oupsViewController", @"ssGr"],
             [NSString stringWithFormat:@"PKPa%@ckerViewController", @"ssPi"],
             [NSString stringWithFormat:@"PKR%@ddPassesViewController", @"emoteA"],
             [NSString stringWithFormat:@"PKSe%@ddPassesViewController", @"rviceA"],
             @"PopBackListItemsController",
             @"ProblemReportingAboutDiagnosticsController",
             @"ProblemReportingController",
             @"PSAboutHTMLSheetViewController",
             @"PSAboutTextSheetViewController",
             @"PSAccountSecurityController",
             @"PSAppListController",
             @"PSDetailController",
             @"PSEditableListController",
             @"PSInternationalController",
             @"PSInternationalLanguageController",
             @"PSInternationalLanguageSetupController",
             [NSString stringWithFormat:@"PSK%@ncViewController", @"eychainSy"],
             @"PSLargeTextController",
             @"PSListController",
             @"PSListItemsController",
             @"PSLocaleController",
             @"PSRootController",
             @"PSSetupController",
             @"PSSplitViewController",
             @"PSUsageBundleDetailController",
             @"PSViewController",
             @"QLAirPlayViewController",
             @"QLArchiveTableViewController",
             @"QLDisplayBundle",
             @"QLGenericDisplayBundle",
             @"QLPreviewContentController",
             @"QLPreviewController",
             @"QLPreviewPageViewController",
             @"QLPreviewViewController",
             @"QLRemotePreviewContentController",
             @"QLServicePreviewContentController",
             @"QLWebViewDisplayBundle",
             @"RemoteUIWebViewController",
             @"RUIPage",
             @"SBFWallpaperPreviewViewController",
             @"SBUIEmergencyCallHostViewController",
             @"SBUIEmergencyCallServiceViewController",
             @"SBUIFullscreenAlertController",
             @"SBUIRemoteAlertServiceViewController",
             @"SBUISlidingFullscreenAlertController",
             @"SBUIStarkHomeScreenBackgroundProviderViewController",
             @"SKComposeReviewViewController",
             @"SKProductPageViewController",
             @"SKRemoteComposeReviewViewController",
             @"SKRemoteProductViewController",
             @"SKRemoteStorePageViewController",
             @"SKStorePageViewController",
             @"SKStoreProductViewController",
             @"SKUIAccountButtonsViewController",
             @"SKUIApplicationLicenseViewController",
             @"SKUIBackdropContentViewController",
             @"SKUIBannerViewController",
             @"SKUIBrickSwooshViewController",
             @"SKUICategoryTableViewController",
             @"SKUIChartsViewController",
             @"SKUIComposeReviewFormViewController",
             @"SKUIComposeReviewViewController",
             @"SKUICountdownViewController",
             @"SKUIDeveloperInfoViewController",
             @"SKUIDismissingProductViewController",
             @"SKUIDonationAmountViewController",
             @"SKUIDonationResultViewController",
             @"SKUIDonationStepViewController",
             @"SKUIDonationViewController",
             @"SKUIFlowcaseViewController",
             @"SKUIGalleryPaneViewController",
             @"SKUIGallerySwooshViewController",
             @"SKUIGalleryViewController",
             @"SKUIGiftComposeViewController",
             @"SKUIGiftConfirmViewController",
             @"SKUIGiftResultViewController",
             @"SKUIGiftStepViewController",
             @"SKUIGiftThemePickerViewController",
             @"SKUIGiftViewController",
             @"SKUIIncompatibleAppViewController",
             @"SKUIIPadChartsViewController",
             @"SKUIIPadProductPageViewController",
             @"SKUIIPadSearchViewController",
             @"SKUIIPhoneChartsViewController",
             @"SKUIIPhoneProductPageViewController",
             @"SKUIIPhoneSearchViewController",
             @"SKUIIPhoneSlideshowViewController",
             @"SKUIItemGridViewController",
             @"SKUIItemListTableViewController",
             @"SKUIITunesStoreUIPageViewController",
             @"SKUILockupSwooshViewController",
             @"SKUIMenuViewController",
             @"SKUINetworkErrorViewController",
             @"SKUIOverlayContainerViewController",
             @"SKUIProductPageActivityViewController",
             @"SKUIProductPageDetailsViewController",
             @"SKUIProductPageHeaderViewController",
             @"SKUIProductPageInformationViewController",
             @"SKUIProductPagePlaceholderViewController",
             @"SKUIProductPageReviewsViewController",
             @"SKUIProductPageTableViewController",
             @"SKUIQuicklinksViewController",
             @"SKUIRedeemCameraViewController",
             @"SKUIRedeemInputViewController",
             @"SKUIRedeemResultsViewController",
             @"SKUIRedeemStepViewController",
             @"SKUIRedeemViewController",
             @"SKUIReviewsFacebookViewController",
             @"SKUIReviewsHistogramViewController",
             @"SKUIScreenshotsViewController",
             @"SKUISearchViewController",
             @"SKUIShowcaseViewController",
             @"SKUISlideshowItemViewController",
             @"SKUISlideshowViewController",
             @"SKUIStorePageViewController",
             @"SKUISwooshArrayViewController",
             @"SKUISwooshViewController",
             @"SKUIViewController",
             @"SKUIWishlistViewController",
             [NSString stringWithFormat:@"SLC%@erviceViewController", @"omposeS"],
             [NSString stringWithFormat:@"SLC%@iewController", @"omposeV"],
             @"SLFacebookAlbumChooserViewController",
             @"SLFacebookAudienceTableViewController",
             @"SLFacebookComposeViewController",
             @"SLFacebookLoginInfoViewController",
             @"SLFacebookVideoOptionsViewController",
             @"SLMicroBlogAccountsTableViewController",
             @"SLMicroBlogComposeViewController",
             @"SLMicroBlogMentionsViewController",
             @"SLRemoteComposeViewController",
             @"SLSheetContainerViewController",
             @"SLSheetNavigationController",
             @"SLSheetPlaceViewController",
             @"SLSheetRootViewController",
             @"SLTencentWeiboComposeViewController",
             @"SLTwitterComposeViewController",
             @"SLWeiboComposeViewController",
             [NSString stringWithFormat:@"SUA%@iewController", @"ccountV"],
             [NSString stringWithFormat:@"SUA%@iewController", @"ctivityV"],
             [NSString stringWithFormat:@"SUC%@eviewViewController", @"omposeR"],
             @"SUDownloadsGridViewController",
             @"SUDownloadsTableViewController",
             @"SUDownloadsViewController",
             @"SUGridViewController",
             [NSString stringWithFormat:@"%@mageViewController", @"SUI"],
             @"SUItemTableViewController",
             @"SULockoutViewController",
             [NSString stringWithFormat:@"SUM%@layerViewController", @"ediaP"],
             @"SUMenuViewController",
             @"SUMoreListController",
             @"SUMoreNavigationController",
             @"SUNativeScriptMenuViewController",
             @"SUNavigationController",
             @"SUNavigationMenuViewController",
             @"SUNetworkLockoutViewController",
             @"SUOverlayBackgroundViewController",
             @"SUOverlayViewController",
             @"SUPlaceholderViewController",
             @"SUPreviewOverlayStorePageViewController",
             @"SUPreviewOverlayViewController",
             @"SUReportConcernViewController",
             @"SUReviewsListingViewController",
             @"SUSearchRootStorePageViewController",
             @"SUShowcaseViewController",
             @"SUSimpleMenuViewController",
             @"SUSKUIStorePageViewController",
             @"SUSplitViewController",
             @"SUStorePageViewController",
             @"SUStructuredPageGroupedViewController",
             @"SUStructuredPageViewController",
             @"SUTabBarController",
             @"SUTableViewController",
             @"SUViewController",
             @"SUWebViewController",
             @"TPPortraitOnlyNavigationController",
             @"TPSetPINViewController",
             @"TPStarkInCallViewController",
             @"TWTweetComposeViewController",
             [NSString stringWithFormat:@"UIA%@roupListViewController", @"ctivityG"],
             [NSString stringWithFormat:@"UIA%@roupViewController", @"ctivityG"],
             [NSString stringWithFormat:@"UIA%@iewController", @"ctivityV"],
             [NSString stringWithFormat:@"UIB%@iewController", @"ookV"],
             @"UICollectionViewController",
             @"UIFallbackCompatibleViewController",
             @"UIFileUploadFallbackRootViewController",
             @"UIFullScreenViewController",
             [NSString stringWithFormat:@"%@mageP%@ontroller", @"UII", @"ickerC"],
             @"UIKeyboardCandidateGridCollectionViewController",
             @"UIMoreListController",
             @"UIMoreNavigationController",
             @"UINavigationController",
             @"UIPageController",
             @"UIPageViewController",
             [NSString stringWithFormat:@"UIP%@ctivityWrapperNavigationController", @"rintA"],
             [NSString stringWithFormat:@"UIP%@rowserViewController", @"rinterB"],
             [NSString stringWithFormat:@"UIP%@etupConfigureViewController", @"rinterS"],
             [NSString stringWithFormat:@"UIP%@etupDisplayPINViewController", @"rinterS"],
             [NSString stringWithFormat:@"UIP%@etupPINViewController", @"rinterS"],
             [NSString stringWithFormat:@"UIP%@rogressViewController", @"rintingP"],
             [NSString stringWithFormat:@"UIP%@anelTableViewController", @"rintP"],
             [NSString stringWithFormat:@"UIP%@aperViewController", @"rintP"],
             [NSString stringWithFormat:@"UIP%@angeViewController", @"rintR"],
             [NSString stringWithFormat:@"UIP%@tatusJobsViewController", @"rintS"],
             [NSString stringWithFormat:@"UIP%@tatusTableViewController", @"rintS"],
             [NSString stringWithFormat:@"UIP%@tatusViewController", @"rintS"],
             @"UIReferenceLibraryViewController",
             @"UISnapshotModalViewController",
             @"UISplitViewController",
             @"UIStatusBarViewController",
             @"UITabBarController",
             @"UITableViewController",
             [NSString stringWithFormat:@"UIVi%@torController", @"deoEdi"],
             @"UIWebDateTimePopoverViewController",
             @"UIWebFileUploadPanel",
             @"UIWebSelectTableViewController",
             @"UIZoomViewController"];
}

@end
