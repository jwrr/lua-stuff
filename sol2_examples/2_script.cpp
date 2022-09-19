#define SOL_ALL_SAFETIES_ON 1
#include <sol/sol.hpp> // or #include "sol.hpp", whichever suits your needs

#include <tuple>
#include <vector>
#include <utility> // for std::pair

using namespace std;


string get_lua(sol::state lua, string key, string def)
{
    string val = def;
    auto chk = lua[val];
    if (chk.valid()) {
        val = lua[key];
    }
    return val;
}


int main(int argc, char* argv[]) {

    sol::state lua;
    // lua.open_libraries(sol::lib::base);
    lua.open_libraries(); // Open all libraries
    lua.script("print('bark bark bark!')");
    lua.script_file("../hello.lua");

    string str_a = lua["a"];
    cout << "a = " << str_a << endl;

    int int_no = lua["no"].get_or(1234);
    cout << "no = " << int_no << endl;

    auto bark = lua["asdfasdf"];
    if (bark.valid()) {
        cout << "bark is valid" << endl;
    } else {
        cout << "bark is NOT valid" << endl;
    }

    string str_b = "B DOES NOT EXIST. USING THIS DEFAULT VALUE";
    auto chk = lua["bb"];
    if (chk.valid()) {
        str_b = lua["bb"];
    }
    cout << "b is " << str_b << endl;

    string str_default = "DEFAULT BADBADBAD";
//    string str_c = lua["cde"].get_or(str_default); //   get_lua(lua, "c", "BADBAD");
    string str_c = lua["cde"].get_or((string)"SuperBad"); //   get_lua(lua, "c", "BADBAD");
    cout << "c is " << str_c << endl;

    string key = "e";
    if (!lua[key].valid()) lua[key] = "ASSIGNED FROM C++";
    string str_eee = lua[key];
    cout << key << " is " << str_eee << endl;

    sol::table all_lua_variables = lua["t"];
    all_lua_variables.for_each([&](sol::object const& key, sol::object const& value) {
        cout << key.as<int>() << " " << value.as<std::string>() << endl;
    });

    lua.script("v = ret1984()");

//    int& from_lua_v = lua["v"];
//    cout << "from_lua_v in C++" << from_lua_v << endl;

    return 0;
}




