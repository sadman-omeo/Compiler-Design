#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count);
    ~symbol_table();
    void enter_scope();
    void exit_scope();
    bool insert(symbol_info* symbol);
    bool remove(symbol_info* symbol);         //new
    symbol_info* lookup(symbol_info* symbol);
    void print_current_scope(ofstream& outlog);    // new
    void print_all_scopes(ofstream& outlog);

    // you can add more methods if you need
 
};

// complete the methods of symbol_table class

symbol_table::symbol_table(int bucket_count)
{
    this->bucket_count = bucket_count;
    this->current_scope = NULL;
    this->current_scope_id = 0;
}

void symbol_table::enter_scope()
{
    current_scope_id++;

    current_scope = new scope_table(bucket_count, current_scope_id, current_scope);
}

void symbol_table::exit_scope()
{
    if (current_scope == NULL)
    {
        return;
    }

    scope_table *scope_to_remove = current_scope;
    current_scope = current_scope->get_parent_scope();

    delete scope_to_remove;
}

bool symbol_table::insert(symbol_info* symbol)
{
    if (current_scope == NULL || symbol == NULL)
    {
        return false;
    }

    return current_scope->insert_in_scope(symbol);
}

bool symbol_table::remove(symbol_info* symbol)
{
    if (current_scope == NULL || symbol == NULL)
    {
        return false;
    }
    
    return current_scope->delete_from_scope(symbol);
}

symbol_info *symbol_table::lookup(symbol_info* symbol)
{
    if (symbol == NULL)
    {
        return NULL;
    }

    scope_table *temp_scope = current_scope;

    while (temp_scope != NULL)
    {
        symbol_info *found_symbol = temp_scope->lookup_in_scope(symbol);

        if (found_symbol != NULL)
        {
            return found_symbol;
        }

        temp_scope = temp_scope->get_parent_scope();
    }

    return NULL;
}

void symbol_table::print_current_scope(ofstream& outlog)
{
    if (current_scope == NULL)
    {
        return;
    }

    current_scope->print_scope_table(outlog);
}

//Using the same instructor given at first 
void symbol_table::print_all_scopes(ofstream& outlog)
{
   outlog << "################################" << endl << endl;
   scope_table *temp = current_scope;
   while (temp != NULL)
   {
       temp->print_scope_table(outlog);
       temp = temp->get_parent_scope();
   }
   outlog << "################################" << endl << endl;
}

symbol_table::~symbol_table()
{
    while (current_scope != NULL)
    {
        exit_scope();
    }
}