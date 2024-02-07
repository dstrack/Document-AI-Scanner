UPDATE DOCUMENT_SCAN_AI_CONFIG
SET context_id_query = 'SELECT NAME, ID FROM Weco_Tower1.V_DOCUMENT_SCAN_AI_CONTEXT ORDER BY 1'	-- Werteliste - Select-Statement für die Zuweisung einen Kontext für die spätere Verarbeitung
    , context_fields_query = 'SELECT * FROM Weco_Tower1.V_DOCUMENT_SCAN_AI_CONTEXT_FIELDS'	-- Select-Statement für Kontext Felder siehe TYPE rec_Context_fields
	, address_id_query = q'[SELECT DISPLAY_VALUE, ID FROM Weco_Tower1.VADRESSEN_LOV WHERE WORKSPACE$_ID = 124 ORDER BY 1]'
	, find_address_function = 'Weco_Tower1.Document_Scan_AI_Find_Address'
	, invoice_export_view = 'Weco_Tower1.V_DOCUMENT_SCAN_AI_INVOICE_EXPORT'
	, invoice_export_procedure = 'Weco_Tower1.EXPORT_INVOICE_DOCUMENTS'
WHERE Config_Id = 1;
COMMIT;
