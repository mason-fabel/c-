%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "getopt.h"
#include "ast.h"
#include "symtab.h"
#include "token.h"

#define DEFINED 1

extern void scanner_use_file(char*);
extern int yylex(void);

extern int yydebug;
extern int optind;

void yyerror(const char* msg);
void print_value(token_t* tok);
void print_input(token_t* tok);
void print_token(token_t* tok);
const char* token_name(int token_class);

int parser_errors = 0;
int parser_warnings = 0;
Scope* record_types = new Scope("record");
ast_t* syntax_tree;
%}

%union {
	token_t* token;
	ast_t* node;
}

%token <token> ADDASS
%token <token> AND
%token <token> BOOL
%token <token> BOOLCONST
%token <token> BREAK
%token <token> CHAR
%token <token> CHARCONST
%token <token> DEC
%token <token> DIVASS
%token <token> ELSE
%token <token> EQ
%token <token> GRTEQ
%token <token> ID
%token <token> IF
%token <token> INC
%token <token> INT
%token <token> LESSEQ
%token <token> MULASS
%token <token> NOT
%token <token> NOTEQ
%token <token> NUMCONST
%token <token> OR
%token <token> RECORD
%token <token> RECTYPE
%token <token> RETURN
%token <token> STATIC
%token <token> SUBASS
%token <token> WHILE

%type<token> '+'
%type<token> '-'
%type<token> '*'
%type<token> '/'
%type<token> '%'
%type<token> '?'
%type<token> '='
%type<token> '<'
%type<token> '>'
%type<token> '('
%type<token> ')'
%type<token> '['
%type<token> ']'
%type<token> '{'
%type<token> '}'
%type<token> '.'
%type<token> ','
%type<token> ':'
%type<token> ';'
%type<node> declarationList
%type<node> declaration
%type<node> recDeclaration
%type<node> varDeclaration
%type<node> scopedVarDeclaration
%type<node> varDeclList
%type<node> varDeclInitialize
%type<node> varDeclId
%type<node> scopedTypeSpecifier
%type<node> typeSpecifier
%type<node> returnTypeSpecifier
%type<node> funDeclaration
%type<node> params
%type<node> paramList
%type<node> paramTypeList
%type<node> paramIdList
%type<node> paramId
%type<node> statement
%type<node> matchedStmt
%type<node> unmatchedStmt
%type<node> otherStmt
%type<node> compoundStmt
%type<node> localDeclarations
%type<node> statementList
%type<node> expressionStmt
%type<node> returnStmt
%type<node> breakStmt
%type<node> expression
%type<node> simpleExpression
%type<node> andExpression
%type<node> unaryRelExpression
%type<node> relExpression
%type<node> relop
%type<node> sumExpression
%type<node> sumop
%type<node> term
%type<node> mulop
%type<node> unaryExpression
%type<node> unaryop
%type<node> factor
%type<node> mutable
%type<node> immutable
%type<node> call
%type<node> args
%type<node> argList
%type<node> constant

%token-table

%start program

%%

program					: declarationList {
							syntax_tree = $1;
						}
						;

declarationList			: declarationList declaration {
							$$ = $1;
							ast_add_sibling($$, $2);
						}
						| declaration {
							$$ = $1;
						}
						;

declaration				: varDeclaration {
							$$ = $1;
						}
						| funDeclaration {
							$$ = $1;
						}
						| recDeclaration {
							$$ = $1;
						}
						;

recDeclaration			: RECORD ID '{' localDeclarations '}' {
							record_types->insert(
								std::string($2->value.str_val),
								(void*) DEFINED);

							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_RECORD;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $4);
						}
						;

varDeclaration			: typeSpecifier varDeclList ';' {
							ast_t* node;
							ast_t* decl;

							$$ = NULL;
							node = $2;


							while (node != NULL) {
								decl = ast_create_node();
								decl->lineno = node->lineno;
								decl->data.name = strdup(node->data.name);

								switch ($1->data.token_class) {
									case BOOL:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_BOOL_ARRAY;
										} else {
											decl->type = TYPE_VAR_BOOL;
										}
										break;
									case CHAR:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_CHAR_ARRAY;
										} else {
											decl->type = TYPE_VAR_CHAR;
										}
										break;
									case INT:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_INT_ARRAY;
										} else {
											decl->type = TYPE_VAR_INT;
										}
										break;
									case RECTYPE:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_REC_ARRAY;
										} else {
											decl->type = TYPE_VAR_REC;
										}
										break;
								}

								if (node->child[0]) {
									ast_add_child(decl, 0, node->child[0]);
								}

								if ($$ == NULL) {
									$$ = decl;
								} else {
									ast_add_sibling($$, decl);
								}

								node = node->sibling;
							}
						}
						;

