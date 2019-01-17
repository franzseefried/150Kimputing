BEGIN PA_SYS.SETUSERCONTEXT(PA_CONST.CONTEXT_MANDANT_IDX, TO_CHAR(PA_CONST.MANDANT_MANDANTTNADNAM)); END;
/
-- Pedigree-Export

DECLARE

  fFileOut          UTL_FILE.FILE_TYPE;

  myJobID           NUMBER;
  
BEGIN
  
    fFileOut := Utl_File.Fopen(Pa_Const.File_OUT_DSCH ,'jobid.txt' ,'W'); 
     
     
    SELECT job_id into myJobID FROM T_JOB A WHERE A.JOB_PRGNAME='PA_ZWS_PEDI.CallExportPedigree';


	PA_SYS.PUT_LINE(fFileOut,
         myJobID
       );
    UTL_FILE.FFLUSH(fFileOut);
    UTL_FILE.FCLOSE(fFileOut);
     
END;
/
EXIT;
