using System;

namespace MobileAppTracking
{
    public class MATEventItem : Object
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

        public override bool Equals(Object obj)
        {
            // If parameter is null return false.
            if (obj == null)
            {
                return false;
            }

            // If parameter cannot be cast to MATEventItem return false.
            MATEventItem p = obj as MATEventItem;
            if ((Object)p == null)
            {
                return false;
            }

            // Return true if the fields match:
            return (item.Equals(p.item) &&
                    quantity.Equals(p.quantity) &&
                    unit_price.Equals(p.unit_price) &&
                    revenue.Equals(p.revenue) &&
                    attribute_sub1.Equals(p.attribute_sub1) &&
                    attribute_sub2.Equals(p.attribute_sub2) &&
                    attribute_sub3.Equals(p.attribute_sub3) &&
                    attribute_sub4.Equals(p.attribute_sub4) &&
                    attribute_sub5.Equals(p.attribute_sub5));
        }

        public override int GetHashCode()
        {
            return base.GetHashCode();
        }
    }
}