scopedVarDeclaration	: scopedTypeSpecifier varDeclList ';' {
							ast_t* node;
							ast_t* decl;

							$$ = NULL;
							node = $2;

							while (node != NULL) {
								decl = ast_create_node();
								decl->lineno = node->lineno;
								decl->data.name = strdup(node->data.name);

								switch ($1->data.token_class) {
									case BOOL:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_BOOL_ARRAY;
										} else {
											decl->type = TYPE_VAR_BOOL;
										}
										break;
									case CHAR:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_CHAR_ARRAY;
										} else {
											decl->type = TYPE_VAR_CHAR;
										}
										break;
									case INT:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_INT_ARRAY;
										} else {
											decl->type = TYPE_VAR_INT;
										}
										break;
									case RECTYPE:
										if (node->data.is_array) {
											decl->type = TYPE_VAR_REC_ARRAY;
										} else {
											decl->type = TYPE_VAR_REC;
										}
										break;
								}

								if (node->child[0]) {
									ast_add_child(decl, 0, node->child[0]);
								}

								if ($$ == NULL) {
									$$ = decl;
								} else {
									ast_add_sibling($$, decl);
								}

								node = node->sibling;
							}
						}
						;

varDeclList				: varDeclList ',' varDeclInitialize {
							$$ = $1;
							ast_add_sibling($$, $3);
						}
						| varDeclInitialize {
							$$ = $1;
						}
						;

varDeclInitialize		: varDeclId {
							$$ = $1;
						}
						| varDeclId ':' simpleExpression {
							$$ = $1;
							ast_add_child($$, 0, $3);
						}
						;

varDeclId				: ID {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_ID;
							$$->data.name = strdup($1->input);
						}
						| ID '[' NUMCONST ']' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_ID;
							$$->data.name = strdup($1->input);
							$$->data.is_array = 1;
						}
						;

scopedTypeSpecifier		: STATIC typeSpecifier {
							$$ = $2;
						}
						| typeSpecifier {
							$$ = $1;
						}
						;

typeSpecifier			: returnTypeSpecifier {
							$$ = $1;
						}
						| RECTYPE {
							$$ = ast_from_token($1);
						}
						;

returnTypeSpecifier		: INT {
							$$ = ast_from_token($1);
						}
						| BOOL {
							$$ = ast_from_token($1);
						}
						| CHAR {
							$$ = ast_from_token($1);
						}
						;

funDeclaration			: typeSpecifier ID '(' params ')' statement {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;

							switch ($1->data.token_class) {
								case BOOL:
									$$->type = TYPE_FUNC_BOOL;
									break;
								case CHAR:
									$$->type = TYPE_FUNC_CHAR;
									break;
								case INT:
									$$->type = TYPE_FUNC_INT;
									break;
								case RECTYPE:
									$$->type = TYPE_FUNC_REC;
									break;
							}

							$$->data.name = strdup($2->value.str_val);

							ast_add_child($$, 0, $4);
							ast_add_child($$, 1, $6);
						}
						| ID '(' params ')' statement {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_FUNC_VOID;
							$$->data.name = strdup($1->value.str_val);
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
						}
						;

params					: paramList {
							$$ = $1;
						}
						| %empty {
							$$ = NULL;
						}
						;

paramList				: paramList ';' paramTypeList {
							$$ = $1;
							ast_add_sibling($$, $3);
						}
						| paramTypeList {
							$$ = $1;
						}
						;

paramTypeList			: typeSpecifier paramIdList {
							ast_t* node;
							ast_t* decl;

							$$ = NULL;
							node = $2;

							while (node != NULL) {
								decl = ast_create_node();
								decl->lineno = node->lineno;
								decl->data.name = strdup(node->data.name);

								switch ($1->data.token_class) {
									case BOOL:
										if (node->data.is_array) {
											decl->type = TYPE_PARAM_BOOL_ARRAY;
										} else {
											decl->type = TYPE_PARAM_BOOL;
										}
										break;
									case CHAR:
										if (node->data.is_array) {
											decl->type = TYPE_PARAM_CHAR_ARRAY;
										} else {
											decl->type = TYPE_PARAM_CHAR;
										}
										break;
									case INT:
										if (node->data.is_array) {
											decl->type = TYPE_PARAM_INT_ARRAY;
										} else {
											decl->type = TYPE_PARAM_INT;
										}
										break;
									case RECTYPE:
										if (node->data.is_array) {
											decl->type = TYPE_PARAM_REC_ARRAY;
										} else {
											decl->type = TYPE_PARAM_REC;
										}
										break;
								}

								if (node->child[0]) {
									ast_add_child(decl, 0, node->child[0]);
								}

								if ($$ == NULL) {
									$$ = decl;
								} else {
									ast_add_sibling($$, decl);
								}

								node = node->sibling;
							}
						}
						;

