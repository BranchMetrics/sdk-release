using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobileAppTracking
{
    public interface MATResponse
    {
        void EnqueuedActionWithRefId(string refId);

        void DidSucceedWithData(string response);

        void DidFailWithError(string error);
    }
}
