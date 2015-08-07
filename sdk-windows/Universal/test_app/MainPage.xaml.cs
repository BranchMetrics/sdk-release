using System;
using System.Collections.Generic;
using System.Diagnostics;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;



using MobileAppTracking;

// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234238

namespace MATWindows81TestApp
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Page
    {
        DispatcherTimer newTimer;
        int counter = 99999999;
        MobileAppTracker mat;

        public MainPage()
        {
            newTimer = new DispatcherTimer();
            newTimer.Interval = TimeSpan.FromTicks(1);
            newTimer.Tick += delegate { clock.Content = counter--; };
            newTimer.Start();

            this.InitializeComponent();
            
            // Init MobileAppTracker
            mat = MobileAppTracker.InitializeValues("877", "8c14d6bbe466b65211e781d62e301eec");
            mat.SetAllowDuplicates(true);
            mat.SetDebugMode(true);

            MyMATResponse response = new MyMATResponse();
            mat.SetMATResponse(response);
        }

        private void SessionBtn_Click(object sender, RoutedEventArgs e)
        {
            mat.MeasureSession();
        }

        private void ActionBtn_Click(object sender, RoutedEventArgs e)
        {
            MATEventItem item1 = new MATEventItem("test item");
            List<MATEventItem> items = new List<MATEventItem>();
            items.Add(item1);
            mat.MeasureAction("test event", 0.99, "USD", "123", items);
        }

        private void TestBtn_Click(object sender, RoutedEventArgs e) 
        {
            //Use to test UI responsiveness 
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
