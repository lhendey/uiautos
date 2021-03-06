/******************* URBAN INSTITUTE MACRO LIBRARY *********************
 
 Macro: Compile_num_desc

 Description: Compiles numeric statistics (n, sum, mean, std, min, max) for all
 variables in a data set.  Default is to put statistics in a data set
 called WORK._DESC_&ds_name.
 
 Use: Open code
 
 Author: Peter Tatian
 
***********************************************************************/

%macro Compile_num_desc( 
  stats=n mean std min max,     /* List of statistics */
  ds_lib=work,                  /* Input data set library */
  ds_name=,                     /* Input data set name */
  var_list=_numeric_,           /* List of variables to include */
  out_pre=work._desc,           /* Prefix for output data set lib & name */
  var_pre=_desc                 /* Output variable prefix */
  );
  
  /*************************** USAGE NOTES *****************************
   
   SAMPLE CALL: 
     %Compile_num_desc( 
       stats=n mean std min max,
       ds_lib=,
       ds_name=Test,
       var_list=a b
     )
     calculates n, mean, std, min, and max of variables
     a and b and saves them in new data set work._desc_test.
     one observation in output data set for each input variable.
     Variables in output data set are _name_ (name of input var), 
     and _desc_n, _desc_mean, etc.
     Default is to put statistics in data set WORK._DESC_&ds_name.
     Output data set name is saved in global macro var _compile_num_desc_out.

  *********************************************************************/

  /*************************** UPDATE NOTES ****************************

   08/31/04  Peter A. Tatian
   09/02/04  Added cleanup of temporary data sets
             Added var_list option
   10/28/04  Forced temporary data sets to be uncompressed.
             Added var_pre option
   10/29/04  Now sorts temp. output data sets and merges them by _NAME_.
   09/29/10  PAT  Makes sure that output data set name is 32 chars or less.
                   Creates global macro variable _compile_num_desc_out which
                   has full name of output data set.
   02/23/11  PAT  Added declaration for local macro vars.
                  Added default value WORK for ds_lib=.
                  Added macro testing code.

  *********************************************************************/

  %***** ***** ***** MACRO SET UP ***** ***** *****;
   
  %global _compile_num_desc_out;  /** Global macro var for output data set name **/
  %local out_lib out_name i s files; 
   
  %** Assume WORK library if blank **;
  %if &ds_lib = %then %let ds_lib = work;

  %** Shorter file name for temporary data sets **;
  
  %if %index( &out_pre._&ds_name, . ) > 0 %then %do;
    %let out_lib = %scan( &out_pre._&ds_name, 1, . );
    %let out_name  = %scan( &out_pre._&ds_name, 2, . );
  %end;
  %else %do;
    %let out_lib = work;
    %let out_name  = &out_pre._&ds_name;
  %end;
  
  %** Shorten output data set name if over 32 chars. **;

  %if %length( &out_name ) > 32 %then %let out_name = %substr( &out_name, 1, 32 );
  
  %let _compile_num_desc_out = &out_lib..&out_name; 
  
  %note_mput( macro=Compile_num_desc, 
              msg=Output data set name %upcase(&_compile_num_desc_out) saved to global macro variable _COMPILE_NUM_DESC_OUT. )

    
  %***** ***** ***** ERROR CHECKS ***** ***** *****;



  %***** ***** ***** MACRO BODY ***** ***** *****;

  %let i = 1;
  %let s = %scan( &stats, &i );
  %let files = ;

  %do %while( %length( &s ) > 0 ); 
  
    proc summary data=&ds_lib..&ds_name;
      var &var_list;
      output out=_cnd_&s (drop=_type_ _freq_ compress=no) &s= ;

    proc transpose data=_cnd_&s 
      out=_cnd_&s._tr (drop=_label_ rename=(col1=&var_pre._&s) compress=no);
    
    proc sort data=_cnd_&s._tr;
      by _name_;
    
    run;
    
    %let files = &files _cnd_&s._tr;

  %let i = %eval( &i + 1 );
  %let s = %scan( &stats, &i );

  %end;

  data &_compile_num_desc_out;
    merge &files;
    by _name_;
  run;
  
  
  %***** ***** ***** CLEAN UP ***** ***** *****;

  proc datasets library=work memtype=(data) nolist nowarn;
    delete _cnd_: ;
  quit;
  
%mend Compile_num_desc;


/************************ UNCOMMENT TO TEST ***************************

title "Compile_num_desc:  SAS Macro";

** Autocall macros **;

filename uiautos "K:\Metro\PTatian\UISUG\Uiautos";
options sasautos=(uiautos sasautos);

options mprint nosymbolgen nomlogic;

data Test;

  input id a b;
  
  label 
    a = 'Var A'
    b = 'Var B';

  cards;
  1 1 387
  2 2 193
  3 3 82
  4 4 0
  5 5 390
  6 6 982
  7 7 34
  8 8 2
  9 9 145
  10 10 603
  ;
  
run;

%Compile_num_desc( 
  stats=n mean std min max,
  ds_lib=,
  ds_name=Test,
  var_list=a b
)

proc means data=Test;
run;

proc print data=&_compile_num_desc_out;
  title2 "File = &_compile_num_desc_out";
run;

proc datasets library=work memtype=(data);
quit;

/**********************************************************************/
