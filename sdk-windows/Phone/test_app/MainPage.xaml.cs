using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using MATPhone8TestApp.Resources;

using MobileAppTracking;
using System.Threading;
using System.Windows.Threading;

namespace MATPhone8TestApp
{
    public partial class MainPage : PhoneApplicationPage
    {
        DispatcherTimer newTimer;

        // Constructor
        public MainPage()
        {
            InitializeComponent();

            newTimer = new DispatcherTimer();
            newTimer.Interval = TimeSpan.FromTicks(1);
            newTimer.Tick += OnTimerTick;
            newTimer.Start();

            MobileAppTracker.Instance.InitializeValues("877", "8c14d6bbe466b65211e781d62e301eec");
            MobileAppTracker.Instance.SetPackageName("com.hasofferstestapp");
            MobileAppTracker.Instance.SetAllowDuplicates(true);
            MobileAppTracker.Instance.SetDebugMode(true);

            MyMATResponse response = new MyMATResponse();
            MobileAppTracker.Instance.SetMATResponse(response);
        }

        private void SessionBtn_Click(object sender, RoutedEventArgs e)
        {
            MobileAppTracker.Instance.MeasureSession();
        }

        private void ActionBtn_Click(object sender, RoutedEventArgs e)
        {
            MATEventItem item1 = new MATEventItem("test item");
            List<MATEventItem> items = new List<MATEventItem>();
            items.Add(item1);
            MobileAppTracker.Instance.MeasureAction("test event", 0.99, "USD", "123", items);
        }

        private void TestBtn_Click(object sender, RoutedEventArgs e)
        {
            int i = 0;
            while (i < 10000)
            i++;
            Debug.WriteLine("Side task computed that i = " + i);
        }

        int counter = 999999999;
        void OnTimerTick(Object sender, EventArgs args)
        {
            counter--;
            if (counter < 0)
            {
                newTimer.Stop();
                counter = 60;
            }
            else
            {
                clock.Text = counter.ToString();
            }
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