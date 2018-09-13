package com.tune;

import java.io.Serializable;
import java.util.HashMap;

import org.json.JSONObject;

/**
 * Event items that can be attached to an event.
 */
public class TuneEventItem implements Serializable {
    private static final long serialVersionUID = 509248377324509251L;

    static final String ITEM = "item";
    static final String QUANTITY = "quantity";
    static final String UNIT_PRICE = "unit_price";
    static final String REVENUE = "revenue";
    static final String ATTRIBUTE1 = "attribute_sub1";
    static final String ATTRIBUTE2 = "attribute_sub2";
    static final String ATTRIBUTE3 = "attribute_sub3";
    static final String ATTRIBUTE4 = "attribute_sub4";
    static final String ATTRIBUTE5 = "attribute_sub5";

    private final String itemName;
    private int quantity;
    private double unitPrice;
    private double revenue;
    private String attribute1;
    private String attribute2;
    private String attribute3;
    private String attribute4;
    private String attribute5;

    /**
     * Constructor.
     * @param itemName Item Name
     */
    public TuneEventItem(String itemName) {
        this.itemName = itemName;
    }

    /**
     * Add a quantity to the event item.
     * @param quantity Quantity
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withQuantity(int quantity) {
        this.quantity = quantity;
        return this;
    }

    /**
     * Add a unit price to the event item.
     * @param unitPrice Unit Price
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withUnitPrice(double unitPrice) {
        this.unitPrice = unitPrice;
        return this;
    }

    /**
     * Add revenue to the event item.
     * @param revenue Revenue
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withRevenue(double revenue) {
        this.revenue = revenue;
        return this;
    }

    /**
     * Add a custom attribute (1) to the event item.
     * @param attribute Attribute
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withAttribute1(String attribute) {
        this.attribute1 = attribute;
        return this;
    }

    /**
     * Add a custom attribute (2) to the event item.
     * @param attribute Attribute
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withAttribute2(String attribute) {
        this.attribute2 = attribute;
        return this;
    }

    /**
     * Add a custom attribute (3) to the event item.
     * @param attribute Attribute
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withAttribute3(String attribute) {
        this.attribute3 = attribute;
        return this;
    }

    /**
     * Add a custom attribute (4) to the event item.
     * @param attribute Attribute
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withAttribute4(String attribute) {
        this.attribute4 = attribute;
        return this;
    }

    /**
     * Add a custom attribute (5) to the event item.
     * @param attribute Attribute
     * @return this {@link TuneEventItem}
     */
    public TuneEventItem withAttribute5(String attribute) {
        this.attribute5 = attribute;
        return this;
    }

    String getAttrStringByName(String name) {
        switch (name) {
            case "itemname":
                return itemName;
            case "quantity":
                return Integer.toString(quantity);
            case "unitPrice":
                return Double.toString(unitPrice);
            case "revenue":
                return Double.toString(revenue);
            case "attribute1":
                return attribute1;
            case "attribute2":
                return attribute2;
            case "attribute3":
                return attribute3;
            case "attribute4":
                return attribute4;
            case "attribute5":
                return attribute5;
            default:
                break;
        }

        return null;
    }

    JSONObject toJson() {
        HashMap<String, String> mapValues = new HashMap<>();

        if (this.itemName != null) {
            mapValues.put(ITEM, this.itemName);
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

        return new JSONObject(mapValues);
    }
}
