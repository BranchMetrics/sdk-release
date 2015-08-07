using Org.BouncyCastle.Crypto.Digests;
using Org.BouncyCastle.Utilities.Encoders;
using System;
using System.Text;
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.Core;
using Windows.Storage.Streams;

namespace MobileAppTracking
{
    class MATEncryption
    {
        private SymmetricKeyAlgorithmProvider alg;
        private string key;
        private string iv;

        public MATEncryption(string key, string iv)
        {
            this.alg = SymmetricKeyAlgorithmProvider.OpenAlgorithm(SymmetricAlgorithmNames.AesCbc);
            this.key = key;
            this.iv = iv;
        }

        public string Encrypt(string plainText)
        {
            if (string.IsNullOrEmpty(plainText))
                throw new ArgumentNullException("plainText");
            if (string.IsNullOrEmpty(key))
                throw new ArgumentNullException("Key");
            if (string.IsNullOrEmpty(iv))
                throw new ArgumentNullException("IV");

            BinaryStringEncoding encoding = BinaryStringEncoding.Utf8;

            IBuffer keyBuffer = CryptographicBuffer.ConvertStringToBinary(key, encoding);
            CryptographicKey cryptoKey = alg.CreateSymmetricKey(keyBuffer);
            IBuffer ivBuffer = CryptographicBuffer.ConvertStringToBinary(iv, encoding);

            // Add padding so buffer length is multiple of 16
            plainText = PadString(plainText);
                
            IBuffer inputBuffer = CryptographicBuffer.ConvertStringToBinary(plainText, encoding);
            IBuffer encryptedBuffer = CryptographicEngine.Encrypt(cryptoKey, inputBuffer, ivBuffer);

            return CryptographicBuffer.EncodeToHexString(encryptedBuffer);
        }

        // Add padding to string to encrypt so it's AES_CBC compatible
        private string PadString(string source)
        {
            char paddingChar = ' ';
            int blockSize = 16;
            int extraLength = source.Length % blockSize;
            int padLength = blockSize - extraLength;

            for (int i = 0; i < padLength; i++)
                source += paddingChar;

            return source;
        }

        public static string Md5(string input)
        {
            var data = System.Text.Encoding.UTF8.GetBytes(input);
            MD5Digest hash = new MD5Digest();
            hash.BlockUpdate(data, 0, data.Length);
            byte[] result = new byte[hash.GetDigestSize()];
            hash.DoFinal(result, 0);
            return Hex.ToHexString(result);
        }

        public static string Sha1(string input)
        {
            var data = System.Text.Encoding.UTF8.GetBytes(input);
            Sha1Digest hash = new Sha1Digest();
            hash.BlockUpdate(data, 0, data.Length);
            byte[] result = new byte[hash.GetDigestSize()];
            hash.DoFinal(result, 0);
            return Hex.ToHexString(result);
        }

        public static string Sha256(string input)
        {
            var data = System.Text.Encoding.UTF8.GetBytes(input);
            Sha256Digest hash = new Sha256Digest();
            hash.BlockUpdate(data, 0, data.Length);
            byte[] result = new byte[hash.GetDigestSize()];
            hash.DoFinal(result, 0);
            return Hex.ToHexString(result);
        }
    }
}