paramIdList				: paramIdList ',' paramId {
							$$ = $1;
							ast_add_sibling($$, $3);
						}
						| paramId {
							$$ = $1;
						}
						;

paramId					: ID {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_ID;
							$$->data.name = strdup($1->input);
						}
						| ID '[' ']' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_ID;
							$$->data.name = strdup($1->input);
							$$->data.is_array = 1;
						}
						;

statement				: matchedStmt {
							$$ = $1;
						}
						| unmatchedStmt {
							$$ = $1;
						}
						;

matchedStmt				: IF '(' simpleExpression ')' matchedStmt ELSE matchedStmt {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_IF;
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
							ast_add_child($$, 2, $7);
						}
						| WHILE '(' simpleExpression ')' matchedStmt {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_WHILE;
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
						}
						| otherStmt {
							$$ = $1;
						}
						;

unmatchedStmt			: IF '(' simpleExpression ')' matchedStmt {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_IF;
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
						}
						| IF '(' simpleExpression ')' unmatchedStmt {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_IF;
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
						}
						| IF '(' simpleExpression ')' matchedStmt ELSE unmatchedStmt {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_IF;
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
							ast_add_child($$, 2, $7);
						}
						| WHILE '(' simpleExpression ')' unmatchedStmt {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_WHILE;
							ast_add_child($$, 0, $3);
							ast_add_child($$, 1, $5);
						}
						;

otherStmt				: expressionStmt {
							$$ = $1;
						}
						| compoundStmt {
							$$ = $1;
						}
						| returnStmt {
							$$ = $1;
						}
						| breakStmt {
							$$ = $1;
						}
						;

compoundStmt			: '{' localDeclarations statementList '}' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_COMPOUND;
							ast_add_child($$, 0, $2);
							ast_add_child($$, 1, $3);
						}
						;

localDeclarations		: localDeclarations scopedVarDeclaration {
							if ($1 == NULL) {
								$$ = $2;
							} else {
								$$ = $1;
								ast_add_sibling($$, $2);
							}
						}
						| %empty {
							$$ = NULL;
						}
						;

statementList			: statementList statement {
							if ($1 == NULL && $2 == NULL) {
								$$ = NULL;
							} else if ($1 == NULL) {
								$$ = $2;
							} else if ($2 == NULL) {
								$$ = $1;
							} else {
								ast_add_sibling($$, $2);
							}
						}
						| %empty {
							$$ = NULL;
						}
						;

expressionStmt			: expression ';' {
							$$ = $1;
						}
						| ';' {
							$$ = NULL;
						}
						;

returnStmt				: RETURN ';' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_RETURN;
						}
						| RETURN expression ';' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_RETURN;
							ast_add_child($$, 0, $2);
						}
						;

breakStmt				: BREAK ';' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_BREAK;
						}
						;

expression				: mutable '=' expression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| mutable ADDASS expression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| mutable SUBASS expression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| mutable MULASS expression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| mutable DIVASS expression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| mutable INC {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
						}
						| mutable DEC {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_ASSIGN;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
						}
						| simpleExpression {
							$$ = $1;
						}
						;

simpleExpression		: simpleExpression OR andExpression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| andExpression {
							$$ = $1;
						}
						;

