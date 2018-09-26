package com.tune;

import com.tune.utils.TuneStringUtils;
import com.tune.utils.TuneUtils;

import java.security.NoSuchAlgorithmException;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class TuneEncryption {
    private final IvParameterSpec ivspec;
    private final SecretKeySpec keyspec;
    private Cipher cipher;

    /**
     * Constructor.
     * @param secretKey Secret Key.
     * @param iv Initialization Vector.
     */
    public TuneEncryption(String secretKey, String iv) {
        ivspec = new IvParameterSpec(iv.getBytes());

        keyspec = new SecretKeySpec(secretKey.getBytes(), "AES");

        try {
            cipher = Cipher.getInstance("AES/CBC/NoPadding");
        } catch (NoSuchAlgorithmException e) {
            TuneDebugLog.d("TuneEncryption() No Algorithm exception", e);
        } catch (NoSuchPaddingException e) {
            TuneDebugLog.d("TuneEncryption() No Padding exception", e);
        }
    }

    /**
     * Encrypt text.
     * @param plainText String to encrypt
     * @return AES-encrypted string
     * @throws Exception if the given key is inappropriate for initializing this cipher.
     */
    byte[] encrypt(String plainText) throws Exception {
        if (TuneStringUtils.isNullOrEmpty(plainText)) {
            throw new Exception("Empty string");
        }

        byte[] encrypted;

        try {
            cipher.init(Cipher.ENCRYPT_MODE, keyspec, ivspec);

            encrypted = cipher.doFinal(padString(plainText).getBytes());
        } catch (Exception e) {
            throw new Exception("[encrypt] " + e.getMessage());
        }

        return encrypted;
    }

    /**
     * Decrypt an encrypted string.
     * @param encryptedText Encrypted string to decrypt
     * @return AES-decrypted string
     * @throws Exception if the encrypted string cannot be decrypted.
     */
    byte[] decrypt(String encryptedText) throws Exception {
        if (TuneStringUtils.isNullOrEmpty(encryptedText)) {
            throw new Exception("Empty string");
        }

        byte[] decrypted;

        try {
            cipher.init(Cipher.DECRYPT_MODE, keyspec, ivspec);

            decrypted = cipher.doFinal(TuneUtils.hexToBytes(encryptedText));
        } catch (Exception e) {
            throw new Exception("[decrypt] " + e.getMessage());
        }
        return decrypted;
    }
    
    /**
     * Pad an encrypted string to the correct block size.
     * @param source String that requires padding
     * @return Padded string for AES/CBC encryption
     */
    private static String padString(String source) {
        char paddingChar = ' ';
        int size = 16;
        int x = source.length() % size;
        int padLength = size - x;

        StringBuilder sourceBuilder = new StringBuilder(source);
        for (int i = 0; i < padLength; i++) {
            sourceBuilder.append(paddingChar);
        }
        source = sourceBuilder.toString();

        return source;
    }
}
