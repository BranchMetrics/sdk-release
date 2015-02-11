using System;

namespace MobileAppTracking
{
    public interface MATTestRequest
    {
        void ParamsToBeEncrypted(String param);

        void ConstructedRequest(String url);
    }
}
