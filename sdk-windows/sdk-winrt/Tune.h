#pragma once

#include "TuneEvent.h"

#include <string>
#include <wrl/client.h>
#include <Windows.Web.Http.h>
#include <Windows.Web.Http.Headers.h>

using namespace std;

namespace TuneSDK
{
    class Tune
    {
    public:
        Tune(wstring tune_advertiser_id, wstring tune_conversion_key);
        void MeasureSession();
        void MeasureEvent(wstring event_name);
        void MeasureEvent(TuneEvent tune_event);
        void SetDebugMode(bool debug);
        void SetExistingUser(bool existing);
        void SetFacebookUserId(wstring id);
        void SetGoogleUserId(wstring id);
        void SetPackageName(wstring package_name);
        void SetTwitterUserId(wstring id);
        void SetUserId(wstring id);
    private:
        Microsoft::WRL::ComPtr<ABI::Windows::Web::Http::IHttpClient> httpClient;
        Microsoft::WRL::ComPtr<ABI::Windows::Web::Http::IHttpResponseMessage> response;

        void Measure(TuneEvent tune_event);
        wstring BuildUrl(wstring action, TuneEvent tune_event);
        void HttpGet(wstring url);
        wstring CreateGuid();
        time_t UnixTimestamp();
        wstring SafeAppend(wstring url, wstring key, wstring value);
        wstring SafeAppend(wstring url, wstring key, time_t value);
        wstring SafeAppend(wstring url, wstring key, int value);
        wstring SafeAppend(wstring url, wstring key, double value);
    };
}