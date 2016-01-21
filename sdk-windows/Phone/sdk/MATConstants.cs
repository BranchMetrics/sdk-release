using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobileAppTracking
{
    class MATConstants
    {
        public const string DOMAIN = "engine.mobileapptracking.com";
        public const string IV = "heF9BATUfWuISyO8";
        public const string SDK_TYPE = "windows";
        public const string SDK_VERSION = "3.5.2";
        public const string SETTINGS_MATID_KEY = "mat_id";
        public const string SETTINGS_MATLASTOPENLOGID_KEY = "mat_last_open_log_id";
        public const string SETTINGS_MATOPENLOGID_KEY = "mat_open_log_id";
        public const string SETTINGS_IS_PAYING_USER_KEY = "mat_is_paying_user";
        public const string SETTINGS_PHONENUMBER_KEY = "mat_phone_number";
        public const string SETTINGS_USERID_KEY = "mat_user_id";
        public const string SETTINGS_USEREMAIL_KEY = "mat_user_email";
        public const string SETTINGS_USERNAME_KEY = "mat_user_name";
        public const string SETTINGS_MATEVENTQUEUE_KEY = "mat_event_queue";

        public const int MAX_NUMBER_OF_RETRY_ATTEMPTS = 5;
    }
}
