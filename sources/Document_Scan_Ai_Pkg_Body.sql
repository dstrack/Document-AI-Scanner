CREATE OR REPLACE PACKAGE BODY Document_Scan_Ai_Pkg AS
	-- the documentation says that the following date formats are used for the field_value of type date and time.
	-- But two different formats can be found in the results. 
	--	1. UNIX time in milliseconds since 1.1.1970
	--  2. the format YYYY-MM-DD"T"HH24:MI:SS.FF"Z"
	GC_OCI_DOC_AI_DATE_FORMAT 		 		CONSTANT VARCHAR2(100)    := 'yyyy-mm-dd';	-- format of the date field values.
	GC_OCI_DOC_AI_TIME_FORMAT 		 		CONSTANT VARCHAR2(100)    := 'yyyy-mm-dd hh-mi-ss';	-- format of the time field values.
	GC_OCI_DOC_AI_TIMESTAMP_FORMAT			CONSTANT VARCHAR2(100)    := 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"';
	GC_JOB_ID_FORMAT						CONSTANT VARCHAR2(20)	  := 'FM000009';
	GC_Job_Name_Prefix						CONSTANT VARCHAR2(50)     := 'DOCUMENT_SCAN_AI_';
	GC_Jobs_Sleep_Seconds					CONSTANT NUMBER 	  	  := 2;
	GC_OCI_DOC_AI_FEATURE_KEY_VALUES		CONSTANT VARCHAR2(100) := '{
	"featureType": "KEY_VALUE_EXTRACTION"
	}';
	GC_OCI_DOC_AI_FEATURE_TABLE_EXTRACTION		CONSTANT VARCHAR2(100) := '{
	"featureType": "TABLE_EXTRACTION"
	}';
	GC_OCI_DOC_AI_FEATURE_TEXT_EXTRACTION	CONSTANT VARCHAR2(100) := '{    
	"featureType": "TEXT_EXTRACTION",    
	"generateSearchablePdf": true   
	}';

	GC_OCI_DOC_AI_PAYLOAD			 CONSTANT VARCHAR2(32767) := '{
	"processorConfig": {
			"processorType": "GENERAL",
			"features": [
				{
					"featureType": "DOCUMENT_CLASSIFICATION",
					"maxResults": 5
				},
				{
					"featureType": "LANGUAGE_CLASSIFICATION",
					"maxResults": 5
				} 
				%s
				%s
				%s
			],
			"documentType": %s,
			"language": %s
		},
		"inputLocation": {
			"sourceType": "OBJECT_STORAGE_LOCATIONS",
			"objectLocations": [
				%s
			]
		},
		"compartmentId": "%s",
		"outputLocation": {
			"namespaceName": "%s",
			"bucketName": "%s",
			"prefix": "%s"
		}
	}';

	CURSOR cr_processorJob_data (cp_json IN CLOB) IS
		SELECT jt.*
		FROM JSON_TABLE(cp_json
				, '$'
				COLUMNS (processorJob_ID		 VARCHAR2(1000) PATH '$.id',
						  language_code			 VARCHAR2(50)	PATH '$.processorConfig.language',
						  documentType			 VARCHAR2(200) 	PATH '$.processorConfig.documentType',
						  lifecycleState		 VARCHAR2(200) 	PATH '$.lifecycleState',
						  lifecycleDetails		 VARCHAR2(200)  PATH '$.lifecycleDetails' NULL ON EMPTY,
						  percentComplete		 NUMBER			PATH '$.percentComplete'
				)
			) jt;

	PROCEDURE set_cloud_credentials (
		p_credential_name IN VARCHAR2 DEFAULT GC_CLOUD_CREDENTIAL_ID,
		p_username IN VARCHAR2,
		p_password IN VARCHAR2 
	) IS 
		Credential_already_exists EXCEPTION;
		PRAGMA EXCEPTION_INIT (Credential_already_exists, -20022); -- ORA-20022: Credential ... already exists
	BEGIN
$IF DOCUMENT_SCAN_AI_PKG.G_USE_DBMS_CLOUD $THEN
		DBMS_CLOUD.CREATE_CREDENTIAL(
			credential_name => p_credential_name,
			username => p_username,
			password => p_password
		);
	exception 
		when Credential_already_exists then 
			DBMS_CLOUD.UPDATE_CREDENTIAL (
				credential_name => p_credential_name,
				attribute      => 'USERNAME',
				value          =>  p_username
			);
			DBMS_CLOUD.UPDATE_CREDENTIAL (
				credential_name => p_credential_name,
				attribute      => 'PASSWORD',
				value          =>  p_password
			);
		when others then 
			raise;
$ELSE
	RAISE_APPLICATION_ERROR (-20100, 'Document_Scan_Ai_Pkg.Set_Cloud_Credentials - Function is not implemented');
