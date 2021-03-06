/******************* URBAN INSTITUTE MACRO LIBRARY *********************
 
 Macro: FmtSearch

 Description: Autocall macro to manage multiple SAS format libraries.
 
 Written by Pete Lund, presented at SUGI 28, "Keep Those Formats
 Rolling: A Macro to Manage the FMTSEARCH= Option."
 <http://www2.sas.com/proceedings/sugi28/116-28.pdf>

 Use: Open code
 
 Author: Pete Lund
 
***********************************************************************/

%macro FmtSearch(
  Action=M, /** Action to perform on catalog **/
  A=,      /** Action to perform on catalog (alt parameter) **/
  Cat=,    /** Name of format catalog **/
  C=,      /** Name of format catalog (alt parameter) **/
  Status=Y,
  Recurse=N
  );

  /*************************** USAGE NOTES *****************************
   
   SAMPLE CALL: 
     %FmtSearch( cat=General, action=E )
       add the catalog General.Formats to the end of the format search

    macro variables/parameters
      Cat (C):    name of the format catalog
      Action (A): What do you want to do with the catalog:
         B = put it at the beginning of the format search list,
             even before WORK.FORMATS and LIBRARY.FORMATS
         E = put it at the end of the format search list
         D = remove it from the format search list
         M = put it in the "middle" of the format search list.  It
             will go after WORK.FORMATS and LIBRARY.FORMATS and before
             any user-defined catalogs in the search list.
         L = simply lists the current format search list

     notes: The M does work, it's just that when B has been previously 
            used, WORK and LIBRARY have been explicitely set and a     
            later M will still go at the front.                        

  *********************************************************************/

  /*************************** UPDATE NOTES ****************************


  *********************************************************************/

  %***** ***** ***** MACRO SET UP ***** ***** *****;
   
  %local _FMS i pos _ThisCat _Index1 _Index2 _ByVal NumCats;
  %global _NewFMS _Recurse;

  %if &C ne %str() %then %let Cat = &C;
  %if &A ne %str() %then %let Action = &A;
  %let Action = %upcase(&Action);

    
  %***** ***** ***** ERROR CHECKS ***** ***** *****;

  %if %index(BMEDXLZ,&Action) eq 0 or
      %length(&Action) ne 1 %then
    %do;
      %put ;
      %put %str(=====================================================================);
      %err_mput( macro=FmtSearch, msg=No valid action requested. Cat=&Cat Action=&Action )
      %put %str(=====================================================================);
      %put ;
      %goto Finish;
    %end;

  %***** ***** ***** MACRO BODY ***** ***** *****;

  %if &Cat eq %str() and &Action ne L and &Action ne X and &Action ne Z %then
    %do;
      %put Here%str(%')s a list:;
      %goto Finish;
    %end;

  %if &Action eq X %then 
    %do;
      options fmtsearch=();
      %let Cat = %str();
    %end;

  %let Cat = %sysfunc(tranwrd(%upcase(&Cat),%str(.FORMATS),%str()));
  %if &Cat ne %str() %then %let Cat = %sysfunc(compbl(&Cat));

  %let NumCats = %eval(%length(&Cat) - %length(%sysfunc(compress(&Cat,%str( )))) +1);
  %if &Action eq Z %then %let NumCats = 1;

  %if &NumCats ge 1 %then
    %do;
      %if &Action eq M or &Action eq B %then
        %do;
          %let _Index1 = &NumCats;
          %let _Index2 = 1;
          %let _ByVal  = -1;
        %end;
      %else
        %do;
          %let _Index1 = 1;
          %let _Index2 = &NumCats;
          %let _ByVal  = 1;
        %end;
      %do i = &_Index1 %to &_Index2 %by &_ByVal;
        %let _ThisCat = %scan(&Cat,&i,%str( ));

        %let _FMS   = 
           %upcase(%sysfunc(compress(%sysfunc(getoption(fmtsearch)),%str(%(%)))));
        %let _FMS   = %sysfunc(tranwrd(&_FMS,%str(.FORMATS),%str()));

        %if &Action eq Z %then 
          %do;
            %put FMS: &_FMS;
            %let _FMS   = %sysfunc(tranwrd(&_FMS,%str(WORK),%str()));
            %let _FMS   = %sysfunc(tranwrd(&_FMS,%str(LIBRARY),%str()));
            options fmtsearch=(&_FMS);
          %end;

        %if &Action eq D or &Action eq M or &Action eq B or &Action eq E  %then
          %do;
            %let _NewFMS = %sysfunc(tranwrd(%str( &_FMS ),%str( &_ThisCat ),%str()));
            %if &_NewFMS ne %str() %then
              %do;
                /*%if %substr(&_NewFMS,1,%sysfunc(min(12,%length(&_NewFMS)))) eq WORK LIBRARY %then %let _NewFMS = %substr(&_NewFMS,13);*/
                %if %substr(&_NewFMS,1,%sysfunc(min(12,%length(&_NewFMS)))) eq WORK LIBRARY %then %let _NewFMS = %substr(&_NewFMS%str( ),13);
              %end;
            %if &Action eq D %then %str(options fmtsearch=(&_NewFMS););
          %end;

        %if &Action eq M %then
          %do;
            options fmtsearch=(&_ThisCat &_NewFMS);
          %end;

        %if &Action eq B %then
          %do;
            %let _NewCat = &_ThisCat;
            %if %sysfunc(indexw(&_NewFMS,WORK)) eq 0 and &_ThisCat ne WORK %then 
              %let _NewCat = &_NewCat WORK;
            %if %sysfunc(indexw(&_NewFMS,LIBRARY)) eq 0 and &_ThisCat ne LIBRARY %then 
              %let _NewCat = &_NewCat LIBRARY;
            options fmtsearch=(&_NewCat &_NewFMS);
          %end;

        %if &Action eq E %then
          %do;
            options fmtsearch=(&_NewFMS &_ThisCat);
          %end;
      %end;
    %end;

  %if %mparam_is_yes( &Status ) %then
    %do;
      %put; 
      %put %str(=====================================================================);
      %let _FMS = %upcase(%sysfunc(compress(%sysfunc(getoption(fmtsearch)),%str(%(%)))));
      %if %sysfunc(indexw(%upcase(&_FMS),LIBRARY)) eq 0 %then
        %let _FMS = LIBRARY* &_FMS;
      %if %sysfunc(indexw(%upcase(&_FMS),WORK)) eq 0 %then %let _FMS = WORK* &_FMS;
      %put Current FmtSearch Option value:;
      %put ;
      %put %str(     )&_FMS;
      %put ;
      %if %index(&_FMS,*) ne 0 %then
        %do;
          %put %str(   )*implicitly included by default.;
          %put;
        %end;

      %let _FMS = %sysfunc(compress(&_FMS,%str(*)));
      %put %str(=====================================================================);
      %put Status of current catalogs:;
      %put ;
      %let i = 1;
      %do %while(%scan(&_FMS,&i,%str( )) ne %str( ));
        %let ThisCat = %scan(&_FMS,&i,%str( ));
        %if %index(&ThisCat,.) eq 0 %then %let ThisCat = &ThisCat..FORMATS;
        %if %sysfunc(cexist(&ThisCat)) eq 1 %then 
          %put NOTE:    &ThisCat EXISTS;
        %else 
          %put NOTE:    &ThisCat DOES NOT EXIST;
        %let i = %eval(&i + 1);
      %end;
      %put %str(=====================================================================);
      %put ;
    %end;

  %Finish:
  %let _Recurse = %str();
  

  %***** ***** ***** CLEAN UP ***** ***** *****;

%mend FmtSearch;


/************************ UNCOMMENT TO TEST ***************************

libname Test 'D:\';

%FmtSearch( action=L )

%FmtSearch( cat=Test, action=0 )

%FmtSearch( cat=Test, action=E )

/**********************************************************************/


/*********************** ORIGINAL HEADER ******************************/
/*-------------------------------------------------------------------*/
/* program:    FmtSearch.sas                                      |  */
/* programmer: Pete Lund                                          |�N*/
/*             (360) 528-8970                                     |2W*/
/* date:       September 2002                                     |0C*/
/* project:    Utility macro                                      |0S*/
/*                                                                |3R*/
/* purpose: Manages the FMTSEARCH option                          |  */
/*                                                                |  */
/*                                                                |  */
/*-------------------------------------------------------------------*/

