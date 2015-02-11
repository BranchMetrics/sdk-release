using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobileAppTracking
{
    public interface MATTestRequest
    {
        void ParamsToBeEncrypted(String param);

        void ConstructedRequest(String url);
    }
}