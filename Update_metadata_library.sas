/******************* URBAN INSTITUTE MACRO LIBRARY *********************
 
 Macro: Update_metadata_library

 Description: Registers metadata for a SAS library.
 
 Use: Open code
 
 Author: Peter Tatian
 
***********************************************************************/

%macro Update_metadata_library( 
         lib_name= ,       /** Library reference **/
         lib_desc= ,       /** Library description **/
         meta_lib= ,       /** Library reference for metadata data sets **/
         meta_pre= meta,   /** Prefix for metadata data set names **/
         quiet=N           /** Suppress notes to LOG (Y/N) **/
       );

  /*************************** USAGE NOTES *****************************
   
   SAMPLE CALL: 
     %Update_metadata_library( 
              lib_name=Sashelp,
              lib_desc=SAS help library,
              meta_lib=metadata
           )

  *********************************************************************/

  /*************************** UPDATE NOTES ****************************

   01/02/04  Peter A. Tatian
   10/29/04  Macro now will create _libs file if it does not exist.
   09/06/05  Set OPTIONS OBS=MAX to avoid data loss when updating metadata.
   09/29/10  PAT  Delete temporary data set at end of macro execution.

  *********************************************************************/

  %***** ***** ***** MACRO SET UP ***** ***** *****;
   
  %** Save current OBS= setting then set to MAX **;

  %Push_option( obs )
  
  options obs=max;
  %Note_mput( macro=Update_metadata_library, msg=OPTIONS OBS set to MAX for metadata processing. )


  %***** ***** ***** ERROR CHECKS ***** ***** *****;



  %***** ***** ***** MACRO BODY ***** ***** *****;

  ** Create library record **;
  
  data _lib_&lib_name;
  
    length Library $ 32 LibDesc $ 400;
    
    Library = upcase( "&lib_name" );
    LibDesc = "&lib_desc";
  
  run;
  
  ** Create library metadata file if it does not exist **;
  
  %if not %dataset_exists( &meta_lib..&meta_pre._libs ) %then %do;
    %Note_mput( macro=Update_metadata_library, msg=File &meta_lib..&meta_pre._libs does not exist - it will be created. )
    data &meta_lib..&meta_pre._libs;
      set _lib_&lib_name (obs=0);
    run;
  %end;  

** Update library list **;
  
  data &meta_lib..&meta_pre._libs (compress=char);
  
    update &meta_lib..&meta_pre._libs _lib_&lib_name;
      by Library;
      
  run;
  
  %if %upcase( &quiet ) ~= Y %then %do;

    data _null_;
      set _lib_&lib_name;
      put;
      %Note_put( macro=Update_metadata_file, msg="Update to Library metadata record:" )
      put (_all_) (= /);
      put /;
    run;
    
  %end;
  
  run;
  
  %Note_mput( macro=Update_metadata_library, msg=Library %upcase( &lib_name ) has been registered with the metadata system. )

  ** Delete temporary data set **;
  
  proc datasets library=work memtype=(data) nolist nowarn;
    delete _lib_&lib_name;
  quit;
  
  %exit:


  %***** ***** ***** CLEAN UP ***** ***** *****;

  %** Restore system options **;
  
  %Pop_option( obs )


  %Note_mput( macro=Update_metadata_library, msg=Macro exiting. )
    
%mend Update_metadata_library;



/************************ UNCOMMENT TO TEST ***************************

** Autocall macros **;

filename uiautos "K:\Metro\PTatian\UISUG\Uiautos";
options sasautos=(uiautos sasautos);

%Update_metadata_library( 
         lib_name=Work,
         lib_desc=Test library,
         meta_lib=work
      )

%Update_metadata_library( 
         lib_name=Sashelp,
         lib_desc=SAS help library,
         meta_lib=work
      )

proc datasets library=work memtype=(data);
quit;

%File_info( data=Meta_libs, printobs=50, contents=n, stats= )

/**********************************************************************/
