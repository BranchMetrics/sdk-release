#include "pch.h"
#include "Tune.h"

#include <ctime>
#include <iostream>
#include <sstream>
#include <algorithm>
#include <Windows.h>

#include <Windows.ApplicationModel.h>
#include <Windows.ApplicationModel.Store.h>
#include <Windows.Foundation.h>
#include <Windows.Security.ExchangeActiveSyncProvisioning.h>
#include <Windows.System.UserProfile.h>
#include <Windows.UI.Core.h>
#include <Windows.UI.Xaml.h>
#include <Windows.UI.Xaml.Navigation.h>

using namespace std;

namespace TuneSDK
{
    static wstring domain = L"engine.mobileapptracking.com";
    static wstring sdk_type = L"windows";
    static wstring sdk_version = L"4.0.0";

    bool debug_mode;
    bool existing_user;
    bool paying_user;

    wstring advertiser_id;
    wstring conversion_key;
    wstring package_name;
    wstring advertising_id;
    wstring app_version;
    wstring device_brand;
    wstring device_model;
    wstring device_type;

    wstring facebook_user_id;
    wstring google_user_id;
    wstring twitter_user_id;
    wstring user_id;

    /* Public methods */
    Tune::Tune(wstring tune_advertiser_id, wstring tune_conversion_key)
    {
        advertiser_id = tune_advertiser_id;
        conversion_key = tune_conversion_key;

        // Get Windows Advertising Id
        Wrappers::HString buf;
        {
          ComPtr<System::UserProfile::IAdvertisingManagerStatics> adManagerStatics;
          if (SUCCEEDED(Foundation::GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_System_UserProfile_AdvertisingManager).Get(), &adManagerStatics)))
              adManagerStatics->get_AdvertisingId(buf.GetAddressOf());
        }
        advertising_id = wstring(buf.GetRawBuffer(nullptr));

        // Get app version
        ComPtr<ApplicationModel::IPackage> package; ComPtr<ApplicationModel::IPackageId> packageId;
        {
          ComPtr<ApplicationModel::IPackageStatics> packageStatics;
          if (SUCCEEDED(Foundation::GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_ApplicationModel_Package).Get(), &packageStatics)))
          {
              if (SUCCEEDED(packageStatics->get_Current(&package)))
                  package->get_Id(&packageId);
          }
        }
        ApplicationModel::PackageVersion version;
        packageId->get_Version(&version);

        stringstream s;
        s << version.Major << "." << version.Minor << "." << version.Build << "." << version.Revision;
        string version_str = s.str();
        app_version = wstring(version_str.begin(), version_str.end());

        // Use local package name by default
        packageId->get_Name(buf.GetAddressOf());
        package_name = wstring(buf.GetRawBuffer(nullptr));

        // If there's a store app id, use it
        Wrappers::HStringReference empty(L"{00000000-0000-0000-0000-000000000000}");
        GUID empty_guid;
        HRESULT hr = IIDFromString(empty.GetRawBuffer(nullptr), &empty_guid);
        if (SUCCEEDED(hr)) {
            ComPtr<ApplicationModel::Store::ICurrentApp> currentApp;
            if (SUCCEEDED(Foundation::GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_ApplicationModel_Store_CurrentApp).Get(), &currentApp)))
            {
                GUID appId;
                if (SUCCEEDED(currentApp->get_AppId(&appId)))
                {
                    if (appId != empty_guid)
                    {
                        LPOLESTR appIdString;
                        StringFromCLSID(appId, &appIdString);

                        wstring appId = appIdString;
                        CoTaskMemFree(appIdString);

                        // Remove curly brackets around GUID
                        wstring guid_result_initial;
                        wstring guid_result_final;
                        remove_copy(appId.begin(), appId.end(), back_inserter(guid_result_initial), '{');
                        remove_copy(guid_result_initial.begin(), guid_result_initial.end(), back_inserter(guid_result_final), '}');
                        package_name = guid_result_final;
                    }
                }
            }
        }

        // Get device info
        ComPtr<Security::ExchangeActiveSyncProvisioning::IEasClientDeviceInformation> deviceInfo;
        if (SUCCEEDED(Windows::Foundation::ActivateInstance(Wrappers::HStringReference(RuntimeClass_Windows_Security_ExchangeActiveSyncProvisioning_EasClientDeviceInformation).Get(), &deviceInfo)))
        {
            if (SUCCEEDED(deviceInfo->get_SystemManufacturer(buf.GetAddressOf())))
                device_brand = wstring(buf.GetRawBuffer(nullptr));
            if (SUCCEEDED(deviceInfo->get_SystemProductName(buf.GetAddressOf())))
                device_model = wstring(buf.GetRawBuffer(nullptr));
            if (SUCCEEDED(deviceInfo->get_OperatingSystem(buf.GetAddressOf())))
                device_type = wstring(buf.GetRawBuffer(nullptr)); // Windows or WindowsPhone
        }

        Windows::Foundation::ActivateInstance(Wrappers::HStringReference(RuntimeClass_Windows_Web_Http_HttpClient).Get(), &httpClient);
    }

    void Tune::MeasureSession()
    {
        TuneEvent tune_event;
        tune_event.event_name = L"session";
        Measure(tune_event);
    }

    void Tune::MeasureEvent(wstring event_name)
    {
        TuneEvent tune_event;
        tune_event.event_name = event_name;
        Measure(tune_event);
    }

    void Tune::MeasureEvent(TuneEvent event)
    {
        Measure(event);
    }

    void Tune::SetDebugMode(bool debug)
    {
        debug_mode = debug;
    }

    void Tune::SetExistingUser(bool existing)
    {
        existing_user = existing;
    }

    void Tune::SetFacebookUserId(wstring id)
    {
        facebook_user_id = id;
    }

    void Tune::SetGoogleUserId(wstring id)
    {
        google_user_id = id;
    }

    void Tune::SetPackageName(wstring package)
    {
        package_name = package;
    }

    void Tune::SetTwitterUserId(wstring id)
    {
        twitter_user_id = id;
    }

    void Tune::SetUserId(wstring id)
    {
        user_id = id;
    }

    /* Private methods */
    void Tune::Measure(TuneEvent tune_event)
    {
        // Default action is conversion
        wstring action = L"conversion";

        // Don't send close events
        if (tune_event.event_name == L"close")
        {
            return;
        }
        if (tune_event.event_name == L"open" || tune_event.event_name == L"install" || tune_event.event_name == L"update" || tune_event.event_name == L"session")
        {
            action = L"session";
        }

        if (tune_event.revenue > 0)
        {
            paying_user = true;
        }

        wstring url = BuildUrl(action, tune_event);
        HttpGet(url);
    }

    wstring Tune::BuildUrl(wstring action, TuneEvent tune_event)
    {
        wstring url = L"https://";
        url += advertiser_id;
        url += L".";
        if (debug_mode)
        {
            url += L"debug.";
        }
        url += domain;
        url += L"/serve?";

        url += L"sdk=" + sdk_type;
        url += L"&ver=" + sdk_version;
        url += L"&advertiser_id=" + advertiser_id;
        url += L"&action=" + action;
        url += L"&package_name=" + package_name;
        
        // Add transaction id guid to url
        url += L"&transaction_id=" + CreateGuid();
        
        if (action == L"conversion")
        {
            if (!tune_event.event_name.empty())
            {
                url += L"&site_event_name=" + tune_event.event_name;
            }
            if (tune_event.event_id != 0)
            {
                url += L"&site_event_id=" + to_wstring(tune_event.event_id);
            }
        }
        if (debug_mode)
        {
            url += L"&debug=1";
        }
        if (existing_user)
        {
            url += L"&existing_user=1";
        }

        // Append data params
        url += L"&data=";
        url += L"&system_date=" + to_wstring(UnixTimestamp());

        url += L"&windows_aid=" + advertising_id;
        url += L"&app_version=" + app_version;
        url += L"&device_brand=" + device_brand;
        url += L"&device_model=" + device_model;
        url += L"&device_type=" + device_type;

        url = SafeAppend(url, L"user_id", user_id);
        url = SafeAppend(url, L"facebook_user_id", facebook_user_id);
        url = SafeAppend(url, L"google_user_id", google_user_id);
        url = SafeAppend(url, L"twitter_user_id", twitter_user_id);
        if (paying_user)
        {
            url += L"&is_paying_user=1";
        }

        // Append event data
        url = SafeAppend(url, L"advertiser_ref_id", tune_event.advertiser_ref_id);
        url = SafeAppend(url, L"attribute_sub1", tune_event.attribute1);
        url = SafeAppend(url, L"attribute_sub2", tune_event.attribute2);
        url = SafeAppend(url, L"attribute_sub3", tune_event.attribute3);
        url = SafeAppend(url, L"attribute_sub4", tune_event.attribute4);
        url = SafeAppend(url, L"attribute_sub5", tune_event.attribute5);
        url = SafeAppend(url, L"content_id", tune_event.content_id);
        url = SafeAppend(url, L"content_type", tune_event.content_type);
        url = SafeAppend(url, L"currency_code", tune_event.currency_code);
        url = SafeAppend(url, L"content_id", tune_event.content_id);
        url = SafeAppend(url, L"content_id", tune_event.content_id);
        url = SafeAppend(url, L"content_id", tune_event.content_id);
        url = SafeAppend(url, L"date1", tune_event.date1);
        url = SafeAppend(url, L"date2", tune_event.date2);
        url = SafeAppend(url, L"level", tune_event.level);
        url = SafeAppend(url, L"quantity", tune_event.quantity);
        url = SafeAppend(url, L"rating", tune_event.rating);
        url = SafeAppend(url, L"revenue", tune_event.revenue);
        url = SafeAppend(url, L"search_string", tune_event.search_string);
        
        // Append event item JSON
        Wrappers::HString buf;
        tune_event.StringifyEventItems(buf.GetAddressOf());
        url += L"&site_event_items=" + wstring(buf.GetRawBuffer(nullptr));

        return url;
    }

    void Tune::HttpGet(wstring url)
    {
        ComPtr<Foundation::IUriRuntimeClass> resourceUri;
        Windows::Foundation::ActivateInstance(Wrappers::HStringReference(RuntimeClass_Windows_Web_Http_HttpResponseMessage).Get(), &response);

        ComPtr<IActivationFactory> uriActivationFactory;
        if (FAILED(Foundation::GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_Foundation_Uri).Get(), &uriActivationFactory)))
            return;

        ComPtr<Foundation::IUriRuntimeClassFactory> uriFactory;
        if (FAILED(uriActivationFactory.As(&uriFactory)))
            return;

        if (FAILED(uriFactory->CreateUri(Wrappers::HStringReference(url.c_str()).Get(), &resourceUri)))
            return;

        Wrappers::HString schemeName;
        resourceUri->get_SchemeName(schemeName.GetAddressOf());
        if (schemeName != Wrappers::HStringReference(L"http") && schemeName != Wrappers::HStringReference(L"https"))
        {
            return;
        }

        if (debug_mode)
        {
            OutputDebugString(L"Sending TUNE event to server...\n");
            OutputDebugString(url.c_str());
            OutputDebugString(L"\n");
        }

        ComPtr<Foundation::IAsyncOperationWithProgress<Web::Http::HttpResponseMessage*, struct Web::Http::HttpProgress>> asyncOp;
        if (FAILED(httpClient->GetAsync(resourceUri.Get(), &asyncOp)))
        {
            OutputDebugString(L"Failed sending TUNE event\n");
            return;
        }

        asyncOp->put_Completed(Callback<Foundation::IAsyncOperationWithProgressCompletedHandler<Web::Http::HttpResponseMessage*, struct Web::Http::HttpProgress>>(
        [](Foundation::IAsyncOperationWithProgress<Web::Http::HttpResponseMessage*, struct Web::Http::HttpProgress> *action, AsyncStatus status) -> HRESULT
        {
            ComPtr<Web::Http::IHttpResponseMessage> response;
            action->GetResults(&response);
            if (!response)
            {
                OutputDebugString(L"Failed sending TUNE event\n");
                return E_FAIL;
            }

            if (debug_mode)
            {
                Web::Http::HttpStatusCode statusCode;
                response->get_StatusCode(&statusCode);

                Wrappers::HString reasonPhrase;
                response->get_ReasonPhrase(reasonPhrase.GetAddressOf());
                OutputDebugString((to_wstring((int)statusCode) + L" " + reasonPhrase.GetRawBuffer(nullptr)).c_str());
            }

            ComPtr<Web::Http::IHttpContent> content;
            response->get_Content(&content);
            if (!content)
                return E_FAIL;

            ComPtr<Foundation::IAsyncOperationWithProgress<HSTRING, UINT64>> asyncOp;
            if (FAILED(content->ReadAsStringAsync(&asyncOp)))
                return E_FAIL;

            return asyncOp->put_Completed(Callback<Foundation::IAsyncOperationWithProgressCompletedHandler<HSTRING, UINT64>>(
            [](Foundation::IAsyncOperationWithProgress<HSTRING, UINT64> *action, AsyncStatus status) -> HRESULT
            {
                Wrappers::HString responseBodyAsText;
                action->GetResults(responseBodyAsText.GetAddressOf());
                if (debug_mode)
                {
                    OutputDebugString(responseBodyAsText.GetRawBuffer(nullptr));
                    OutputDebugString(L"\n");
                }
                return S_OK;
            }).Get());
        }).Get());
    }

    wstring Tune::CreateGuid()
    {
        // Create GUID
        GUID guid;
        CoCreateGuid(&guid);

        LPOLESTR buf;
        StringFromCLSID(guid, &buf);

        wstring transaction_id_str = buf;
        CoTaskMemFree(buf);

        // Remove curly brackets around GUID
        wstring guid_result_initial;
        wstring guid_result_final;
        remove_copy(transaction_id_str.begin(), transaction_id_str.end(), back_inserter(guid_result_initial), '{');
        remove_copy(guid_result_initial.begin(), guid_result_initial.end(), back_inserter(guid_result_final), '}');

        return guid_result_final;
    }

    time_t Tune::UnixTimestamp()
    {
        time_t result = time(nullptr);
        tm gmt;
        gmtime_s(&gmt, &result);
        return result;
    }

    wstring Tune::SafeAppend(wstring url, wstring key, wstring value)
    {
        if (!value.empty())
        {
            url += L"&" + key + L"=" + value;
        }
        return url;
    }

    wstring Tune::SafeAppend(wstring url, wstring key, time_t value)
    {
        if (value != 0)
        {
            url += L"&" + key + L"=" + to_wstring(value);
        }
        return url;
    }

    wstring Tune::SafeAppend(wstring url, wstring key, int value)
    {
        if (value != 0)
        {
            url += L"&" + key + L"=" + to_wstring(value);
        }
        return url;
    }

    wstring Tune::SafeAppend(wstring url, wstring key, double value)
    {
        if (value != 0)
        {
            url += L"&" + key + L"=" + to_wstring(round(value * 100) / 100.0);
        }
        return url;
    }
}