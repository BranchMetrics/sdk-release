using System.Runtime.Serialization;

namespace MobileAppTracking
{
    [DataContract]
    public class MATEventItem
    {
        [DataMember]
        public string item;
        [DataMember]
        public int quantity;
        [DataMember]
        public double unit_price;
        [DataMember]
        public double revenue;

        [DataMember]
        public string attribute_sub1;
        [DataMember]
        public string attribute_sub2;
        [DataMember]
        public string attribute_sub3;
        [DataMember]
        public string attribute_sub4;
        [DataMember]
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
