package com.mobileapptracker;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

class Encryption {
    private IvParameterSpec ivspec;
    private SecretKeySpec keyspec;
    private Cipher cipher;

    /**
     * @param SecretKey
     * @param iv
     */
    public Encryption(String SecretKey, String iv) {
        ivspec = new IvParameterSpec(iv.getBytes());

        keyspec = new SecretKeySpec(SecretKey.getBytes(), "AES");

        try {
            cipher = Cipher.getInstance("AES/CBC/NoPadding");
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (NoSuchPaddingException e) {
            e.printStackTrace();
        }
    }

    /**
     * @param text String to encrypt
     * @return AES-encrypted string
     * @throws Exception
     */
    public byte[] encrypt(String text) throws Exception {
        if (text == null || text.length() == 0) throw new Exception("Empty string");

        byte[] encrypted = null;

        try {
            cipher.init(Cipher.ENCRYPT_MODE, keyspec, ivspec);

            encrypted = cipher.doFinal(padString(text).getBytes());
        } catch (Exception e) {
            throw new Exception("[encrypt] " + e.getMessage());
        }

        return encrypted;
    }

    /**
     * @param code Encrypted string to decrypt
     * @return AES-decrypted string
     * @throws Exception
     */
    public byte[] decrypt(String code) throws Exception {
        if (code == null || code.length() == 0) throw new Exception("Empty string");

        byte[] decrypted = null;

        try {
            cipher.init(Cipher.DECRYPT_MODE, keyspec, ivspec);

            decrypted = cipher.doFinal(hexToBytes(code));
        } catch (Exception e) {
            throw new Exception("[decrypt] " + e.getMessage());
        }
        return decrypted;
    }

    /**
     * @param data Byte array to convert to hex
     * @return Hex string
     */
    public String bytesToHex(byte[] data) {
        if (data == null) {
            return null;
        }

        int len = data.length;
        String str = "";
        for (int i = 0; i < len; i++) {
            if ((data[i] & 0xFF) < 16) {
                str = str + "0" + java.lang.Integer.toHexString(data[i] & 0xFF);
            } else {
                str = str + java.lang.Integer.toHexString(data[i] & 0xFF);
            }
        }
        return str;
    }

    /**
     * @param str Hex string to convert to bytes
     * @return Byte array
     */
    public static byte[] hexToBytes(String str) {
        if (str == null) {
            return null;
        } else if (str.length() < 2) {
            return null;
        } else {
            int len = str.length() / 2;
            byte[] buffer = new byte[len];
            for (int i = 0; i < len; i++) {
                buffer[i] = (byte) Integer.parseInt(str.substring(i * 2, i * 2 + 2), 16);
            }
            return buffer;
        }
    }

    /**
     * @param source String that requires padding
     * @return Padded string for AES/CBC encryption
     */
    private static String padString(String source) {
        char paddingChar = ' ';
        int size = 16;
        int x = source.length() % size;
        int padLength = size - x;

        for (int i = 0; i < padLength; i++) {
            source += paddingChar;
        }

        return source;
    }

    /**
     * @param s String to MD5 hash
     * @return MD5 hashed string
     */
    public String md5(String s) {
        if (s == null) {
            return "";
        }
        try {
            // Create MD5 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            digest.update(s.getBytes());
            byte[] messageDigest = digest.digest();
            return bytesToHex(messageDigest);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }
    
    /**
     * @param s String to SHA-1 hash
     * @return SHA-1 hashed string
     */
    public String sha1(String s) {
        if (s == null) {
            return "";
        }
        try {
            // Create SHA-1 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("SHA-1");
            digest.update(s.getBytes());
            byte[] messageDigest = digest.digest();
            return bytesToHex(messageDigest);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }
    
    /**
     * @param s String to SHA-256 hash
     * @return SHA-256 hashed string
     */
    public String sha256(String s) {
        if (s == null) {
            return "";
        }
        try {
            // Create SHA-256 Hash
            MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            digest.update(s.getBytes());
            byte[] messageDigest = digest.digest();
            return bytesToHex(messageDigest);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }
}

