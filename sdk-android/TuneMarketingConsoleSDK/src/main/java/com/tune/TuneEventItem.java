package com.tune;

import com.tune.ma.analytics.model.TuneAnalyticsVariable;

import org.json.JSONObject;

import java.io.Serializable;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class TuneEventItem implements Serializable {
    private static final long serialVersionUID = 509248377324509251L;

    public static final String ITEM = "item";
    public static final String QUANTITY = "quantity";
    public static final String UNIT_PRICE = "unit_price";
    public static final String UNIT_PRICE_CAMEL = "unitPrice";
    public static final String REVENUE = "revenue";
    public static final String ATTRIBUTE1 = "attribute_sub1";
    public static final String ATTRIBUTE2 = "attribute_sub2";
    public static final String ATTRIBUTE3 = "attribute_sub3";
    public static final String ATTRIBUTE4 = "attribute_sub4";
    public static final String ATTRIBUTE5 = "attribute_sub5";

    public String itemname;
    public int quantity;
    public double unitPrice;
    public double revenue;
    public String attribute1;
    public String attribute2;
    public String attribute3;
    public String attribute4;
    public String attribute5;

    public Set<TuneAnalyticsVariable> tags = new HashSet<TuneAnalyticsVariable>();

    private Set<String> addedTags = new HashSet<String>();

    private static final List<String> invalidTags = Arrays.asList(
            ITEM,
            QUANTITY,
            UNIT_PRICE,
            REVENUE,
            ATTRIBUTE1,
            ATTRIBUTE2,
            ATTRIBUTE3,
            ATTRIBUTE4,
            ATTRIBUTE5
    );
    
    public TuneEventItem(String itemname) {
        this.itemname = itemname;
    }
    
    public TuneEventItem withQuantity(int quantity) {
        this.quantity = quantity;
        return this;
    }
    
    public TuneEventItem withUnitPrice(double unitPrice) {
        this.unitPrice = unitPrice;
        return this;
    }
    
    public TuneEventItem withRevenue(double revenue) {
        this.revenue = revenue;
        return this;
    }
    
    public TuneEventItem withAttribute1(String attribute) {
        this.attribute1 = attribute;
        return this;
    }
    
    public TuneEventItem withAttribute2(String attribute) {
        this.attribute2 = attribute;
        return this;
    }
    
    public TuneEventItem withAttribute3(String attribute) {
        this.attribute3 = attribute;
        return this;
    }
    
    public TuneEventItem withAttribute4(String attribute) {
        this.attribute4 = attribute;
        return this;
    }
    
    public TuneEventItem withAttribute5(String attribute) {
        this.attribute5 = attribute;
        return this;
    }
    
    public String getAttrStringByName(String name) {
        if (name.equals("itemname")) return itemname;
        if (name.equals("quantity")) return Integer.toString(quantity);
        if (name.equals("unitPrice")) return Double.toString(unitPrice);
        if (name.equals("revenue")) return Double.toString(revenue);
        if (name.equals("attribute1")) return attribute1;
        if (name.equals("attribute2")) return attribute2;
        if (name.equals("attribute3")) return attribute3;
        if (name.equals("attribute4")) return attribute4;
        if (name.equals("attribute5")) return attribute5;
        
        return null;
    }

    public JSONObject toJson() {
        HashMap<String, String> mapValues = new HashMap<String, String>();

        if (this.itemname != null) {
            mapValues.put(ITEM, this.itemname);
        }
        if (this.quantity != 0) {
            mapValues.put(QUANTITY, Integer.toString(this.quantity));
        }
        if (this.unitPrice != 0) {
            mapValues.put(UNIT_PRICE, Double.toString(this.unitPrice));
        }
        if (this.revenue != 0) {
            mapValues.put(REVENUE, Double.toString(this.revenue));
        }
        if (this.attribute1 != null) {
            mapValues.put(ATTRIBUTE1, this.attribute1);
        }
        if (this.attribute2 != null) {
            mapValues.put(ATTRIBUTE2, this.attribute2);
        }
        if (this.attribute3 != null) {
            mapValues.put(ATTRIBUTE3, this.attribute3);
        }
        if (this.attribute4 != null) {
            mapValues.put(ATTRIBUTE4, this.attribute4);
        }
        if (this.attribute5 != null) {
            mapValues.put(ATTRIBUTE5, this.attribute5);
        }
        // TuneAnalyticsVariables conversion to JSON
        if (!this.tags.isEmpty()) {
            for (TuneAnalyticsVariable tag : tags) {
                mapValues.put(tag.getName(), tag.getValue());
            }
        }

        return new JSONObject(mapValues);
    }
}
