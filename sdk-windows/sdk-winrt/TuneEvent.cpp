#include "pch.h"
#include "TuneEvent.h"

#include <Windows.Data.Json.h>

HRESULT TuneEvent::StringifyEventItems(HSTRING *result) {
    HRESULT hr;

    ComPtr<Data::Json::IJsonArray> jsonArray;
    if (FAILED(hr = Windows::Foundation::ActivateInstance(Wrappers::HStringReference(RuntimeClass_Windows_Data_Json_JsonArray).Get(), &jsonArray)))
        return hr;

    ComPtr<Foundation::Collections::IVector<Data::Json::IJsonValue*>> jsonArrayVector;
    if (FAILED(hr = jsonArray.As(&jsonArrayVector)))
        return hr;

    ComPtr<Data::Json::IJsonValueStatics> jsonValueStatics;
    if (FAILED(hr = Foundation::GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_Data_Json_JsonValue).Get(), &jsonValueStatics)))
        return hr;

    ComPtr<Data::Json::IJsonValue> jsonValue;

    // Iterate through event items and add to JsonArray
    for (auto item = event_items.begin(); item != event_items.end(); ++item) {
        Wrappers::HString itemString;
        if (FAILED(hr = item->Stringify(itemString.GetAddressOf())))
            return hr;

        if (FAILED(hr = jsonValueStatics->Parse(itemString.Get(), &jsonValue)))
            return hr;

        if (FAILED(hr = jsonArrayVector->Append(jsonValue.Get())))
            return hr;
    }

    if (FAILED(hr = jsonArray.As(&jsonValue)))
        return hr;

    return jsonValue->Stringify(result);
}