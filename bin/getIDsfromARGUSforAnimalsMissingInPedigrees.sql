/* Refere to http://www.oracle.com/technetwork/issue-archive/2015/15-sep/o55sql-dev-2692807.html for examle */
SET ECHO OFF
SET SQLFORMAT CSV
SPOOL &1
select idanimal,
       ANI_ITB_NR,
       anisex 
from animal 
where animal.idanimal = PA_ani.ngetaniid('&2');
--120127454141
SPOOL OFF
exit;