andExpression			: andExpression AND unaryRelExpression {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| unaryRelExpression {
							$$ = $1;
						}
						;

unaryRelExpression		: NOT unaryRelExpression {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
							ast_add_child($$, 0, $2);
						}
						| relExpression {
							$$ = $1;
						}
						;

relExpression			: sumExpression relop sumExpression {
							$$ = $2;
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| sumExpression {
							$$ = $1;
						}
						;

relop					: LESSEQ {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '<' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '>' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| GRTEQ {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| EQ {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| NOTEQ {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						;

sumExpression			: sumExpression sumop term {
							$$ = $2;
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| term {
							$$ = $1;
						}
						;

sumop					: '+' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '-' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						;

term					: term mulop unaryExpression {
							$$ = $2;
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| unaryExpression {
							$$ = $1;
						}
						;

mulop					: '*' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '/' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '%' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						;

unaryExpression			: unaryop unaryExpression {
							$$ = $1;
							ast_add_child($$, 0, $2);
						}
						| factor {
							$$ = $1;
						}
						;

unaryop					: '-' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '*' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						| '?' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($1->input);
						}
						;

factor					: immutable {
							$$ = $1;
						}
						| mutable {
							$$ = $1;
						}
						;

mutable					: ID {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_ID;
							$$->data.name = strdup($1->input);
						}
						| mutable '[' expression ']' {
							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($2->input);
							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, $3);
						}
						| mutable '.' ID {
							ast_t* id;

							$$ = ast_create_node();
							$$->lineno = $2->lineno;
							$$->type = TYPE_OP;
							$$->data.name = strdup($2->input);

							id = ast_create_node();
							id->lineno = $3->lineno;
							id->type = TYPE_ID;
							id->data.name = strdup($3->input);

							ast_add_child($$, 0, $1);
							ast_add_child($$, 1, id);
						}
						;

immutable				: '(' expression ')' {
							$$ = $2;
						}
						| call {
							$$ = $1;
						}
						| constant {
							$$ = $1;
						}
						;

call					: ID '(' args ')' {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_CALL;
							$$->data.name = strdup($1->value.str_val);
							ast_add_child($$, 0, $3);
						}
						;

args					: argList {
							$$ = $1;
						}
						| %empty {
							$$ = NULL;
						}
						;

argList					: argList ',' expression {
							ast_add_sibling($$, $3);
						}
						| expression {
							$$ = $1;
						}
						;

constant				: NUMCONST {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_CONST_INT;
							$$->data.int_val = $1->value.int_val;
						}
						| CHARCONST {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_CONST_CHAR;
							$$->data.char_val = $1->value.char_val;
						}
						| BOOLCONST {
							$$ = ast_create_node();
							$$->lineno = $1->lineno;
							$$->type = TYPE_CONST_BOOL;
							$$->data.bool_val = $1->value.int_val;
						}
						;

%%

void yyerror(const char* msg) {
	fprintf(stdout, "parser error: %s\n", msg);

	return;
}

void print_value(token_t* tok) {
	switch (tok->value_mode) {
		case MODE_NONE:
			break;
		case MODE_INT:
			fprintf(stdout, " Value: %i", tok->value.int_val);
			break;
		case MODE_CHAR:
			fprintf(stdout, " Value: \'%c\'", tok->value.char_val);
			break;
		case MODE_STR:
			fprintf(stdout, " Value: %s", tok->value.str_val);
			break;
	}

	return;
}

void print_input(token_t* tok) {
	fprintf(stdout, "  Input: %s", tok->input);

	return;
}

void print_token(token_t* tok) {
	fprintf(stdout, "Line %i Token: %s", tok->lineno, token_name(tok->type));

	switch (tok->type) {
		case BOOLCONST:
		case CHARCONST:
		case ID:
		case NUMCONST:
			print_value(tok);
	}

	switch (tok->type) {
		case BOOLCONST:
		case CHARCONST:
		case NUMCONST:
			print_input(tok);
	}

	fprintf(stdout, "\n");

	return;
}

const char* token_name(int token_class) {
	char* name;

	if (token_class >= 258) {
		/* NOTE: We first undo an offset of 258 introduced by the flex token
		 * class numbering, and then add 3 as bison puts 3 tokens ("$end",
		 * "error", "$undefined") at the begining of the toke name table.
		 */
		name = (char*) yytname[token_class - 258 + 3];
	} else {
		/* Implicit single-character token type */
		name = (char*) malloc(sizeof(char) * 2);
		snprintf(name, (size_t) 2, "%c", (char) token_class);
	}

	return (const char*) name;
}

int main(int argc, char** argv) {
	char c;
	int i;

	while ((c = getopt(argc, argv, (char*) "d")) != -1) {
		switch (c) {
			case 'd':
				yydebug = 1;
				break;
			case '?':
			default:
				fprintf(stderr, "getopt: case '%c'\n", c);
				exit(1);
		}
	}

	switch (argc - optind) {
		case 1:
			scanner_use_file(argv[optind]);
			break;
		case 0:
			/* read from STDIN */
			break;
		default:
			fprintf(stderr, "%s: invalid arguments:\n", argv[0]);
			for (i = optind; i < argc; i++) {
				fprintf(stderr, "  %i: %s\n", i, argv[i]);
			}
			exit(1);
	}

	yyparse();

	ast_print(syntax_tree);

	fprintf(stdout, "Number of warnings: %i\n", parser_warnings);
	fprintf(stdout, "Number of errors: %i\n", parser_errors);

	exit(0);
}
