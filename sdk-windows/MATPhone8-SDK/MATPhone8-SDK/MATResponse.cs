
namespace MobileAppTracking
{
    public interface MATResponse
    {
        void EnqueuedActionWithRefId(string refId);

        void DidSucceedWithData(string response);

        void DidFailWithError(string error);
    }
}
