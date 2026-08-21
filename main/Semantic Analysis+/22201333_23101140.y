%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object

int lines = 1;

ofstream outlog;
ofstream outerror;

int error_count = 0;

symbol_table *table = NULL;

string current_data_type = "";
vector<pair<string, string>> current_parameters;
vector<string> declaration_errors;
string current_function_name = "";

bool function_scope_pending = false;

int next_scope_id = 0;
vector<int> active_scope_ids;

// you may declare other necessary variables here to store necessary info
// such as current variable type, variable list, function name, return type, function parameter types, parameters names etc.

void report_error(const string& msg)
{
	outlog << "At line no: " << lines << " "
		   << msg << endl << endl;
	outerror << "At line no: " << lines << " "
			 << msg << endl << endl;
	error_count++;
}

void copy_semantic_type(symbol_info *destination, symbol_info *source)
{
	destination->set_semantic_type(source->get_semantic_type());
	destination->set_void_function_name(source->get_void_function_name());

	if(source->is_constant())
	{
		destination->set_constant_value(source->get_constant_value());
	}
}

string arith_result_type(symbol_info *left, symbol_info *right)
{
	string left_type = left->get_semantic_type();
	string right_type = right->get_semantic_type();

	if(left_type == "error" || right_type == "error")
	{
		return "error";
	}
	if(left_type == "void" || right_type == "void")
	{
		return "void";
	}
	if(left_type == "float" || right_type == "float")
	{
		return "float";
	}
	if((left_type == "int" || left_type == "char") && (right_type == "int" || right_type == "char"))
	{
		return "int";
	}
	return "";
}

bool reject_void_expression(symbol_info *first, symbol_info *second = NULL)
{
	symbol_info *void_expression = NULL;

    if(first != NULL && first->get_semantic_type() == "void")
    {
        void_expression = first;
    }
    else if(second != NULL && second->get_semantic_type() == "void")
    {
        void_expression = second;
    }

    if(void_expression == NULL)
    {
        return false;
    }

    string function_name = void_expression->get_void_function_name();

    if(function_name == "")
    {
        report_error("Void function used in expression");
    }
    else
    {
        report_error("Void function used in expression: " + function_name);
    }

    if(first != NULL && first->get_semantic_type() == "void")
    {
        first->set_semantic_type("error");
    }

    if(second != NULL && second->get_semantic_type() == "void")
    {
        second->set_semantic_type("error");
    }
    return true;
}

void check_assignment_type(symbol_info *left, symbol_info *right)
{
	string left_type = left->get_semantic_type();
	string right_type = right->get_semantic_type();

	if(left_type == "error" || right_type == "error" || left_type == "" || right_type == "")
	{
		return;
	}

	
	if(right_type == "void")
    {
        reject_void_expression(right);
		return;
    }

	bool left_is_int = left_type == "int" || left_type == "char";
	bool right_is_int =  right_type == "int" || right_type == "char";

	if(left_is_int && right_type == "float")
	{
		report_error("Warning: possible loss of data in assignment of FLOAT to INT");
	}
	else if(left_type == "float" && right_is_int)
	{
		//Integer to float coversion is allowed
	}
	else if(left_is_int && right_is_int)
	{
		//integer family assignment is allowed
	}
	else if(left_type != right_type)
	{
		report_error("Type mismatch in assignment");
	}
}

void check_function_call(symbol_info *identifier, symbol_info *argument_list, symbol_info *result)
{
	string function_name = identifier->getname();

    symbol_info *found_symbol = table->lookup(identifier);

	if(found_symbol == NULL)
	{
		report_error("Undeclared function: " + function_name);
		result->set_semantic_type("error");
		return;
	}

	if(found_symbol->get_symbol_category() != "Function Definition")
	{
		report_error("Function call with non-function type identifier: " + function_name);
		result->set_semantic_type("error");
        return;
	}
	
	vector<pair<string, string>> parameters = found_symbol->get_parameters();

    vector<string> argument_types = argument_list->get_argument_types();

    if(parameters.size() != argument_types.size())
	{
		report_error( "Inconsistencies in number of arguments in function call: " + function_name);
		result->set_semantic_type("error");
        return;
	}
	bool argument_error = false;

	for(int i = 0; i < static_cast<int>(argument_types.size()); i++)
	{
		if(argument_types[i] == "error")
		{
			 argument_error = true;
		}
		else if(argument_types[i] != parameters[i].first)
		{
			report_error("argument " + to_string(i + 1) + " type mismatch in function call: " + function_name);
			argument_error = true;
		}
	}

	if(argument_error)
    {
        result->set_semantic_type("error");
    }
    else
    {
        result->set_semantic_type(found_symbol->get_data_type());

        if(found_symbol->get_data_type() == "void")
        {
            result->set_void_function_name(function_name);
        }
	}

}


