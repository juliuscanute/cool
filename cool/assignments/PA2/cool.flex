/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;
int start_string = 0;
int nested_comments = 0;
int report_error(int code,char *text);
#define LCHECK(x,y) if(x>=y){ return report_error(5,NULL); }

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */
DARROW          =>
ASSIGN          <-
LE              <=
IF              [iI][fF]
THEN            [tT][hH][eE][nN]
ELSE            [eE][lL][sS][eE]
FI              [fF][iI]
IN              [iI][nN]
NOT             [nN][oO][tT]
WHILE           [wW][hH][iI][lL][eE]
LOOP            [lL][oO][oO][pP]
POOL            [pP][oO][oO][lL]
CASE            [cC][aA][sS][eE]
ESAC            [eE][sS][aA][cC]
NEW             [nN][eE][wW]
ISVOID          [iI][sS][vV][oO][iI][dD]
CLASS           [cC][lL][aA][sS][sS]
INHERITS        [iI][nN][hH][eE][rR][iI][tT][sS]
LET             [lL][eE][tT]
OF              [oO][fF]
INT_CONST       [0-9]+
BOOL_CONST      ([t][rR][uU][eE])|([f][[aA][lL][sS][eE])
TYPEID          [A-Z][a-zA-Z_0-9]*
OBJECTID        [a-z][a-zA-Z_0-9]*
%x COMMENT STRING ESCAPE CODE SKIP
%%

 /*
  *  Nested comments
  */

<COMMENT>\*\)                      {
                                      if(nested_comments == 0)
                                        BEGIN(INITIAL);
                                      else
                                        nested_comments--;
                                   }
<COMMENT>\(\*                      {nested_comments++;}
<COMMENT>\n                        {curr_lineno += 1;}
<COMMENT><<EOF>>                   {
                                      BEGIN(INITIAL);
                                      return report_error(3,NULL);
                                   }
<COMMENT>.                         {/*eat everything in between*/}


\(\*                               {nested_comments=0;BEGIN(COMMENT);}
\-\-([^\n])*                        ;                              
\*\)                               {
                                      return report_error(4,NULL);
                                   }
 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}    { return (ASSIGN); }
{LE}        { return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{IF}        { return (IF); }
{IN}        { return (IN); }
{NOT}       { return (NOT); }
{THEN}      { return (THEN); }
{ELSE}      { return (ELSE); }
{FI}        { return (FI); }
{WHILE}     { return (WHILE); }
{LOOP}      { return (LOOP); }
{POOL}      { return (POOL); }
{CASE}      { return (CASE); }
{ESAC}      { return (ESAC); }
{NEW}       { return (NEW); }
{ISVOID}    { return (ISVOID); }
{CLASS}     { return (CLASS); }
{INHERITS}  { return (INHERITS); }
{LET}       { return (LET); }
{OF}        { return (OF); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
{INT_CONST}  { 
                cool_yylval.symbol = inttable.add_string(yytext);
                return (INT_CONST); 
             } 
{BOOL_CONST} {
                if(strcasecmp("true",yytext) == 0)
                   cool_yylval.boolean = true;
                else
                   cool_yylval.boolean = false;
                return (BOOL_CONST);
             }
{TYPEID}     {
                cool_yylval.symbol = idtable.add_string(yytext);
                return (TYPEID);
             }
{OBJECTID}   {
                cool_yylval.symbol = idtable.add_string(yytext);
                return (OBJECTID);
             }

\"                      { start_string=0;BEGIN(STRING);}
<STRING>\\              { BEGIN(ESCAPE); }
<ESCAPE>[n]             { LCHECK(start_string,MAX_STR_CONST);string_buf[start_string++] = '\n'; BEGIN(STRING);}
<ESCAPE>[b]             { LCHECK(start_string,MAX_STR_CONST);string_buf[start_string++] = '\b'; BEGIN(STRING);}
<ESCAPE>[t]             { LCHECK(start_string,MAX_STR_CONST);string_buf[start_string++] = '\t'; BEGIN(STRING);}
<ESCAPE>[f]             { LCHECK(start_string,MAX_STR_CONST);string_buf[start_string++] = '\f'; BEGIN(STRING);}
<ESCAPE>\n              { LCHECK(start_string,MAX_STR_CONST);string_buf[start_string++] = '\n'; curr_lineno += 1; BEGIN(STRING);}
<ESCAPE>\0              { BEGIN(CODE); }
<CODE>\"                { BEGIN(INITIAL);return report_error(2,NULL); }
<CODE>\\                { BEGIN(SKIP); }
<SKIP><<EOF>>           { BEGIN(INITIAL);return report_error(2,NULL);}
<SKIP>.                 { BEGIN(CODE);}
<CODE><<EOF>>           { BEGIN(INITIAL);return report_error(2,NULL); }
<CODE>\n                { BEGIN(INITIAL);return report_error(2,NULL); }
<CODE>.                 {          }
<ESCAPE><<EOF>>         {
                            BEGIN(INITIAL);
                            return report_error(0,NULL);
                        }
<ESCAPE>.               { LCHECK(start_string,MAX_STR_CONST);string_buf[start_string++] = yytext[0]; BEGIN(STRING); }
<STRING>\n              {
                            BEGIN(INITIAL);                          
                            curr_lineno += 1;
                            return report_error(1,NULL);
                        }
<STRING>\"              {
                            BEGIN(INITIAL);
                            LCHECK(start_string,MAX_STR_CONST);
                            string_buf[start_string] = '\0';
                            cool_yylval.symbol = stringtable.add_string(strdup(string_buf));
                            return (STR_CONST);
                        }
<STRING>\0              {
                          BEGIN(CODE);
                        }  
<STRING><<EOF>>         {
                            BEGIN(INITIAL);
                            return report_error(0,NULL);
                        }
<STRING>.               {
                            LCHECK(start_string,MAX_STR_CONST);
                            string_buf[start_string++] = yytext[0];
                        }
\n           curr_lineno += 1;
[ \t\v\r\f]  ;
[\+\/\-\*\=\<\.\~\,\;\:\(\)\@\{\}]    { return yytext[0]; }
.            {
                return report_error(6,yytext);
             } 
%%
int report_error(int code,char *text) {
  switch(code) {
    case 0:
        cool_yylval.error_msg = "EOF in string constant";
        break;
    case 1:
        cool_yylval.error_msg = "Unterminated string constant";
        break;
    case 2:
        cool_yylval.error_msg = "String contains null character";
        break;
    case 3:
        cool_yylval.error_msg = "EOF in comment";
        break;
    case 4:
        cool_yylval.error_msg = "Unmatched *)";
        break;
    case 5:
        cool_yylval.error_msg = "String constant too long";
        break;
    case 6:
        cool_yylval.error_msg = text;
        break;

  }
  return (ERROR);
}
