CREATE OR REPLACE PROCEDURE Ctx_Adressen_Text (
	r in rowid, 
	c in out nocopy clob 
) is
	CURSOR cr_address IS
		SELECT	NAME||' '||VORNAME||' '||STRASSE||' '||PLZ||' '||ORT||' '||FIRMA1||' '||FIRMA2 NAME
		FROM	 WECO_TOWER1.ADRESSEN_BT
		WHERE	 ROWID = r;

	lv_textline		VARCHAR2(4000);
BEGIN
	OPEN	cr_address;
	FETCH cr_address INTO lv_textline;
	CLOSE cr_address;

	lv_textline := REGEXP_REPLACE(ASCIISTR(lv_textline), '\\[[:xdigit:]]{4}', '');
	dbms_lob.writeappend(c, length(lv_textline), lv_textline);
END Ctx_Adressen_Text;
/


declare
	v_Datastore_Name 	VARCHAR2(30) 	:= 'adressen_datastore';
	v_Lexer_Name		VARCHAR2(30)	:= 'adressen_lexer';
	v_Wordlist_Name 	VARCHAR2(30)	:= 'adressen_wordlist';
	PROCEDURE drop_preference (p_Pref_Name VARCHAR2)
	is 
	begin
		ctx_ddl.drop_preference(p_Pref_Name);
	exception when others then 
	  	if SQLCODE != -20000 then 
			raise;
		end if;
	end;
begin
	drop_preference(v_Datastore_Name);
	drop_preference(v_Lexer_Name);
	drop_preference(v_Wordlist_Name);
    -- datastore
	-- ctx_ddl.create_preference(v_Datastore_Name,'multi_column_datastore'); 
	-- ctx_ddl.set_attribute(v_Datastore_Name, 'columns','NAME,VORNAME,STRASSE,PLZ,ORT,FIRMA1'); 
	ctx_ddl.create_preference(v_Datastore_Name, 'user_datastore'); 
	ctx_ddl.set_attribute(v_Datastore_Name, 'procedure', SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')||'.CTX_ADRESSEN_TEXT'); 
	ctx_ddl.set_attribute(v_Datastore_Name, 'output_type', 'CLOB');
    -- lexer
    ctx_ddl.create_preference(v_Lexer_Name,'basic_lexer');
    ctx_ddl.set_attribute(v_Lexer_Name,'composite','german');
    ctx_ddl.set_attribute(v_Lexer_Name,'mixed_case','no');
    ctx_ddl.set_attribute(v_Lexer_Name,'alternate_spelling','german');
    ctx_ddl.set_attribute(v_Lexer_Name,'printjoins','-/');
    ctx_ddl.set_attribute(v_Lexer_Name,'continuation','-/');
	ctx_ddl.set_attribute(v_Lexer_Name, 'index_themes', 'NO');
    -- wordlist
	ctx_ddl.create_preference(v_Wordlist_Name, 'BASIC_WORDLIST');
	ctx_ddl.set_attribute(v_Wordlist_Name, 'FUZZY_MATCH', 'GERMAN');
	ctx_ddl.set_attribute(v_Wordlist_Name, 'FUZZY_SCORE', '50');
	ctx_ddl.set_attribute(v_Wordlist_Name, 'FUZZY_NUMRESULTS', '100');
	ctx_ddl.set_attribute(v_Wordlist_Name, 'SUBSTRING_INDEX', 'FALSE');
	commit;	
end;
/

begin
	EXECUTE IMMEDIATE 'DROP INDEX ADRESSEN_TEXT_I FORCE';
exception when others then 
	if SQLCODE != -1418 then -- specified index does not exist
		raise;
	end if;
end;
/

CREATE INDEX ADRESSEN_TEXT_I ON ADRESSEN_BT (NAME)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS ('
	DATASTORE adressen_datastore 
	FILTER CTXSYS.AUTO_FILTER 
	LEXER adressen_lexer 
	WORDLIST adressen_wordlist 
	TRANSACTIONAL SYNC (EVERY "SYSDATE+1/1440*10")');


/*
SELECT id, name,
   (select case when count(*) != 0 then 'Y' else 'N' end 
      from DR$ADRESSEN_TEXT_I$K I 
      where I.TEXTKEY = CAST(A.ROWID AS VARCHAR2(20))
    ) HAS_TEXT_INDEX,
    (select ERR_TEXT 
      from CTX_USER_INDEX_ERRORS E
      where E.ERR_INDEX_NAME = 'ADRESSEN_TEXT_I'
      and E.ERR_TEXTKEY = CAST(A.ROWID AS VARCHAR2(20))
    ) TEXT_INDEX_ERR_TEXT
FROM WECO_TOWER1.ADRESSEN_BT A
;
*/
