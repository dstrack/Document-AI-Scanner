DECLARE
	 C_CTX_INDEX_DSTORE_PREFS constant varchar2(50) := 'DOC_SCAN_AI_DSTORE';
BEGIN
	begin
		ctx_ddl.drop_preference(C_CTX_INDEX_DSTORE_PREFS);
	exception when others then
		if SQLCODE != -20000 then
			raise;
		end if;
	end;
	ctx_ddl.create_preference(C_CTX_INDEX_DSTORE_PREFS, 'user_datastore'); 
	ctx_ddl.set_attribute(C_CTX_INDEX_DSTORE_PREFS, 'procedure', 
		SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')||'.DOCUMENT_SCAN_AI_PKG.CTX_DOCUMENT_CONTENT'); 
	ctx_ddl.set_attribute(C_CTX_INDEX_DSTORE_PREFS, 'output_type', 'blob_loc');
	COMMIT;
END;
/

begin
	EXECUTE IMMEDIATE 'DROP INDEX DOCUMENT_SCAN_AI_DOCS_TEXT_I FORCE';
exception when others then 
	if SQLCODE != -1418 then -- specified index does not exist
		raise;
	end if;
end;
/

CREATE INDEX DOCUMENT_SCAN_AI_DOCS_TEXT_I ON DOCUMENT_SCAN_AI_DOCS (SEARCHABLE_PDF_URL)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS ('
	DATASTORE DOC_SCAN_AI_DSTORE
	FILTER CTXSYS.AUTO_FILTER
	FORMAT COLUMN INDEX_FORMAT
	TRANSACTIONAL SYNC (EVERY "SYSDATE+1/1440*10")');

/*
SELECT document_id, file_name,
   (select case when count(*) != 0 then 'Y' else 'N' end 
      from DR$DOCUMENT_SCAN_AI_DOCS_TEXT_I$K I 
      where I.TEXTKEY = CAST(A.ROWID AS VARCHAR2(20))
    ) HAS_TEXT_INDEX,
    (select ERR_TEXT 
      from CTX_USER_INDEX_ERRORS E
      where E.ERR_INDEX_NAME = 'DOCUMENT_SCAN_AI_DOCS_TEXT_I'
      and E.ERR_TEXTKEY = CAST(A.ROWID AS VARCHAR2(20))
    ) TEXT_INDEX_ERR_TEXT
FROM DOCUMENT_SCAN_AI_DOCS A
;
*/