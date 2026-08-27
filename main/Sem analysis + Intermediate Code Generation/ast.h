#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Variable node (for ID references)

class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                              int& temp_count, int& label_count) const {
        // TODO: Implement this method
        // Should generate code to calculate the array index and return the temp variable
        
        if (index == nullptr) {
            return "";
        }

        //Generate and return the temporary containing the index
        return index->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for variable access or array access
        
        //handle array access
        if (has_index()) {
            string index_temp = generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
        string result_temp = "t" + to_string(temp_count);
        temp_count++;

        outcode << result_temp << " = "
                << name << "[" << index_temp << "]" << endl;
        
        return result_temp; 
        }

        // handle a normal variable
        string temp = "t" + to_string(temp_count);
        temp_count++;

        if (symbol_to_temp.find(name) == symbol_to_temp.end()) {
            outcode << temp << " = " << name << endl;
            symbol_to_temp[name] = temp;
        }

        return symbol_to_temp[name];
        
    }
    
    string get_name() const { return name; }
};

// Constant node

class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for constant values

        string temp = "t" + to_string(temp_count);
        temp_count++;

        outcode << temp << " = " << value << endl;

        return temp; 
    }
};

// Binary operation node

class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for binary operations

        // Generate code for the left expression
        string left_temp = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        // Generaste code for the right expr
        string right_temp = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        // Create a temporary for the result
        string result_temp = "t" + to_string(temp_count);
        temp_count++;

        // Generate the operation
        outcode << result_temp << " = "
                << left_temp << " "
                << op << " "
                << right_temp << endl;
        return result_temp;
    }
};

// Unary operation node

class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for unary operations

        // generate code for the expr
        string expr_temp = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        // create a temporary for the result 
        string result_temp = "t" + to_string(temp_count);
        temp_count++;

        // generate the unary operation
        outcode << result_temp << " = "
                << op << expr_temp << endl;
        return result_temp;
    
    }
};

// Assignment node

class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for assignment operations
        
        //generate the value that will be assigned 
        string rhs_temp = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        //array assignment 
        if (lhs->has_index()) {
            string index_temp = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);

            outcode << lhs->get_name()
                    << "[" << index_temp << "]"
                    << " = " << rhs_temp << endl;
        }
        else {    
            outcode << lhs->get_name()
                    << " = " << rhs_temp << endl;
            
            //update an existing remembered value
            auto found = symbol_to_temp.find(lhs->get_name());

            if (found != symbol_to_temp.end()) {
                found->second = rhs_temp;
            }
        }
        return rhs_temp;

    }
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for expression statements

        // An empty statement such as ";" generates no code
        if (expr == nullptr) {
            return "";
        }

        // Generate code for the expression
        return expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for all statements in the block

        string last_result = "";

        // Generate code for each statement in order
        for (auto stmt : statements) {
            if (stmt != nullptr) {
                last_result = stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            }
        }

        return last_result;

    }
};

// If statement node

class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for if-else statements

        // Generate the condition
        string condition_temp = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        //Create labels
        string true_label = "L" + to_string(label_count);
        label_count++;

        string false_label = "L" + to_string(label_count);
        label_count++;

        string end_label = "L" + to_string(label_count);
        label_count++;

        // decide which section to enter
        outcode << "if " << condition_temp
                << " goto " << true_label << endl;
        
        outcode << "goto " << false_label << endl;

        //true section
         outcode << true_label << ":" << endl;

        if (then_block != nullptr) {
            then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        outcode << "goto " << end_label << endl;

        // False section
        outcode << false_label << ":" << endl;

        if (else_block != nullptr) {
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        //end of the complete if stmt
        outcode << end_label << ":" << endl;

        return "";
    }
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for while loops

        //create the loop labels
        string condition_label = "L" + to_string(label_count);
        label_count++;

        string body_label = "L" + to_string(label_count);
        label_count++;

        string end_label = "L" + to_string(label_count);
        label_count++;

        //start by checking the condition
        outcode << condition_label << ":" << endl;

        string condition_temp = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        outcode << "if " << condition_temp
                << " goto " << body_label << endl;

        outcode << "goto " << end_label << endl;

        // Loop body
        outcode << body_label << ":" << endl;

        if (body != nullptr) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        // Repeat the loop
        outcode << "goto " << condition_label << endl;

        // Exit location
        outcode << end_label << ":" << endl;

        return "";
    }
};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for for loops

        // Run the initialization once
        if (init != nullptr) {
            init->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        // Create the loop labels
        string condition_label = "L" + to_string(label_count);
        label_count++;

        string body_label = "L" + to_string(label_count);
        label_count++;

        string end_label = "L" + to_string(label_count);
        label_count++;

        // Check the condition
        outcode << condition_label << ":" << endl;

        string condition_temp = "";

        if (condition != nullptr) {
            condition_temp = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        // A missing condition means the loop continues
        if (condition_temp.empty()) {
            outcode << "goto " << body_label << endl;
        }
        else {
            outcode << "if " << condition_temp
                    << " goto " << body_label << endl;

            outcode << "goto " << end_label << endl;
        }

        // Generate the loop body
        outcode << body_label << ":" << endl;

        if (body != nullptr) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        // Generate the update expression
        if (update != nullptr) {
            update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        // Return to the condition
        outcode << "goto " << condition_label << endl;

        // Exit location
        outcode << end_label << ":" << endl;

        return "";
    }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for return statements

        // Return without an expression
        if (expr == nullptr) {
            outcode << "return" << endl;
            return "";
        }

        //Generate the returned expression
        string return_temp = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        outcode << "return " << return_temp << endl;

        return return_temp;
    
    }
};

// Declaration node

class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; // Variable name and array size (0 for regular vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for variable declarations

        //Print each declaration as a comment
        for (const auto& variable : vars) {
            outcode << "// Declaration: "
                    << type << " "
                    << variable.first;
            
            // A positive size means this is an array
            if (variable.second > 0) {
                outcode << "[" << variable.second << "]";
            }

            outcode << endl;
        }

        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for function declarations

        // Start a fresh temporary map for this function
        symbol_to_temp.clear();
        
        // Print the function information
        outcode << "// Function: "
                << return_type << " "
                << name << "(";
        
        for (size_t i = 0; i < params.size(); i++) {
            outcode << params[i].first
                    << " "
                    << params[i].second;
            
            if (i + 1 < params.size()) {
                outcode << ", ";
            }
        }

        outcode << ")" << endl;

        // Generate the function body
        if (body != nullptr) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        outcode << endl;
        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // This node doesn't generate code directly
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for function calls

        // Generate every function argument
        for (auto argument : arguments) {
            if (argument != nullptr) {
                string argument_temp = argument->generate_code(outcode, symbol_to_temp, temp_count, label_count);
                
                outcode << "param " << argument_temp << endl;
            }
        }

        // A void function does not return a value
        if (node_type == "void") {
            outcode << "call " << func_name
                    << ", " << arguments.size() << endl;
            return "";
        }

        // Create a temporary for the returned value
        string result_temp = "t" + to_string(temp_count);
        temp_count++;

        outcode << result_temp
                << " = call " << func_name
                << ", " << arguments.size() << endl;

        return result_temp;

    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // TODO: Implement this method
        // Should generate code for the entire program
        for (auto unit : units) {
            if (unit != nullptr) {
                unit -> generate_code(outcode, symbol_to_temp, temp_count, label_count);
            }
        }
        return "";
    }
};

#endif // AST_H