using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

using MobileAppTracking;


// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234238

namespace MATWindows8TestApp
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Page
    {
        private MobileAppTracker mobileAppTracker;

        public MainPage()
        {
            this.InitializeComponent();

            // Init MobileAppTracker
            mobileAppTracker = new MobileAppTracker("877", "8c14d6bbe466b65211e781d62e301eec");
            mobileAppTracker.AllowDuplicates = true;
            mobileAppTracker.DebugMode = true;

            MyMATResponse response = new MyMATResponse();
            mobileAppTracker.SetMATResponse(response);
        }

        private void SessionBtn_Click(object sender, RoutedEventArgs e)
        {
            mobileAppTracker.MeasureSession();
        }

        private void ActionBtn_Click(object sender, RoutedEventArgs e)
        {
            MATEventItem item1 = new MATEventItem("test item");
            List<MATEventItem> items = new List<MATEventItem>();
            items.Add(item1);
            mobileAppTracker.MeasureAction("test event", 0.99, "USD", "123", items);
        }
    }

    public class MyMATResponse : MATResponse
    {
        public void DidSucceedWithData(string response)
        {
            Debug.WriteLine("We got server response " + response);
        }

        public void DidFailWithError(string error)
        {
            Debug.WriteLine("We got MAT failure " + error);
        }

        public void EnqueuedActionWithRefId(string refId)
        {
            Debug.WriteLine("Enqueued request with ref id " + refId);
        }
    }
}
