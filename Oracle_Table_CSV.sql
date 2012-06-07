-- **************************************************************************************
-- ******** Oracle_Table_CSV.sql: Generates a CSV file from a user.table given by params
-- ******** Usage: sqlplus USER/PASSWORD[@DATABASE] @Oracle_Table_CSV.sql OWNER TABLE
-- ******** Usage: sqlplus USER/PASSWORD[@//host:port/SID] @Oracle_Table_CSV.sql OWNER TABLE
-- ******** USER ---> user to connect to the database (usually a DBA or the owner of the table we wanna export)
-- ******** PASSWORD ---> password of the previous user
-- ******** DATABASE ---> Connect Identifier to the target database
-- ******** OWNER ---> First param. Owner of the table or view we wanna export
-- ******** TABLE ---> Table, view, materialized view,... to export to csv
-- ******** Example1:  sqlplus scott/tiger @Oracle_Table_CSV.sql scott emp
-- ******** Example2:  sqlplus scott/tiger@remoteDB1 @Oracle_Table_CSV.sql scott emp
-- ******** Example3:  sqlplus system/oracle@//10.0.1.103:1521/orcl @Oracle_Table_CSV.sql sys dba_tab_columns
-- ******** The script generates an intermediate SQL file (owner.table.sql) that is executed to generate the final .csv file (owner.table.csv)
-- ******** The field separator is ; by default, and the quotes are " by default
-- **************************************************************************************

SET LINESIZE 1000
SET PAGESIZE 9999
SET NUMWIDTH 20
SET TRIMSPOOL ON
SET TRIMOUT ON
SET VERIFY OFF
SET SERVEROUTPUT ON
SET UNDERLINE OFF
SET FEEDBACK OFF
SET HEAD OFF
SET DEFINE ON;

set serveroutput on
exec dbms_output.enable(null);

spool &1\.&2\.sql

prompt SET VERIFY OFF;
prompt SET SERVEROUTPUT ON;
prompt SET DEFINE ON;
prompt;
prompt exec dbms_output.enable(null);;
prompt spool &&1..&&2..csv
prompt declare
prompt cursor c_heading is select column_name from all_tab_columns where owner=upper('&&1') and table_name=upper('&&2') order by column_id;;
prompt   v_reg c_heading%rowtype;;
prompt   type t_crs is ref cursor;;
prompt   c_tc t_crs;;
prompt   v_tc &&1..&&2%rowtype;;
prompt   v_sep varchar2(1) := ';';;
prompt   v_quo varchar2(1) := '"';;
prompt   v_ftm boolean := TRUE;;
prompt begin
prompt   -- Print heading;
prompt   open c_heading;;
prompt   loop
prompt     fetch c_heading into v_reg;;
prompt     exit when c_heading%notfound;;
prompt     if not v_ftm then dbms_output.put(v_sep); else v_ftm := FALSE; end if;;
prompt     dbms_output.put(v_quo||v_reg.column_name||v_quo);;
prompt   end loop;;
prompt   dbms_output.put_line('');;
prompt   close c_heading;;
prompt   -- Print data;
prompt   open c_tc for'select * from &&1..&&2';;
prompt   loop
prompt     fetch c_tc into v_tc;;
prompt     exit when c_tc%notfound;;
declare
  cursor c_head (p_ownername varchar2, p_tablename varchar2) is select column_name,data_type from all_tab_columns where owner=upper(p_ownername) and table_name=upper(p_tablename) order by column_id;
  v_head c_head%rowtype;
  v_ftm  boolean := TRUE;
  v_sep varchar2(1) := ';';
  v_quo varchar2(1) := '"';
begin
  open c_head ('&&1','&&2');
  loop
    fetch c_head into v_head;
    exit when c_head%notfound;
    dbms_output.put('dbms_output.put(');
    if not v_ftm then dbms_output.put(''''||v_sep||'''||'); else v_ftm := FALSE; end if;
    case
      when v_head.data_type in ('NUMBER','FLOAT') then dbms_output.put_line('to_char(v_tc.'||v_head.column_name||'));');
      when v_head.data_type in ('VARCHAR2','CHAR','NVARCHAR2','') then dbms_output.put_line(''''||v_quo||'''||replace(v_tc.'||v_head.column_name||','''||v_quo||''','''||v_quo||v_quo||''')||'''||v_quo||''');');
      when v_head.data_type in ('DATE') then dbms_output.put_line('to_char(v_tc.'||v_head.column_name||',''yyyy-mm-dd''));');
      else dbms_output.put_line('to_char(v_tc.'||v_head.column_name||'));');
    end case;
  end loop;
  close c_head;
  dbms_output.put_line('dbms_output.put_line('''');');
end;
/
prompt   end loop;;
prompt   close c_tc;;
prompt end;;
prompt /
prompt spool off

spool off
@&&1\.&&2\.sql
--!rm &&1\.&&2\.sql
exit