$END
	END set_cloud_credentials;

	FUNCTION Context_List_Of_Values 
	RETURN tab_list_of_values PIPELINED
	IS 
		l_out_rec rec_list_of_values;
		TYPE cur_type IS REF CURSOR;
   		cr_context cur_type;
	BEGIN 
		if GC_CONTEXT_ID_QUERY IS NULL then 
			return;
		end if;
		OPEN cr_context for GC_CONTEXT_ID_QUERY;
		loop 
			FETCH cr_context INTO l_out_rec;
			EXIT WHEN cr_context%NOTFOUND;
			PIPE ROW (l_out_rec);
		end loop;
		CLOSE cr_context;
	END Context_List_Of_Values;

	FUNCTION pipe_context_fields (p_Context_ID IN NUMBER)
	RETURN tab_Context_fields PIPELINED
	IS 
		l_out_rec rec_Context_fields;
		l_query VARCHAR2(2000);
		TYPE cur_type IS REF CURSOR;
   		cr_context cur_type;
	BEGIN 
		if GC_CONTEXT_FIELDS_QUERY IS NULL then 
			return;
		end if;
		l_query := 'SELECT * FROM (' || GC_CONTEXT_FIELDS_QUERY || ') WHERE ID = :a';
		OPEN cr_context for l_query USING p_Context_ID;
		loop 
			FETCH cr_context INTO l_out_rec;
			EXIT WHEN cr_context%NOTFOUND;
			PIPE ROW (l_out_rec);
		end loop;
		CLOSE cr_context;
	END pipe_context_fields;

	FUNCTION Context_Display_Value (
		p_Search_Value IN NUMBER
	) RETURN VARCHAR2
	IS 
		l_out_rec rec_list_of_values;
		l_query VARCHAR2(2000);
		TYPE cur_type IS REF CURSOR;
   		cr_context cur_type;
	BEGIN 
		if GC_CONTEXT_ID_QUERY IS NULL then 
			return NULL;
		end if;
		l_query := 'SELECT * FROM (' || GC_CONTEXT_ID_QUERY || ') WHERE ID = :a';
		OPEN cr_context for l_query USING p_Search_Value;
		FETCH cr_context INTO l_out_rec;
		CLOSE cr_context;
		RETURN l_out_rec.display_value;
	END Context_Display_Value;

	FUNCTION Address_List_Of_Values 
	RETURN tab_list_of_values PIPELINED
	IS 
		l_out_rec rec_list_of_values;
		l_query VARCHAR2(2000);
		TYPE cur_type IS REF CURSOR;
   		cr_address cur_type;
	BEGIN 
		if GC_ADDRESS_ID_QUERY IS NULL then 
			return;
		end if;
		OPEN cr_address for GC_ADDRESS_ID_QUERY;
		loop 
			FETCH cr_address INTO l_out_rec;
			EXIT WHEN cr_address%NOTFOUND;
			PIPE ROW (l_out_rec);
		end loop;
		CLOSE cr_address;
	END Address_List_Of_Values;

	FUNCTION Address_Display_Value (
		p_Search_Value IN NUMBER DEFAULT NULL
	) RETURN VARCHAR2
	IS 
		l_out_rec rec_list_of_values;
		l_query VARCHAR2(2000);
		TYPE cur_type IS REF CURSOR;
   		cr_address cur_type;
	BEGIN 
		if GC_ADDRESS_ID_QUERY IS NULL then 
			return NULL;
		end if;
		l_query := 'SELECT * FROM (' || GC_ADDRESS_ID_QUERY || ') WHERE ID = :a';
		OPEN cr_address for l_query USING p_Search_Value;
		FETCH cr_address INTO l_out_rec;
		CLOSE cr_address;
		RETURN l_out_rec.display_value;
	END Address_Display_Value;
	--------------------------------------------------------------------------------
	FUNCTION Get_Invoice_Export_Query (
		p_Job_ID IN VARCHAR2 
	) RETURN VARCHAR2
	IS 
	BEGIN 
		RETURN case when GC_INVOICE_EXPORT_VIEW is not null 
			then apex_string.format('select * from %s where job_id = %s'
				,GC_INVOICE_EXPORT_VIEW
				,NVL(p_Job_ID, 0))
			else 'select 0 document_id, 0 job_id, null file_name from dual'
		end;
	END Get_Invoice_Export_Query;

	PROCEDURE Name_Resolve (
		p_Table_Name		IN VARCHAR2,
		p_Resoled_Owner		OUT VARCHAR2,
		p_Resoled_Name		OUT VARCHAR2
	)
	is
		v_Part2 VARCHAR2(128);
		v_Dblink VARCHAR2(128);
		v_Part1_Type NUMBER;
		v_Object_Number NUMBER;
	begin
		DBMS_UTILITY.NAME_RESOLVE (
			name => p_Table_Name,
			context => 0, --  table
			schema => p_Resoled_Owner, 
			part1 => p_Resoled_Name,
			part2 => v_Part2,
			dblink => v_Dblink,
			part1_type => v_Part1_Type,
			object_number => v_Object_Number
		);
	end Name_Resolve;
	
	FUNCTION Get_Invoice_Export_Column_List 
	RETURN VARCHAR2
	IS 
		l_Column_List VARCHAR2(32767);
		l_Table_Name  VARCHAR2(128);
		l_Table_Owner VARCHAR2(128);
	BEGIN 
		Name_Resolve(GC_INVOICE_EXPORT_VIEW, l_Table_Owner, l_Table_Name);
		
		SELECT LISTAGG(INITCAP(COLUMN_NAME), ':') WITHIN GROUP (ORDER BY COLUMN_ID)
		INTO l_Column_List
		FROM ALL_TAB_COLUMNS
		WHERE TABLE_NAME = l_Table_Name
		AND OWNER = l_Table_Owner;
		
		RETURN l_Column_List;
	END Get_Invoice_Export_Column_List;
	
	PROCEDURE Export_Invoice_List(p_Job_ID IN NUMBER) 
	IS 
		l_call 	VARCHAR2(2000);
		l_Is_Exported VARCHAR2(10);
	BEGIN 
		SELECT Is_Exported INTO l_Is_Exported
		FROM DOCUMENT_SCAN_AI_JOBS
		WHERE job_id = p_Job_ID;
		IF l_Is_Exported = 'Y' THEN 
			raise_application_error(-20101,'This invoice list has already been exported.');
		END IF;
		if GC_INVOICE_EXPORT_PROCEDURE IS NOT NULL then 
			l_call := apex_string.format('begin %s(:a); end;', GC_INVOICE_EXPORT_PROCEDURE);
			EXECUTE IMMEDIATE l_call USING IN p_Job_ID;
			
			UPDATE DOCUMENT_SCAN_AI_JOBS
			SET Is_Exported = 'Y'
			WHERE job_id = p_Job_ID;
			
			COMMIT;
		end if;	
	END Export_Invoice_List;
	--------------------------------------------------------------------------------

	FUNCTION Encode_Object_Name(p_source_object_name IN VARCHAR2) RETURN VARCHAR2
	IS
		v_ascii_name VARCHAR2(4000);
	BEGIN
		v_ascii_name := CONVERT(p_source_object_name, 'US7ASCII');
		v_ascii_name := REGEXP_REPLACE(v_ascii_name, '\s+', '_');  
		RETURN UTL_URL.ESCAPE(v_ascii_name);
	END;

	FUNCTION get_OCI_Config_ID RETURN NUMBER
	IS 
	BEGIN 
		RETURN GC_CONFIG_ID;
	END;

	FUNCTION get_OCI_OBJ_STORE_BASE_URL RETURN VARCHAR2
	IS
		GC_OCI_OBJ_STORE_BASE_URL CONSTANT VARCHAR2(100)	:= '%s/n/%s/b/%s/o/';
	BEGIN 
		RETURN apex_string.format(GC_OCI_OBJ_STORE_BASE_URL, 
				GC_OBJECT_STORE_BASE_URL, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				p_max_length=>4000);
	END;
	
	FUNCTION get_OCI_OBJ_STORE_INPUT_URL(
		p_file_name IN VARCHAR2, 
		p_job_id IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN VARCHAR2
	IS 
		GC_OCI_OBJ_STORE_INPUT_URL	CONSTANT VARCHAR2(100)	:= '%s/n/%s/b/%s/o/%s/job%s/%s';
	BEGIN 
		RETURN apex_string.format(GC_OCI_OBJ_STORE_INPUT_URL,
				GC_OBJECT_STORE_BASE_URL, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_INPUT_LOCATION_PREFIX,
				to_char(p_Job_Id, GC_JOB_ID_FORMAT),
				Encode_Object_Name(p_file_name),
				p_max_length=>32767)
				;
	END;
	
	FUNCTION get_OCI_OBJ_STORE_OUTPUT_URL RETURN VARCHAR2
	IS 
		GC_OCI_OBJ_STORE_OUTPUT_URL CONSTANT VARCHAR2(100)	:= '%s/n/%s/b/%s/o/%s/';
	BEGIN 
		RETURN apex_string.format(GC_OCI_OBJ_STORE_OUTPUT_URL, 
				GC_OBJECT_STORE_BASE_URL, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_OUTPUT_LOCATION_PREFIX,
				p_max_length=>32767);
	END;
	
	FUNCTION get_OCI_OBJ_STORE_PDF_URL RETURN VARCHAR2
	IS 
		GC_OCI_OBJ_STORE_OUTPUT_URL CONSTANT VARCHAR2(100)	:= '%s/n/%s/b/%s/o/%s/';
	BEGIN 
		RETURN apex_string.format(GC_OCI_OBJ_STORE_OUTPUT_URL, 
				GC_OBJECT_STORE_BASE_URL, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_PDF_LOCATION_PREFIX,
				p_max_length=>32767);
	END;
	
	FUNCTION get_OCI_INPUT_DOC_LOCATION(
		p_file_name IN VARCHAR2, 
		p_job_id IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN VARCHAR2
	IS 
		GC_OCI_INPUT_DOC_LOCATION	CONSTANT VARCHAR2(1000) := '
		{
			"source": "OBJECT_STORAGE",
			"namespaceName": "%s",
			"bucketName": "%s",
			"objectName": "%s/job%s/%s"
		}';
	BEGIN 
		RETURN apex_string.format(GC_OCI_INPUT_DOC_LOCATION, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_INPUT_LOCATION_PREFIX, 
				to_char(p_Job_Id, GC_JOB_ID_FORMAT),
				Encode_Object_Name(p_file_name),
				p_max_length=>32767);
	END;
	
	FUNCTION get_OCI_OUTPUT_JSON_LOCATION(
		p_processorJob_ID VARCHAR2, 
		p_file_name VARCHAR2, 
		p_job_id IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN VARCHAR2
	IS 
		GC_OCI_OUTPUT_DOC_LOCATION	CONSTANT VARCHAR2(100) := '%s/%s_%s/results/%s/job%s/%s.json';
	BEGIN 
		RETURN apex_string.format(GC_OCI_OUTPUT_DOC_LOCATION, 
				p_processorJob_ID, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_INPUT_LOCATION_PREFIX, 
				to_char(p_Job_Id, GC_JOB_ID_FORMAT),
				Encode_Object_Name(p_file_name),
				p_max_length=>32767
		);
	END;
	
	FUNCTION get_OCI_OUTPUT_PDF_LOCATION(
		p_processorJob_ID VARCHAR2, 
		p_file_name VARCHAR2, 
		p_job_id IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN VARCHAR2
	IS 
		GC_OCI_OUTPUT_DOC_LOCATION	CONSTANT VARCHAR2(100) := '%s/%s_%s/searchablePdf/%s/job%s/%s.pdf';
	BEGIN 
		RETURN apex_string.format(GC_OCI_OUTPUT_DOC_LOCATION, 
				p_processorJob_ID, 
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_INPUT_LOCATION_PREFIX, 
				to_char(p_Job_Id, GC_JOB_ID_FORMAT),
				Encode_Object_Name(p_file_name), 
				p_max_length=>32767
		);
	END;
	
	FUNCTION get_OCI_DOC_AI_PAYLOAD(
		p_documentType VARCHAR2 DEFAULT 'INVOICE', 
		p_Language VARCHAR2 DEFAULT 'ENG', 
		p_generateSearchablePdf VARCHAR2 DEFAULT 'N',
		p_Key_Values_Extraction VARCHAR2 DEFAULT 'N',
		p_Table_Extraction VARCHAR2 DEFAULT 'N',
		p_objectLocations VARCHAR2
	) RETURN VARCHAR2
	IS 
	BEGIN 
		RETURN apex_string.format(GC_OCI_DOC_AI_PAYLOAD, 
				case when p_Key_Values_Extraction = 'Y' then ',' || GC_OCI_DOC_AI_FEATURE_KEY_VALUES  end,
				case when p_Table_Extraction = 'Y' then ',' || GC_OCI_DOC_AI_FEATURE_TABLE_EXTRACTION  end,
				case when p_generateSearchablePdf = 'Y' then ',' || GC_OCI_DOC_AI_FEATURE_TEXT_EXTRACTION end,
				case when p_documentType IS NOT NULL then DBMS_ASSERT.ENQUOTE_NAMe(p_documentType) else 'null' end, 
				case when p_Language IS NOT NULL then DBMS_ASSERT.ENQUOTE_NAMe(p_Language) else 'null' end, 
				p_objectLocations,
				GC_COMPARTMENT_ID,
				GC_OBJECT_NAMESPACE_NAME, 
				GC_OBJECT_BUCKET_NAME, 
				GC_OUTPUT_LOCATION_PREFIX,
				p_max_length=>32767
		);
	END;
	--------------------------------------------------------------------------------
    -- produce a format mask for p_Value string using p_NumChars, p_Currency
    FUNCTION Get_Number_Mask (
        p_Value VARCHAR2,                   -- string with formated number
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,   -- decimal and group character
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER  -- currency character
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN REGEXP_REPLACE(TRANSLATE(p_Value, 
                '+-012345678'||p_NumChars||p_Currency||' ', 
                '99999999999DGL'), 
            '[e|E]9+$', -- detect exponent 
            'EEEE');
    END Get_Number_Mask;

    FUNCTION Get_Number_Normalized (
        p_Value VARCHAR2,                   -- string with formated number
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER,  -- currency character
        p_ISO_Currency VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    	v_string			VARCHAR2(4000);
    BEGIN
    	v_string := REPLACE(p_Value, p_ISO_Currency, p_Currency);	-- replace currency_code with currency_character
    	v_string := REGEXP_REPLACE(v_string, '\s?\'||p_Currency||'\s?', p_Currency); -- remove blanks before or after currency_character
    	v_string := REGEXP_REPLACE(v_string, '(\d) (\d)', '\1\2'); -- remove blanks between digits
   		v_string := RTRIM(v_string, '/√-');	-- remove marking characters after number
        RETURN TRIM(v_string);
    END Get_Number_Normalized;

    -- produce the NLS_Param for the to_number function using p_NumChars, p_Currency
    FUNCTION Get_NLS_Param (
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,   -- decimal (radix) and group character
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER, -- current Currency character
        p_Territory VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    PRAGMA UDF;
    BEGIN
        RETURN 'NLS_NUMERIC_CHARACTERS = ' || dbms_assert.enquote_literal(p_NumChars)
        || ' NLS_CURRENCY = ' || dbms_assert.enquote_literal(p_Currency)
        || case when p_Territory IS NOT NULL then ' NLS_ISO_CURRENCY = ' || p_Territory end;
    END Get_NLS_Param;

    -- Convert any to_char(x, 'FM9') string to sql number using p_NumChars, p_Currency
    -- convert string with formated oracle floating point number to oracle number.
    -- the string was produced by function TO_CHAR with format FM9 
    -- or a format that contains G D L or EEEE symbols
    FUNCTION FM9_TO_Number(
        p_Value VARCHAR2, 
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER,
        p_ISO_Currency VARCHAR2 DEFAULT NULL,
        p_Territory VARCHAR2 DEFAULT NULL,
        p_Default_On_Error NUMBER DEFAULT NULL
    ) RETURN NUMBER DETERMINISTIC
    IS
    PRAGMA UDF;
    	v_string	VARCHAR2(4000);
    BEGIN
    	v_string := Get_Number_Normalized(p_Value, p_Currency, p_ISO_Currency);
        RETURN TO_NUMBER(v_string, 
            Get_Number_Mask(v_string, p_NumChars, p_Currency), 
            Get_NLS_Param (p_NumChars, p_Currency, p_Territory));
    EXCEPTION WHEN VALUE_ERROR THEN
        if p_Default_On_Error IS NOT NULL then 
            return p_Default_On_Error;
        else 
            raise;
        end if;
    END FM9_TO_Number;

    FUNCTION Text_TO_Number(
        p_Value VARCHAR2, 
        p_iso_code VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
        p_Default_On_Error NUMBER DEFAULT NULL
	) RETURN NUMBER
    IS
    PRAGMA UDF;
		CURSOR cr_nls_param (p_iso_code IN VARCHAR2) IS
			SELECT	
				common_number_format,
				territory, nls_numeric_characters, nls_currency, nls_iso_currency
		FROM DOCUMENT_SCAN_AI_LANGUAGES 
		WHERE iso_code = p_iso_code;
		lr_nls_param	cr_nls_param%ROWTYPE;
    	v_string	VARCHAR2(4000);
    BEGIN
		OPEN	cr_nls_param (p_iso_code => p_iso_code);
		FETCH cr_nls_param INTO lr_nls_param;
		CLOSE cr_nls_param;
    	v_string := Get_Number_Normalized(p_Value, lr_nls_param.nls_currency, lr_nls_param.nls_iso_currency);
        RETURN TO_NUMBER(v_string, 
            Get_Number_Mask(v_string, lr_nls_param.nls_numeric_characters, lr_nls_param.nls_currency), 
            Get_NLS_Param (lr_nls_param.nls_numeric_characters, lr_nls_param.nls_currency, lr_nls_param.territory)
        );
    EXCEPTION WHEN VALUE_ERROR THEN
        if p_Default_On_Error IS NOT NULL then 
            return p_Default_On_Error;
        else 
            raise;
        end if;
    END Text_TO_Number;

    -- used to validate the input for acceptable number strings
    FUNCTION Validate_Number_Conversion (
        p_Value VARCHAR2,
        p_NumChars VARCHAR2 DEFAULT GC_NUMBER_CHARACTER,
        p_Currency VARCHAR2 DEFAULT GC_CURRENCY_CHARACTER,
        p_ISO_Currency VARCHAR2 DEFAULT NULL,
        p_Territory VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER DETERMINISTIC
    IS PRAGMA UDF;
    	v_string			VARCHAR2(4000);
    	v_decimal_char   	VARCHAR2(1) := SUBSTR(p_NumChars, 1, 1);
    	v_group_char   		VARCHAR2(1) := SUBSTR(p_NumChars, 2, 1);
    	v_decimal_offset 	NUMBER;
    	v_decimal_offset2 	NUMBER;
    	v_group_offset 		NUMBER;
    BEGIN
    	if TRANSLATE(p_Value, '0123456789', '----------') = p_Value then -- are there any digit in the string?
    		RETURN 0;													-- return 0 when not digits found; 
    	end if;

    	v_string := Get_Number_Normalized(p_Value, p_Currency, p_ISO_Currency);
    	v_decimal_offset 	:= INSTR(v_string, v_decimal_char);
    	v_decimal_offset2 	:= INSTR(v_string, v_decimal_char, 1, 2);
    	v_group_offset		:= INSTR(v_string, v_group_char);
    	if (v_group_offset > 0 and LENGTH(v_string) - v_group_offset < 3) 	-- group char must be at least in the 3 position from end of string
    	or (v_decimal_offset > 0 and v_group_offset > v_decimal_offset)		-- group char must appear before decimal char 
    	or (v_decimal_offset2 > 0) 											-- only one decimal char is allowed
    	or (v_group_offset > 0 and v_decimal_offset > 0 						-- the distance between group char and decimal char 
    		and mod(v_decimal_offset - v_group_offset, 4) != 0)				-- must be a multiple of 4
    	then 
    		RETURN 0;
    	end if;
        RETURN VALIDATE_CONVERSION(v_string AS NUMBER, 
        		Get_Number_Mask(v_string, p_NumChars, p_Currency), 
            	Get_NLS_Param (p_NumChars, p_Currency, p_Territory));
    END Validate_Number_Conversion;

    FUNCTION Get_Date_Normalized (
        p_Value VARCHAR2                   -- string with formated date
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    	v_string			VARCHAR2(1000);
    BEGIN
    	v_string := REGEXP_REPLACE(p_Value, '(\d) (\d)', '\1\2'); -- remove blanks between digits
        RETURN TRIM(v_string);
    END Get_Date_Normalized;

    FUNCTION Validate_Date_Conversion (
        p_Value VARCHAR2,
        p_Date_format VARCHAR2,
        p_NLS_Date_Language VARCHAR2
    ) RETURN NUMBER DETERMINISTIC
    IS PRAGMA UDF;
    	v_nlsparam CONSTANT VARCHAR2(50) := 'NLS_DATE_LANGUAGE = '||p_NLS_Date_Language;
    	v_string			VARCHAR2(1000);
    BEGIN
    	v_string := Get_Date_Normalized(p_Value);
    	RETURN VALIDATE_CONVERSION(v_string AS DATE, p_Date_format, v_nlsparam);
    END Validate_Date_Conversion;

    FUNCTION To_Date_Conversion (
        p_Value VARCHAR2,
        p_Date_format VARCHAR2,
        p_NLS_Date_Language VARCHAR2
    ) RETURN DATE DETERMINISTIC
    IS PRAGMA UDF;
    	v_nlsparam CONSTANT VARCHAR2(50) := 'NLS_DATE_LANGUAGE = '||p_NLS_Date_Language;
    	v_string			VARCHAR2(1000);
    BEGIN
    	v_string := Get_Date_Normalized(p_Value);
    	RETURN TO_DATE(v_string, p_Date_format, v_nlsparam);
    END To_Date_Conversion;

	FUNCTION Get_String_Type (
        p_Value_Type VARCHAR2,
        p_Item_Value VARCHAR2
	) RETURN VARCHAR2 DETERMINISTIC
    IS PRAGMA UDF;
    BEGIN 
    	RETURN case when NVL(p_Value_Type, 'EMAIL' ) = 'EMAIL' and REGEXP_LIKE(p_Item_Value, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,8}$') 
			then 'EMAIL'	-- Regular expression for basic email validation
		when NVL(p_Value_Type, 'IBAN' ) = 'IBAN' and REGEXP_LIKE(p_Item_Value, '^[A-Z]{2}\s?\d{2}(\s?\w)*$') 
			then 'IBAN'		-- Regular expression for IBAN validation in the DACH region
		when NVL(p_Value_Type, 'SWIFTBIC' ) = 'SWIFTBIC' and REGEXP_LIKE(p_Item_Value, '^[A-Z0-9]{8,11}$')
			then 'SWIFTBIC'	-- Regular expression for BIC validation
		when NVL(p_Value_Type, 'PHONE' ) = 'PHONE' and REGEXP_LIKE(p_Item_Value,'^\+?[0-9()-/ ]+$')
			then 'PHONE'
		when NVL(p_Value_Type, 'STRING' ) IN ('STRING','INITCAP') and REGEXP_LIKE(p_Item_Value, '^[A-Za-z \.]+:?$')
		and INITCAP(p_Item_Value) = p_Item_Value
			then 'INITCAP'
		when NVL(p_Value_Type, 'STRING' ) IN ('STRING','UPPER') and REGEXP_LIKE(p_Item_Value, '^[A-Z]+:?$')
			then 'UPPER'
		when  NVL(p_Value_Type, 'STRING' ) IN ('STRING','NUMERIC') and REGEXP_LIKE(p_Item_Value, '^[0-9,\.]+$') 
			then 'NUMERIC'
		when  NVL(p_Value_Type, 'STRING' ) IN ('STRING','ALPHANUM') and REGEXP_LIKE(p_Item_Value, '[0-9]+') 
			then 'ALPHANUM'	-- contains at least one digit 
		else 'STRING'
		end;
    END Get_String_Type; 

	FUNCTION Trim_String_Type (
        p_Value_Type VARCHAR2,
        p_Item_Value VARCHAR2
	) RETURN VARCHAR2 DETERMINISTIC
    IS PRAGMA UDF;
    BEGIN 
    	RETURN case 
    	when p_Value_Type = 'EMAIL'
    		then REGEXP_REPLACE(p_Item_Value, '[,;]+.*', '')
    	when p_Value_Type = 'IBAN'
     		then REGEXP_REPLACE(p_Item_Value, '[,; ]+BIC:.*', '')
    	else trim(p_Item_Value)
    	end;
   END Trim_String_Type; 

	--------------------------------------------------------------------------------
	PROCEDURE handle_rest_response (
		p_function IN VARCHAR2,
		p_response IN CLOB,
		p_status_code IN NUMBER DEFAULT 200,
		p_job_id IN Document_Scan_Ai_Jobs.Job_Id%TYPE DEFAULT NULL
	) IS
		CURSOR cr_document_error (cp_json IN CLOB) IS
			SELECT	jt.*
			FROM	JSON_TABLE(cp_json, '$'
				 COLUMNS (	code		VARCHAR2(50)	PATH '$.code',
							message		VARCHAR2(500)	PATH '$.message'
				)) jt;
		lr_document_error		cr_document_error%ROWTYPE;
	BEGIN 
		IF apex_web_service.g_status_code != p_status_code then
			apex_debug.message('%s - status_code: %s', p_function, apex_web_service.g_status_code);
			apex_debug.message('%s response : %s', p_function, p_response);
			OPEN	cr_document_error (cp_json => p_response);
			FETCH cr_document_error INTO lr_document_error;
			CLOSE cr_document_error;
			if p_Job_Id IS NOT NULL then 
				UPDATE DOCUMENT_SCAN_AI_JOBS
				SET ProcessorJob_Message = lr_document_error.message
				,	lifecycleState = 'FAILED'	
				WHERE Job_Id = p_Job_Id;
				COMMIT;
			end if;
			raise_application_error(-20111,apex_string.format('Unable to %s with job_id %s on OCI. %s', p_function, p_Job_Id, lr_document_error.message));
		END IF;	
	END handle_rest_response;
	--------------------------------------------------------------------------------
	FUNCTION put_file (
		p_mime_type			IN VARCHAR2,
		p_file_blob			IN BLOB,
		p_file_name			IN VARCHAR2,
		p_job_id			IN Document_Scan_Ai_Jobs.Job_Id%TYPE DEFAULT NULL
	) RETURN VARCHAR2
	IS

		l_response				CLOB;
		v_object_store_url		VARCHAR2(4000);
	BEGIN
		-- Build the full Object Storage URL.
		v_object_store_url := get_OCI_OBJ_STORE_INPUT_URL(p_file_name, p_job_id);

$IF DOCUMENT_SCAN_AI_PKG.G_USE_DBMS_CLOUD $THEN
		DBMS_CLOUD.PUT_OBJECT (
			credential_name		=> GC_CLOUD_CREDENTIAL_ID,
			object_uri			=> UTL_URL.ESCAPE(v_object_store_url),
			contents			=> p_file_blob
		);
$ELSE
		-- Set Mime Type of the file in the Request Header.
		apex_web_service.g_request_headers.DELETE;
		apex_web_service.g_request_headers(1).name	:= 'Content-Type';
		apex_web_service.g_request_headers(1).value := p_mime_type;

		apex_debug.message('put_file object_store_url : %s', v_object_store_url);
		-- Call Web Service to PUT file in OCI.
		l_response := apex_web_service.make_rest_request (
			p_url					=> v_object_store_url,
			p_http_method			=> 'PUT',
			p_body_blob				=> p_file_blob,
			p_credential_static_id	=> GC_WC_CREDENTIAL_ID
		);
		handle_rest_response (
			p_function => 'put_file',
			p_response => l_response,
			p_status_code => 200,
			p_job_id => p_job_id
		);
$END
		RETURN v_object_store_url;
	END put_file;

	PROCEDURE Rename_File(
		p_old_object_name IN VARCHAR2,
		p_new_object_name IN VARCHAR2,
		p_job_id			IN Document_Scan_Ai_Jobs.Job_Id%TYPE DEFAULT NULL
	) IS
		l_old_object_name VARCHAR2(32767);
		l_new_object_name VARCHAR2(32767);
		l_endpoint VARCHAR2(32767);
		l_request_body CLOB;
		l_response CLOB;
		GC_OCI_OBJ_STORE_RENAME_URL	CONSTANT VARCHAR2(100)	:= '%s/n/%s/b/%s/actions/renameObject';
	BEGIN
		-- Encode the object names to ensure they are URL-safe
		l_old_object_name := Encode_Object_Name(p_old_object_name);
		l_new_object_name := Encode_Object_Name(p_new_object_name);

$IF DOCUMENT_SCAN_AI_PKG.G_USE_DBMS_CLOUD $THEN
		l_endpoint := get_OCI_OBJ_STORE_BASE_URL;
		DBMS_CLOUD.MOVE_OBJECT (
			source_credential_name 	=> GC_CLOUD_CREDENTIAL_ID,
			source_object_uri 		=> l_endpoint || l_old_object_name,
			target_object_uri		=> l_endpoint || l_new_object_name
		);
$ELSE
		-- Build the API endpoint for renaming the object
		l_endpoint := apex_string.format(GC_OCI_OBJ_STORE_RENAME_URL,
			GC_OBJECT_STORE_BASE_URL, 
			GC_OBJECT_NAMESPACE_NAME, 
			GC_OBJECT_BUCKET_NAME, 
			p_max_length=>32767
		);
		-- Build the request body for renaming the object
		l_request_body := '{"sourceName": "' || l_old_object_name || '", "newName": "' || l_new_object_name || '"}';

		apex_web_service.g_request_headers.DELETE;
		apex_web_service.g_request_headers(1).name  := 'Content-Type';
		apex_web_service.g_request_headers(1).value := 'application/json';
		-- Send the rename request using APEX_WEB_SERVICE
		l_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
			p_url => l_endpoint,
			p_http_method => 'POST',
			p_body => l_request_body,
			p_credential_static_id	=> GC_WC_CREDENTIAL_ID
		);
		handle_rest_response (
			p_function => 'Rename_File',
			p_response => l_response,
			p_status_code => 200,
			p_job_id => p_job_id
		);
$END
	END Rename_File;

	PROCEDURE Delete_File(
		p_object_name IN VARCHAR2,
		p_job_id	  IN Document_Scan_Ai_Jobs.Job_Id%TYPE DEFAULT NULL
	) IS
		l_endpoint VARCHAR2(4000);
		l_object_name VARCHAR2(4000);
		l_response CLOB;
		GC_OCI_OBJ_STORE_DELETE_URL	CONSTANT VARCHAR2(100)	:= '%s/n/%s/b/%s/o/';
	BEGIN
		-- Set the namespace, bucket, and object names
		l_object_name := Encode_Object_Name(p_object_name);
		apex_debug.message('Delete_File: ' || l_object_name);
		-- Build the API endpoint for deleting the object
		l_endpoint := get_OCI_OBJ_STORE_BASE_URL;
$IF DOCUMENT_SCAN_AI_PKG.G_USE_DBMS_CLOUD $THEN
		DBMS_CLOUD.DELETE_OBJECT (
			credential_name		=> GC_CLOUD_CREDENTIAL_ID,
			object_uri			=> l_endpoint || l_object_name
		);
$ELSE
		-- Send the delete request using APEX_WEB_SERVICE
		l_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
			p_url => l_endpoint || l_object_name,
			p_http_method => 'DELETE',
			p_credential_static_id	=> GC_WC_CREDENTIAL_ID
		);
		handle_rest_response (
			p_function => 'Delete_File',
			p_response => l_response,
			p_status_code => 204,
			p_job_id => p_job_id
		);
$END
	END Delete_File;


	--------------------------------------------------------------------------------
	FUNCTION upload_file (
		p_file_name		IN VARCHAR2,
		p_blob_content  IN BLOB,
		p_mime_type		IN VARCHAR2,
		p_custom_id		IN NUMBER,
		p_job_id		IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE
	IS
		v_document_id	DOCUMENT_SCAN_AI_DOCS.document_id%TYPE;
		v_object_store_url VARCHAR2(4000);
	BEGIN
	
		-- Post file to OCI Object Store.
		v_object_store_url := put_file (
			p_mime_type		=> p_mime_type,
			p_file_blob		=> p_blob_content,
			p_file_name		=> p_file_name,
			p_job_id		=> p_job_id
		);

		-- Create Document Record
		INSERT INTO DOCUMENT_SCAN_AI_DOCS (file_name, mime_type, object_store_url, custom_id, job_id)
		VALUES (p_file_name, p_mime_type, v_object_store_url, p_custom_id, p_job_id) 
		RETURNING document_id INTO v_document_id;

		apex_debug.message('upload_file - document_id: %s', v_document_id);
		RETURN v_document_id;
	END upload_file;
	--------------------------------------------------------------------------------
	FUNCTION Create_Processorjob_Details (
		p_documentType			IN VARCHAR2 DEFAULT 'INVOICE', 
		p_Language				IN VARCHAR2 DEFAULT 'ENG',
		p_Key_Values_Extraction IN VARCHAR2 DEFAULT 'N',
		p_Table_Extraction		IN VARCHAR2 DEFAULT 'N',
		p_generateSearchablePdf IN VARCHAR2 DEFAULT 'N',
		p_files_cv				IN files_ref_cursor,
		p_Context 				IN NUMBER DEFAULT NULL
	) RETURN Document_Scan_Ai_Jobs.Job_Id%TYPE
	IS 
		v_files					rec_files_type;
		v_Job_ID				DOCUMENT_SCAN_AI_JOBS.Job_Id%TYPE;
		v_document_id			DOCUMENT_SCAN_AI_DOCS.document_id%TYPE;
		v_object_store_url 		VARCHAR2(4000);
		v_doc_locations_json	VARCHAR2(32767);
		l_request_json			VARCHAR2(32767);
		v_Count 				NUMBER := 0;
		v_File_Name				DOCUMENT_SCAN_AI_DOCS.File_Name%TYPE;
		v_Mime_Type 			DOCUMENT_SCAN_AI_DOCS.mime_type%TYPE;
	BEGIN
		INSERT INTO Document_Scan_Ai_Jobs (
			Language_Code, Documenttype, Generate_Searchable_Pdf, Key_Value_Extraction, Table_Extraction, Context_Id, Config_ID
		) VALUES (
			p_Language, p_documentType, p_generateSearchablePdf, p_Key_Values_Extraction, p_Table_Extraction, p_Context, GC_CONFIG_ID
		) RETURNING Job_Id INTO v_Job_ID;

		LOOP 
			FETCH p_files_cv INTO v_files;
			EXIT WHEN p_files_cv%NOTFOUND;
			v_Count := v_Count + 1;
			-- Get file and upload to OCI Object Storage.
			v_document_id := upload_file (
				p_file_name   	=> v_files.FILENAME,
				p_blob_content	=> v_files.BLOB_CONTENT,
				p_mime_type		=> v_files.MIME_TYPE,
				p_custom_id		=> v_files.CUSTOM_ID,
				p_job_id		=> v_Job_ID
			);
			v_doc_locations_json := v_doc_locations_json 
								|| case when v_Count > 1 then ',' end
								|| get_OCI_INPUT_DOC_LOCATION(v_files.filename, v_job_id);
		END LOOP;

		l_request_json := get_OCI_DOC_AI_PAYLOAD(
			p_documentType 			=> p_documentType, 
			p_Language 				=> GC_PROCESSOR_LANGUAGE_CODE, 
			p_Key_Values_Extraction => p_Key_Values_Extraction,
			p_Table_Extraction		=> p_Table_Extraction,
			p_generateSearchablePdf => p_generateSearchablePdf,
			p_objectLocations 		=> v_doc_locations_json
		);
		UPDATE Document_Scan_Ai_Jobs 
		SET Processorjob_Details = l_request_json
		wHERE Job_Id = v_Job_ID;

		RETURN v_Job_ID;
	END Create_Processorjob_Details;
	--------------------------------------------------------------------------------

	FUNCTION Create_Processorjob (
		p_Job_Id	Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN cr_processorJob_data%ROWTYPE
	IS 
		l_request_json			VARCHAR2(32767);
		l_response_json			CLOB;
		vr_processorJob_data	cr_processorJob_data%ROWTYPE;
	BEGIN 
		SELECT Processorjob_Details INTO l_request_json
		FROM Document_Scan_Ai_Jobs 
		WHERE Job_Id = p_Job_Id;
		
		-- Set Content-Type in the Request Header. This is required by the Document AI REST Service.
		apex_web_service.g_request_headers.DELETE;
		apex_web_service.g_request_headers(1).name	:= 'Content-Type';
		apex_web_service.g_request_headers(1).value := 'application/json';

		-- Call the Document AI analyzeDocument REST Web Service.
		l_response_json := apex_web_service.make_rest_request (
			p_url					=> GC_OCI_DOC_AI_URL,
			p_http_method			=> 'POST',
			p_body					=> l_request_json,
			p_credential_static_id	=> GC_WC_CREDENTIAL_ID
		);
		apex_debug.message('Create_Processorjob - CreateProcessorJob - status_code: %s', apex_web_service.g_status_code);
		apex_debug.message('l_request_json: %s', l_request_json, p_max_length=>3600);
		apex_debug.message('l_response_json: %s', l_response_json, p_max_length=>3600);
		handle_rest_response (
			p_function => 'Create_Processorjob',
			p_response => l_response_json,
			p_status_code => 201,
			p_Job_Id => p_Job_Id
		);

		OPEN	cr_processorJob_data (cp_json => l_response_json);
		FETCH cr_processorJob_data INTO vr_processorJob_data;
		CLOSE cr_processorJob_data;
		IF vr_processorJob_data.processorJob_ID IS NULL THEN
			raise_application_error(-20112,'Unable to call OCI Document AI. Job ID not found.');				
		END IF;			
		apex_debug.message('Create_Processorjob - GetProcessorJob - id : %s, language :%s, documentType : %s, lifecycleState : %s, percentComplete : %s', 
			vr_processorJob_data.processorJob_ID, 
			vr_processorJob_data.language_code, 
			vr_processorJob_data.documentType, 
			vr_processorJob_data.lifecycleState, 
			vr_processorJob_data.percentComplete );
			
		UPDATE DOCUMENT_SCAN_AI_JOBS
		SET processorJob_ID = vr_processorJob_data.processorJob_ID
		,	lifecycleState = vr_processorJob_data.lifecycleState
		,	percentComplete = vr_processorJob_data.percentComplete
		WHERE Job_Id = p_Job_Id;
		COMMIT;
		RETURN vr_processorJob_data;

	END Create_Processorjob;
	
	FUNCTION Get_Job_State (
		p_processorJobId IN Document_Scan_Ai_Jobs.processorJob_ID%TYPE,
		p_Job_Id		IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) RETURN cr_processorJob_data%ROWTYPE
	IS 
		l_response_json			CLOB;
		vr_processorJob_data	cr_processorJob_data%ROWTYPE;
	BEGIN 
		apex_debug.message('Get_Job_State URL : %s', GC_OCI_DOC_AI_URL || '/' || p_processorJobId);
		
		l_response_json := apex_web_service.make_rest_request (
			p_url					=> GC_OCI_DOC_AI_URL || '/' || p_processorJobId,
			p_http_method			=> 'GET',
			p_credential_static_id	=> GC_WC_CREDENTIAL_ID
		);
		handle_rest_response (
			p_function => 'Get_Job_State',
			p_response => l_response_json,
			p_status_code => 200,
			p_Job_Id => p_Job_Id
		);
		OPEN	cr_processorJob_data (cp_json => l_response_json);
		FETCH cr_processorJob_data INTO vr_processorJob_data;
		CLOSE cr_processorJob_data;
		IF vr_processorJob_data.processorJob_ID IS NULL THEN
			raise_application_error(-20112,'Unable to call OCI Document AI. processorJob_ID not found.');				
		END IF;
		
		apex_debug.message('get_job_state - id : %s, language :%s, documentType : %s, lifecycleState : %s, percentComplete : %s', 
			vr_processorJob_data.processorJob_ID, 
			vr_processorJob_data.language_code, 
			vr_processorJob_data.documentType, 
			vr_processorJob_data.lifecycleState, 
			vr_processorJob_data.percentComplete );
		UPDATE Document_Scan_Ai_Jobs
		SET lifecycleState = vr_processorJob_data.lifecycleState
		,   lifecycleDetails = vr_processorJob_data.lifecycleDetails
		,	percentComplete = vr_processorJob_data.percentComplete
		,	ProcessorJob_Response = l_response_json
		WHERE Job_Id = p_Job_Id;
		COMMIT;

		RETURN vr_processorJob_data;
	END Get_Job_State;
	--------------------------------------------------------------------------------
	/* splt text line from the json document into fragments with key-value pairs when a separator like - ; | or . is found. */
	FUNCTION Document_Text_Fragments (p_document_id IN NUMBER)
	RETURN tab_text_fragments_type PIPELINED
	IS 
		CURSOR text_cur
		IS 	
		with FULL_LINES as (
			SELECT s.document_id, s.job_id, jt.page_number, 
				jt.text_line, jt.line_no, 
				jt.y3 - jt.y0 line_height,
				jt.x0, jt.y0, jt.x1, jt.y1, jt.x2, jt.y2, jt.x3, jt.y3, 
				J.config_id, J.context_id, J.language_code job_language_code, s.language_code,
				J.documentType job_document_type, S.document_type_code,
				case when REGEXP_LIKE(jt.text_line, '( - |;| \| | \. )+\D+\W+\w+') then 1
					when REGEXP_LIKE(jt.text_line, '( - |;| \| |\. |, )+(\D+:|[A-Z]+ )') then 2
					when REGEXP_LIKE(jt.text_line, '^[A-Z][A-Za-z]* \w+, [A-Z][A-Za-z]* \w+') then 3
					when REGEXP_LIKE(text_line, '^[A-Z][A-Za-z]*: [^ ]*( [A-Z][A-Za-z]*: [^ ]*)*$') then 4
					else 0
				end composite_pattern
			FROM DOCUMENT_SCAN_AI_JOBS j, DOCUMENT_SCAN_AI_DOCS s, 
				JSON_TABLE(s.doc_ai_json, '$.pages[*]' COLUMNS 
					(page_number             NUMBER PATH '$.pageNumber',
					NESTED PATH '$.lines[*]' COLUMNS
						(line_no             FOR ORDINALITY,
						text_line            VARCHAR2(1000) TRUNCATE PATH '$.text',
						x0					 NUMBER PATH '$.boundingPolygon.normalizedVertices[0].x', -- upper left
						y0					 NUMBER PATH '$.boundingPolygon.normalizedVertices[0].y',
						x1					 NUMBER PATH '$.boundingPolygon.normalizedVertices[1].x', -- upper right
						y1					 NUMBER PATH '$.boundingPolygon.normalizedVertices[1].y',
						x2					 NUMBER PATH '$.boundingPolygon.normalizedVertices[2].x', -- lower right
						y2					 NUMBER PATH '$.boundingPolygon.normalizedVertices[2].y',
						x3					 NUMBER PATH '$.boundingPolygon.normalizedVertices[3].x', -- lower left
						y3					 NUMBER PATH '$.boundingPolygon.normalizedVertices[3].y'
				))) jt
			WHERE s.job_id = j.job_id
			AND s.document_id = p_document_id
		)
		select s.job_id, s.document_id, s.page_number, 
			trim(sp.text_line) text_line, 
			s.line_no, sp.element_no, 
			s.line_height, s.x0, s.y0, s.x1, s.y1, s.x2, s.y2, s.x3, s.y3,
			s.config_id, s.context_id, s.job_language_code, s.language_code,
			s.job_document_type, s.document_type_code, s.composite_pattern
		from FULL_LINES s
		cross apply (SELECT /*+ CARDINALITY (C 3) */ COLUMN_VALUE text_line, ROWNUM element_no 
			FROM apex_string.split(s.text_line, '( - |;| \| | \. )') C
		) sp
		where composite_pattern = 1
		union all 
		select s.job_id, s.document_id, s.page_number, 
			trim(sp.text_line) text_line, 
			s.line_no, sp.element_no, 
			s.line_height, s.x0, s.y0, s.x1, s.y1, s.x2, s.y2, s.x3, s.y3,
			s.config_id, s.context_id, s.job_language_code, s.language_code,
			s.job_document_type, s.document_type_code, s.composite_pattern
		from FULL_LINES s
		cross apply (SELECT /*+ CARDINALITY (C 3) */ COLUMN_VALUE text_line, ROWNUM element_no 
			FROM apex_string.split(s.text_line, '( - |;| \| |\. |, )') C
		) sp
		where composite_pattern = 2
		union all 
		select s.job_id, s.document_id, s.page_number, 
			trim(sp.text_line) text_line, 
			s.line_no, sp.element_no, 
			s.line_height, s.x0, s.y0, s.x1, s.y1, s.x2, s.y2, s.x3, s.y3,
			s.config_id, s.context_id, s.job_language_code, s.language_code,
			s.job_document_type, s.document_type_code, s.composite_pattern
		from FULL_LINES s
		cross apply (SELECT /*+ CARDINALITY (C 3) */ COLUMN_VALUE text_line, ROWNUM element_no 
			FROM apex_string.split(s.text_line, ', ') C
		) sp
		where composite_pattern = 3
		union all 
		select s.job_id, s.document_id, s.page_number, 
			REGEXP_SUBSTR(s.text_line, '[A-Z][A-Za-z]*: [^ ]*', 1, LEVEL) AS text_line, 
			s.line_no, LEVEL element_no, 
			s.line_height, s.x0, s.y0, s.x1, s.y1, s.x2, s.y2, s.x3, s.y3,
			s.config_id, s.context_id, s.job_language_code, s.language_code,
			s.job_document_type, s.document_type_code, s.composite_pattern
		from (
			select * from FULL_LINES 
			where composite_pattern = 4
		) s
		connect by REGEXP_SUBSTR(s.text_line, '[A-Z][A-Za-z]*: [^ ]*', 1, LEVEL) IS NOT NULL
		union all 
		select s.job_id, s.document_id, s.page_number, 
			trim(s.text_line) text_line, 
			s.line_no, 1 element_no, 
			s.line_height, s.x0, s.y0, s.x1, s.y1, s.x2, s.y2, s.x3, s.y3,
			s.config_id, s.context_id, s.job_language_code, s.language_code,
			s.job_document_type, s.document_type_code, s.composite_pattern
		from FULL_LINES s
		where composite_pattern = 0;
		v_in_rows tab_text_fragments_type;
	BEGIN 
		OPEN text_cur;
		LOOP
			FETCH text_cur BULK COLLECT INTO v_in_rows LIMIT 200;
			EXIT WHEN v_in_rows.COUNT = 0;
			FOR ind IN 1 .. v_in_rows.COUNT LOOP
				pipe row (v_in_rows(ind));
			END LOOP;
		END LOOP;
		CLOSE text_cur;  
	END Document_Text_Fragments;

	FUNCTION Document_Text_Key_Values (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	RETURN tab_text_key_values_type PIPELINED
	IS 
		CURSOR text_cur
		IS 	
		with TEXT_FRAGMENTS as (
		select 
				d.JOB_ID,
				d.DOCUMENT_ID,
				t.PAGE_NUMBER,
				t.TEXT_LINE,
				t.LINE_NO,
				t.ELEMENT_NO,
				t.LINE_HEIGHT,
				t.X0,
				t.Y0,
				t.X1,
				t.Y1,
				t.X2,
				t.Y2,
				t.X3,
				t.Y3,
				t.CONFIG_ID,
				t.CONTEXT_ID,
				t.JOB_LANGUAGE_CODE,
				t.LANGUAGE_CODE,
				t.JOB_DOCUMENT_TYPE,
				t.DOCUMENT_TYPE_CODE,
				t.COMPOSITE_PATTERN
			from DOCUMENT_SCAN_AI_DOCS d, table(Document_Scan_Ai_Pkg.Document_Text_Fragments(d.DOCUMENT_ID)) t
			where (d.job_id = p_Job_Id or p_Job_Id IS NULL)
			and (d.document_id = p_document_id OR p_document_id IS NULL)
		)
		, LABEL_LINES as (
			select s.document_id, s.job_id, s.page_number, 
				s.text_line, 
				s.line_no, s.element_no,
				s.line_height, s.x0, s.y0, s.x1, s.y1, 
				s.config_id, s.context_id, s.job_language_code, s.language_code,
				s.job_document_type, s.document_type_code,
				s.composite_pattern,
				INSTR(s.text_line, ':', length(fa.field_alias)+1) colon_offset,
				ltrim(substr(s.text_line, length(fa.field_alias)+1), ': ') data_part,
				fa.field_alias, fa.Field_label, ft.Value_Type
			from TEXT_FRAGMENTS s
			join DOCUMENT_SCAN_AI_FIELD_ALIAS fa 
				on UPPER(s.text_line) LIKE UPPER(fa.field_alias||'%')
				and s.config_id = fa.config_id 
				and fa.language_code IN (s.language_code, s.job_language_code)
				and fa.Document_type in (s.job_document_type, s.document_type_code)
				and (UPPER(s.text_line) = UPPER(fa.field_alias) or substr(s.text_line, length(fa.field_alias)+1, 1) in (' ', ':'))
			join DOCUMENT_SCAN_AI_FIELD_TYPES ft 
				on ft.Document_type = fa.Document_type
				and ft.config_id = fa.config_id
				and ft.Field_label = fa.Field_label
		) 
		, TEXT_KEY_VALUES as (
			select lb.document_id, lb.job_id, lb.page_number, lb.line_no, lb.element_no
				, lb.item_label, lb.item_value, lb.x0, lb.y0
				, lb.Field_label
				, round(lb.label_height, 4) label_height
				, round(lb.value_height, 4) value_height
				, round(value_height / label_height, 4) height_ratio
				, lb.Value_Type
				, case 
					when lb.Value_Type = 'DATE' and Document_Scan_Ai_Pkg.Validate_Date_Conversion(lb.item_value, L.common_date_format, L.nls_date_language) = 1 
					then 'DATE'
					when lb.Value_Type = 'NUMBER' and Document_Scan_Ai_Pkg.Validate_Number_Conversion(lb.item_value, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 
					then 'NUMBER' 
					else Document_Scan_Ai_Pkg.Get_String_Type (lb.Value_Type, lb.item_value)
				end Item_Value_Type
				, case when Document_Scan_Ai_Pkg.Validate_Date_Conversion(lb.item_value, L.common_date_format, L.nls_date_language) = 0
					and Document_Scan_Ai_Pkg.Validate_Number_Conversion(lb.item_value, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 
					then Document_Scan_Ai_Pkg.FM9_TO_Number(lb.item_value, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory, p_Default_On_Error=>0)
				end Number_value
				, case when Document_Scan_Ai_Pkg.Validate_Date_Conversion(lb.item_value, L.common_date_format, L.nls_date_language) = 1 
					then Document_Scan_Ai_Pkg.To_Date_Conversion(lb.item_value, L.common_date_format, L.nls_date_language)
				end Date_Value 
				, case when l.iso_code = lb.language_code then 1 else 2 end language_rank
				, l.territory
				, lb.category
			from (
				-- find composite lines with label : value  
				select lb.document_id, lb.job_id, lb.page_number, lb.line_no
					, lb.field_alias item_label, lb.Field_label, lb.Value_Type
					, lb.data_part item_value
					, lb.x0, lb.y0, lb.element_no, lb.job_document_type, lb.document_type_code
					, lb.config_id, lb.context_id, lb.language_code, lb.job_language_code, 1 category
					, lb.line_height label_height, lb.line_height value_height
				from LABEL_LINES lb
				where (colon_offset != 0 or Document_Scan_Ai_Pkg.Get_String_Type (lb.Value_Type, lb.text_line) != 'INITCAP')
				and lb.data_part IS NOT NULL
				union all
				-- find labels (optional ending with :) followed by a value on the next line below
				select lb.document_id, lb.job_id, lb.page_number, lv.line_no
					, lb.field_alias item_label, lb.Field_label, lb.Value_Type
					, lv.text_line item_value
					, lv.x0, lv.y0, 1 element_no, lb.job_document_type, lb.document_type_code
					, lb.config_id, lb.context_id, lb.language_code, lb.job_language_code, 3 category
					, lb.line_height label_height, lv.line_height value_height
				from LABEL_LINES lb, TEXT_FRAGMENTS lv
				where lb.document_id = lv.document_id
				and lb.page_number = lv.page_number
				and UPPER(lb.text_line) in (UPPER(lb.field_alias), UPPER(lb.field_alias)||':')
				and INSTR(lv.text_line, ':') !=  LENGTH(lv.text_line) -- does not end with colon :
				and lb.y0 < lv.y0              	-- label above value 
				and (lv.y0 - lb.y0) < lb.line_height * 2.5		-- near by; in the next lines below
				and (abs(lb.x0 - lv.x0) < lb.line_height * 2.5 or abs(lb.x1 - lv.x1) < lb.line_height * 2.5) -- same column, left or right aligned 
				and lv.composite_pattern = 0
				and lb.composite_pattern = 0
				union all
				-- find labels with known alias followed by a value in the same line.
				select  
					lb.document_id, lb.job_id, lb.page_number, lv.line_no
					, lb.field_alias item_label, lb.Field_label, lb.Value_Type
					, lv.text_line item_value
					, lv.x0, lv.y0, 1 element_no, lb.job_document_type, lb.document_type_code
					, lb.config_id, lb.context_id, lb.language_code, lb.job_language_code, 4 category
					, lb.line_height label_height, lv.line_height value_height
				from LABEL_LINES lb, TEXT_FRAGMENTS lv
				where lb.document_id = lv.document_id
				and lb.page_number = lv.page_number
				--and UPPER(lb.text_line) in (UPPER(lb.field_alias), UPPER(lb.field_alias)||':')
				and UPPER(RTRIM(lb.text_line, ': ')) = UPPER(lb.field_alias)
				and INSTR(lv.text_line, ':') !=  LENGTH(lv.text_line) -- does not end with colon :
				and lb.x0 < lv.x0              -- label before value 
				and abs(lb.y0 - lv.y0) < lb.line_height * 0.8 -- same line 
				and lv.composite_pattern = 0
				and lb.composite_pattern = 0
			) lb 
			outer apply (
				select Context_Id, Client_Name, Client_Email, Client_Tax_Id, Client_Phone, Client_Iban, Client_Swift_Bic
				from table(Document_Scan_Ai_Pkg.pipe_context_fields(lb.context_id))
			) cx 
			join DOCUMENT_SCAN_AI_LANGUAGES l 
				on l.iso_code IN (lb.language_code, lb.job_language_code)
				and lb.config_id = l.config_id
			where not exists (
				select 1
				from DOCUMENT_SCAN_AI_FIELD_ALIAS fx
				where UPPER(RTRIM(lb.item_value, ': ')) = UPPER(fx.field_alias)
				-- UPPER(lb.item_value) in (UPPER(fx.field_alias), UPPER(fx.field_alias||':'))
				and lb.config_id = fx.config_id 
				and fx.language_code IN (lb.language_code, lb.job_language_code)
				and fx.Document_type in (lb.job_document_type, lb.document_type_code)
			)
			and not (lb.Field_label = 'VendorName' and NVL(UPPER(cx.Client_Name), '+') = UPPER(lb.item_value))
			and not (lb.Field_label = 'VendorEmail' and NVL(UPPER(cx.Client_Email), '+') = UPPER(lb.item_value))
			and not (lb.Field_label = 'VendorPhone' and NVL(REPLACE(cx.Client_Phone, ' '), '+') = REPLACE(lb.item_value, ' '))
			and not (lb.Field_label = 'VendorTaxId' and NVL(REPLACE(cx.Client_Tax_Id, ' '), '+') = REPLACE(lb.item_value, ' '))
			and not (lb.Field_label = 'BankIBAN' and NVL(REPLACE(cx.Client_IBAN, ' '), '+') = REPLACE(lb.item_value, ' '))
		)
		select distinct kv.* 
			, case when (Value_Type = Item_Value_Type or Value_Type = 'STRING')
				then 1 else 0 
			end as Valid_Conversion
			, DENSE_RANK() OVER (PARTITION BY Document_Id, Field_label
				ORDER BY case when (Value_Type = Item_Value_Type or Value_Type = 'STRING') 
						then 0 else 1 end
					, case when page_number <= 4 then 0 else 1 end
					, LENGTH(ITEM_LABEL) DESC, ITEM_LABEL
					, ABS(NUMBER_VALUE) desc nulls last, DATE_VALUE desc nulls last
					, category
					, case 
						when category = 3 then y0  -- first element below label
						when  category = 4 and Value_Type = 'NUMBER' then 1-x0 -- last element in the line
						else x0 end -- next element in the line
					, height_ratio desc
					, page_number -- first occourence
					, line_no
					, element_no
					, language_rank, territory
			) RANK
		from TEXT_KEY_VALUES kv;

		v_in_rows tab_text_key_values_type;
	BEGIN 
		OPEN text_cur;
		LOOP
			FETCH text_cur BULK COLLECT INTO v_in_rows LIMIT 200;
			EXIT WHEN v_in_rows.COUNT = 0;
			FOR ind IN 1 .. v_in_rows.COUNT LOOP
				pipe row (v_in_rows(ind));
			END LOOP;
		END LOOP;
		CLOSE text_cur;  
	END Document_Text_Key_Values;

	FUNCTION Document_New_Key_Values (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	RETURN tab_new_key_values_type PIPELINED
	IS 
		CURSOR text_cur
		IS 	
		with TEXT_FRAGMENTS as (
			select 
				d.JOB_ID,
				d.DOCUMENT_ID,
				t.PAGE_NUMBER,
				t.TEXT_LINE,
				t.LINE_NO,
				t.ELEMENT_NO,
				t.LINE_HEIGHT,
				t.X0,
				t.Y0,
				t.X1,
				t.Y1,
				t.X2,
				t.Y2,
				t.X3,
				t.Y3,
				t.CONFIG_ID,
				t.CONTEXT_ID,
				t.JOB_LANGUAGE_CODE,
				t.LANGUAGE_CODE,
				t.JOB_DOCUMENT_TYPE,
				t.DOCUMENT_TYPE_CODE,
				t.COMPOSITE_PATTERN
			from DOCUMENT_SCAN_AI_DOCS d, table(Document_Scan_Ai_Pkg.Document_Text_Fragments(d.DOCUMENT_ID)) t
			where (d.job_id = p_Job_Id or p_Job_Id IS NULL)
			and (d.document_id = p_document_id OR p_document_id IS NULL)
		)
		select distinct field_text
			, FIRST_VALUE(field_alias) OVER (PARTITION BY field_text ORDER BY LENGTH(field_alias) DESC, field_alias DESC) field_alias
			, field_type
			, language_code
			, document_type
			, match_pattern
			, Document_Scan_Ai_Pkg.Get_String_Type ('STRING', field_text) label_type
			, job_id 
			, FIRST_VALUE(document_id) OVER (PARTITION BY field_text ORDER BY document_id) document_id
		from (
			select trim(substr(s.text_line,1,instr(s.text_line,':')-1)) field_text
				, fa.field_alias
				, fa.field_label field_type
				, NVL(NULLIF(s.language_code, 'OTHERS'), s.job_language_code) language_code
				, NVL(NULLIF(s.job_document_type, 'OTHERS'), s.document_type_code) document_type
				, document_id, job_id, 'colon' match_pattern
			from TEXT_FRAGMENTS s
			left outer join DOCUMENT_SCAN_AI_FIELD_ALIAS fa 
				on UPPER(s.text_line) LIKE UPPER(fa.field_alias||'%')
				and s.config_id = fa.config_id 
				and fa.language_code IN (s.language_code, s.job_language_code)
				and fa.Document_type in (s.job_document_type, s.document_type_code)
				and (UPPER(s.text_line) = UPPER(fa.field_alias) or substr(s.text_line, length(fa.field_alias)+1, 1) in (' ', ':'))
			where instr(s.text_line,':') > 1 	-- line contains a colon
			and length(s.text_line ) between 2 and 40
			and REGEXP_LIKE(s.text_line, '^\D+') -- line begins with a word
			union 
			select  
				lb.text_line field_text
				, fa.field_alias
				, fa.field_label field_type
				, COALESCE(NULLIF(lb.language_code, 'OTHERS'), lb.job_language_code) language_code
				, COALESCE(NULLIF(lb.job_document_type, 'OTHERS'), lb.document_type_code) Document_type
				, document_id, job_id, 'pos' match_pattern
			from TEXT_FRAGMENTS lb
			left outer join DOCUMENT_SCAN_AI_FIELD_ALIAS fa 
				on lb.text_line = fa.field_alias
				and lb.config_id = fa.config_id 
				and fa.language_code IN (lb.language_code, lb.job_language_code)
				and fa.Document_type in (lb.job_document_type, lb.document_type_code)
			where Document_Scan_Ai_Pkg.Get_String_Type ('STRING', lb.text_line) in ('INITCAP', 'UPPER', 'STRING')
			and lb.composite_pattern = 0
			and instr(lb.text_line,':') = 0 	-- line contains no colon
			and length(lb.text_line ) between 2 and 40
			and exists( 
				select 1 
				from TEXT_FRAGMENTS lv
				JOIN DOCUMENT_SCAN_AI_LANGUAGES l 
					ON l.iso_code IN (lv.language_code, lv.job_language_code)
					AND l.config_id = lv.config_id
				where lb.document_id = lv.document_id
				and lb.page_number = lv.page_number
				and lb.job_id = lv.job_id
				and lv.composite_pattern = 0
				and (Document_Scan_Ai_Pkg.Validate_Date_Conversion(lv.text_line, L.common_date_format, L.nls_date_language) = 1 
				 or Document_Scan_Ai_Pkg.Validate_Number_Conversion(lv.text_line, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1
				)
				--and Document_Scan_Ai_Pkg.Get_String_Type ('STRING', lv.text_line) IN ('ALPHANUM', 'NUMERIC')
				and ((
					-- find labels (optional ending with :) followed by a value on the next line below
					lb.y0 < lv.y0              	-- label above value 
					and (lv.y0 - lb.y0) < lb.line_height * 2.5		-- near by; in the next lines below
					and (abs(lb.x0 - lv.x0) < lb.line_height * 2.5 or abs(lb.x1 - lv.x1) < lb.line_height * 2.5) -- same column, left or right aligned 
				  ) or ( 
					-- find labels with known alias followed by a value in the same line.
					lb.x0 < lv.x0              -- label before value 
					and abs(lb.y0 - lv.y0) < lb.line_height * 0.8 -- same line 
					and lb.line_height <= lv.line_height
				  )
				)
			)
		)
		order by 1;
		
		v_in_rows tab_new_key_values_type;
	BEGIN 
		OPEN text_cur;
		LOOP
			FETCH text_cur BULK COLLECT INTO v_in_rows LIMIT 200;
			EXIT WHEN v_in_rows.COUNT = 0;
			FOR ind IN 1 .. v_in_rows.COUNT LOOP
				pipe row (v_in_rows(ind));
			END LOOP;
		END LOOP;
		CLOSE text_cur;  
	END Document_New_Key_Values;


	PROCEDURE Load_Document_Field_Alias (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	IS 
	BEGIN 
		-- Extract Key-Values from text lines with matching labels from DOCUMENT_SCAN_AI_FIELD_ALIAS
        MERGE INTO DOCUMENT_SCAN_AI_FIELDS D
        USING (
			SELECT document_id, 
					'KEY_VALUE' as field_type_code, 
					field_label as field_label, 
					0.99 as label_score, 
					COALESCE(to_char(number_value,'TM9','NLS_NUMERIC_CHARACTERS = ''.,'''), 
							to_char(cast(date_value AS TIMESTAMP), 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"'), 
							item_value) field_value, 
					page_number as page_number, 
					line_no as line_number, 
					item_value_type as value_type, 
					cast(item_value as varchar2(1000)) as field_text,
					item_label as field_alias,
					valid_conversion user_confirmed
			FROM TABLE(Document_Scan_Ai_Pkg.Document_Text_Key_Values(p_Job_Id => p_Job_Id, p_document_id => p_document_id))
			WHERE rank = 1
        ) S
        ON (D.DOCUMENT_ID = S.DOCUMENT_ID AND D.PAGE_NUMBER = S.PAGE_NUMBER AND D.FIELD_TYPE_CODE = S.FIELD_TYPE_CODE 
        	AND D.FIELD_LABEL = S.FIELD_LABEL AND D.FIELD_TEXT = S.FIELD_TEXT)
        WHEN MATCHED THEN
            UPDATE SET D.FIELD_VALUE = case when S.user_confirmed = 1 then S.FIELD_VALUE else D.FIELD_VALUE end, 
                D.VALUE_TYPE = S.VALUE_TYPE, D.LABEL_SCORE = S.LABEL_SCORE,
                D.FIELD_ALIAS = S.FIELD_ALIAS, D.USER_CONFIRMED = S.USER_CONFIRMED
        WHEN NOT MATCHED THEN
            INSERT (D.DOCUMENT_ID, D.FIELD_TYPE_CODE, D.FIELD_LABEL, D.LABEL_SCORE, 
                D.FIELD_VALUE, D.PAGE_NUMBER, D.LINE_NUMBER, 
                D.VALUE_TYPE, D.FIELD_TEXT, D.FIELD_ALIAS, D.USER_CONFIRMED)
            VALUES (S.DOCUMENT_ID, S.FIELD_TYPE_CODE, S.FIELD_LABEL, S.LABEL_SCORE, 
                S.FIELD_VALUE, S.PAGE_NUMBER, S.LINE_NUMBER, 
                S.VALUE_TYPE, S.FIELD_TEXT, S.FIELD_ALIAS, S.USER_CONFIRMED)
        ;
	END Load_Document_Field_Alias;

	PROCEDURE Load_Document_Fields (
		p_Job_Id 		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	IS 
	BEGIN 
		INSERT INTO DOCUMENT_SCAN_AI_FIELDS (document_id,page_number,field_type_code,field_label,label_score,field_value,value_type,field_text)
		SELECT s.document_id, jt.page_number, jt.field_type_code, jt.field_label, jt.label_score, jt.field_value, jt.value_type, jt.field_text
		FROM   DOCUMENT_SCAN_AI_DOCS s, 
				JSON_TABLE(s.doc_ai_json, '$.pages[*]'
					COLUMNS (page_number		   NUMBER			PATH '$.pageNumber',
						NESTED PATH '$.documentFields[*]' COLUMNS
							(field_type_code VARCHAR2(50)			PATH '$.fieldType',
							field_label			VARCHAR2(100)	PATH '$.fieldLabel.name',
							label_score			NUMBER			PATH '$.fieldLabel.confidence',
							field_value			VARCHAR2(1000)	PATH '$.fieldValue.value',
							value_type			VARCHAR2(80)	PATH '$.fieldValue.valueType',
							field_text			VARCHAR2(80)	PATH '$.fieldValue.text'
				))) jt
		WHERE jt.field_type_code = 'KEY_VALUE'
		AND (s.job_id = p_Job_Id or p_Job_Id IS NULL)
		AND (s.document_id = p_document_id OR p_document_id IS NULL);

		INSERT INTO DOCUMENT_SCAN_AI_FIELDS (document_id,page_number,line_number,field_type_code,field_label,label_score,field_value, 
							value_type,field_text,column_number)
		SELECT s.document_id, jt.page_number, jt.line_number, jt.field_type_code2, jt.field_label, jt.label_score, jt.field_value, 
				jt.value_type, jt.field_text, jt.column_number
		FROM   DOCUMENT_SCAN_AI_DOCS s, 
				JSON_TABLE(s.doc_ai_json, '$.pages[*]'
					COLUMNS (page_number		   NUMBER			PATH '$.pageNumber',
						NESTED PATH '$.documentFields[*]' COLUMNS
							(field_type_code1 VARCHAR2(50)		PATH '$.fieldType',
							NESTED PATH '$.fieldValue.items[*]' COLUMNS
							(field_type_code2 VARCHAR2(50)		PATH '$.fieldType',
							line_number							FOR ORDINALITY,
							NESTED PATH '$.fieldValue.items[*]' COLUMNS
							(field_type_code3 VARCHAR2(50)		PATH '$.fieldType',
							field_label			VARCHAR2(100)	PATH '$.fieldLabel.name',
							label_score			NUMBER			PATH '$.fieldLabel.confidence',
							field_value			VARCHAR2(1000)	PATH '$.fieldValue.value',
							value_type			VARCHAR2(80)	PATH '$.fieldValue.valueType',
							field_text			VARCHAR2(80)	PATH '$.fieldValue.text',
							column_number						FOR ORDINALITY
				))))) jt
		WHERE	 jt.field_type_code1 = 'LINE_ITEM_GROUP'
		AND jt.field_type_code2 = 'LINE_ITEM'
		AND jt.field_type_code3 = 'LINE_ITEM_FIELD'
		AND (s.job_id = p_Job_Id or p_Job_Id IS NULL)
		AND (s.document_id = p_document_id OR p_document_id IS NULL);

		Load_Document_Field_Alias(p_Job_Id => p_Job_Id, p_document_id => p_document_id);
		
		INSERT INTO DOCUMENT_SCAN_AI_TABLES (document_id,page_number,table_number,rowCount,columnCount,column_names)
		SELECT s.document_id, jt.page_number, jt.table_number, jt.rowCount, jt.columnCount, 
			LISTAGG(jt.text, ';') WITHIN GROUP (ORDER BY jt.columnIndex) column_names
		FROM DOCUMENT_SCAN_AI_DOCS s, 
			JSON_TABLE(s.doc_ai_json, '$.pages[*]'
			COLUMNS (page_number		   NUMBER		PATH '$.pageNumber',
				NESTED PATH '$.tables[*]' COLUMNS
					(table_number						FOR ORDINALITY,
					rowCount			NUMBER			PATH '$.rowCount',
					columnCount			NUMBER			PATH '$.columnCount',
				NESTED PATH '$.headerRows.cells[*]' COLUMNS
					(text				VARCHAR2(100) TRUNCATE PATH '$.text',
					columnIndex			NUMBER			PATH '$.columnIndex'
			)))) jt
		where table_number is not null
		AND rowcount is not null
		AND (s.job_id = p_Job_Id or p_Job_Id IS NULL)
		AND (s.document_id = p_document_id OR p_document_id IS NULL)
		group by s.document_id, jt.page_number, jt.table_number, jt.rowCount, jt.columnCount;

	END Load_Document_Fields;
	
	PROCEDURE Rebuild_Fields (
		p_Job_Id IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL
	)
	IS 
	BEGIN 
		if p_Job_Id IS NOT NULL then 
			DELETE FROM DOCUMENT_SCAN_AI_FIELDS df
			WHERE EXISTS (
				SELECT 1 FROM DOCUMENT_SCAN_AI_DOCS d 
				WHERE d.job_id = p_Job_Id
				AND d.document_id = df.document_id
			);
			DELETE FROM DOCUMENT_SCAN_AI_TABLES dt
			WHERE EXISTS (
				SELECT 1 FROM DOCUMENT_SCAN_AI_DOCS d 
				WHERE d.job_id = p_Job_Id
				AND d.document_id = dt.document_id
			);
		else 
			DELETE FROM DOCUMENT_SCAN_AI_FIELDS df;
			DELETE FROM DOCUMENT_SCAN_AI_TABLES dt;
		end if;
		Load_Document_Fields(p_Job_Id => p_Job_Id);
		COMMIT;
	END rebuild_fields;
	--------------------------------------------------------------------------------
	
	PROCEDURE Get_Processor_Result (
		p_processorJobId IN Document_Scan_Ai_Jobs.processorJob_ID%TYPE,
		p_file_name		IN VARCHAR2,
		p_document_id 	IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE,
		p_Job_Id		IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE
	) IS
		CURSOR cr_document_data (cp_json IN CLOB) IS
			SELECT jt.*
			FROM	 JSON_TABLE(cp_json, '$'
			 COLUMNS (document_type_code		VARCHAR2(50)	PATH '$.detectedDocumentTypes[0].documentType',
					document_type_score			NUMBER			PATH '$.detectedDocumentTypes[0].confidence',
					language_code				VARCHAR2(50)	PATH '$.detectedLanguages[0].language',
					language_score				NUMBER			PATH '$.detectedLanguages[0].confidence',
					page_count					NUMBER			PATH '$.documentMetadata.pageCount',
					error_message				VARCHAR2(500)	PATH '$.errors[0].message' 
					)) jt;

		l_response_json			CLOB;
		lr_document_data		cr_document_data%ROWTYPE;
		l_object_name			VARCHAR2(4000);
		l_result_url			VARCHAR2(4000);
		l_searchable_pdf		VARCHAR2(4000);
		l_searchable_pdf_url	VARCHAR2(4000);
		l_generateSearchablePdf	VARCHAR2(10);
	BEGIN
		l_object_name := get_OCI_OUTPUT_JSON_LOCATION (
		   p_processorJobId, p_file_name, p_Job_Id
		);
		l_result_url := get_OCI_OBJ_STORE_OUTPUT_URL || l_object_name;
		select J.Generate_Searchable_Pdf
		into l_generateSearchablePdf
		from Document_Scan_Ai_Jobs J
		join DOCUMENT_SCAN_AI_DOCS D on D.job_id = J.job_id
		where D.document_id = p_document_id;
		
		if l_generateSearchablePdf = 'Y' then 
			l_searchable_pdf := get_OCI_OUTPUT_PDF_LOCATION (
			   p_processorJobId, p_file_name, p_Job_Id
			);
			l_searchable_pdf_url := get_OCI_OBJ_STORE_OUTPUT_URL || l_searchable_pdf;
		end if;
		apex_debug.message('get_processor_result - url: %s', l_result_url);

		-- Get the Document AI analyze result from the object store
		l_response_json := apex_web_service.make_rest_request (
			p_url				   => l_result_url,
			p_http_method		   => 'GET',
			p_credential_static_id => GC_WC_CREDENTIAL_ID
		);

		apex_debug.message('get_processor_result - document_id: %s, status_code: %s', p_document_id, apex_web_service.g_status_code);
		apex_debug.message('get_processor_result - response_json:');
		apex_debug.log_long_message(p_message => TO_CHAR(SUBSTR(l_response_json, 1, 2000)), p_level => apex_debug.c_log_level_info);
		handle_rest_response (
			p_function => 'Get_Processor_Result',
			p_response => l_response_json,
			p_status_code => 200,
			p_Job_Id => p_Job_Id
		);
		-- Get Document Level Data from the JSON response.
		OPEN	cr_document_data (cp_json => l_response_json);
		FETCH cr_document_data INTO lr_document_data;
		CLOSE cr_document_data;

		-- Update Document Table with Results.
		UPDATE DOCUMENT_SCAN_AI_DOCS
		SET		 doc_ai_json		 = l_response_json
		,		 language_code		 = lr_document_data.language_code
		,		 language_score		 = lr_document_data.language_score
		,		 document_type_code	 = lr_document_data.document_type_code
		,		 document_type_score = lr_document_data.document_type_score
		,		 page_count			 = lr_document_data.page_count
		,		 searchable_pdf_url  = l_searchable_pdf_url
		,		 ProcessorJob_Message= lr_document_data.error_message
		,		 index_format 		 = case when l_searchable_pdf_url is not null 
										or mime_type = 'application/pdf' then 'BINARY' else 'IGNORE' end
		WHERE	 document_id		 = p_document_id;
		if lr_document_data.error_message IS NULL then 
			Load_Document_Fields(p_document_id => p_document_id);
		end if;
		COMMIT;
		if lr_document_data.error_message IS NOT NULL then 
			apex_debug.message('get_processor_result - error_message : %s', lr_document_data.error_message);
		end if;
	END Get_Processor_Result;

	--------------------------------------------------------------------------------
	PROCEDURE await_job_completion (
		p_processorJobId IN Document_Scan_Ai_Jobs.processorJob_ID%TYPE,
		p_Job_Id		IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	) IS 
		vr_processorJob_data	cr_processorJob_data%ROWTYPE;
	BEGIN
		loop 
			vr_processorJob_data := Get_Job_State (
				p_processorJobId => p_processorJobId, 
				p_Job_Id 		=> p_Job_Id
			);
			exit when vr_processorJob_data.lifecycleState IN ('SUCCEEDED', 'FAILED', 'CANCELED', 'CANCELING');
			-- APEX_UTIL.PAUSE(2); -- pause is a no-op on cloud
			SYS.DBMS_LOCK.SLEEP (GC_Jobs_Sleep_Seconds);			
		end loop;		
		IF vr_processorJob_data.lifecycleState = 'FAILED'
		and vr_processorJob_data.lifecycleDetails = 'COMPLETELY_FAILED' THEN
			raise_application_error(-20112,'Unable to call OCI Document AI. Job State is ' || vr_processorJob_data.lifecycleState);				
		END IF;
	END await_job_completion;
	--------------------------------------------------------------------------------
	PROCEDURE Run_Processorjob (
		p_Job_Id	IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	)
	IS 
		vr_processorJob_data	cr_processorJob_data%ROWTYPE;
	BEGIN 
		vr_processorJob_data := Create_Processorjob (
			p_Job_Id => p_Job_Id
		);
		await_job_completion (
			p_processorJobId => vr_processorJob_data.processorJob_ID, 
			p_Job_Id 		=> p_Job_Id
		);
		for cv in (
			select document_id, file_name 
			from DOCUMENT_SCAN_AI_DOCS 
			where Job_Id = p_Job_Id
		) loop
			get_processor_result (
				p_processorJobId => vr_processorJob_data.processorJob_ID,
				p_file_name		=> cv.file_name,
				p_document_id	=> cv.document_id,
				p_Job_Id		=> p_Job_Id
			);
		end loop;
		Link_Document_Addresses (
			p_Job_Id => p_Job_Id
		);
		if GC_DELETE_PROCESSOR_OUTPUT = 'Y' then 
			Cleanup_Processorjob(p_Job_Id => p_Job_Id);
		end if;
		update DOCUMENT_SCAN_AI_JOBS
		set Is_Completed = 'Y'
		where Job_Id = p_Job_Id;
		COMMIT;
	exception when others then
		update DOCUMENT_SCAN_AI_JOBS
		set Is_Completed = 'Y'
		,	lifecycleState = 'FAILED'
		,	ProcessorJob_Message = NVL(ProcessorJob_Message, DBMS_UTILITY.FORMAT_ERROR_STACK)
		where Job_Id = p_Job_Id;
		COMMIT;
		if GC_EXECUTE_ASYNCHRONOUS = 'N' then 
			raise;
		end if;
	
	END Run_Processorjob;

	PROCEDURE Cleanup_Processorjob (
		p_Job_Id	IN Document_Scan_Ai_Jobs.Job_Id%TYPE
	)
	IS 
		l_old_object_name		VARCHAR2(4000);
		l_new_object_name		VARCHAR2(4000);
		l_object_name			VARCHAR2(4000);
		l_processorJobId		VARCHAR2(4000);
		l_file_name				VARCHAR2(4000);
		l_searchable_pdf_url    VARCHAR2(4000);
		l_obj_store_base_url	VARCHAR2(4000);
	BEGIN 
		l_obj_store_base_url := get_OCI_OBJ_STORE_BASE_URL;
		for cv in (
			select D.document_id, D.file_name, D.searchable_pdf_url, D.object_store_url, J.processorJob_ID 
			from Document_Scan_Ai_Jobs J
			join DOCUMENT_SCAN_AI_DOCS D on D.job_id = J.job_id
			where D.Job_Id = p_Job_Id
			and J.Is_Cleaned_up = 'N'
		) loop
			-- Move searchable pdf 
			l_processorJobId := cv.processorJob_ID;
			if cv.searchable_pdf_url NOT LIKE get_OCI_OBJ_STORE_PDF_URL||'%' then 
				l_old_object_name := GC_OUTPUT_LOCATION_PREFIX || '/' || get_OCI_OUTPUT_PDF_LOCATION (
				   cv.processorJob_ID, cv.file_name, p_Job_Id
				);
				l_file_name := base_file_name(cv.file_name);
				l_new_object_name := apex_string.format('%s/job%s/%s.pdf', 
					GC_PDF_LOCATION_PREFIX, 
					to_char(p_Job_Id, GC_JOB_ID_FORMAT), 
					Encode_Object_Name(l_file_name)
				);
				l_searchable_pdf_url := apex_string.format('%sjob%s/%s.pdf', 
					get_OCI_OBJ_STORE_PDF_URL, 
					to_char(p_Job_Id, GC_JOB_ID_FORMAT), 
					Encode_Object_Name(l_file_name)
				);
				apex_debug.message('-------------------------------');
				apex_debug.message('old: ' || l_old_object_name);
				apex_debug.message('new: ' || l_new_object_name);
				apex_debug.message('pdf: ' || l_searchable_pdf_url);
				Rename_File(
					p_old_object_name => l_old_object_name,
					p_new_object_name => l_new_object_name,
					p_job_id => p_Job_Id
				);
				update DOCUMENT_SCAN_AI_DOCS
				set searchable_pdf_url = l_searchable_pdf_url
				where document_id = cv.document_id;
			end if;
			-- delete input file
			if GC_KEEP_ORIGINAL_FILES = 'N'
			and cv.object_store_url LIKE l_obj_store_base_url||'%'
			and cv.searchable_pdf_url IS NOT NULL then 
				l_object_name := SUBSTR(cv.object_store_url, LENGTH(l_obj_store_base_url)+1);
				Delete_File (
					p_object_name => l_object_name,
					p_job_id => p_Job_Id
				);
				update DOCUMENT_SCAN_AI_DOCS
				set object_store_url = null
				where document_id = cv.document_id;
			end if;
			-- delete output json file
			l_object_name := GC_OUTPUT_LOCATION_PREFIX || '/' || get_OCI_OUTPUT_JSON_LOCATION (
			   cv.processorJob_ID, cv.file_name, p_Job_Id
			);
			Delete_File (
				p_object_name => l_object_name,
				p_job_id => p_Job_Id
			);
		end loop;
		-- delete output folder
		if l_processorJobId IS NOT NULL then 
			l_object_name := apex_string.format('%s/%s/', 
				GC_OUTPUT_LOCATION_PREFIX,
				l_processorJobId
			);
			Delete_File (
				p_object_name => l_object_name,
				p_job_id => p_Job_Id
			);
		end if;
		update DOCUMENT_SCAN_AI_JOBS
		set Is_Cleaned_up = 'Y'
		where Job_Id = p_Job_Id;
	END Cleanup_Processorjob;
	--------------------------------------------------------------------------------
	PROCEDURE Delete_Doc_Searchable_Pdf (
		p_searchable_pdf_url	IN DOCUMENT_SCAN_AI_DOCS.searchable_pdf_url%TYPE,
		p_object_store_url 		IN DOCUMENT_SCAN_AI_DOCS.object_store_url%TYPE
	)
	IS 
		l_object_name			VARCHAR2(4000);
		l_obj_store_base_url			VARCHAR2(4000);
	BEGIN 
		l_obj_store_base_url := get_OCI_OBJ_STORE_BASE_URL;
		if p_searchable_pdf_url LIKE l_obj_store_base_url||'%' then 
			l_object_name := SUBSTR(p_searchable_pdf_url, LENGTH(l_obj_store_base_url)+1);
			Delete_File (p_object_name => l_object_name);
		end if;
		if p_object_store_url LIKE l_obj_store_base_url||'%' then 
			l_object_name := SUBSTR(p_object_store_url, LENGTH(l_obj_store_base_url)+1);
			apex_debug.message('del: ' || l_object_name);
			Delete_File (p_object_name => l_object_name);
		end if;
	END Delete_Doc_Searchable_Pdf;
	--------------------------------------------------------------------------------
	
	-- Main API function to process uploaded files from APEX_APPLICATION_TEMP_FILES or p_file_blob --
	FUNCTION Process_Files_Cursor (
		p_documentType			IN VARCHAR2 DEFAULT GC_PROCESSOR_DOCUMENT_TYPE, 
		p_Language				IN VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
		p_Key_Values_Extraction IN VARCHAR2 DEFAULT GC_KEY_VALUES_EXTRACTION,
		p_Table_Extraction		IN VARCHAR2 DEFAULT GC_TABLE_EXTRACTION,
		p_generateSearchablePdf IN VARCHAR2 DEFAULT GC_GENERATE_SEARCHABLE_PDF,
		p_exec_asynchronous 	IN VARCHAR2 DEFAULT GC_EXECUTE_ASYNCHRONOUS,
		p_files_cv				IN files_ref_cursor,
		p_Context 				IN NUMBER DEFAULT NULL
	) RETURN Document_Scan_Ai_Jobs.Job_Id%TYPE
	IS 
		v_Job_ID		DOCUMENT_SCAN_AI_JOBS.Job_Id%TYPE;
		v_sql			VARCHAR2(1000);
	BEGIN 
		v_Job_ID := Create_Processorjob_Details (
			p_documentType			=> p_documentType,
			p_Language				=> p_Language,
			p_Key_Values_Extraction => p_Key_Values_Extraction,
			p_Table_Extraction		=> p_Table_Extraction,
			p_generateSearchablePdf => p_generateSearchablePdf,
			p_files_cv				=> p_files_cv,
			p_Context				=> p_Context
		);
		if p_exec_asynchronous = 'Y' then 
			v_sql := apex_string.format(p_message => 
				'begin 
				!   apex_session.attach (%s, %s, %s);
				!   Document_Scan_Ai_Pkg.Run_Processorjob (p_Job_Id => %s);
				!   apex_session.detach;
				!end;', 
				p0 => V('APP_ID'), 
				p1 => V('APP_PAGE_ID'),
				p2 => V('APP_SESSION'),
				p3 => v_Job_ID, 
				p_prefix => '!'
			);
			dbms_scheduler.create_job (
				job_name => GC_Job_Name_Prefix || v_Job_ID,
				start_date => SYSDATE,
				job_type => 'PLSQL_BLOCK',
				job_action => v_sql,
				enabled => true 
			);
		else 
			Run_Processorjob (p_Job_Id => v_Job_ID);
		end if;

		RETURN v_Job_ID;
	END Process_Files_Cursor;

	FUNCTION Process_Files (
		p_documentType			IN VARCHAR2 DEFAULT GC_PROCESSOR_DOCUMENT_TYPE, 
		p_Language				IN VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
		p_Key_Values_Extraction IN VARCHAR2 DEFAULT GC_KEY_VALUES_EXTRACTION,
		p_Table_Extraction		IN VARCHAR2 DEFAULT GC_TABLE_EXTRACTION,
		p_generateSearchablePdf IN VARCHAR2 DEFAULT GC_GENERATE_SEARCHABLE_PDF,
		p_exec_asynchronous 	IN VARCHAR2 DEFAULT GC_EXECUTE_ASYNCHRONOUS,
		p_Context 				IN NUMBER DEFAULT NULL
	) RETURN Document_Scan_Ai_Jobs.Job_Id%TYPE
	IS 
		l_Job_ID		DOCUMENT_SCAN_AI_JOBS.Job_Id%TYPE;
		cr_files 	files_ref_cursor;
	BEGIN  
		OPEN cr_files FOR
			SELECT FILENAME, MIME_TYPE, 0 CUSTOM_ID, BLOB_CONTENT
			FROM APEX_APPLICATION_TEMP_FILES;
		
		l_Job_ID := Process_Files_Cursor (
			p_documentType			=> p_documentType, 
			p_Language				=> p_Language, 
			p_Key_Values_Extraction => p_Key_Values_Extraction,
			p_Table_Extraction		=> p_Table_Extraction,
			p_generateSearchablePdf => p_generateSearchablePdf,
			p_exec_asynchronous 	=> p_exec_asynchronous,
			p_files_cv				=> cr_files,
			p_Context				=> p_Context
		);
		CLOSE cr_files;
	
		RETURN l_Job_ID;
	END Process_Files;
	
	--------------------------------------------------------------------------------
	FUNCTION get_file (p_request_url IN VARCHAR2) RETURN BLOB IS
		l_file_blob				BLOB;
	BEGIN
$IF DOCUMENT_SCAN_AI_PKG.G_USE_DBMS_CLOUD $THEN
		l_file_blob := DBMS_CLOUD.GET_OBJECT (
			credential_name		=> GC_CLOUD_CREDENTIAL_ID,
			object_uri			=> UTL_URL.ESCAPE(p_request_url)
		);
$ELSE
		-- Call OCI Web Service to get the requested file.
		l_file_blob := apex_web_service.make_rest_request_b (
			p_url					=> UTL_URL.ESCAPE(p_request_url),
			p_http_method			=> 'GET',
			p_credential_static_id	=> GC_WC_CREDENTIAL_ID);

		IF apex_web_service.g_status_code != 200 then
			apex_debug.message('get_file - status_code: %s', apex_web_service.g_status_code);
			raise_application_error(-20112,'Unable to Get File. Status_Code: '||apex_web_service.g_status_code ||', URL: '||UTL_URL.ESCAPE(p_request_url));
		END IF;
$END
		RETURN l_file_blob;
	END get_file;

	FUNCTION base_file_name (p_file_name IN VARCHAR2) RETURN VARCHAR2 IS
		l_file_name VARCHAR2(300);
		l_offset INTEGER;
	BEGIN
		l_file_name := p_file_name;
		l_offset := INSTR(l_file_name,'.',-1);
		if l_offset > 0 and LENGTH(l_file_name) - l_offset between 1 and 3 then 
			l_file_name := SUBSTR(l_file_name, 1, l_offset - 1);
		end if;
		RETURN l_file_name;
	END base_file_name;
	--------------------------------------------------------------------------------
	PROCEDURE Render_Document (
		p_document_id  			IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE
		,p_use_searchable_pdf 	IN VARCHAR2 DEFAULT 'Y'
	) IS

		CURSOR cr_document IS
			SELECT	mime_type
			,		file_name
			,		object_store_url
			,		searchable_pdf_url
			FROM	 DOCUMENT_SCAN_AI_DOCS
			WHERE	 document_id = p_document_id;

		lr_document		cr_document%ROWTYPE;
		l_mime_type 	VARCHAR2(200);
		l_file_name 	VARCHAR2(300);
		l_file_blob		BLOB;
	BEGIN
		
		-- Get the OCI URL and Mimetytpe of the receipt file.
		OPEN	cr_document;
		FETCH cr_document INTO lr_document;
		CLOSE cr_document;

		-- Get the file BLOB from OCI Object Storage.
		if (p_use_searchable_pdf = 'Y' or lr_document.object_store_url IS NULL) 
		and lr_document.searchable_pdf_url is not null then 
			l_mime_type := 'application/pdf';
			l_file_name := base_file_name(lr_document.file_name) || '.pdf';
			l_file_blob := get_file (p_request_url => lr_document.searchable_pdf_url);
		elsif lr_document.object_store_url IS NOT NULL then
			l_mime_type := lr_document.mime_type;
			l_file_name := lr_document.file_name;
			l_file_blob := get_file (p_request_url => lr_document.object_store_url);
		end if;

		-- Output the file so it shows in APEX.
		htp.init();
		owa_util.mime_header(l_mime_type, false);
		htp.p('Content-Length: ' || dbms_lob.getlength(l_file_blob)); 
		htp.p('Content-Disposition:  inline; filename="'||l_file_name||'"');
		owa_util.http_header_close;	 
		wpg_docload.download_file(l_file_blob);

	END Render_Document;
	--------------------------------------------------------------------------------
	PROCEDURE Download_Searchable_Pdf (p_document_id  IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE) IS

		CURSOR cr_document IS
			SELECT	mime_type
			,		file_name
			,		searchable_pdf_url
			FROM	 DOCUMENT_SCAN_AI_DOCS
			WHERE	 document_id = p_document_id;

		lr_document		cr_document%ROWTYPE;
		l_file_name 	VARCHAR2(300);
		l_file_blob		BLOB;
	BEGIN

		-- Get the OCI URL and Mimetytpe of the receipt file.
		OPEN	cr_document;
		FETCH cr_document INTO lr_document;
		CLOSE cr_document;

		-- Get the file BLOB from OCI Object Storage.
		l_file_blob := get_file (p_request_url => lr_document.searchable_pdf_url);
		l_file_name := base_file_name(lr_document.file_name) || '.pdf';
		htp.init();
		owa_util.mime_header('application/pdf',false);
		htp.p('Content-Length: ' || dbms_lob.getlength(l_file_blob)); 
		htp.p('Content-Disposition:  attachment; filename="'|| l_file_name || '"');
		owa_util.http_header_close;	 
		wpg_docload.download_file(l_file_blob);

	END Download_Searchable_Pdf;
	--------------------------------------------------------------------------------
	FUNCTION convert_to_Searchable_Pdf (
		p_file_blob 			IN BLOB,
		p_documentType			IN VARCHAR2 DEFAULT GC_PROCESSOR_DOCUMENT_TYPE, 
		p_Language				IN VARCHAR2 DEFAULT GC_PROCESSOR_LANGUAGE_CODE,
		p_mime_type				IN VARCHAR2 DEFAULT 'application/pdf'
	) RETURN BLOB 
	IS
		l_file_blob		BLOB;
		l_Job_ID		DOCUMENT_SCAN_AI_JOBS.Job_Id%TYPE;

		CURSOR cr_document IS
			SELECT	mime_type
			,		file_name
			,		object_store_url
			,		searchable_pdf_url
			FROM	DOCUMENT_SCAN_AI_DOCS
			WHERE	job_id = l_Job_ID;
		lr_document	cr_document%ROWTYPE;
		cr_files 	Document_Scan_Ai_Pkg.files_ref_cursor;
	BEGIN
		OPEN cr_files FOR
			SELECT 
				'temporary.pdf' FILENAME,
				p_mime_type MIME_TYPE,
				0 CUSTOM_ID,
				p_file_blob BLOB_CONTENT
			FROM DUAL;
		l_Job_ID := Document_Scan_Ai_Pkg.Process_Files_Cursor (
			p_documentType			=> p_documentType, 
			p_Language				=> p_Language, 
			p_Key_Values_Extraction => 'N',
			p_Table_Extraction		=> 'N',
			p_generateSearchablePdf => 'Y',
			p_exec_asynchronous 	=> 'N',
			p_files_cv				=> cr_files
		);
		CLOSE cr_files;
		-- Get the OCI URL and Mimetytpe of the receipt file.
		OPEN	cr_document;
		FETCH cr_document INTO lr_document;
		CLOSE cr_document;
		
		l_file_blob := Document_Scan_Ai_Pkg.get_file (p_request_url => lr_document.searchable_pdf_url);
		Delete_File (
			p_object_name => lr_document.object_store_url,
			p_job_id => l_Job_ID
		);
		Delete_File (
			p_object_name => lr_document.searchable_pdf_url,
			p_job_id => l_Job_ID
		);
		DELETE FROM DOCUMENT_SCAN_AI_JOBS
		WHERE job_id = l_Job_ID;
		COMMIT;
		-- Get the file BLOB from OCI Object Storage.
		RETURN l_file_blob;
	END convert_to_Searchable_Pdf;
	--------------------------------------------------------------------------------
	FUNCTION cursor_to_csv (
		p_cursor_id     INTEGER,
		p_Separator IN VARCHAR2 DEFAULT ';',
		p_Enclosed_By IN VARCHAR2 DEFAULT '"'
	)
	RETURN CLOB
	IS
		l_colval        VARCHAR2 (2096);
		l_buffer        VARCHAR2 (32767) DEFAULT '';
		i_colcount      NUMBER DEFAULT 0;
		i_rowcount      NUMBER DEFAULT 0;
		l_separator     VARCHAR2 (10);
		l_enclosed_by   VARCHAR2 (10);
		l_file          CLOB;
		l_eol           VARCHAR(2) DEFAULT CHR (10);
		l_colsdescr     dbms_sql.desc_tab;
	BEGIN
		l_separator := NVL(p_Separator, ';');
		l_enclosed_by := NVL(p_Enclosed_By, '"');
		dbms_sql.describe_columns(p_cursor_id, i_colcount, l_colsdescr);
		FOR i IN 1 .. i_colcount
		LOOP
			dbms_sql.define_column (p_cursor_id, i, l_colval, 2000);
			l_buffer := l_buffer || case when i > 1 then l_separator end || l_colsdescr(i).col_name;
		END LOOP;
		dbms_lob.createtemporary(l_file, true, dbms_lob.call);
		l_buffer := l_buffer || l_eol;
		dbms_lob.write( l_file, LENGTH(l_buffer), 1, l_buffer);
		LOOP
			EXIT WHEN dbms_sql.fetch_rows (p_cursor_id) <= 0;
			i_rowcount := i_rowcount + 1;
			l_buffer := '';
			FOR i IN 1 .. i_colcount
			LOOP
				dbms_sql.column_value (p_cursor_id, i, l_colval);
				IF (INSTR(l_colval, l_separator) > 0 or INSTR(l_colval, l_eol) > 0)
				THEN
					l_colval := l_enclosed_by || REPLACE(l_colval, l_enclosed_by, l_enclosed_by||l_enclosed_by) || l_enclosed_by;
				END IF;
				l_buffer := l_buffer || case when i > 1 then l_separator end || l_colval;
			END LOOP;
			l_buffer := l_buffer || l_eol;
			dbms_lob.writeappend( l_file, LENGTH(l_buffer), l_buffer);
		END LOOP;
		if i_rowcount = 0 then 
			RETURN NULL;
		end if;
		RETURN l_file;
	END cursor_to_csv;

	FUNCTION Report_to_CSV (
		p_report IN  apex_ir.t_report,
		p_Separator IN VARCHAR2 DEFAULT ';',
		p_Enclosed_By IN VARCHAR2 DEFAULT '"'
	)
	RETURN CLOB
	IS
		v_ret 		INTEGER;
		v_curid 	INTEGER;
		v_file      CLOB;
	BEGIN
		if p_report.sql_query IS NOT NULL then 
			v_curid := dbms_sql.open_cursor;
			dbms_sql.parse(v_curid, apex_plugin_util.replace_substitutions (p_report.sql_query), DBMS_SQL.NATIVE);
			for i in 1..p_report.binds.count
			loop
				dbms_sql.bind_variable(v_curid, p_report.binds(i).name, p_report.binds(i).value);
			end loop;
			v_ret := DBMS_SQL.EXECUTE(v_curid);
			v_file := cursor_to_csv (v_curid, p_Separator, p_Enclosed_By);
			dbms_sql.close_cursor (v_curid);
		end if;
		return v_file;
	EXCEPTION
		WHEN OTHERS THEN
			dbms_output.put_line(SQLERRM);

			IF dbms_sql.is_open (v_curid) THEN
				dbms_sql.close_cursor (v_curid);
			END IF;
			RAISE;
	END Report_to_CSV;

    FUNCTION Clob_To_Blob(
        p_src_clob IN CLOB,
		p_charset IN VARCHAR2 DEFAULT 'AL32UTF8' -- 'WE8ISO8859P1'
    ) RETURN BLOB
    IS
        v_dstoff	    pls_integer := 1;
        v_srcoff		pls_integer := 1;
        v_langctx 		pls_integer := dbms_lob.default_lang_ctx;
        v_warning 		pls_integer := 1;
    	v_blob_csid     pls_integer := nls_charset_id(p_charset);
    	v_dest_lob		BLOB;
    BEGIN
    	dbms_lob.createtemporary(v_dest_lob, true, dbms_lob.call);
        dbms_lob.converttoblob(
            dest_lob     =>	v_dest_lob,
            src_clob     =>	p_src_clob,
            amount	     =>	dbms_lob.getlength(p_src_clob),
            dest_offset  =>	v_dstoff,
            src_offset	 =>	v_srcoff,
            blob_csid	 =>	v_blob_csid,
            lang_context => v_langctx,
            warning		 => v_warning
        );
        return v_dest_lob;
    END Clob_To_Blob;

	PROCEDURE Document_List_Csv (
		p_Job_ID IN NUMBER,
		p_Separator IN VARCHAR2 DEFAULT ';', 
		p_Enclosed_By IN VARCHAR2 DEFAULT '"',
		p_zipped_blob IN OUT NOCOPY BLOB
	)
	IS
		CURSOR cr_document IS
			SELECT	document_id
			,		file_name
			,		object_store_url
			,		searchable_pdf_url
			FROM	 DOCUMENT_SCAN_AI_DOCS
			WHERE	 job_id = p_Job_id;

		lr_document		cr_document%ROWTYPE;

		CURSOR cr_doc_tables IS
			SELECT	d.document_id
			,		d.file_name
			FROM	DOCUMENT_SCAN_AI_DOCS d
			WHERE	 job_id = p_Job_id
			AND EXISTS(SELECT 1 
				FROM DOCUMENT_SCAN_AI_TABLES t 
				WHERE d.document_id = t.document_id
			);
		lr_doc_table	cr_doc_tables%ROWTYPE;

		CURSOR cr_job IS 
			SELECT * FROM V_DOCUMENT_SCAN_AI_JOB_DETAILS 
			WHERE	 job_id = p_Job_id;
		lr_job			cr_job%ROWTYPE;
			
		v_csv 			CLOB;
		v_file_content 	BLOB;
		v_report 		apex_ir.t_report; 
		v_zip_file 		BLOB;
		v_File_Name		varchar2(1024);
		v_File_Size  	pls_integer;
		v_Separator 	VARCHAR2(16);
		v_Enclosed_By	VARCHAR2(16);
	BEGIN
		OPEN	cr_job;
		FETCH cr_job INTO lr_job;
		CLOSE cr_job;
		
		if lr_job.SHOW_INVOICE = 'Y' then 
			-- document_list --
			v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_INVOICES WHERE job_id = :job_id';
			v_report.binds(1).name := 'job_id';
			v_report.binds(1).value := p_Job_ID;
			v_File_Name := apex_string.format('csv_files/Invoices_List_%s.csv', p_Job_ID);

			v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
			if dbms_lob.getlength(v_csv) > 0 then
				v_file_content := Clob_To_Blob (
					p_src_clob	=> v_csv
				);
				apex_zip.add_file (
					p_zipped_blob => p_zipped_blob, 
					p_file_name => v_File_Name , 
					p_content => v_file_content );
			end if;
		
			OPEN	cr_document;
			loop 
				FETCH cr_document INTO lr_document;
				EXIT WHEN cr_document%NOTFOUND;
				-- document line items --
				v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE WHERE document_id = :document_id';
				v_report.binds(1).name := 'document_id';
				v_report.binds(1).value := lr_document.document_id;
			
				v_File_Name := apex_string.format('csv_files/%s_Line_Items.csv', base_file_name(lr_document.file_name));

				v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
				if dbms_lob.getlength(v_csv) > 0 then
					v_file_content := Clob_To_Blob (
						p_src_clob	=> v_csv
					);
					apex_zip.add_file (
						p_zipped_blob => p_zipped_blob, 
						p_file_name => v_File_Name , 
						p_content => v_file_content );
				end if;
			end loop;
			CLOSE cr_document;
		end if;

		if lr_job.SHOW_RECEIPT = 'Y' then 
			-- document_list --
			v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_RECEIPTS WHERE job_id = :job_id';
			v_report.binds(1).name := 'job_id';
			v_report.binds(1).value := p_Job_ID;
			v_File_Name := apex_string.format('csv_files/Receipts_List_%s.csv', p_Job_ID);

			v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
			if dbms_lob.getlength(v_csv) > 0 then
				v_file_content := Clob_To_Blob (
					p_src_clob	=> v_csv
				);
				apex_zip.add_file (
					p_zipped_blob => p_zipped_blob, 
					p_file_name => v_File_Name , 
					p_content => v_file_content );
			end if;
			OPEN	cr_document;
			loop 
				FETCH cr_document INTO lr_document;
				EXIT WHEN cr_document%NOTFOUND;
				-- document line items --
				v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_LINE_ITEM_RECEIPT WHERE document_id = :document_id';
				v_report.binds(1).name := 'document_id';
				v_report.binds(1).value := lr_document.document_id;
			
				v_File_Name := apex_string.format('csv_files/%s_Line_Items.csv', base_file_name(lr_document.file_name));

				v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
				if dbms_lob.getlength(v_csv) > 0 then
					v_file_content := Clob_To_Blob (
						p_src_clob	=> v_csv
					);
					apex_zip.add_file (
						p_zipped_blob => p_zipped_blob, 
						p_file_name => v_File_Name , 
						p_content => v_file_content );
				end if;
			end loop;
			CLOSE cr_document;
		end if;
		
		if lr_job.SHOW_DRIVER_LICENSE = 'Y' then 
			-- document_list --
			v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_DRIVER_LICENSE WHERE job_id = :job_id';
			v_report.binds(1).name := 'job_id';
			v_report.binds(1).value := p_Job_ID;
			v_File_Name := apex_string.format('csv_files/Driver_License_List_%s.csv', p_Job_ID);

			v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
			if dbms_lob.getlength(v_csv) > 0 then
				v_file_content := Clob_To_Blob (
					p_src_clob	=> v_csv
				);
				apex_zip.add_file (
					p_zipped_blob => p_zipped_blob, 
					p_file_name => v_File_Name , 
					p_content => v_file_content );
			end if;
		end if;
		
		if lr_job.SHOW_DRIVER_LICENSE = 'Y' then 
			-- document_list --
			v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_PASSPORT WHERE job_id = :job_id';
			v_report.binds(1).name := 'job_id';
			v_report.binds(1).value := p_Job_ID;
			v_File_Name := apex_string.format('csv_files/Passport_List_%s.csv', p_Job_ID);

			v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
			if dbms_lob.getlength(v_csv) > 0 then
				v_file_content := Clob_To_Blob (
					p_src_clob	=> v_csv
				);
				apex_zip.add_file (
					p_zipped_blob => p_zipped_blob, 
					p_file_name => v_File_Name , 
					p_content => v_file_content );
			end if;
		end if;
		
		if lr_job.SHOW_TABLES = 'Y' then 
			OPEN	cr_doc_tables;
			loop 
				FETCH cr_doc_tables INTO lr_doc_table;
				EXIT WHEN cr_doc_tables%NOTFOUND;
				-- document line items --
				v_report.sql_query := 'SELECT * FROM V_DOCUMENT_SCAN_AI_TABLES WHERE document_id = :document_id';
				v_report.binds(1).name := 'document_id';
				v_report.binds(1).value := lr_doc_table.document_id;
			
				v_File_Name := apex_string.format('csv_files/%s_Tables.csv'
					, base_file_name(lr_doc_table.file_name)
				);

				v_csv := Report_to_CSV(v_report, p_Separator, p_Enclosed_By);
				if dbms_lob.getlength(v_csv) > 0 then
					v_file_content := Clob_To_Blob (
						p_src_clob	=> v_csv
					);
					apex_zip.add_file (
						p_zipped_blob => p_zipped_blob, 
						p_file_name => v_File_Name , 
						p_content => v_file_content );
				end if;
			end loop;
			CLOSE cr_doc_tables;
		end if;
	end Document_List_Csv; 

	--------------------------------------------------------------------------------

	PROCEDURE Download_Searchable_Pdf_Zip (p_Job_id  IN DOCUMENT_SCAN_AI_DOCS.job_id%TYPE) IS

		CURSOR cr_document IS
			SELECT	mime_type
			,		file_name
			,		object_store_url
			,		searchable_pdf_url
			FROM	 DOCUMENT_SCAN_AI_DOCS
			WHERE	 job_id = p_Job_id;

		lr_document		cr_document%ROWTYPE;
		l_file_name 	VARCHAR2(300);
		l_file_blob		BLOB;
		l_Zip_File		BLOB;
	BEGIN
	    dbms_lob.createtemporary( lob_loc => l_file_blob, cache => true, dur => dbms_lob.call );
	    dbms_lob.createtemporary( lob_loc => l_Zip_File, cache => true, dur => dbms_lob.call );

		-- Get the OCI URL and Mimetytpe of the receipt file.
		OPEN	cr_document;
		loop 
			FETCH cr_document INTO lr_document;
			EXIT WHEN cr_document%NOTFOUND;
			-- Get the file BLOB from OCI Object Storage.
			if lr_document.searchable_pdf_url is not null then 
				l_file_blob := get_file (p_request_url => lr_document.searchable_pdf_url);
				l_file_name := apex_string.format('searchable_pdf/%s.pdf', base_file_name(lr_document.file_name));
			else 
				l_file_blob := get_file (p_request_url => lr_document.object_store_url);
				l_file_name := lr_document.file_name;
			end if;
			apex_zip.add_file (
				p_zipped_blob => l_Zip_File,
				p_file_name => l_file_name,
				p_content => l_file_blob
			);
		end loop;
		CLOSE cr_document;
		
		Document_List_Csv (
			p_Job_ID => p_Job_ID,
			p_zipped_blob => l_Zip_File
		);
		
		apex_zip.finish (p_zipped_blob => l_Zip_File);
		
		UPDATE DOCUMENT_SCAN_AI_JOBS 
		SET Is_Downloaded = 'Y'
		WHERE Job_id = p_Job_id;
		COMMIT;
		htp.init();
		owa_util.mime_header('application/zip', false);
		htp.p('Content-Length: ' || dbms_lob.getlength(l_Zip_File)); 
		htp.p('Content-Disposition:  attachment; filename="Document_AI_Files_'||to_char(p_Job_Id, GC_JOB_ID_FORMAT)||'.zip"');
		owa_util.http_header_close;	 
		wpg_docload.download_file(l_Zip_File);

	END Download_Searchable_Pdf_Zip;
	--------------------------------------------------------------------------------
	-- deliver blob for text index 
	PROCEDURE Ctx_Document_Content(r in rowid, c in out nocopy blob) is
		CURSOR cr_document IS
			SELECT	mime_type
			,		file_name
			,		object_store_url
			,		searchable_pdf_url
			FROM	 DOCUMENT_SCAN_AI_DOCS
			WHERE	 ROWID = r;

		lr_document		cr_document%ROWTYPE;
	BEGIN
		-- Get the OCI URL and Mimetytpe of the document file.
		OPEN	cr_document;
		FETCH cr_document INTO lr_document;
		CLOSE cr_document;

		-- Get the file BLOB from OCI Object Storage.
		if lr_document.searchable_pdf_url is not null then 
			c := get_file (p_request_url => lr_document.searchable_pdf_url);
		elsif lr_document.mime_type like 'application/%' or lr_document.mime_type like 'text/%' then
			c := get_file (p_request_url => lr_document.object_store_url);
		end if;
	END Ctx_Document_Content;

	FUNCTION Ctx_Document_Filter(p_docid in varchar2) return clob
	is
	  l_data clob;
	begin
	  dbms_lob.createtemporary(
		lob_loc => l_data, 
		cache   => true, 
		dur     => dbms_lob.call
	  );
	  ctx_doc.filter(
		index_name => 'DOCUMENT_SCAN_AI_DOCS_TEXT_I',
		textkey    => p_docid, 
		restab      => l_data,
		plaintext   => TRUE
	  );
	  return l_data;
	end Ctx_Document_Filter;
	
	--------------------------------------------------------------------------------
	FUNCTION Get_User_Job_State_Peek (
		p_Job_ID VARCHAR2 DEFAULT NULL
	) RETURN VARCHAR2
	IS
		v_Job_Name 	USER_SCHEDULER_JOBS.JOB_NAME%TYPE := SUBSTR(GC_Job_Name_Prefix || p_Job_ID, 1, 17);
		v_Running_Count binary_integer := 0;
		v_Scheduled_Count binary_integer := 0;
		v_Job_State	USER_SCHEDULER_JOBS.STATE%TYPE := 'DONE';
	BEGIN
		COMMIT; -- start a new transaction, to load fresh data.
		SELECT SUM(case when STATE = 'RUNNING' then 1 end) Running_Count,
			SUM(case when STATE = 'SCHEDULED' then 1 end) Scheduled_Count
		INTO v_Running_Count,  v_Scheduled_Count
		FROM SYS.USER_SCHEDULER_JOBS 
		WHERE JOB_NAME LIKE v_Job_Name || '%';
		v_Job_State := case 
			when v_Running_Count > 0 then 'RUNNING'
			when v_Scheduled_Count > 0 then 'SCHEDULED'
			else 'DONE'
		end;
		apex_debug.message(
			p_message => 'Get_User_Job_State_Peek Job_State : %s',
			p0 => DBMS_ASSERT.ENQUOTE_LITERAL(v_Job_State)
		);
		return v_Job_State;
	END Get_User_Job_State_Peek;

	FUNCTION oracle_text_fuzzy_search (
		p_search in varchar2 
	) return varchar2
	is
	begin
		return 'FUZZY({' || replace( p_search, '}', '\}' ) || '}, 30, 2000)';
	end oracle_text_fuzzy_search;
	
	FUNCTION oracle_text_progress_search (
    	p_search in varchar2 
    ) return varchar2 
	is
		c_xml constant varchar2(32767) := '<query><textquery><progression>' ||
											'<seq>  #SEARCH#  </seq>' ||
											'<seq> ?#SEARCH#  </seq>' ||
											'<seq>  #SEARCH#% </seq>' ||
											'<seq> %#SEARCH#% </seq>' ||
										  '</progression></textquery></query>';
		l_search varchar2(32767);
	begin
		-- remove special characters; irrelevant for full text search
		l_search := nvl(translate( p_search, '-[<>{}/()*%&!$?.:,;\+#]', ' ' ),  'x');

		return replace( c_xml, '#SEARCH#', l_search );
	end oracle_text_progress_search;

	FUNCTION oracle_text_token_search (
    	p_Search IN VARCHAR2,
    	p_Language IN VARCHAR2 DEFAULT 'GERMAN'
    ) return varchar2 
	is
		c_xml constant varchar2(32767) := 
		'<query>
		  <textquery lang="%s" grammar="CONTEXT"> {%s}
			<progression>
			  <seq><rewrite>transform((TOKENS, "{", "}", " "))</rewrite></seq> 
			  <seq><rewrite>transform((TOKENS, "{", "}", " ; "))</rewrite></seq> 
			  <seq><rewrite>transform((TOKENS, "{", "}", "AND"))</rewrite></seq> 
			  <seq><rewrite>transform((TOKENS, "{", "}", "ACCUM"))</rewrite></seq>
			</progression> 
		  </textquery>
		<score datatype="FLOAT" algorithm="COUNT"/>
		</query>';
		l_Search varchar2(32767);
	begin
		-- remove special characters; irrelevant for full text search
		l_search := nvl(translate( p_search, '-[<>{}/()*%&!$?.:,;\+#]', ' ' ),  'x');

		return apex_string.format( c_xml, p_Language, l_Search );
	end oracle_text_token_search;

	
	PROCEDURE Rebuild_Text_Index 
	IS 
	BEGIN 
		begin
			EXECUTE IMMEDIATE 'DROP INDEX DOCUMENT_SCAN_AI_DOCS_TEXT_I FORCE';
		exception when others then 
			if SQLCODE != -1418 then -- specified index does not exist
				raise;
			end if;
		end;

		EXECUTE IMMEDIATE q'[
		CREATE INDEX DOCUMENT_SCAN_AI_DOCS_TEXT_I ON DOCUMENT_SCAN_AI_DOCS (SEARCHABLE_PDF_URL)
		INDEXTYPE IS CTXSYS.CONTEXT
		PARAMETERS ('
			DATASTORE DOC_SCAN_AI_DSTORE
			FILTER CTXSYS.AUTO_FILTER
			FORMAT COLUMN INDEX_FORMAT
			TRANSACTIONAL SYNC (EVERY "SYSDATE+1/1440*10")')
		]';
	END Rebuild_Text_Index;

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
	) RETURN NUMBER
	IS 
		l_search VARCHAR2(2000) := TRIM(p_Search);
		l_result NUMBER;
		l_call 	VARCHAR2(2000);
	BEGIN 
		if ((COALESCE( l_search, p_Vendor_Name, p_Vendor_Address, p_Vendor_Logo, p_Email, p_Phone, p_Tax_ID, p_IBAN, p_SWIFT_BIC) IS NOT NULL)
		 or p_Search_Project_Client = 'Y' and p_Context_ID IS NOT null)
		and GC_FIND_ADDRESS_FUNCTION IS NOT NULL then 
			l_call := apex_string.format('begin :x := %s(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l); end;', GC_FIND_ADDRESS_FUNCTION);
			apex_debug.message('Find_Address_call: %s, ', l_call);
			apex_debug.message('(l_search: %s, p_Vendor_Name: %s, p_Vendor_Address: %s, p_Vendor_Logo: %s, p_Language: %s, p_Context_ID:%s, ',
							l_search, p_Vendor_Name, p_Vendor_Address, p_Vendor_Logo, p_Language, p_Context_ID);
			apex_debug.message('p_Email: %s, p_Phone: %s, p_Tax_ID: %s, p_IBAN: %s, p_SWIFT_BIC: %s, p_Search_Project_Client: %s )', 
							p_Email, p_Phone, p_Tax_ID, p_IBAN, p_SWIFT_BIC, p_Search_Project_Client);
			EXECUTE IMMEDIATE l_call USING OUT l_result, 
				IN l_search, p_Language, p_Context_ID, p_Vendor_Name, p_Vendor_Address, p_Vendor_Logo
				, p_Email, p_Phone, p_Tax_ID, p_IBAN, p_SWIFT_BIC, p_Search_Project_Client;
			apex_debug.message(' - returns: %s', l_result);
		end if;
		RETURN l_result;
	END Find_Address_call; 
	
	PROCEDURE Link_Document_Addresses (
		p_Job_Id IN DOCUMENT_SCAN_AI_DOCS.Job_Id%TYPE DEFAULT NULL,
		p_document_id IN DOCUMENT_SCAN_AI_DOCS.document_id%TYPE DEFAULT NULL
	)
	IS 		
		l_Context_ID NUMBER;
		l_ClientAddress_ID NUMBER;
		l_CustomerAddress_ID NUMBER;
		l_VendorAddress_ID NUMBER;
		l_BillingAddress_ID NUMBER;
		l_ShippingAddress_ID NUMBER;
		l_ServiceAddress_ID NUMBER;
		l_RemittanceAddress_ID NUMBER;
		l_MerchantAddress_ID NUMBER;
	BEGIN 
		if GC_FIND_ADDRESS_FUNCTION IS NULL then 
			return;
		end if;
		for cr_doc in (
			SELECT d.* 
			FROM V_DOCUMENT_SCAN_AI_INVOICES d
			WHERE (job_id = p_Job_Id or p_Job_Id IS NULL)
			AND (document_id = p_document_id or p_document_id IS NULL)
		)
		loop 
			/* address id from project context of the project Client */
			l_ClientAddress_ID :=  Document_Scan_Ai_Pkg.Find_Address_call (
				p_Context_ID => cr_doc.Context_Id, 
				p_Search_Project_Client => 'Y'
			);
			apex_debug.message('Link_Document_Addresses-invoices 1: document_id: %s, Vendor_Name: %s, Invoice_Total: %s, ClientAddress_ID: %s.', 
				cr_doc.document_id, cr_doc.Vendor_Name, cr_doc.Invoice_Total, l_ClientAddress_ID);
			l_CustomerAddress_ID := Find_Address_call (
				p_Language => cr_doc.language_name,
				p_Context_ID => cr_doc.Context_Id,
				p_Vendor_Name => cr_doc.Customer_Name, 
				p_Vendor_Address => cr_doc.Customer_Address, 
				p_Tax_ID => cr_doc.Customer_Tax_Id
			);
			l_VendorAddress_ID := Find_Address_call (
				p_Language => cr_doc.language_name,
				p_Context_ID => cr_doc.Context_Id,
				p_Search => cr_doc.Vendor_Name||' '||cr_doc.Vendor_Name_Logo,
				p_Vendor_Name => cr_doc.Vendor_Name, 
				p_Vendor_Address => cr_doc.Vendor_Address, 
				p_Vendor_Logo => cr_doc.Vendor_Name_Logo,
				p_Email => cr_doc.Vendor_Email,
				p_Phone => NVL(cr_doc.Vendor_Mobil, cr_doc.Vendor_Phone),
				p_Tax_ID => cr_doc.Vendor_Tax_Id,
				p_IBAN => cr_doc.Bank_IBAN,
				p_SWIFT_BIC => cr_doc.Bank_BIC
			);
			l_BillingAddress_ID := Find_Address_call (
				p_Search => cr_doc.Billing_Address,
				p_Language => cr_doc.language_name,
				p_Context_ID => cr_doc.Context_Id
			);
			l_ShippingAddress_ID := Find_Address_call (
				p_Search => cr_doc.Shipping_Address,
				p_Language => cr_doc.language_name,
				p_Context_ID => cr_doc.Context_Id
			);
			l_ServiceAddress_ID := Find_Address_call (
				p_Search => cr_doc.Service_Address,
				p_Language => cr_doc.language_name,
				p_Context_ID => cr_doc.Context_Id
			);
			l_RemittanceAddress_ID := Find_Address_call (
				p_Search => cr_doc.Remittance_Address,
				p_Language => cr_doc.language_name,
				p_Context_ID => cr_doc.Context_Id
			);
			/* contractor address used in accounting */
			l_VendorAddress_ID := coalesce(l_VendorAddress_ID, l_BillingAddress_ID, l_ShippingAddress_ID, 
											l_ServiceAddress_ID, l_RemittanceAddress_ID);
			if l_VendorAddress_ID = l_ClientAddress_ID 
			and (l_CustomerAddress_ID != l_ClientAddress_ID or l_CustomerAddress_ID IS NULL) then 
			/*	disentangle wrong address assigment */
				apex_debug.message('Link_Document_Addresses-invoices 2: set l_VendorAddress_ID to l_CustomerAddress_ID %s', l_CustomerAddress_ID);
				l_VendorAddress_ID := l_CustomerAddress_ID;
				l_CustomerAddress_ID := l_ClientAddress_ID;
			end if;
			if l_CustomerAddress_ID != l_ClientAddress_ID or l_CustomerAddress_ID IS NULL then 
				apex_debug.message('Link_Document_Addresses-invoices 3: set l_CustomerAddress_ID to l_ClientAddress_ID %s', l_ClientAddress_ID);
				l_CustomerAddress_ID := l_ClientAddress_ID;			
			end if;
			UPDATE DOCUMENT_SCAN_AI_DOCS 
				SET CustomerAddress_ID	= l_CustomerAddress_ID
				, VendorAddress_ID		= l_VendorAddress_ID
				, BillingAddress_ID		= l_BillingAddress_ID
				, ShippingAddress_ID	= l_ShippingAddress_ID
				, ServiceAddress_ID		= l_ServiceAddress_ID
				, RemittanceAddress_ID	= l_RemittanceAddress_ID
				, Total_Amount = NVL(cr_doc.Invoice_Total, cr_doc.Amount_Due)
			WHERE document_id = cr_doc.document_id;
		end loop;

		for cr_rec in (
			SELECT d.* 
			FROM V_DOCUMENT_SCAN_AI_RECEIPTS d
			WHERE (job_id = p_Job_Id or p_Job_Id IS NULL)
			AND (document_id = p_document_id or p_document_id IS NULL)
		)
		loop 
			apex_debug.message('Link_Document_Addresses-receipts: document_id: %s, Merchant_Name: %s, Invoice_Total: %s.', cr_rec.document_id, cr_rec.Merchant_Name, cr_rec.Total);
			l_MerchantAddress_ID := Find_Address_call (
				p_Search => apex_string.format('%s %s %s', cr_rec.Merchant_Name, cr_rec.Merchant_Address, cr_rec.Merchant_Phone_Number),
				p_Language => cr_rec.language_name
			);
			UPDATE DOCUMENT_SCAN_AI_DOCS 
				SET MerchantAddress_ID	= l_MerchantAddress_ID
				, Total_Amount = cr_rec.Total
			WHERE document_id = cr_rec.document_id;
		end loop;
	END Link_Document_Addresses;

	--------------------------------------------------------------------------------
	FUNCTION Duplicate_Configuration (p_config_id IN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE)
	RETURN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE
	IS
		l_new_config_id DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE;
		l_config_rec DOCUMENT_SCAN_AI_CONFIG%ROWTYPE;
	BEGIN 
		SELECT * INTO l_config_rec
		FROM DOCUMENT_SCAN_AI_CONFIG 
		WHERE config_id = p_config_id;
		
		l_config_rec.config_id := null;
		l_config_rec.configuration_name := substr(l_config_rec.configuration_name||'_duplicate_'||p_config_id, 1, 255);
		INSERT INTO DOCUMENT_SCAN_AI_CONFIG
		VALUES l_config_rec
		RETURNING config_id INTO l_new_config_id;
		
		INSERT INTO DOCUMENT_SCAN_AI_FIELD_TYPES (
			Document_type,field_label,Description,API_Response_Value,value_type,format_mask,config_id)
		SELECT Document_type,field_label,Description,API_Response_Value,value_type,format_mask
				,l_new_config_id config_id
		FROM DOCUMENT_SCAN_AI_FIELD_TYPES 
		WHERE config_id = p_config_id;
		
		INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (
			Document_type, Field_label, field_alias, config_id)
		SELECT Document_type, Field_label, field_alias
				,l_new_config_id config_id
		FROM DOCUMENT_SCAN_AI_FIELD_ALIAS 
		WHERE config_id = p_config_id;
		
		INSERT INTO DOCUMENT_SCAN_AI_LINE_ITEM_TYPES (
			Document_type,Line_Item,Description,value_type,config_id)
		SELECT Document_type,Line_Item,Description,value_type
				,l_new_config_id config_id
		FROM DOCUMENT_SCAN_AI_LINE_ITEM_TYPES 
		WHERE config_id = p_config_id;
		
		INSERT INTO DOCUMENT_SCAN_AI_LANGUAGES (
			iso_code,language_name,common_date_format,common_number_format,nls_date_language
			,territory,nls_numeric_characters,nls_currency,nls_iso_currency,config_id)
		SELECT iso_code,language_name,common_date_format,common_number_format,nls_date_language
			,territory,nls_numeric_characters,nls_currency,nls_iso_currency
			,l_new_config_id config_id
		FROM DOCUMENT_SCAN_AI_LANGUAGES 
		WHERE config_id = p_config_id;
		
		RETURN l_new_config_id;
	END Duplicate_Configuration;
	--------------------------------------------------------------------------------
	PROCEDURE Set_Current_Configuration (p_config_id IN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE)
	IS
	BEGIN 
		UPDATE DOCUMENT_SCAN_AI_CONFIG 
		SET is_current_config = case when config_id = p_config_id then 'Y' else 'N' end;
		COMMIT;
		Load_Configuration;
	END;
	--------------------------------------------------------------------------------
	PROCEDURE Load_Configuration (p_config_id IN DOCUMENT_SCAN_AI_CONFIG.config_id%TYPE DEFAULT NULL)
    IS 
    BEGIN
    	SELECT config_id 
    	    ,input_location_prefix
			,output_location_prefix
			,pdf_location_prefix
			,compartment_id
			,object_bucket_name
			,object_namespace_name
			,object_store_base_url
			,oci_doc_ai_url
			,wc_credential_id
			,cloud_credential_id
			,currency_character
			,number_character 
			,processor_language_code
			,processor_documentType 
			,generate_Searchable_Pdf
			,Key_Values_Extraction
			,Table_Extraction
			,execute_asynchronous
			,delete_processor_output
			,keep_original_files
			,find_address_function
			,address_id_query
			,context_id_query
			,context_fields_query
			,invoice_export_view
			,invoice_export_procedure
		INTO GC_CONFIG_ID
		    ,GC_INPUT_LOCATION_PREFIX
			,GC_OUTPUT_LOCATION_PREFIX
			,GC_PDF_LOCATION_PREFIX
			,GC_COMPARTMENT_ID
			,GC_OBJECT_BUCKET_NAME
			,GC_OBJECT_NAMESPACE_NAME
			,GC_OBJECT_STORE_BASE_URL
			,GC_OCI_DOC_AI_URL
			,GC_WC_CREDENTIAL_ID	
			,GC_CLOUD_CREDENTIAL_ID
			,GC_CURRENCY_CHARACTER
			,GC_NUMBER_CHARACTER 
			,GC_PROCESSOR_LANGUAGE_CODE
			,GC_PROCESSOR_DOCUMENT_TYPE
			,GC_GENERATE_SEARCHABLE_PDF
			,GC_KEY_VALUES_EXTRACTION
			,GC_TABLE_EXTRACTION
			,GC_EXECUTE_ASYNCHRONOUS
			,GC_DELETE_PROCESSOR_OUTPUT
			,GC_KEEP_ORIGINAL_FILES
			,GC_FIND_ADDRESS_FUNCTION
			,GC_ADDRESS_ID_QUERY
			,GC_CONTEXT_ID_QUERY
			,GC_CONTEXT_FIELDS_QUERY
			,GC_INVOICE_EXPORT_VIEW
			,GC_INVOICE_EXPORT_PROCEDURE
		FROM DOCUMENT_SCAN_AI_CONFIG
		WHERE (config_id = p_config_id OR p_config_id IS NULL and is_current_config = 'Y')
		AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    	NULL;
    END Load_Configuration;

BEGIN
	Load_Configuration;
END Document_Scan_Ai_Pkg;
/


CREATE OR REPLACE TRIGGER DOCUMENT_SCAN_AI_DOCS_DEL BEFORE DELETE ON DOCUMENT_SCAN_AI_DOCS 
FOR EACH ROW 
begin 
	Document_Scan_Ai_Pkg.Delete_Doc_Searchable_Pdf(:OLD.searchable_pdf_url, :OLD.object_store_url);
exception when others then
	if SQLCODE NOT IN (-20404		-- ORA-20404: Object not found -
			 		, -20111) then 	-- ORA-20111: Unable to delete_file
    	raise;
	end if;
end;
/