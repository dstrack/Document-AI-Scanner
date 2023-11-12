
UPDATE DOCUMENT_SCAN_AI_CONFIG
SET configuration_name = '20221109/processorJobs'	-- Name der Konfiguration
    , Input_Location_Prefix = 'scan_ai_documents'	-- Sammelordnername für die hochgeladenen Dateien im Objektspeicher
    , Output_Location_Prefix = 'scan_ai_results'	-- Sammelordnername für die AI Prozessor Ergebnisse im Objektspeicher
    , Compartment_Id = 'ocid1.compartment.oc1..aaaaaaaackpx37s32zo44j4ymjdfplq4uk6fnvkfl6qnj6azezaefqoefdfa' -- Compartment_Id im Objektspeicher
    , Object_Bucket_Name = 'APEX_OCI_AI_REST_SERVICE'	-- Bucketname im Objektspeicher
    , Object_Namespace_Name = 'frsvel7ogr9o'			-- Objekt Namespacename im Objektspeicher
    , Object_Store_Base_Url = 'https://objectstorage.eu-frankfurt-1.oraclecloud.com' -- Base_Url des Objektspeicher
    , Oci_Doc_Ai_Url = 'https://document.aiservice.eu-frankfurt-1.oci.oraclecloud.com/20221109/processorJobs'-- Base_Url des AI Prozessor
    , Wc_Credential_Id = 'APEX_OCI_CREDENTIAL'			-- Static Name der Web-Credentials im APEX Workspace
    , cloud_credential_id = 'APEX_OCI_CRED'			-- Credential name für DBMS_CLOUD Object Store access
    , context_id_query = 'SELECT NAME, ID FROM Weco_Tower1.V_DOCUMENT_SCAN_AI_CONTEXT ORDER BY 1'	-- Werteliste - Select-Statement für die Zuweisung einen Kontext für die spätere Verarbeitung
    , context_fields_query = 'SELECT * FROM Weco_Tower1.V_DOCUMENT_SCAN_AI_CONTEXT_FIELDS'	-- Select-Statement für Kontext Felder siehe TYPE rec_Context_fields
	, address_id_query = q'[SELECT DISPLAY_VALUE, ID FROM Weco_Tower1.VADRESSEN_LOV WHERE WORKSPACE$_ID = 124 ORDER BY 1]'
	, find_address_function = 'Weco_Tower1.Document_Scan_AI_Find_Address'
	, invoice_export_view = 'Weco_Tower1.V_DOCUMENT_SCAN_AI_INVOICE_EXPORT'
	, invoice_export_procedure = 'Weco_Tower1.EXPORT_INVOICE_DOCUMENTS'
WHERE Config_Id = 1;
COMMIT;

/*
set scan on 
begin 
	Document_Scan_Ai_Pkg.set_cloud_credentials(
		p_username => 'APEX_OCI_AI_REST_SERVICE_ACCOUNT',
		p_password => '&PASSWORD.'
	);
end;
/
begin
DBMS_CLOUD.CREATE_CREDENTIAL(
	credential_name => 'APEX_OCI_CRED',
	username => 'APEX_OCI_AI_REST_SERVICE_ACCOUNT',
	password => '&PASSWORD.');
END;
/
*/