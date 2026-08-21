#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        // write your hash function here
        int hash_value = 0;

        for (char character : name)
        {
            hash_value += character;
        }

        return (hash_value % bucket_count);
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();

    // you can add more methods if you need
};

// complete the methods of scope_table class

scope_table::scope_table()
{
    bucket_count = 0;
    unique_id = 0;
    parent_scope = NULL;
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;

    table.resize(bucket_count);
}

scope_table*scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}


symbol_info *scope_table::lookup_in_scope(symbol_info* symbol)
{
    if(symbol == NULL)
    {
        return NULL;
    }

    int bucket_index = hash_function(symbol->get_name());

    for(symbol_info *stored_symbol : table[bucket_index])
    {
        if(stored_symbol->get_name() == symbol->get_name())
        {
            return stored_symbol;
        }
    }

    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    if(symbol == NULL)
    {
        return false;
    }

    if(lookup_in_scope(symbol) != NULL)
    {
        return false;
    }

    int bucket_index = hash_function(symbol->get_name());
    table[bucket_index].push_back(symbol);

    return true;
}

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    if(symbol == NULL)
    {
        return false;
    }

    int bucket_index = hash_function(symbol->get_name());

    for(auto iterator = table[bucket_index].begin();
        iterator != table[bucket_index].end();
        iterator++)
    {
        if((*iterator)->get_name() == symbol->get_name())
        {
            delete *iterator;
            table[bucket_index].erase(iterator);
            return true;
        }
    }

    return false;
}


void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # "+ to_string(unique_id) << endl;

    //iterate through the current scope table and print the symbols and all relevant information

    for(int i = 0; i < bucket_count; i++)
    {
        if(table[i].empty())
        {
            continue;
        }

        outlog << i << " --> " << endl;

        for(symbol_info *symbol : table[i])
        {
            outlog << "< " << symbol->get_name()
                   << " : " << symbol->get_type()
                   << " >" << endl;
            
            if(symbol->get_symbol_category() == "Variable")
            {
                outlog << "Variable" << endl;
                outlog << "Type: "
                       << symbol->get_data_type() << endl;
            }
            else if(symbol->get_symbol_category() == "Array")
            {
                outlog << "Array" << endl;
                outlog << "Type: "
                       << symbol->get_data_type() << endl;
                outlog << "Size: "
                       << symbol->get_array_size() << endl;
            }
            else if(symbol->get_symbol_category() == "Function Definition")
            {
                outlog << "Function Definition" << endl;
                outlog << "Return Type: "
                       << symbol->get_data_type() << endl;
                outlog << "Number of Parameters: "
                       << symbol->get_parameter_count() << endl;
                outlog << "Parameter Details: ";

                vector<pair<string, string>> parameters =
                    symbol->get_parameters();
                
                for(int j = 0; j < static_cast<int>(parameters.size()); j++)
                {
                    if (j > 0)
                    {
                        outlog << ", ";
                    }
                    outlog << parameters[j].first;

                    if(parameters[j].second != "")
                    {
                        outlog << " " << parameters[j].second;
                    }
                }
                 outlog << endl;
            }
        }
        outlog << endl;
    }
}


scope_table::~scope_table()
{
    for(int i = 0; i < bucket_count; i++)
    {
        for(symbol_info *symbol : table[i])
        {
            delete symbol;
        }

        table[i].clear();
    }

    table.clear();
}