void insert_declared_symbol(symbol_info *declared_symbol)
{
	if(current_data_type == "void")
	{
		declaration_errors.push_back("variable type can not be void");
		declared_symbol->set_data_type("error");
	}

	if(!table->insert(declared_symbol))
	{
		declaration_errors.push_back("Multiple declaration of variable " + declared_symbol->getname());
		delete declared_symbol;
	}
}


void add_current_parameter(const string& parameter_type, const string& parameter_name)
{
	if(parameter_name != "")
	{
		for(const pair<string, string>& parameter : current_parameters)
		{
			if(parameter.second == parameter_name)
			{
				report_error("Multiple declaration of variable " + parameter_name + " in parameter of " + current_function_name);
				break;
			}
		}
	}
	current_parameters.push_back({parameter_type, parameter_name});
}


void yyerror(char *s)
{
	report_error(s);

    // you may need to reinitialize variables if you find an error
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		// Print your whole symbol table here
		table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN
		{
			current_function_name = $2->getname();
		}
		param_list RPAREN 
		{
            symbol_info *function_symbol = new symbol_info($2->getname(), "ID");

            function_symbol->set_symbol_category("Function Definition");
            function_symbol->set_data_type($1->getname());
            function_symbol->set_parameters(current_parameters);

           if(!table->insert(function_symbol))
			{
    			report_error("Multiple declaration of function " + $2->getname());

		    	delete function_symbol;
			}

            function_scope_pending = true;
        }
		compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$5->getname()+")\n"<<$8->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$5->getname()+")\n"+$8->getname(),"func_def");	
			
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
		}
		| type_specifier ID LPAREN
		{
			current_function_name = $2->getname();
			current_parameters.clear();
		}
		RPAREN 
		{

            symbol_info *function_symbol = new symbol_info($2->getname(), "ID");

            function_symbol->set_symbol_category("Function Definition");
			function_symbol->set_data_type($1->getname());
            function_symbol->set_parameters(current_parameters);

            if(!table->insert(function_symbol))
			{
    			report_error("Multiple declaration of function " + $2->getname());
    			delete function_symbol;
			}

            function_scope_pending = true;
        }
		compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$7->getname(),"func_def");	
		}
 		;

param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;

			//current_parameters.push_back({$3->getname(), $4->getname()});
			add_current_parameter($3->getname(), $4->getname());

			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;

			//current_parameters.push_back({$3->getname(), ""});
			add_current_parameter($3->getname(), "");

			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;

			current_parameters.clear();
            //current_parameters.push_back({$1->getname(), $2->getname()});
			add_current_parameter($1->getname(), $2->getname());

			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;

			current_parameters.clear();
            //current_parameters.push_back({$1->getname(), ""});
			add_current_parameter($1->getname(), "");

			$$ = new symbol_info($1->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		;

compound_statement : LCURL
			{
                table->enter_scope();

                next_scope_id++;
                active_scope_ids.push_back(next_scope_id);

                outlog << "New ScopeTable with ID "
                       << next_scope_id
                       << " created" << endl << endl;

                if(function_scope_pending)
                {
                    for(pair<string, string> parameter : current_parameters)
                    {
                        if(parameter.second != "")
                        {
                            symbol_info *parameter_symbol = new symbol_info(parameter.second,"ID");

                            parameter_symbol->set_symbol_category("Variable");
                            parameter_symbol->set_data_type(parameter.first);

                            table->insert(parameter_symbol);
                        }
                    }

                    function_scope_pending = false;
                    current_parameters.clear();
                }
            }
			statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
                // The compound statement is complete.
                // Print the symbol table here and exit the scope
                // Note that function parameters should be in the current scope

				table->print_all_scopes(outlog);

                int removed_scope_id = active_scope_ids.back();

                table->exit_scope();
                active_scope_ids.pop_back();

                outlog << "Scopetable with ID "
                       << removed_scope_id
                       << " removed" << endl << endl;
 		    }
 		    | LCURL 
			{
                table->enter_scope();

                next_scope_id++;
                active_scope_ids.push_back(next_scope_id);

                outlog << "New ScopeTable with ID "
                       << next_scope_id
                       << " created" << endl << endl;

                if(function_scope_pending)
                {
                    for(pair<string, string> parameter : current_parameters)
                    {
                        if(parameter.second != "")
                        {
                            symbol_info *parameter_symbol = new symbol_info(parameter.second, "ID");

                            parameter_symbol->set_symbol_category("Variable");
                            parameter_symbol->set_data_type(parameter.first);

                            table->insert(parameter_symbol);
                        }
                    }

                    function_scope_pending = false;
                    current_parameters.clear();
                }
            }
			RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				// The compound statement is complete.
                // Print the symbol table here and exit the scope

				table->print_all_scopes(outlog);

                int removed_scope_id = active_scope_ids.back();

                table->exit_scope();
                active_scope_ids.pop_back();

                outlog << "Scopetable with ID "
                       << removed_scope_id
                       << " removed" << endl << endl;
 		    }
 		    ;
 		    
