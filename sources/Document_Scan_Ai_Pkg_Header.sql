-------------------------------------------------------------------------------
/*
-- NAME        : DOCUMENT_SCAN_AI_PKG
-- FILE NAME   : Document_Scan_Ai_Pkg.sql
-- REVISION    : $2023.1.0$
-- PURPOSE     : Package containing code for the OCI Document Understanding AI Demo.
--
	DELIVERED BY: $dstrack$
	see: https://blog.cloudnueva.com/apex-and-oci-document-ai#heading-analyzing-key-values-in-the-response
	https://github.com/oracle-samples/oci-data-science-ai-samples/blob/master/labs/ai-document-understanding/workshops/3-postman/3-postman.md
	https://docs.oracle.com/en-us/iaas/api/#/en/document-understanding/20221109/ProcessorJob/
		
	Features: 
	- Upload multibe documents and process them in a AI processor job.
	 * Manage phases: 1. Create Job, 2. Await completion, 3. Process results.
	 * Run in javascript loop and show progress bar.
	 * Load searchable pdf file into DOCUMENT_SCAN_AI_DOCS.searchable_pdf_url
	- Convert text to numbers, and dates with formats and punctation acording to the detected language 

	- List for processor jobs. 
	 * Support download of searchable pdf files.
	 * Support user to choose the job to list the files.
	 * List Details of processed documents and there Line Items below.
	- Search documents via full text index.
	- Export job result as Excel sheet.
	- Enable Edit for DOCUMENT_SCAN_AI_DOCS
	 * LOV for .document_type_code, DOCUMENT_SCAN_AI_DOCS.language_code
	- Enable Edit of DOCUMENT_SCAN_AI_FIELDS
	 * field_value
	- Enable Edit of DOCUMENT_SCAN_AI_FIELDS
	 * field_value
 	 * LOV for user_label with matching value_type and DOCUMENT_SCAN_AI_JOBS.documentType

-- Required privileges:
GRANT EXECUTE ON CTXSYS.CTX_DDL TO OWNER;
GRANT EXECUTE ON SYS.DBMS_LOCK TO OWNER;

*/

