#include <string>
#include <hstring.h>

using namespace std;

struct TuneEventItem {
    wstring name;
    int quantity = 0;
    double revenue = 0;
    double unit_price = 0;
    wstring attribute1;
    wstring attribute2;
    wstring attribute3;
    wstring attribute4;
    wstring attribute5;

    HRESULT Stringify(HSTRING *result);
};