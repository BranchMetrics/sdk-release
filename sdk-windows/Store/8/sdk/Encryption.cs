using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.Core;
using Windows.Storage.Streams;

namespace MobileAppTracking
{
    class Encryption
    {
        private SymmetricKeyAlgorithmProvider alg;
        private string key;
        private string iv;

        public Encryption(string key, string iv)
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
    }
}
