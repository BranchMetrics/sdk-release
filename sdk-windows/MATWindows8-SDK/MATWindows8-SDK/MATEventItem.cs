using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobileAppTracking
{
    public class MATEventItem
    {
        public string item;
        public int quantity;
        public double unit_price;
        public double revenue;

        public string attribute_sub1;
        public string attribute_sub2;
        public string attribute_sub3;
        public string attribute_sub4;
        public string attribute_sub5;

        public MATEventItem(string item, int quantity = 0, double unit_price = 0, double revenue = 0,
            string sub1 = "", string sub2 = "", string sub3 = "", string sub4 = "", string sub5 = "")
        {
            this.item = item;
            this.quantity = quantity;
            this.unit_price = unit_price;
            this.revenue = revenue;
            this.attribute_sub1 = sub1;
            this.attribute_sub2 = sub2;
            this.attribute_sub3 = sub3;
            this.attribute_sub4 = sub4;
            this.attribute_sub5 = sub5;
        }
    }
}
