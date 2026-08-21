#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    
    string symbol_category;

    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    
    string data_type;

    // Write necessary attributes to store the parameters of a function
    
    vector<pair<string, string>> parameters;

    // Write necessary attributes to store the array size if the symbol is an array
    
    int array_size;
    
   


public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;

        this->symbol_category = "";
        this->data_type = "";
        this->array_size = -1;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    
    //new method for getname() as this method is used more often
    string getname()
    {
        return name;
    }

    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes

    string get_symbol_category()
    {
        return symbol_category;
    }

    void set_symbol_category(string symbol_category)
    {
        this->symbol_category = symbol_category;
    }

    string get_data_type()
    {
        return data_type;
    }

    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }


    vector<pair<string, string>> get_parameters()
    {
        return parameters;
    }

    void set_parameters(vector<pair<string, string>> parameters)
    {
        this->parameters = parameters;
    }

    void add_parameter(string parameter_type, string parameter_name)
    {
        parameters.push_back({parameter_type, parameter_name});
    }

    int get_parameter_count()
    {
        return static_cast<int>(parameters.size());
    }



    int get_array_size()
    {
        return array_size;
    }

    void set_array_size(int array_size)
    {
        this->array_size = array_size;
    }

    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};