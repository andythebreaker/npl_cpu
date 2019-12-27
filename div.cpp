#include <iostream>
#include <string>
#include <fstream>
#include <windows.h>
using namespace std;
int a = 0;
int b = 0;
string ot = "";
int main()
{
    for (a = 0; a < 65536; a++)
    {
        for (b = 1; b < 65536; b++)
        {
            ot = ot + to_string(a / b) + "\n";
        }
    }
    cout << ot;
}