variable_decl : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;

			for(const string &message : declaration_errors)
			{
				report_error(message);
			}
			declaration_errors.clear();
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
			
			// Insert necessary information about the variables in the symbol table
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;

			current_data_type = "int";
			
			$$ = new symbol_info("int","type");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;

			current_data_type = "float";
			
			$$ = new symbol_info("float","type");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;

			current_data_type = "void";
			
			$$ = new symbol_info("void","type");
	    }
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;

			current_data_type = "char";
			
			$$ = new symbol_info("char","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			symbol_info *variable_symbol = new symbol_info($3->getname(), "ID");

			variable_symbol->set_symbol_category("Variable");
            variable_symbol->set_data_type(current_data_type);

			//table->insert(variable_symbol);           before
			insert_declared_symbol(variable_symbol);  //after

			$$ = new symbol_info($1->getname()+","+$3->getname(), "declaration_list");
			
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later

			symbol_info *array_symbol = new symbol_info($3->getname(), "ID");

			array_symbol->set_symbol_category("Array");
            array_symbol->set_data_type(current_data_type);
            array_symbol->set_array_size(stoi($5->getname()));

            insert_declared_symbol(array_symbol);

            $$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]", "declaration_list");

 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later

			symbol_info *variable_symbol = new symbol_info($1->getname(), "ID");

            variable_symbol->set_symbol_category("Variable");
            variable_symbol->set_data_type(current_data_type);

            insert_declared_symbol(variable_symbol);

            $$ = new symbol_info($1->getname(), "declaration_list");
			
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			
			symbol_info *array_symbol = new symbol_info($1->getname(), "ID");

            array_symbol->set_symbol_category("Array");
            array_symbol->set_data_type(current_data_type);
            array_symbol->set_array_size(stoi($3->getname()));

            insert_declared_symbol(array_symbol);

            $$ = new symbol_info($1->getname()+"["+$3->getname()+"]", "declaration_list");
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   ;
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			reject_void_expression($4);

			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			reject_void_expression($3);

			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			reject_void_expression($3);

			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			reject_void_expression($3);

			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 

			//new addition
			symbol_info *found_symbol = table->lookup($3);

			if(found_symbol == NULL || found_symbol->get_symbol_category() == "Function Definition")
    		{
        		report_error("Undeclared variable " + $3->getname());
    		}
			else if(found_symbol->get_symbol_category() == "Array")
			{
				report_error("variable is of array type : " + $3->getname());
			}
			
			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			reject_void_expression($2);

			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");

				copy_semantic_type($$, $1);
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"varbl");

		//new addition
		symbol_info *found_symbol = table->lookup($1);

		if (found_symbol == NULL || found_symbol->get_symbol_category() == "Function Definition") {
			report_error("Undeclared variable " + $1->getname());

			$$->set_semantic_type("error");			
		}
		else if(found_symbol->get_symbol_category() == "Array") 
		{
			report_error("variable is of array type : " + $1->getname());

			$$->set_semantic_type("error");
		}
		else
		{
			$$->set_semantic_type(found_symbol->get_data_type());
		}	
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");

		//new addition
		symbol_info *found_symbol = table->lookup($1);
		
		if(found_symbol == NULL || found_symbol->get_symbol_category() == "Function Definition")
		{
			report_error("Undeclared variable " + $1->getname());
			$$->set_semantic_type("error");
		}
		else if(found_symbol->get_symbol_category() != "Array")
		{
			report_error("variable is not of array type : " + $1->getname());
			$$->set_semantic_type("error");
		}
		else if($3->get_semantic_type() == "error")
    	{
        	$$->set_semantic_type("error");
    	}
		else if(reject_void_expression($3))
		{
    			$$->set_semantic_type("error");
		}
		else if($3->get_semantic_type() != "int" && $3->get_semantic_type() != "char")
    	{
        	report_error("array index is not of integer type : " + $1->getname());
        	$$->set_semantic_type("error");
    	}
		else
		{
			$$->set_semantic_type(found_symbol->get_data_type());
		}
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
			copy_semantic_type($$, $1);
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			check_assignment_type($1, $3);

			$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
			copy_semantic_type($$, $1);
	   }
	   ;
			
