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
    
    //Temporary attrs used during semantic analysis

    string semantic_type;

    vector<string> argument_types;

    bool constant_value_known;
    double constant_value;

    string void_function_name;
   


public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;

        this->symbol_category = "";
        this->data_type = "";
        this->array_size = -1;

        this->semantic_type = "";
        this->constant_value_known = false;
        this->constant_value = 0.0;
        this->void_function_name = "";
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

    string get_semantic_type()
    {
        return semantic_type;
    }

    void set_semantic_type(string sem_type)
    {
        this->semantic_type = sem_type;
    }

    vector<string> get_argument_types()
    {
        return argument_types;
    }

    void set_argument_types(vector<string> arg_types)
    {
        this->argument_types = arg_types;
    }

    void add_argument_type(string arg_type)
    {
        argument_types.push_back(arg_type);
    }

    bool is_constant_value_known()
    {
        return constant_value_known;
    }

    bool is_constant()
    {
        return constant_value_known;
    }

    double get_constant_value()
    {
        return constant_value;
    }

    void set_constant_value(double cons_val)
    {
        this->constant_value_known = true;
        this->constant_value = cons_val;
    }

    void clear_constant_value()
    {
        this->constant_value_known = false;
        this->constant_value = 0.0;
    }

    string get_void_function_name()
    {
        return void_function_name;
    }

    void set_void_function_name(string vfn)
    {
        this->void_function_name = vfn;
    }

    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};