package com.mobileapptracker;

import android.content.Context;


public class MATUser {
    private Context mContext;
    private int age;
    private MATGender gender;
    private boolean existingUser;
    private boolean payingUser;
    private String facebookUserId;
    private String googleUserId;
    private String phoneNumber;
    private String phoneNumberMd5;
    private String phoneNumberSha1;
    private String phoneNumberSha256;
    private String twitterUserId;
    private String userEmail;
    private String userEmailMd5;
    private String userEmailSha1;
    private String userEmailSha256;
    private String userId;
    private String userName;
    private String userNameMd5;
    private String userNameSha1;
    private String userNameSha256;
    
    public MATUser() {
        mContext = MobileAppTracker.getInstance().mContext;
        this.gender = MATGender.UNKNOWN;
        this.payingUser = MATUtils.getBooleanFromSharedPreferences(mContext, MATConstants.KEY_PAYING_USER);
        this.userEmail = MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_USER_EMAIL);
        this.userId = MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_USER_ID);
        this.userName = MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_USER_NAME);
        this.phoneNumber = MATUtils.getStringFromSharedPreferences(mContext, MATConstants.KEY_PHONE_NUMBER);
    }
    
    public MATUser withAge(int age) {
        this.age = age;
        return this;
    }
    
    public MATUser withGender(MATGender gender) {
        this.gender = gender;
        return this;
    }
    
    public MATUser withExistingUser(boolean existingUser) {
        this.existingUser = existingUser;
        return this;
    }
    
    public MATUser withPayingUser(boolean payingUser) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_PAYING_USER, payingUser);
        this.payingUser = payingUser;
        return this;
    }
    
    public MATUser withFacebookUserId(String facebookUserId) {
        this.facebookUserId = facebookUserId;
        return this;
    }
    
    public MATUser withGoogleUserId(String googleUserId) {
        this.googleUserId = googleUserId;
        return this;
    }
    
    public MATUser withPhoneNumber(String phoneNumber) {
        // Regex remove all non-digits from phoneNumber
        String phoneNumberDigits = phoneNumber.replaceAll("\\D+", "");
        // Convert to digits from foreign characters if needed
        StringBuilder digitsBuilder = new StringBuilder();
        for (int i = 0; i < phoneNumberDigits.length(); i++) {
            int numberParsed = Integer.parseInt(String.valueOf(phoneNumberDigits.charAt(i)));
            digitsBuilder.append(numberParsed);
        }
        String phoneNumberConverted = digitsBuilder.toString();
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_PHONE_NUMBER, phoneNumberConverted);
        this.phoneNumber = phoneNumberConverted;
        this.phoneNumberMd5 = MATUtils.md5(phoneNumberConverted);
        this.phoneNumberSha1 = MATUtils.sha1(phoneNumberConverted);
        this.phoneNumberSha256 = MATUtils.sha256(phoneNumberConverted);
        return this;
    }
    
    public MATUser withTwitterUserId(String twitterUserId) {
        this.twitterUserId = twitterUserId;
        return this;
    }
    
    public MATUser withUserEmail(String userEmail) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_USER_EMAIL, userEmail);
        this.userEmail = userEmail;
        this.userEmailMd5 = MATUtils.md5(userEmail);
        this.userEmailSha1 = MATUtils.sha1(userEmail);
        this.userEmailSha256 = MATUtils.sha256(userEmail);
        return this;
    }
    
    public MATUser withUserId(String userId) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_USER_ID, userId);
        this.userId = userId;
        return this;
    }
    
    public MATUser withUserName(String userName) {
        MATUtils.saveToSharedPreferences(mContext, MATConstants.KEY_USER_NAME, userName);
        this.userName = userName;
        this.userNameMd5 = MATUtils.md5(userName);
        this.userNameSha1 = MATUtils.sha1(userName);
        this.userNameSha256 = MATUtils.sha256(userName);
        return this;
    }
    
    public int getAge() {
        return age;
    }
    
    public MATGender getGender() {
        return gender;
    }
    
    public boolean getIsExistingUser() {
        return existingUser;
    }
    
    public boolean getIsPayingUser() {
        return payingUser;
    }
    
    public String getFacebookUserId() {
        return facebookUserId;
    }
    
    public String getGoogleUserId() {
        return googleUserId;
    }
    
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
    public String getPhoneNumberMd5() {
        return phoneNumberMd5;
    }
    
    public String getPhoneNumberSha1() {
        return phoneNumberSha1;
    }
    
    public String getPhoneNumberSha256() {
        return phoneNumberSha256;
    }
    
    public String getTwitterUserId() {
        return twitterUserId;
    }
    
    public String getUserEmail() {
        return userEmail;
    }
    
    public String getUserEmailMd5() {
        return userEmailMd5;
    }
    
    public String getUserEmailSha1() {
        return userEmailSha1;
    }
    
    public String getUserEmailSha256() {
        return userEmailSha256;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public String getUserName() {
        return userName;
    }
    
    public String getUserNameMd5() {
        return userNameMd5;
    }
    
    public String getUserNameSha1() {
        return userNameSha1;
    }
    
    public String getUserNameSha256() {
        return userNameSha256;
    }
}
