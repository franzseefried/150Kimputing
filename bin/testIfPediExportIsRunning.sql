BEGIN PA_SYS.SETUSERCONTEXT(PA_CONST.CONTEXT_MANDANT_IDX, TO_CHAR(PA_CONST.MANDANT_MANDANTTNADNAM)); END;
/
-- Pedigree-Export

DECLARE

  fFileOut          UTL_FILE.FILE_TYPE;

  myJobSTAT           NUMBER;
  
BEGIN
  
    fFileOut := Utl_File.Fopen(Pa_Const.File_OUT_DSCH ,'jobstatus.txt' ,'W'); 
     
     
    SELECT job_status into myJobSTAT FROM T_JOB A WHERE A.JOB_PRGNAME='PA_ZWS_PEDI.CallExportPedigree';


	PA_SYS.PUT_LINE(fFileOut,
         myJobSTAT
       );
    UTL_FILE.FFLUSH(fFileOut);
    UTL_FILE.FCLOSE(fFileOut);
     
END;
/
EXIT;
