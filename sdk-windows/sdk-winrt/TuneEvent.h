#include "TuneEventItem.h"

#include <string>
#include <vector>

using namespace std;

struct TuneEvent {
    wstring event_name;
    int event_id = 0;
    double revenue = 0;
    wstring currency_code;
    wstring advertiser_ref_id;
    vector<TuneEventItem> event_items;
    wstring content_type;
    wstring content_id;
    int level = 0;
    int quantity = 0;
    wstring search_string;
    double rating = 0;
    time_t date1 = 0;
    time_t date2 = 0;
    wstring attribute1;
    wstring attribute2;
    wstring attribute3;
    wstring attribute4;
    wstring attribute5;

    HRESULT StringifyEventItems(HSTRING *result);
};