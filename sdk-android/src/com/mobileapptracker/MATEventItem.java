package com.mobileapptracker;

import java.util.HashMap;

import org.json.JSONObject;

public class MATEventItem {
    public String itemname = null;
    public int quantity = 0;
    public double unitPrice = 0;
    public double revenue = 0;
    public String attribute_sub1 = null;
    public String attribute_sub2 = null;
    public String attribute_sub3 = null;
    public String attribute_sub4 = null;
    public String attribute_sub5 = null;
    
    public MATEventItem(String itemname, int quantity, double unitPrice, double revenue) {
        this.itemname = itemname;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.revenue = revenue;
    }
    
    public MATEventItem(String itemname, String att1, String att2, String att3, String att4, String att5) {
        this.itemname = itemname;
        this.attribute_sub1 = att1;
        this.attribute_sub2 = att2;
        this.attribute_sub3 = att3;
        this.attribute_sub4 = att4;
        this.attribute_sub5 = att5;
    }
    
    public MATEventItem(String itemname, int quantity, double unitPrice, double revenue, String att1, String att2, String att3, String att4, String att5) {
        this.itemname = itemname;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.revenue = revenue;
        this.attribute_sub1 = att1;
        this.attribute_sub2 = att2;
        this.attribute_sub3 = att3;
        this.attribute_sub4 = att4;
        this.attribute_sub5 = att5;
    }
    
    public JSONObject toJSON() {
        HashMap<String, String> mapValues = new HashMap<String, String>();
        
        if (this.itemname != null) {
            mapValues.put("item", this.itemname);
        }
        mapValues.put("quantity", Integer.toString(this.quantity));
        mapValues.put("unit_price", Double.toString(this.unitPrice));
        mapValues.put("revenue", Double.toString(this.revenue));
        if (this.attribute_sub1 != null) {
            mapValues.put("attribute_sub1", this.attribute_sub1);
        }
        if (this.attribute_sub2 != null) {
            mapValues.put("attribute_sub2", this.attribute_sub2);
        }
        if (this.attribute_sub3 != null) {
            mapValues.put("attribute_sub3", this.attribute_sub3);
        }
        if (this.attribute_sub4 != null) {
            mapValues.put("attribute_sub4", this.attribute_sub4);
        }
        if (this.attribute_sub5 != null) {
            mapValues.put("attribute_sub5", this.attribute_sub5);
        }
        
        return new JSONObject(mapValues);
    }
    
    public String getAttrStringByName(String name)
    {
    	if (name.equals("itemname")) return itemname;
    	if (name.equals("quantity")) return Integer.toString(quantity);
    	if (name.equals("unitPrice")) return Double.toString(unitPrice);
    	if (name.equals("revenue")) return Double.toString(revenue);
    	if (name.equals("attribute_sub1")) return attribute_sub1;
    	if (name.equals("attribute_sub2")) return attribute_sub2;
    	if (name.equals("attribute_sub3")) return attribute_sub3;
    	if (name.equals("attribute_sub4")) return attribute_sub4;
    	if (name.equals("attribute_sub5")) return attribute_sub5;

    	return null;
    }
}
