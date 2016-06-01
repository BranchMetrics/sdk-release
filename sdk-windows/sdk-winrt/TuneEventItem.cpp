#include "pch.h"
#include "TuneEventItem.h"

using namespace std;

#include <Windows.Data.Json.h>

HRESULT TuneEventItem::Stringify(HSTRING *result) {
    HRESULT hr;

    ComPtr<Data::Json::IJsonObject> jsonObject;
    if (FAILED(hr = Windows::Foundation::ActivateInstance(Wrappers::HStringReference(RuntimeClass_Windows_Data_Json_JsonObject).Get(), &jsonObject)))
        return hr;

    ComPtr<Foundation::Collections::IMap<HSTRING, Data::Json::IJsonValue*>> jsonObjectMap;
    if (FAILED(hr = jsonObject.As(&jsonObjectMap)))
        return hr;

    ComPtr<Data::Json::IJsonValueStatics> jsonValueStatics;
    if (FAILED(hr = Foundation::GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_Data_Json_JsonValue).Get(), &jsonValueStatics)))
        return hr;

    ComPtr<Data::Json::IJsonValue> jsonValue;
    if (FAILED(hr = jsonValueStatics->CreateStringValue(Wrappers::HStringReference(name.c_str()).Get(), &jsonValue)))
        return hr;

    boolean replaced;
    if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"item").Get(), jsonValue.Get(), &replaced)))
        return hr;

    // Optional values
    if (quantity != 0)
    {
        if (FAILED(hr = jsonValueStatics->CreateNumberValue(quantity, &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"quantity").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (unit_price != 0)
    {
        if (FAILED(hr = jsonValueStatics->CreateNumberValue(unit_price, &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"unit_price").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (revenue != 0)
    {
        if (FAILED(hr = jsonValueStatics->CreateNumberValue(revenue, &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"revenue").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (!attribute1.empty())
    {
        if (FAILED(hr = jsonValueStatics->CreateStringValue(Wrappers::HStringReference(attribute1.c_str()).Get(), &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"attribute_sub1").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (!attribute2.empty())
    {
        if (FAILED(hr = jsonValueStatics->CreateStringValue(Wrappers::HStringReference(attribute2.c_str()).Get(), &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"attribute_sub2").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (!attribute3.empty())
    {
        if (FAILED(hr = jsonValueStatics->CreateStringValue(Wrappers::HStringReference(attribute3.c_str()).Get(), &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"attribute_sub3").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (!attribute4.empty())
    {
        if (FAILED(hr = jsonValueStatics->CreateStringValue(Wrappers::HStringReference(attribute4.c_str()).Get(), &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"attribute_sub4").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
    if (!attribute5.empty())
    {
        if (FAILED(hr = jsonValueStatics->CreateStringValue(Wrappers::HStringReference(attribute5.c_str()).Get(), &jsonValue)))
            return hr;

        if (FAILED(hr = jsonObjectMap->Insert(Wrappers::HStringReference(L"attribute_sub5").Get(), jsonValue.Get(), &replaced)))
            return hr;
    }
 
    if (FAILED(hr = jsonObject.As(&jsonValue)))
        return hr;

    return jsonValue->Stringify(result);
}