using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace MobileAppTracking
{
    class Encryption
    {
        private AesManaged aes;

        public Encryption(string key, string iv)
        {
            aes = new AesManaged();
            aes.Key = Encoding.UTF8.GetBytes(key);
            aes.IV = Encoding.UTF8.GetBytes(iv);
        }

        public byte[] Encrypt(string plainText)
        {
            if (string.IsNullOrEmpty(plainText))
                throw new ArgumentNullException("plainText");
            if (string.IsNullOrEmpty(aes.Key.ToString()))
                throw new ArgumentNullException("Key");
            if (string.IsNullOrEmpty(aes.IV.ToString()))
                throw new ArgumentNullException("IV");

            byte[] encrypted = null;
            using (MemoryStream memoryStream = new MemoryStream())
            {
                ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

                using (CryptoStream cryptoStream = new CryptoStream(memoryStream, encryptor, CryptoStreamMode.Write))
                using (StreamWriter streamWriter = new StreamWriter(cryptoStream))
                {
                    // Write encrypted data to the stream
                    streamWriter.Write(plainText);
                }
                encrypted = memoryStream.ToArray();
            }

            // Return encrypted bytes from memory stream
            return encrypted;
        }

        public string Decrypt(byte[] encryptedText)
        {
            string plainText = null;

            var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

            using (var memoryStream = new MemoryStream(encryptedText))
            using (var cryptoStream = new CryptoStream(memoryStream, decryptor, CryptoStreamMode.Read))
            using (var streamReader = new StreamReader(cryptoStream))
            {
                plainText = streamReader.ReadToEnd();
            }
            return plainText;
        }

        // Convert byte array to string
        public static string ByteArrayToString(byte[] bytes)
        {
            StringBuilder hex = new StringBuilder(bytes.Length * 2);
            foreach (byte b in bytes)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }
    }
}
