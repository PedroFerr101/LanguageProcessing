%{
    #include <stdio.h>
    #include <string.h>
    #include <glib.h>
    #include "structPage.h"
    Page p;
    int pos;
    int top_state;
    int ignore_page;

%}

%x PAGE TITLE TEXT INFOBOX PARENTHESES CATEGORY CURLY ABSTRACT INFOLINES

quotes ("''"|"'''")
sepCatg ("|")
parentOpen ("[["|"{{")
parentClose ("]]"|"}}")

%option stack

%%
"<page>"                        {BEGIN PAGE; p=initPage(); ignore_page=0;}

<PAGE>{
	"<title>"                 	{BEGIN TITLE;}
	\<text[^>]+\>/[A-Z]			{BEGIN ABSTRACT;}
	\<text[^>]+\>/[^A-Z]        {BEGIN INFOBOX;}
	"</page>"                 	{BEGIN INITIAL;	if(!ignore_page)pageToHTML(p);  printf("=================#==================#=================\n"); printPage(p); printf("=================#==================#=================\n");}
	.|\n 					   	{;}
}

<TITLE>(.+?)/"</title>"         {setPageTitle(p, yytext); BEGIN PAGE;}

<TEXT>{
	"[[Categoria:"            	{BEGIN CATEGORY;} 
	"</text>"                 	{BEGIN PAGE;}
	.|\n 						{;}
}

<CATEGORY>{	
	[^|\]]+/[\]|]				{addCategoria(p, yytext);} // apanhar texto todo até à | ou ]] (algumas catgorias nao tem | terminam logo com ]]!!!!!!!)
	[\]|]                  		{BEGIN TEXT;} // detetar fim de categoria (depois da | nao importa)
}
	
<INFOBOX>{
	#(?i:redire)												{ignore_page=1; BEGIN PAGE;}
	"{{"(?i:info)\n												{BEGIN INFOLINES; printf("nao tem tema de infobox\n");}
	"{{"(?i:info)[ /][^}\n|]+/[\n|}]							{printf("a adicionar cat %s\n", yytext);setPageInfoBCatg(p, yytext+7);BEGIN INFOLINES;}
	"{{"[^iI][^{}]*"}}"\n  										{printf("a eliminar1: %s ###\n",yytext);}//eliminar o que nao interessa
	"[["[^\[\]]*"]]"\n 											{printf("a eliminar2: %s ###\n",yytext);}//eliminar o que nao interessa
	"{{"														{yy_push_state(CURLY); top_state=yy_top_state();}
	[A-Z']								 						{ECHO;unput(yytext[yyleng-1]); printf("a comecar abstract\n"); BEGIN ABSTRACT;} // volta a por carater do resumo no input
}

<INFOLINES>{
	\ ?\|[^|&\[\n}{]*/[\n&{|\[}]	    {if(yytext[0]==' ') pos=2; else pos=1; addInfoLine(p, yytext+pos);}	
	[^\[|&}{\n]+/[{\n\[|&}] 			{addInfoLineChunk(p, yytext);} // curls tao aqui por causa de detetar o fim sem ser no inicio de frase, assim nao os apanha
	"}}"		         				{printf("a sair de infolines\n");BEGIN INFOBOX;}
	\{\{(.+?)\}\}						{;}
}	

<ABSTRACT>[^\[\n{&]+/[\[\n{&]		{printf("apanha isto");addChunkAbstract(p, yytext);}
<ABSTRACT>(\n\n|\n=)   				{printf("este");BEGIN TEXT;}
<ABSTRACT>\[						{printf("este2");addChunkAbstract(p,yytext);}//precaver de [...] que aparecem em algumas paginas


<PARENTHESES>{
	[^|\]]+    					{if(top_state==INFOLINES)
									addInfoLineChunk(p, yytext);
								 if(top_state==ABSTRACT)
									addChunkAbstract(p, yytext);
								}
	[^|\]]*\|					{;}		  
	"]]"               			{yy_pop_state();}
}

<CURLY>{
	[A-Za-z]*/[}]				{if(top_state==INFOLINES)
									addInfoLineChunk(p, yytext);
								 if(top_state==ABSTRACT)
									addChunkAbstract(p, yytext);
								}
	"}}"						{yy_pop_state();}
}

<TEXT,ABSTRACT>{quotes}         {printf("aqui");}

<INFOLINES,ABSTRACT>{
	"[["       							{yy_push_state(PARENTHESES); top_state=yy_top_state();}
	&lt;ref(.+?)&gt;(.+?)&lt;\/ref&gt; 	{printf("apanhou REF %s\n",yytext);}
	&lt;br&gt;							{;}
	"{{"								{yy_push_state(CURLY); top_state=yy_top_state();}		
}



(.|\n)                          {;}


%%


int yywrap(){
    return 1;
}


int main(){ 
    yylex();
    return 0;
}