-- Revision History:
-- VER   			DATE         AUTHOR           DESCRIPTION
-- ========		===========  ================ ===================================
-- 2023.2.0		16-MAY-2023	 dstrack		  Adaptations for Document Understanding AI
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE Document_Scan_Ai_Pkg AS
	TYPE document_id_list IS TABLE OF DOCUMENT_SCAN_AI_DOCS.document_id%TYPE;
	subtype t_path_name is varchar2(32767);
	TYPE file_list IS TABLE OF t_path_name;
	
	-- begin configuration parameter --
	GC_CONFIG_ID				NUMBER			:= 1;
	GC_INPUT_LOCATION_PREFIX	VARCHAR2(500)	:= 'scan_ai_documents';
	GC_OUTPUT_LOCATION_PREFIX	VARCHAR2(500)	:= 'scan_ai_results';
	GC_PDF_LOCATION_PREFIX		VARCHAR2(500)	:= 'searchablePdf';
	GC_COMPARTMENT_ID			VARCHAR2(500)	:= ''; 		-- from Compartments/APEX_OCI_SERVICES-OCID
	GC_OBJECT_BUCKET_NAME		VARCHAR2(500)	:= 'APEX_OCI_AI_REST_SERVICE';	
	GC_OBJECT_NAMESPACE_NAME	VARCHAR2(500)	:= '';		-- from Object Storage / Bucket Details
	GC_OBJECT_STORE_BASE_URL	VARCHAR2(500)	:= 'https://objectstorage.eu-frankfurt-1.oraclecloud.com';	
	GC_OCI_DOC_AI_URL			VARCHAR2(500)	:= 'https://document.aiservice.eu-frankfurt-1.oci.oraclecloud.com/20221109/processorJobs'; -- Document Understanding API Endpoint
	GC_WC_CREDENTIAL_ID			VARCHAR2(50)	:= 'APEX_OCI_CREDENTIAL';
	GC_CLOUD_CREDENTIAL_ID		VARCHAR2(50)	:= 'APEX_OCI_STORAGE';			-- Credential name für DBMS_CLOUD Object Store access
	GC_CURRENCY_CHARACTER		VARCHAR2(10)	:= '€';		-- currency character, expected in the text_value of NUMBER fields.
	GC_NUMBER_CHARACTER 		VARCHAR2(10)    := ',.';	-- decimal and group character, expected in the text_value of NUMBER fields.
	GC_PROCESSOR_LANGUAGE_CODE	VARCHAR2(10)    := 'ENG';	-- ENG is required for feature KEY_VALUE extraction. decimal and group character '.,' will be used by the processor
	GC_PROCESSOR_DOCUMENT_TYPE	VARCHAR2(10)    := 'INVOICE'; -- one of INVOICE:RECEIPT:RESUME:TAX_FORM:DRIVER_LICENSE:PASSPORT:BANK_STATEMENT:CHECK:PAYSLIP:OTHERS
	GC_GENERATE_SEARCHABLE_PDF  VARCHAR2(10)    := 'Y';		-- when actived, the projecsor job will generate searchable pdf files in the object store.
	GC_KEY_VALUES_EXTRACTION	VARCHAR2(10)    := 'Y';		-- when actived, the projecsor job will extract key values
	GC_TABLE_EXTRACTION  		VARCHAR2(10)    := 'Y';		-- when actived, the projecsor job will extract tables
	GC_EXECUTE_ASYNCHRONOUS  	VARCHAR2(10)    := 'Y';		-- when actived, use a scheduler job to run the projecsor job and await the results.
	GC_DELETE_PROCESSOR_OUTPUT  VARCHAR2(10)    := 'Y';		-- when actived, delete processor output json files from object store.
	GC_KEEP_ORIGINAL_FILES		VARCHAR2(10)    := 'Y';		-- when actived, original files remain in the object store when the job is cleaned up.
	GC_FIND_ADDRESS_FUNCTION	VARCHAR2(500);
	GC_CONTEXT_ID_QUERY			VARCHAR2(2000);
	GC_CONTEXT_FIELDS_QUERY		VARCHAR2(2000);
	GC_ADDRESS_ID_QUERY			VARCHAR2(2000);
	GC_INVOICE_EXPORT_VIEW		VARCHAR2(2000);
	GC_INVOICE_EXPORT_PROCEDURE VARCHAR2(2000);
	-- end configuration parameter --
	G_USE_DBMS_CLOUD			CONSTANT BOOLEAN := TRUE;
	FUNCTION get_OCI_Config_ID RETURN NUMBER;
	
	PROCEDURE set_cloud_credentials (
		p_credential_name IN VARCHAR2 DEFAULT GC_CLOUD_CREDENTIAL_ID,
		p_username IN VARCHAR2,
		p_password IN VARCHAR2 
	);

	------------------------------------
	TYPE rec_list_of_values IS RECORD (
		DISPLAY_VALUE VARCHAR2(1000),
		RETURN_VALUE NUMBER
	);
	-- output of data_browser_utl.Column_Value_List, data_browser_utl.Get_Detail_View_Column_Cursor
	TYPE tab_list_of_values IS TABLE OF rec_list_of_values;

	FUNCTION context_list_of_values 
	RETURN tab_list_of_values PIPELINED;

	------------------------------------
	TYPE rec_Context_fields IS RECORD (
		Context_ID NUMBER,
		Client_Name VARCHAR2(100),
		Client_Email VARCHAR2(100),
		Client_Tax_Id VARCHAR2(100),
		Client_Phone VARCHAR2(100),
		Client_IBAN VARCHAR2(100),
		Client_SWIFT_BIC VARCHAR2(100)
	);
	TYPE tab_Context_fields IS TABLE OF rec_Context_fields;

	FUNCTION pipe_context_fields (p_Context_ID IN NUMBER)
	RETURN tab_Context_fields PIPELINED;

	-------------------------------------
	FUNCTION context_display_value (
		p_Search_Value IN NUMBER
	) RETURN VARCHAR2;

	FUNCTION address_list_of_values 
	RETURN tab_list_of_values PIPELINED;

	FUNCTION address_display_value (
		p_Search_Value IN NUMBER DEFAULT NULL
	) RETURN VARCHAR2;

	FUNCTION Get_Invoice_Export_Query (
		p_Job_ID IN VARCHAR2 
	) RETURN VARCHAR2;

	FUNCTION Get_Invoice_Export_Column_List RETURN VARCHAR2;

	PROCEDURE Export_Invoice_List(p_Job_ID IN NUMBER);

	FUNCTION Encode_Object_Name(p_source_object_name IN VARCHAR2) RETURN VARCHAR2;
	
    FUNCTION Get_Number_Mask (
        p_Value VARCHAR2,                   -- string with formated number
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,   -- decimal and group character
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER  -- currency character
    ) RETURN VARCHAR2 DETERMINISTIC;

    FUNCTION Get_Number_Normalized (
        p_Value VARCHAR2,                   -- string with formated number
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER,  -- currency character
        p_ISO_Currency VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 DETERMINISTIC;

    FUNCTION Get_NLS_Param (
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,   -- decimal (radix) and group character
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER, -- current Currency character
        p_Territory VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 DETERMINISTIC;

    -- Convert any to_char(x, 'FM9') string to sql number using p_NumChars, p_Currency
    FUNCTION FM9_TO_Number(
        p_Value VARCHAR2, 
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER,
        p_ISO_Currency VARCHAR2 DEFAULT NULL,
        p_Territory VARCHAR2 DEFAULT NULL,
        p_Default_On_Error NUMBER DEFAULT NULL
    ) RETURN NUMBER DETERMINISTIC;

    FUNCTION Text_TO_Number(
        p_Value VARCHAR2, 
        p_iso_code VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
        p_Default_On_Error NUMBER DEFAULT NULL
	) RETURN NUMBER;

    -- used to validate the input for acceptable number strings
    FUNCTION Validate_Number_Conversion (
        p_Value VARCHAR2,
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER,
        p_ISO_Currency VARCHAR2 DEFAULT NULL,
        p_Territory VARCHAR2 DEFAULT NULL,
        p_Decimal_Required VARCHAR2 DEFAULT 'Y'
    ) RETURN NUMBER DETERMINISTIC;

    FUNCTION Validate_Date_Conversion (
        p_Value VARCHAR2,
        p_Date_format VARCHAR2,
        p_NLS_Date_Language VARCHAR2
    ) RETURN NUMBER DETERMINISTIC;

    FUNCTION To_Date_Conversion (
        p_Value VARCHAR2,
        p_Date_format VARCHAR2,
        p_NLS_Date_Language VARCHAR2
    ) RETURN DATE DETERMINISTIC;

	FUNCTION Get_String_Type (
        p_Value_Type VARCHAR2,
        p_Item_Value VARCHAR2
	) RETURN VARCHAR2 DETERMINISTIC;

	FUNCTION Trim_String_Type (
        p_Value_Type VARCHAR2,
        p_Item_Value VARCHAR2
	) RETURN VARCHAR2 DETERMINISTIC;

	PROCEDURE Rename_File(
		p_old_object_name IN VARCHAR2,
		p_new_object_name IN VARCHAR2,
		p_job_id			IN Document_Scan_Ai_Jobs.Job_Id%TYPE DEFAULT NULL
	);
	PROCEDURE Delete_File(
		p_object_name IN VARCHAR2,
		p_job_id	  IN Document_Scan_Ai_Jobs.Job_Id%TYPE DEFAULT NULL
	);

	PROCEDURE Rebuild_Fields (
		p_Job_Id IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL
	);

	PROCEDURE Run_Processorjob (
		p_Job_Id	IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	);
	PROCEDURE Cleanup_Processorjob (
		p_Job_Id	IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	);
	PROCEDURE Delete_Doc_Searchable_Pdf (
		p_searchable_pdf_url	IN DOCUMENT_SCAN_AI_DOCS.searchable_pdf_url%TYPE,
		p_object_store_url 		IN DOCUMENT_SCAN_AI_DOCS.object_store_url%TYPE
	);
	TYPE rec_files_type IS RECORD (
		FILENAME		VARCHAR2(400),
		MIME_TYPE		VARCHAR2(255),
		CUSTOM_ID		NUMBER,
		BLOB_CONTENT	BLOB
	);
	TYPE files_ref_cursor IS REF CURSOR RETURN rec_files_type;
	FUNCTION Process_Files_Cursor (
		p_documentType			IN VARCHAR2 DEFAULT GC_PROCESSOR_DOCUMENT_TYPE, 
		p_Language				IN VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
		p_Key_Values_Extraction IN VARCHAR2 DEFAULT GC_KEY_VALUES_EXTRACTION,
		p_Table_Extraction		IN VARCHAR2 DEFAULT GC_TABLE_EXTRACTION,
		p_generateSearchablePdf IN VARCHAR2 DEFAULT GC_GENERATE_SEARCHABLE_PDF,
		p_exec_asynchronous 	IN VARCHAR2 DEFAULT GC_EXECUTE_ASYNCHRONOUS,
		p_Export_Invoices 		IN VARCHAR2 DEFAULT 'N',
		p_files_cv				IN files_ref_cursor,
		p_Context 				IN NUMBER DEFAULT NULL
	) RETURN Document_Scan_Ai_Jobs.Job_Id%TYPE;

	FUNCTION Process_Files (
		p_documentType			IN VARCHAR2 DEFAULT GC_PROCESSOR_DOCUMENT_TYPE, 
		p_Language				IN VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
		p_Key_Values_Extraction IN VARCHAR2 DEFAULT GC_KEY_VALUES_EXTRACTION,
		p_Table_Extraction		IN VARCHAR2 DEFAULT GC_TABLE_EXTRACTION,
		p_generateSearchablePdf IN VARCHAR2 DEFAULT GC_GENERATE_SEARCHABLE_PDF,
		p_exec_asynchronous 	IN VARCHAR2 DEFAULT GC_EXECUTE_ASYNCHRONOUS,
		p_Export_Invoices 		IN VARCHAR2 DEFAULT 'N',
		p_Context 				IN NUMBER DEFAULT NULL
	) RETURN Document_Scan_Ai_Jobs.Job_Id%TYPE;

	TYPE rec_text_fragments_type IS RECORD (
		JOB_ID	NUMBER,
		DOCUMENT_ID	NUMBER,
		PAGE_NUMBER	NUMBER,
		TEXT_LINE	VARCHAR2(2000 BYTE),
		LINE_NO	NUMBER,
		ELEMENT_NO	NUMBER,
		LINE_HEIGHT	NUMBER,
		X0	NUMBER,
		Y0	NUMBER,
		X1	NUMBER,
		Y1	NUMBER,
		X2	NUMBER,
		Y2	NUMBER,
		X3	NUMBER,
		Y3	NUMBER,
		CONFIG_ID	NUMBER,
		CONTEXT_ID	NUMBER,
		JOB_LANGUAGE_CODE	VARCHAR2(10 BYTE),
		LANGUAGE_CODE	VARCHAR2(10 BYTE),
		JOB_DOCUMENT_TYPE	VARCHAR2(50 BYTE),
		DOCUMENT_TYPE_CODE	VARCHAR2(50 BYTE),
		COMPOSITE_PATTERN	NUMBER
	);
	TYPE tab_text_fragments_type IS TABLE OF rec_text_fragments_type;

	/* splt text line from the json document into fragments with key-value pairs when a separator like - ; | or . is found. */
	FUNCTION Document_Text_Fragments (p_document_id IN NUMBER)
	RETURN tab_text_fragments_type PIPELINED;

	TYPE rec_text_key_values_type IS RECORD (
		DOCUMENT_ID	NUMBER,
		JOB_ID	NUMBER,
		PAGE_NUMBER	NUMBER,
		LINE_NO	NUMBER,
		ELEMENT_NO			NUMBER,
		ITEM_LABEL			VARCHAR2(300 BYTE),
		ITEM_VALUE			VARCHAR2(2000 BYTE),
		X0					NUMBER,
		Y0					NUMBER,
		FIELD_LABEL			VARCHAR2(50 BYTE),
		VALUE_TYPE			VARCHAR2(50 BYTE),
		ITEM_VALUE_TYPE		VARCHAR2(50 BYTE),
		NUMBER_VALUE		NUMBER,
		DATE_VALUE			DATE,
		LANGUAGE_RANK		NUMBER,
		TERRITORY			VARCHAR2(20 BYTE),
		CATEGORY			NUMBER,
		COMPOSITE_PATTERN 	NUMBER,
		VALID_CONVERSION	NUMBER,
		RANK	NUMBER
	);
	TYPE tab_text_key_values_type IS TABLE OF rec_text_key_values_type;
	/* find key-value pairs in text lines from the json document */
	FUNCTION Document_Text_Key_Values (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	RETURN tab_text_key_values_type PIPELINED;

	TYPE rec_new_key_values_type IS RECORD (
		FIELD_TEXT	VARCHAR2(2000 BYTE),
		FIELD_ALIAS	VARCHAR2(300 BYTE),
		FIELD_TYPE	VARCHAR2(50 BYTE),
		LANGUAGE_CODE	VARCHAR2(10 BYTE),
		DOCUMENT_TYPE	VARCHAR2(50 BYTE),
		MATCH_PATTERN	VARCHAR2(5 BYTE),
		LABEL_TYPE	VARCHAR2(50 BYTE),
		JOB_ID	NUMBER,
		DOCUMENT_ID	NUMBER
	);
	TYPE tab_new_key_values_type IS TABLE OF rec_new_key_values_type;
	/* find key-value pairs in text lines from the json document */
	FUNCTION Document_New_Key_Values (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	RETURN tab_new_key_values_type PIPELINED;

	PROCEDURE Load_Document_Field_Alias (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	);

	PROCEDURE Load_Document_Derived_Values (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	);

	PROCEDURE Load_Document_Fields (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	);
	
	FUNCTION get_file (p_request_url IN VARCHAR2) RETURN BLOB;	
	FUNCTION base_file_name (p_file_name IN VARCHAR2) RETURN VARCHAR2;
	PROCEDURE Render_Document (
		p_document_id  			IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE
		,p_use_searchable_pdf 	IN VARCHAR2 DEFAULT 'Y'
	);
	PROCEDURE Download_Searchable_Pdf (p_document_id  IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE);
	PROCEDURE Download_Searchable_Pdf_Zip (p_Job_id  IN DOCUMENT_SCAN_AI_DOCS.job_id%TYPE);
	
	FUNCTION convert_to_Searchable_Pdf (
		p_file_blob 			IN BLOB,
		p_documentType			IN VARCHAR2 DEFAULT GC_PROCESSOR_DOCUMENT_TYPE, 
		p_Language				IN VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
		p_mime_type				IN VARCHAR2 DEFAULT 'application/pdf'
	) RETURN BLOB;

	PROCEDURE Ctx_Document_Content(r in rowid, c in out nocopy blob);
	FUNCTION Ctx_Document_Filter(p_docid in varchar2) return clob;

	FUNCTION Get_User_Job_State_Peek (p_Job_ID VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

	FUNCTION oracle_text_fuzzy_search (
		p_search in varchar2 
	) return varchar2;

	FUNCTION oracle_text_progress_search (
    	p_search in varchar2 
    ) return varchar2;
    
	FUNCTION oracle_text_token_search (
    	p_Search IN VARCHAR2,
    	p_Language IN VARCHAR2 DEFAULT 'GERMAN'
    ) return varchar2;

	PROCEDURE Rebuild_Text_Index;
    
	FUNCTION Find_Address_call (
		p_Search IN VARCHAR2 DEFAULT NULL,			-- search string with name and address
		p_Language IN VARCHAR2 DEFAULT 'GERMAN',	-- language of the search string
		p_Context_ID IN NUMBER DEFAULT NULL,
		p_Vendor_Name IN VARCHAR2  DEFAULT NULL,
		p_Vendor_Address IN VARCHAR2  DEFAULT NULL,
		p_Vendor_Logo IN VARCHAR2  DEFAULT NULL,
		p_Email IN VARCHAR2  DEFAULT NULL,
		p_Phone IN VARCHAR2  DEFAULT NULL,
		p_Tax_ID IN VARCHAR2  DEFAULT NULL,
		p_IBAN IN VARCHAR2  DEFAULT NULL,
		p_SWIFT_BIC IN VARCHAR2  DEFAULT NULL,
		p_Search_Project_Client IN VARCHAR2  DEFAULT 'N'  -- Y/N Value, when Y return adress of the project Client. 
	) RETURN NUMBER;

	PROCEDURE Link_Document_Addresses (
		p_Job_Id IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	);

	FUNCTION Duplicate_Configuration (p_config_id IN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE)
	RETURN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE;

	PROCEDURE Set_Current_Configuration (p_config_id IN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE);

	PROCEDURE Load_Configuration (p_config_id IN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE DEFAULT NULL);
END Document_Scan_Ai_Pkg;
/