logic_expression : rel_expression
	    {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			copy_semantic_type($$, $1);
	    }	
		| rel_expression LOGICOP rel_expression 
		{
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
			
			if($1->get_semantic_type() == "error" || $3->get_semantic_type() == "error")
			{
    			$$->set_semantic_type("error");
			}
			else if(reject_void_expression($1, $3))
			{
    			$$->set_semantic_type("error");
			}
			else
			{
    			$$->set_semantic_type("int");
			}
	    }	
		;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			copy_semantic_type($$, $1);
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
			
			if($1->get_semantic_type() == "error" || $3->get_semantic_type() == "error")
			{
    			$$->set_semantic_type("error");
			}
			else if(reject_void_expression($1, $3))
			{
    			$$->set_semantic_type("error");
			}
			else
			{
    			$$->set_semantic_type("int");
			}
	    }
		;
				
simple_expression : term
        {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			copy_semantic_type($$, $1);
			
	    }
		| simple_expression ADDOP term 
		{
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
			if($1->get_semantic_type() == "error" || $3->get_semantic_type() == "error")
			{
    			$$->set_semantic_type("error");
			}
			else if(reject_void_expression($1, $3))
			{
    			$$->set_semantic_type("error");
			}
			else
			{
    			$$->set_semantic_type(arith_result_type($1, $3));
			}     
		}
		;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
			copy_semantic_type($$, $1);
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");

			string operation = $2->getname();
			string left_type = $1->get_semantic_type();
			string right_type = $3->get_semantic_type();
			
			bool operation_error = false;

			if(left_type == "error" || right_type == "error")
    		{
        		operation_error = true;
    		}
			else if(reject_void_expression($1, $3))
			{
    			operation_error = true;
			}
			else if(operation == "%" && !((left_type == "int" || left_type == "char") && (right_type == "int" || right_type == "char")))
			{
				report_error("Both operands of modulus operator should be integers");
				operation_error = true;
			}
			else if((operation == "%" || operation == "/") && $3->is_constant() && $3->get_constant_value() == 0.0)
			{
				if(operation == "%")
				{
					report_error("Modulus by zero");
				}
				else
				{
					report_error("Division by zero");
				}
				operation_error = true;
			}

			if(operation_error)
			{
				$$->set_semantic_type("error");
			}
			else
			{
				$$->set_semantic_type(arith_result_type($1, $3));
				if($1->is_constant() && $3->is_constant())
				{
					double left_value = $1->get_constant_value();
					double right_value = $3->get_constant_value();

					if(operation == "*")
            		{
                		$$->set_constant_value(left_value * right_value);
            		}
					else if(operation == "/")
            		{
                		$$->set_constant_value(left_value / right_value);
            		}
            		else if(operation == "%")
            		{
                		$$->set_constant_value(fmod(left_value, right_value));
            		}
				}
			}
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		{
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
			copy_semantic_type($$, $2);

			if($2->get_semantic_type() == "void")
			{
    			reject_void_expression($2);
    			$$->set_semantic_type("error");
			}
	    }
		| NOT unary_expression 
		{
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->getname(),"un_expr");
			if($2->get_semantic_type() == "error")
			{
    			$$->set_semantic_type("error");
			}
			else if(reject_void_expression($2))
			{
    			$$->set_semantic_type("error");
			}
			else
			{
    			$$->set_semantic_type("int");
			}
	    }
		| factor_info  
		{
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info  "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			copy_semantic_type($$, $1);
	    }
		;

factor_info : factor	
	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr_info");
		copy_semantic_type($$, $1);
	}
	;	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		copy_semantic_type($$, $1);
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;

		$$ = new symbol_info($1->getname()+"("+$3->getname()+")","fctr");
		
		check_function_call($1, $3, $$);
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		copy_semantic_type($$, $2);
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_semantic_type("int");

		$$->set_constant_value(stod($1->getname()));
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_semantic_type("float");

		$$->set_constant_value(stod($1->getname()));
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
		copy_semantic_type($$, $1);
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
		copy_semantic_type($$, $1);
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
					$$->set_argument_types($1->get_argument_types());
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");

				reject_void_expression($3);

				$$->set_argument_types($1->get_argument_types());
				$$->add_argument_type($3->get_semantic_type());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname(),"arg");

				reject_void_expression($1);

				$$->add_argument_type($1->get_semantic_type());
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("22201333_23101140_log.txt", ios::trunc);
	outerror.open("22201333_23101140_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here

	table = new symbol_table(10);
	table->enter_scope();

	next_scope_id++;
	active_scope_ids.push_back(next_scope_id);

	outlog << "New ScopeTable with ID "
		   << next_scope_id
		   <<" created" <<endl << endl;

	yyparse();
	
	outlog<< endl << "Total lines: " << lines << endl;
	outlog<< "Total errors: " << error_count << endl;

	outerror << "Total errors: " << error_count << endl;
	
	delete table;
	table = NULL;
	
	outlog.close();
	outerror.close();
	
	fclose(yyin);
	
	return 0;
}