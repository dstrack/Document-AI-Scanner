
CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_DOCUMENT_TYPES (
    DISPLAY_VALUE, RETURN_VALUE
) AS
SELECT APEX_LANG.LANG(INITCAP(REPLACE(COLUMN_VALUE, '_', ' '))) DISPLAY_VALUE, COLUMN_VALUE RETURN_VALUE 
FROM APEX_STRING.SPLIT('INVOICE:RECEIPT:RESUME:TAX_FORM:DRIVER_LICENSE:PASSPORT:BANK_STATEMENT:CHECK:PAYSLIP:OTHERS', ':')
;

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_JOB_DETAILS AS
select  j.job_id, j.Context_Id, j.processorJob_ID, j.language_code, j.documentType, j.lifecycleState, j.percentComplete
,       j.ProcessorJob_Message, j.lifecycleDetails, j.Key_Value_Extraction, j.Table_Extraction
,       j.Is_Exported, j.Is_Downloaded, j.Is_Cleaned_up, j.creation_date, j.created_by
,       MAX(case when 'INVOICE'  IN (j.documentType, d.document_type_code) and ft.Document_type = 'INVOICE' then 'Y' else 'N' end) SHOW_INVOICE
,       MAX(case when 'RECEIPT'  IN (j.documentType, d.document_type_code) and ft.Document_type = 'RECEIPT' then 'Y' else 'N' end) SHOW_RECEIPT 
,       MAX(case when 'RESUME'   IN (j.documentType, d.document_type_code) then 'Y' else 'N' end) SHOW_RESUME
,       MAX(case when 'TAX_FORM' IN (j.documentType, d.document_type_code) then 'Y' else 'N' end) SHOW_TAX_FORM
,       MAX(case when 'DRIVER_LICENSE' IN (j.documentType, d.document_type_code) and ft.Document_type = 'DRIVER_LICENSE' then 'Y' else 'N' end) SHOW_DRIVER_LICENSE 
,       MAX(case when 'PASSPORT' IN (j.documentType, d.document_type_code) and ft.Document_type = 'PASSPORT' then 'Y' else 'N' end) SHOW_PASSPORT
,       MAX(case when 'BANK_STATEMENT' IN (j.documentType, d.document_type_code) then 'Y' else 'N' end) SHOW_BANK_STATEMENT
,       MAX(case when 'CHECK'    IN (j.documentType, d.document_type_code) then 'Y' else 'N' end) SHOW_CHECK
,       MAX(case when 'PAYSLIP'  IN (j.documentType, d.document_type_code) then 'Y' else 'N' end) SHOW_PAYSLIP
,       case when (j.Table_Extraction = 'Y' and COUNT(DISTINCT ta.table_id) > 0) then 'Y' else 'N' end SHOW_TABLES
,       COUNT(DISTINCT d.document_id) documents
,       COUNT(DISTINCT ta.table_id) tables
,       SUM(case when f.field_type_code = 'KEY_VALUE' then 1 end) key_values
,       SUM(case when f.field_type_code = 'LINE_ITEM' then 1 end) line_items
from DOCUMENT_SCAN_AI_JOBS j 
left outer join DOCUMENT_SCAN_AI_DOCS d on d.job_id = j.job_id
left outer join DOCUMENT_SCAN_AI_FIELDS f on d.document_id = f.document_id
left outer join DOCUMENT_SCAN_AI_FIELD_TYPES ft 
    on ft.Document_type IN (J.documentType, D.document_type_code) 
    and f.field_label = ft.field_label 
    and f.field_type_code = 'KEY_VALUE'
    and j.config_id = ft.config_id
left outer join DOCUMENT_SCAN_AI_TABLES ta on d.document_id = ta.document_id
group by j.job_id, j.Context_Id, j.documentType, j.processorJob_ID, j.language_code, j.documentType , j.lifecycleState , j.percentComplete
,       j.ProcessorJob_Message, j.lifecycleDetails, j.Key_Value_Extraction, j.Table_Extraction
,       j.Is_Exported, j.Is_Downloaded, j.Is_Cleaned_up, j.creation_date, j.created_by
;
CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_JOB_DETAILS_UPD
INSTEAD OF UPDATE ON V_DOCUMENT_SCAN_AI_JOB_DETAILS 
FOR EACH ROW
BEGIN
    UPDATE DOCUMENT_SCAN_AI_JOBS 
    SET language_code = :new.language_code
    ,   documentType = :new.documentType
    ,   Context_Id = :new.Context_Id
    WHERE job_id = :old.job_id;
END;
/

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_JOB_DETAILS_DEL
INSTEAD OF DELETE ON V_DOCUMENT_SCAN_AI_JOB_DETAILS
FOR EACH ROW
BEGIN
    DELETE FROM DOCUMENT_SCAN_AI_JOBS T1
    WHERE T1.job_id = :old.job_id;
END;
/
------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_DOC_DETAILS AS
SELECT d.document_id
,      d.job_id
,      d.file_name
,      d.mime_type
,      d.language_code
,      TO_CHAR(ROUND(d.language_score * 100 ,1),'fm999.0') || '%' language_score
,      d.document_type_code document_type_code
,      TO_CHAR(ROUND(d.document_type_score * 100,1),'fm999.0') || '%' document_type_score
,      d.page_count
,      d.ProcessorJob_Message
,      d.creation_date
,      (select count(distinct f.word_id) 
        from DOCUMENT_SCAN_AI_FIELDS f 
        where f.document_id = d.document_id and f.field_type_code = 'KEY_VALUE' ) key_values
,      (select count(distinct f.word_id) 
        from DOCUMENT_SCAN_AI_FIELDS f 
        where f.document_id = d.document_id and f.field_type_code = 'LINE_ITEM' ) line_items
,      (select count(distinct f.table_id) 
        from DOCUMENT_SCAN_AI_TABLES f 
        where f.document_id = d.document_id ) tables
,	   d.CustomerAddress_ID
,      Document_Scan_Ai_Pkg.address_display_value(d.CustomerAddress_ID) CustomerAddress
,      d.VendorAddress_ID  
,      Document_Scan_Ai_Pkg.address_display_value(d.VendorAddress_ID) VendorAddress
,      d.BillingAddress_ID
,      Document_Scan_Ai_Pkg.address_display_value(d.BillingAddress_ID) BillingAddress
,      d.ShippingAddress_ID
,      Document_Scan_Ai_Pkg.address_display_value(d.ShippingAddress_ID) ShippingAddress
,      d.ServiceAddress_ID
,      Document_Scan_Ai_Pkg.address_display_value(d.ServiceAddress_ID) ServiceAddress
,      d.RemittanceAddress_ID
,      Document_Scan_Ai_Pkg.address_display_value(d.RemittanceAddress_ID) RemittanceAddress
,      d.MerchantAddress_ID
,      Document_Scan_Ai_Pkg.address_display_value(d.MerchantAddress_ID) MerchantAddress
,      d.Total_Amount
,       d.object_store_url
,       d.searchable_pdf_url
,       j.documentType as job_document_type
,       j.language_code as job_language_code
FROM   DOCUMENT_SCAN_AI_DOCS d
JOIN   DOCUMENT_SCAN_AI_JOBS j ON j.job_id = d.job_id;

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_DOC_DETAILS_UPD
INSTEAD OF UPDATE ON V_DOCUMENT_SCAN_AI_DOC_DETAILS 
FOR EACH ROW
BEGIN
    UPDATE DOCUMENT_SCAN_AI_DOCS 
    SET language_code = :new.language_code
    ,   document_type_code = :new.document_type_code
    WHERE document_id = :old.document_id;
END;
/

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_DOC_DETAILS_DEL
INSTEAD OF DELETE ON V_DOCUMENT_SCAN_AI_DOC_DETAILS
FOR EACH ROW
BEGIN
    DELETE FROM DOCUMENT_SCAN_AI_DOCS T1
    WHERE T1.document_id = :old.document_id;
END;
/

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_DOC_FILES AS
SELECT d.document_id
	, d.job_id
	, d.file_name
	, case when d.searchable_pdf_url IS NOT NULL 
		then 'application/pdf'
		else d.mime_type
	end mime_type
	, d.object_store_url
	, d.searchable_pdf_url
	, case when d.searchable_pdf_url IS NOT NULL 
		then Document_Scan_Ai_Pkg.get_file(d.searchable_pdf_url)
		when d.object_store_url IS NOT NULL 
		then Document_Scan_Ai_Pkg.get_file(d.object_store_url)
	end file_content
	, d.index_format
	, d.creation_date
	, d.thumbnail_png
FROM DOCUMENT_SCAN_AI_DOCS d;
------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_KEY_VALUE (
    WORD_ID, DOCUMENT_ID, FILE_NAME, DOCUMENT_TYPE, JOB_DOCUMENT_TYPE, CONFIG_ID, CUSTOM_ID,
    PAGE_NUMBER, FIELD_LABEL, LABEL_SCORE, FIELD_VALUE, VALUE_TYPE, FIELD_TEXT, 
    USER_CONFIRMED, USER_LABEL, FIELD_ALIAS, NUMBER_VALUE, DATE_VALUE, VALID_CONVERSION, TERRITORY,
    FIELD_NAME_ENG, FIELD_NAME_DEU, PAGE_ITEM_NAME,
    JOB_ID, CONTEXT_ID
) DEFAULT COLLATION USING_NLS_COMP  AS 
SELECT WORD_ID, DOCUMENT_ID, FILE_NAME, DOCUMENT_TYPE, JOB_DOCUMENT_TYPE, CONFIG_ID, CUSTOM_ID,
    PAGE_NUMBER, FIELD_LABEL, LABEL_SCORE, FIELD_VALUE, VALUE_TYPE, FIELD_TEXT, 
    USER_CONFIRMED, USER_LABEL, FIELD_ALIAS, NUMBER_VALUE, DATE_VALUE, VALID_CONVERSION, TERRITORY,
    FIELD_NAME_ENG, FIELD_NAME_DEU, PAGE_ITEM_NAME,
    JOB_ID, CONTEXT_ID
FROM (
    SELECT DISTINCT
        WORD_ID, DOCUMENT_ID, FILE_NAME, DOCUMENT_TYPE, JOB_DOCUMENT_TYPE, CONFIG_ID, CUSTOM_ID,
        PAGE_NUMBER, FIELD_LABEL, LABEL_SCORE, FIELD_VALUE, VALUE_TYPE, FIELD_TEXT, 
        USER_CONFIRMED, USER_LABEL, FIELD_ALIAS, NUMBER_VALUE, DATE_VALUE, VALID_CONVERSION, TERRITORY,
        FIELD_NAME_ENG, FIELD_NAME_DEU, PAGE_ITEM_NAME,
        JOB_ID, CONTEXT_ID,
        DENSE_RANK() OVER (PARTITION BY F.DOCUMENT_ID, F.FIELD_LABEL 
                    ORDER BY F.VALID_CONVERSION desc, F.USER_CONFIRMED desc, 
                        F.LABEL_SCORE desc, F.LANGUAGE_RANK, F.TERRITORY,
                        ABS(F.NUMBER_VALUE) desc nulls last, F.DATE_VALUE desc nulls last, F.word_id) RANK
    FROM (
        SELECT F.word_id
               , F.document_id
               , D.file_name
               , D.document_type_code document_type
               , J.documentType job_document_type
               , J.config_id
               , D.custom_id
               , F.page_number
               , F.field_label
               , ROUND(F.label_score * 100, 0) label_score
               , F.field_value
               , F.value_type
               , F.field_text
               , F.user_confirmed
               , F.user_label
               , F.field_alias
               , case when L.iso_code = D.language_code then 0 else 1 end language_rank
               , L.territory
               , case when (F.value_type = 'NUMBER' or FT.value_type = 'NUMBER') 
                    and Document_Scan_Ai_Pkg.Validate_Number_Conversion(F.field_text, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 then 1 
                    when (F.value_type = 'DATE' or FT.value_type = 'DATE')
                    and Document_Scan_Ai_Pkg.Validate_Date_Conversion(F.field_text, L.common_date_format, L.nls_date_language) = 1 then 1
                    when F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS NUMBER) = 1 then 1 
                    when F.value_type = 'DATE'  and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"') = 1 then 1 
                    when FT.value_type = 'DATE' and FT.format_mask IS NOT NULL and VALIDATE_CONVERSION(F.field_value AS DATE, FT.format_mask) = 1 then 1 
                    when Document_Scan_Ai_Pkg.Get_String_Type (FT.Value_Type, F.field_text) = FT.Value_Type then 1
                    when FT.value_type = 'STRING' then 1
                    else 0
               end Valid_Conversion
               , case when (F.value_type = 'NUMBER' or FT.value_type = 'NUMBER') 
                    and Document_Scan_Ai_Pkg.Validate_Number_Conversion(F.field_text, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 
                    then Document_Scan_Ai_Pkg.FM9_TO_Number(F.field_text, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory, p_Default_On_Error=>0)
               end Number_value
               , case 
                    when (F.value_type = 'DATE' or FT.value_type = 'DATE')
                    and Document_Scan_Ai_Pkg.Validate_Date_Conversion(F.field_text, L.common_date_format, L.nls_date_language) = 1 
                        then Document_Scan_Ai_Pkg.To_Date_Conversion(F.field_text, L.common_date_format, L.nls_date_language)
                    when F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS NUMBER) = 1
                        then TO_DATE( '1970-01-01', 'YYYY-MM-DD' ) + NUMTODSINTERVAL( TO_NUMBER(F.field_value) / 1000, 'SECOND' )
                    when  F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"') = 1
                        then CAST (TO_TIMESTAMP (F.field_value, 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"') AS DATE)
                    when FT.value_type = 'DATE' and FT.format_mask IS NOT NULL and VALIDATE_CONVERSION(F.field_value AS DATE, FT.format_mask) = 1 
                        then TO_DATE(F.field_value, FT.format_mask)
               end Date_Value 
               , ft.field_name_eng, ft.field_name_deu, ft.page_item_name
               , D.job_id
               , J.Context_Id
        FROM   (
            SELECT F.word_id, F.document_id, F.page_number
                   , F.field_label
                   , F.label_score, F.field_value, F.value_type
                   , NVL(F.field_text, F.field_value) field_text
                   , F.user_confirmed
                   , F.user_label
                   , F.field_alias
            FROM DOCUMENT_SCAN_AI_FIELDS F
            WHERE  F.field_type_code = 'KEY_VALUE' 
            UNION ALL 
            SELECT F.word_id, F.document_id, F.page_number
                   , F.user_label as field_label
                   , F.label_score, F.field_value, F.value_type
                   , NVL(F.field_text, F.field_value) field_text
                   , 1 as user_confirmed
                   , F.user_label
                   , F.field_alias
            FROM DOCUMENT_SCAN_AI_FIELDS F
            WHERE  F.user_label IS NOT NULL
        ) F 
        JOIN   DOCUMENT_SCAN_AI_DOCS D ON D.document_id = F.document_id
        JOIN   DOCUMENT_SCAN_AI_JOBS J ON D.job_id = J.job_id
        JOIN   DOCUMENT_SCAN_AI_CONFIG C ON J.config_id = C.config_id
        LEFT OUTER JOIN DOCUMENT_SCAN_AI_LANGUAGES L 
            ON L.iso_code IN (J.language_code, D.language_code)
            and J.config_id = L.config_id
        LEFT OUTER JOIN DOCUMENT_SCAN_AI_FIELD_TYPES FT 
            ON FT.Document_type IN (J.documentType, D.document_type_code) 
            and F.field_label = FT.field_label
            and J.config_id = FT.config_id
    ) F
) where RANK = 1
/

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_KEY_VALUE_UPD
INSTEAD OF UPDATE ON V_DOCUMENT_SCAN_AI_KEY_VALUE 
FOR EACH ROW
BEGIN
    UPDATE DOCUMENT_SCAN_AI_FIELDS 
    SET field_value = :new.field_value
    ,   field_text = :new.field_text
    ,   user_confirmed = :new.user_confirmed
    ,   user_label = :new.user_label
    WHERE word_id = :old.word_id;
END;
/

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_KEY_VALUE_DEL
INSTEAD OF DELETE ON V_DOCUMENT_SCAN_AI_KEY_VALUE
FOR EACH ROW
BEGIN
    DELETE FROM DOCUMENT_SCAN_AI_FIELDS T1
    WHERE T1.word_id = :old.word_id;
END;
/

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_LINE_ITEM (
    WORD_ID, DOCUMENT_ID, FILE_NAME, DOCUMENT_TYPE, JOB_DOCUMENT_TYPE, CONFIG_ID, 
    PAGE_NUMBER, LINE_NUMBER, FIELD_LABEL, LABEL_SCORE, FIELD_VALUE, VALUE_TYPE, FIELD_TEXT, 
    USER_CONFIRMED, USER_LABEL, TERRITORY, VALID_CONVERSION, NUMBER_VALUE, DATE_VALUE, JOB_ID, CONTEXT_ID
) DEFAULT COLLATION USING_NLS_COMP  AS 
  SELECT DISTINCT 
       F.word_id
,      F.document_id
,      D.file_name
,      D.document_type_code document_type
,      J.documentType job_document_type
,      J.config_id
,      F.page_number
,      F.line_number
,      F.field_label
,      ROUND(F.label_score * 100, 0) label_score
,      F.field_value
,      F.value_type
,      F.field_text
,      F.user_confirmed
,      F.user_label
,      L.territory
,      case when (F.value_type = 'NUMBER' or T.value_type = 'NUMBER') 
            and Document_Scan_Ai_Pkg.Validate_Number_Conversion(F.field_text, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 then 1 
            when F.value_type = 'NUMBER' and L.iso_code = C.processor_language_code
            and Document_Scan_Ai_Pkg.Validate_Date_Conversion(F.field_text, L.common_date_format, L.nls_date_language) = 1 then 1
            when F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS NUMBER) = 1 then 1 
            when F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"') = 1 then 1 
            when F.value_type NOT IN ('NUMBER','DATE') then 1
            else 0
       end Valid_Conversion
,      case when (F.value_type = 'NUMBER' or T.value_type = 'NUMBER') 
            and Document_Scan_Ai_Pkg.Validate_Number_Conversion(F.field_text, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 
                then Document_Scan_Ai_Pkg.FM9_TO_Number(F.field_text, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory, p_Default_On_Error=>0)
       end Number_value
,      case 
            when (F.value_type = 'DATE' or T.value_type = 'DATE')
            and Document_Scan_Ai_Pkg.Validate_Date_Conversion(F.field_text, L.common_date_format, L.nls_date_language) = 1 
                then Document_Scan_Ai_Pkg.To_Date_Conversion(F.field_text, L.common_date_format, L.nls_date_language)
            when F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS NUMBER) = 1
                then TO_DATE( '1970-01-01', 'YYYY-MM-DD' ) + NUMTODSINTERVAL( TO_NUMBER(F.field_value) / 1000, 'SECOND' )
            when  F.value_type = 'DATE' and L.iso_code = C.processor_language_code and VALIDATE_CONVERSION(F.field_value AS TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"') = 1
                then CAST (TO_TIMESTAMP (F.field_value, 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"') AS DATE)
       end Date_Value 
,      D.job_id
,      J.Context_Id
FROM   (
        SELECT F.word_id, F.document_id, F.page_number, F.line_number
        ,      F.field_label
        ,      F.label_score, F.field_value, F.value_type
        ,      NVL(F.field_text, F.field_value) field_text
        ,      1 as user_confirmed
        ,      F.user_label
        FROM DOCUMENT_SCAN_AI_FIELDS F
        WHERE  F.field_type_code = 'LINE_ITEM'
    ) F 
JOIN   DOCUMENT_SCAN_AI_DOCS D ON D.document_id = F.document_id
JOIN   DOCUMENT_SCAN_AI_JOBS J ON D.job_id = J.job_id
JOIN   DOCUMENT_SCAN_AI_CONFIG C ON J.config_id = C.config_id
LEFT OUTER JOIN DOCUMENT_SCAN_AI_LANGUAGES L 
    ON L.iso_code IN (J.language_code, D.language_code)
    and J.config_id = L.config_id
LEFT OUTER JOIN DOCUMENT_SCAN_AI_LINE_ITEM_TYPES T 
    ON T.Document_type IN (J.documentType, D.document_type_code) 
    AND F.field_label = T.Line_Item
    AND J.config_id = T.config_id
/

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_LINE_ITEM_UPD
INSTEAD OF UPDATE ON V_DOCUMENT_SCAN_AI_LINE_ITEM 
FOR EACH ROW
BEGIN
    UPDATE DOCUMENT_SCAN_AI_FIELDS 
    SET field_value = :new.field_value
    ,   field_text = :new.field_text
    ,   user_confirmed = :new.user_confirmed
    ,   user_label = :new.user_label
    WHERE word_id = :old.word_id;
END;
/

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_LINE_ITEM_DEL
INSTEAD OF DELETE ON V_DOCUMENT_SCAN_AI_LINE_ITEM
FOR EACH ROW
BEGIN
    DELETE FROM DOCUMENT_SCAN_AI_FIELDS T1
    WHERE T1.word_id = :old.word_id;
END;
/

--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE AS
select a.document_id
    , a.file_name
    , a.page_number
    , a.line_number
    , a.job_id
    , a.Context_Id
    , MAX(DECODE(a.FIELD_LABEL,'Name', a.FIELD_VALUE)) Name
    , MAX(DECODE(a.FIELD_LABEL,'Description', a.FIELD_VALUE)) Description
    , MAX(DECODE(a.FIELD_LABEL,'Quantity', a.NUMBER_VALUE)) Quantity
    , MAX(DECODE(a.FIELD_LABEL,'Unit', a.FIELD_VALUE)) Unit
    , MAX(DECODE(a.FIELD_LABEL,'UnitPrice', a.NUMBER_VALUE)) UnitPrice
    , MAX(DECODE(a.FIELD_LABEL,'Amount', a.NUMBER_VALUE)) Amount
    , MAX(DECODE(a.FIELD_LABEL,'ProductCode', a.FIELD_VALUE)) Product_Code
    , MAX(DECODE(a.FIELD_LABEL,'Tax', a.NUMBER_VALUE)) Tax
    , MAX(DECODE(a.FIELD_LABEL,'Date', a.DATE_VALUE)) Date_Value
from V_DOCUMENT_SCAN_AI_LINE_ITEM a 
join DOCUMENT_SCAN_AI_LINE_ITEM_TYPES t 
    on T.Document_type IN (a.document_type, a.job_document_type) 
    and a.field_label = t.Line_Item
    and a.config_id = t.config_id
where a.VALID_CONVERSION = 1
and t.Document_type = 'INVOICE'
group by a.job_id, a.Context_Id, a.document_id, a.file_name, a.page_number, a.line_number
order by job_id, file_name, page_number, line_number;


CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_INVOICES AS
with KEY_VALUE_INVOICE as (
    select a.document_id
        , a.custom_id 
        , a.file_name
        , a.job_id
        , a.Context_Id
        , a.Config_Id
        , MAX(DECODE(a.FIELD_LABEL,'AmountDue', a.NUMBER_VALUE)) Amount_Due
        , MAX(DECODE(a.FIELD_LABEL,'BillingAddress', a.FIELD_VALUE)) Billing_Address
        , MAX(DECODE(a.FIELD_LABEL,'BillingAddressRecipient', a.FIELD_VALUE)) Billing_Address_Recipient
        , MAX(DECODE(a.FIELD_LABEL,'CustomerAddress', a.FIELD_VALUE)) Customer_Address
        , MAX(DECODE(a.FIELD_LABEL,'CustomerAddressRecipient', a.FIELD_VALUE)) Customer_Address_Recipient
        , MAX(DECODE(a.FIELD_LABEL,'CustomerId', a.FIELD_TEXT)) Customer_Id
        , MAX(DECODE(a.FIELD_LABEL,'CustomerName', a.FIELD_VALUE)) Customer_Name
        , MAX(DECODE(a.FIELD_LABEL,'CustomerTaxId', a.FIELD_VALUE)) Customer_Tax_Id
        , MAX(DECODE(a.FIELD_LABEL,'DueDate', a.DATE_VALUE)) Due_Date
        , MAX(DECODE(a.FIELD_LABEL,'InvoiceDate', a.DATE_VALUE)) Invoice_Date
        , MAX(DECODE(a.FIELD_LABEL,'InvoiceId', a.FIELD_TEXT)) Invoice_Id
        , MAX(DECODE(a.FIELD_LABEL,'InvoiceTotal', a.NUMBER_VALUE)) Invoice_Total
        , MAX(DECODE(a.FIELD_LABEL,'PaymentTerm', a.FIELD_VALUE)) Payment_Term
        , MAX(DECODE(a.FIELD_LABEL,'PreviousUnpaidBalance', a.NUMBER_VALUE)) Previous_Unpaid_Balance
        , MAX(DECODE(a.FIELD_LABEL,'PurchaseOrder', a.FIELD_VALUE)) Purchase_Order
        , MAX(DECODE(a.FIELD_LABEL,'RemittanceAddress', a.FIELD_VALUE)) Remittance_Address
        , MAX(DECODE(a.FIELD_LABEL,'RemittanceAddressRecipient', a.FIELD_VALUE)) Remittance_Address_Recipient
        , MAX(DECODE(a.FIELD_LABEL,'ServiceAddress', a.FIELD_VALUE)) Service_Address
        , MAX(DECODE(a.FIELD_LABEL,'ServiceAddressRecipient', a.FIELD_VALUE)) Service_Address_Recipient
        , MAX(DECODE(a.FIELD_LABEL,'ServiceEndDate', a.DATE_VALUE)) Service_End_Date
        , MAX(DECODE(a.FIELD_LABEL,'ServiceStartDate', a.DATE_VALUE)) Service_Start_Date
        , MAX(DECODE(a.FIELD_LABEL,'ShippingAddress', a.FIELD_VALUE)) Shipping_Address
        , MAX(DECODE(a.FIELD_LABEL,'ShippingAddressRecipient', a.FIELD_VALUE)) Shipping_Address_Recipient
        , MAX(DECODE(a.FIELD_LABEL,'ShippingCost', a.NUMBER_VALUE)) Shipping_Cost
        , MAX(DECODE(a.FIELD_LABEL,'SubTotal', a.NUMBER_VALUE)) SubTotal
        , MAX(DECODE(a.FIELD_LABEL,'TotalTax', a.NUMBER_VALUE)) Total_Tax
        , MAX(DECODE(a.FIELD_LABEL,'TotalVAT', a.NUMBER_VALUE)) Total_VAT
        , MAX(DECODE(a.FIELD_LABEL,'VendorAddress', a.FIELD_VALUE)) Vendor_Address
        , MAX(DECODE(a.FIELD_LABEL,'VendorAddressRecipient', a.FIELD_VALUE)) Vendor_Address_Recipient
        , MAX(DECODE(a.FIELD_LABEL,'VendorName', a.FIELD_VALUE)) Vendor_Name
        , MAX(DECODE(a.FIELD_LABEL,'VendorNameLogo', a.FIELD_VALUE)) Vendor_Name_Logo
        , MAX(DECODE(a.FIELD_LABEL,'VendorTaxId', a.FIELD_VALUE)) Vendor_Tax_Id
		-- extra custom field labels from DOCUMENT_SCAN_AI_FIELD_ALIAS
        , MAX(DECODE(a.FIELD_LABEL,'TaxRate', a.NUMBER_VALUE)) Tax_Rate
        , MAX(DECODE(a.FIELD_LABEL,'InvoiceReceiptDate', a.DATE_VALUE)) Invoice_Receipt_Date	
        , MAX(DECODE(a.FIELD_LABEL,'InvoicePaidDate', a.DATE_VALUE)) Invoice_Paid_Date	
        , MAX(DECODE(a.FIELD_LABEL,'VendorEmail', a.FIELD_VALUE)) Vendor_Email
        , MAX(DECODE(a.FIELD_LABEL,'VendorPhone', a.FIELD_VALUE)) Vendor_Phone
        , MAX(DECODE(a.FIELD_LABEL,'VendorMobil', a.FIELD_VALUE)) Vendor_Mobil
        , MAX(DECODE(a.FIELD_LABEL,'BankBIC', a.FIELD_VALUE)) Bank_BIC
        , MAX(DECODE(a.FIELD_LABEL,'BankIBAN', a.FIELD_VALUE)) Bank_IBAN
        , MAX(DECODE(a.FIELD_LABEL,'BankPurpose', a.FIELD_VALUE)) Bank_Purpose
    from V_DOCUMENT_SCAN_AI_KEY_VALUE a 
    join DOCUMENT_SCAN_AI_FIELD_TYPES t 
        on T.Document_type IN (a.document_type, a.job_document_type) 
        and a.field_label = t.field_label
        and a.config_id = t.config_id
    where t.Document_type = 'INVOICE'
    and a.VALID_CONVERSION = 1
    group by a.document_id
        , a.custom_id 
        , a.file_name
        , a.job_id
        , a.Context_Id
        , a.Config_Id
)
SELECT d.document_id
     , d.custom_id 
     , d.job_id
     , e.Context_Id
     , d.file_name
     , d.mime_type
     , d.language_code 
     , NVL((select max(dl.language_name) from document_scan_ai_languages dl 
			where dl.iso_code = d.language_code and dl.config_id = j.config_id),
		   (select max(jl.language_name) from document_scan_ai_languages jl 
			where jl.iso_code = j.language_code and jl.config_id = j.config_id)
	   ) language_name
     , TO_CHAR(ROUND(d.language_score * 100 ,1),'fm999.0') || '%' language_score
     , d.document_type_code document_type
     , TO_CHAR(ROUND(d.document_type_score * 100,1),'fm999.0') || '%' document_type_score
     , d.CustomerAddress_ID
     , d.VendorAddress_ID  
     , Document_Scan_Ai_Pkg.address_display_value(d.VendorAddress_ID) Linked_Vendor_Address
     , d.BillingAddress_ID
     , d.ShippingAddress_ID
     , d.ServiceAddress_ID
     , d.RemittanceAddress_ID
     , d.page_count
     , d.creation_date
     , e.Amount_due, e.Billing_address, e.Billing_address_recipient
     , e.Customer_address, e.Customer_address_recipient, e.Customer_id, e.Customer_name
     , e.Customer_tax_id, e.Due_date, e.Invoice_date, e.Invoice_id, e.Invoice_total
     , e.Payment_term, e.Previous_unpaid_balance, e.Purchase_order, e.Remittance_address
     , e.Remittance_address_recipient, e.Service_address, e.Service_address_recipient
     , e.Service_end_date, e.Service_start_date, e.Shipping_address
     , e.Shipping_address_recipient, e.Shipping_cost, e.Subtotal
     , e.Total_tax
     , e.Total_vat
     , e.Vendor_address, e.Vendor_address_recipient, e.Vendor_name, e.Vendor_name_logo, e.Vendor_tax_id
     , e.Tax_Rate, e.Invoice_Receipt_Date, e.Invoice_Paid_Date
     , e.Vendor_Email, e.Vendor_Phone, e.Vendor_Mobil
     , e.Bank_BIC, e.Bank_IBAN, e.Bank_Purpose
FROM   DOCUMENT_SCAN_AI_DOCS d 
JOIN   DOCUMENT_SCAN_AI_JOBS j ON d.job_id = j.job_id
LEFT OUTER JOIN KEY_VALUE_INVOICE e ON d.document_id = e.document_id and d.job_id = e.job_id
;
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_RECEIPTS AS
with KEY_VALUE_RECEIPT as (
    select a.document_id
        , a.file_name
        , a.job_id
        , a.Context_Id
        , a.Config_Id
        , MAX(DECODE(a.FIELD_LABEL,'MerchantName', a.FIELD_TEXT)) Merchant_Name
        , MAX(DECODE(a.FIELD_LABEL,'MerchantPhoneNumber', a.FIELD_TEXT)) Merchant_Phone_Number
        , MAX(DECODE(a.FIELD_LABEL,'MerchantAddress', a.FIELD_TEXT)) Merchant_Address
        , MAX(DECODE(a.FIELD_LABEL,'TransactionDate', a.DATE_VALUE)) Transaction_Date
        , MAX(DECODE(a.FIELD_LABEL,'TransactionTime', a.DATE_VALUE)) Transaction_Time
        , MAX(DECODE(a.FIELD_LABEL,'Total', a.NUMBER_VALUE)) Total
        , MAX(DECODE(a.FIELD_LABEL,'SubTotal', a.NUMBER_VALUE)) Subtotal
        , MAX(DECODE(a.FIELD_LABEL,'Tax', a.NUMBER_VALUE)) Tax
        , MAX(DECODE(a.FIELD_LABEL,'Tip', a.NUMBER_VALUE)) Tip
    from V_DOCUMENT_SCAN_AI_KEY_VALUE a 
    join DOCUMENT_SCAN_AI_FIELD_TYPES t 
        on T.Document_type IN (a.document_type, a.job_document_type) 
        and a.field_label = t.field_label
        and a.config_id = t.config_id
    where t.Document_type = 'RECEIPT'
    and a.VALID_CONVERSION = 1
    group by a.document_id
        , a.file_name
        , a.job_id
        , a.Context_Id
        , a.Config_Id
)
SELECT d.document_id
,      d.job_id
,      e.Context_Id
,      d.file_name
,      d.mime_type
,      d.language_code 
,      NVL((select max(dl.language_name) from document_scan_ai_languages dl 
			where dl.iso_code = d.language_code and dl.config_id = j.config_id),
		   (select max(jl.language_name) from document_scan_ai_languages jl 
			where jl.iso_code = j.language_code and jl.config_id = j.config_id)
	   ) language_name
,      TO_CHAR(ROUND(d.language_score * 100 ,1),'fm999.0') || '%' language_score
,      d.document_type_code document_type
,      TO_CHAR(ROUND(d.document_type_score * 100,1),'fm999.0') || '%' document_type_score
,      d.MerchantAddress_ID
,      d.page_count
,      d.creation_date
,      e.Merchant_Name
,      e.Merchant_Phone_Number
,      e.Merchant_Address
,      e.Transaction_Date
,      e.Transaction_Time
,      e.Total
,      e.SubTotal
,      e.Tax
,      e.Tip
FROM   DOCUMENT_SCAN_AI_DOCS d 
JOIN   DOCUMENT_SCAN_AI_JOBS j ON d.job_id = j.job_id
JOIN KEY_VALUE_RECEIPT e ON d.document_id = e.document_id
;

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_LINE_ITEM_RECEIPT AS
select a.document_id
    , a.file_name
    , a.page_number
    , a.line_number
    , a.job_id
    , a.Context_Id
    , MAX(DECODE(a.FIELD_LABEL,'ItemName', a.FIELD_VALUE)) Item_Name
    , MAX(DECODE(a.FIELD_LABEL,'ItemPrice', a.NUMBER_VALUE)) Item_Price
    , MAX(DECODE(a.FIELD_LABEL,'ItemQuantity', a.NUMBER_VALUE)) Item_Quantity
    , MAX(DECODE(a.FIELD_LABEL,'ItemTotalPrice', a.NUMBER_VALUE)) Item_TotalPrice
from V_DOCUMENT_SCAN_AI_LINE_ITEM a 
join DOCUMENT_SCAN_AI_LINE_ITEM_TYPES t 
    on T.Document_type IN (a.document_type, a.job_document_type) 
    and a.field_label = t.Line_Item
    and a.config_id = t.config_id
where a.VALID_CONVERSION = 1
and t.Document_type = 'RECEIPT'
group by a.job_id, a.Context_Id, a.document_id, a.file_name, a.page_number, a.line_number
order by job_id, file_name, page_number, line_number;

--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_DRIVER_LICENSE AS
with KEY_VALUE_DRIVER_LICENSE as (
    select a.document_id
        , a.file_name
        , a.job_id
        , a.Context_Id
        , MAX(DECODE(a.FIELD_LABEL,'FirstName', a.FIELD_VALUE)) First_Name
        , MAX(DECODE(a.FIELD_LABEL,'LastName', a.FIELD_VALUE)) Last_Name
        , MAX(DECODE(a.FIELD_LABEL,'Country', a.FIELD_VALUE)) Country
        , MAX(DECODE(a.FIELD_LABEL,'BirthDate', a.DATE_VALUE)) Birth_Date
        , MAX(DECODE(a.FIELD_LABEL,'ExpiryDate', a.DATE_VALUE)) Expiry_Date
        , MAX(DECODE(a.FIELD_LABEL,'IssueDate', a.DATE_VALUE)) Issue_Date
        , MAX(DECODE(a.FIELD_LABEL,'Gender', a.FIELD_VALUE)) Gender
        , MAX(DECODE(a.FIELD_LABEL,'DocumentNumber', a.FIELD_VALUE)) Document_Number
        , MAX(DECODE(a.FIELD_LABEL,'Address', a.FIELD_VALUE)) Address
        , MAX(DECODE(a.FIELD_LABEL,'Region', a.FIELD_VALUE)) Region
    from V_DOCUMENT_SCAN_AI_KEY_VALUE a 
    join DOCUMENT_SCAN_AI_FIELD_TYPES t 
        on T.Document_type IN (a.document_type, a.job_document_type) 
        and a.field_label = t.field_label
        and a.config_id = t.config_id
    where t.Document_type = 'DRIVER_LICENSE'
    and a.VALID_CONVERSION = 1
    group by a.document_id, a.file_name, a.job_id, a.Context_Id
)
SELECT d.document_id
,      d.job_id
,      e.Context_Id
,      d.file_name
,      d.mime_type
,      d.language_code language_name
,      TO_CHAR(ROUND(d.language_score * 100 ,1),'fm999.0') || '%' language_score
,      d.document_type_code document_type
,      TO_CHAR(ROUND(d.document_type_score * 100,1),'fm999.0') || '%' document_type_score
,      d.page_count
,      d.creation_date
,      e.First_Name
,      e.Last_Name
,      e.Country
,      e.Birth_Date
,      e.Expiry_Date
,      e.Issue_Date
,      e.Gender
,      e.Document_Number
,      e.Address
,      e.Region
FROM   DOCUMENT_SCAN_AI_DOCS d 
JOIN KEY_VALUE_DRIVER_LICENSE e ON d.document_id = e.document_id
;
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_PASSPORT AS
with KEY_VALUE_PASSPORT as (
    select a.document_id
        , a.file_name
        , a.job_id
        , a.Context_Id
        , MAX(DECODE(a.FIELD_LABEL,'FirstName', a.FIELD_VALUE)) First_Name
        , MAX(DECODE(a.FIELD_LABEL,'LastName', a.FIELD_VALUE)) Last_Name
        , MAX(DECODE(a.FIELD_LABEL,'Country', a.FIELD_VALUE)) Country
        , MAX(DECODE(a.FIELD_LABEL,'Nationality', a.DATE_VALUE)) Nationality
        , MAX(DECODE(a.FIELD_LABEL,'BirthDate', a.DATE_VALUE)) Birth_Date
        , MAX(DECODE(a.FIELD_LABEL,'ExpiryDate', a.DATE_VALUE)) Expiry_Date
        , MAX(DECODE(a.FIELD_LABEL,'Gender', a.FIELD_VALUE)) Gender
        , MAX(DECODE(a.FIELD_LABEL,'DocumentType', a.FIELD_VALUE)) Document_Type
        , MAX(DECODE(a.FIELD_LABEL,'DocumentNumber', a.FIELD_VALUE)) Document_Number
    from V_DOCUMENT_SCAN_AI_KEY_VALUE a 
    join DOCUMENT_SCAN_AI_FIELD_TYPES t 
        on T.Document_type IN (a.document_type, a.job_document_type) 
        and a.field_label = t.field_label
        and a.config_id = t.config_id
    where t.Document_type = 'PASSPORT'
    and a.VALID_CONVERSION = 1
    group by a.document_id, a.file_name, a.job_id, a.Context_Id
)
SELECT d.document_id
,      d.job_id
,      e.Context_Id
,      d.file_name
,      d.mime_type
,      d.language_code language_name
,      TO_CHAR(ROUND(d.language_score * 100 ,1),'fm999.0') || '%' language_score
,      d.document_type_code
,      TO_CHAR(ROUND(d.document_type_score * 100,1),'fm999.0') || '%' document_type_score
,      d.page_count
,      d.creation_date
,      e.First_Name
,      e.Last_Name
,      e.Country
,      e.Nationality
,      e.Birth_Date
,      e.Expiry_Date
,      e.Gender
,      e.Document_Type
,      e.Document_Number
FROM   DOCUMENT_SCAN_AI_DOCS d 
JOIN KEY_VALUE_PASSPORT e ON d.document_id = e.document_id
;

--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_TABLES AS
SELECT s.document_id, s.job_id
    , t.table_id, j.page_number, j.table_number
    , j.rowIndex Sequence_ID
    , MAX(DECODE(j.columnIndex,  0, j.text)) Col001
    , MAX(DECODE(j.columnIndex,  1, j.text)) Col002
    , MAX(DECODE(j.columnIndex,  2, j.text)) Col003
    , MAX(DECODE(j.columnIndex,  3, j.text)) Col004
    , MAX(DECODE(j.columnIndex,  4, j.text)) Col005
    , MAX(DECODE(j.columnIndex,  5, j.text)) Col006
    , MAX(DECODE(j.columnIndex,  6, j.text)) Col007
    , MAX(DECODE(j.columnIndex,  7, j.text)) Col008
    , MAX(DECODE(j.columnIndex,  8, j.text)) Col009
    , MAX(DECODE(j.columnIndex,  9, j.text)) Col010
    , MAX(DECODE(j.columnIndex, 10, j.text)) Col011
    , MAX(DECODE(j.columnIndex, 11, j.text)) Col012
    , MAX(DECODE(j.columnIndex, 12, j.text)) Col013
    , MAX(DECODE(j.columnIndex, 13, j.text)) Col014
    , MAX(DECODE(j.columnIndex, 14, j.text)) Col015
    , MAX(DECODE(j.columnIndex, 15, j.text)) Col016
    , MAX(DECODE(j.columnIndex, 16, j.text)) Col017
    , MAX(DECODE(j.columnIndex, 17, j.text)) Col018
    , MAX(DECODE(j.columnIndex, 18, j.text)) Col019
    , MAX(DECODE(j.columnIndex, 19, j.text)) Col020
FROM DOCUMENT_SCAN_AI_DOCS s, DOCUMENT_SCAN_AI_TABLES t,
    JSON_TABLE(s.doc_ai_json, '$.pages[*]'
    COLUMNS (page_number           NUMBER       PATH '$.pageNumber',
        NESTED PATH '$.tables[*]' COLUMNS
            (table_number          FOR ORDINALITY,
            NESTED PATH '$.*.cells[*]' COLUMNS
                (rowIndex           NUMBER          PATH '$.rowIndex',
                columnIndex         NUMBER          PATH '$.columnIndex',
                text                VARCHAR2(1000) TRUNCATE PATH '$.text'
    )))) j
where t.document_id = s.document_id
and t.page_number = j.page_number
and t.table_number = j.table_number
group by s.document_id, s.job_id, t.table_id, j.page_number, j.table_number, j.rowIndex;


CREATE OR REPLACE VIEW  V_DOCUMENT_SCAN_AI_TEXT_LINE_VALUES (
	document_id, page_number, line_no, text_line
    , Value_Type, Number_value, Date_Value
    , field_label, config_id, language_code, Document_type
) AS
with TEXT_LINES as (
    SELECT s.document_id, jt.page_number, jt.line_no, jt.text_line, jt.x0, jt.y0, 
        J.config_id, J.language_code job_language_code, s.language_code,
        J.documentType job_document_type, S.document_type_code
    FROM DOCUMENT_SCAN_AI_JOBS j, DOCUMENT_SCAN_AI_DOCS s, 
        JSON_TABLE(s.doc_ai_json, '$.pages[*]' COLUMNS 
            (page_number             NUMBER PATH '$.pageNumber',
            NESTED PATH '$.lines[*]' COLUMNS
                (line_no             FOR ORDINALITY,
                text_line            VARCHAR2(1000) TRUNCATE PATH '$.text',
                x0					 NUMBER PATH '$.boundingPolygon.normalizedVertices[0].x',
                y0					 NUMBER PATH '$.boundingPolygon.normalizedVertices[0].y'
        ))) jt
    WHERE s.job_id = j.job_id
    AND s.document_id = NV('P5_DOCUMENT_ID')
)
select a.document_id, a.page_number, a.line_no, a.text_line
    , Value_Type, Number_value, Date_Value
    , field_label, config_id, language_code, Document_type
from (
    select distinct a.*
            , DENSE_RANK() OVER (PARTITION BY Document_Id, Page_Number, Line_No
                ORDER BY LENGTH(field_alias) DESC
                    , field_alias DESC
                	, case when Value_Type = 'STRING' then 1 else 0 end
                    , ABS(NUMBER_VALUE) desc nulls last, DATE_VALUE desc nulls last
                    , a.page_number, a.line_no
                    , a.language_code, a.Document_type) RANK
    from (
        select 
                a.document_id, a.page_number, a.line_no, a.text_line
                , case 
                    when Document_Scan_Ai_Pkg.Validate_Date_Conversion(a.text_line, L.common_date_format, L.nls_date_language) = 1 then 'DATE'
                    when Document_Scan_Ai_Pkg.Validate_Number_Conversion(A.text_line, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 then 'NUMBER' 
                    else Document_Scan_Ai_Pkg.Get_String_Type ('STRING', a.text_line)
                end Value_Type
                , case when Document_Scan_Ai_Pkg.Validate_Date_Conversion(a.text_line, L.common_date_format, L.nls_date_language) = 0
                    and Document_Scan_Ai_Pkg.Validate_Number_Conversion(A.text_line, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory) = 1 
                    then Document_Scan_Ai_Pkg.FM9_TO_Number(A.text_line, L.nls_numeric_characters, L.nls_currency, L.nls_iso_currency, L.territory, p_Default_On_Error=>0)
                end Number_value
                , case when Document_Scan_Ai_Pkg.Validate_Date_Conversion(a.text_line, L.common_date_format, L.nls_date_language) = 1 
                    then Document_Scan_Ai_Pkg.To_Date_Conversion(a.text_line, L.common_date_format, L.nls_date_language)
                end Date_Value 
                , fa.field_label
                , fa.field_alias
                , a.config_id
                , COALESCE(fa.language_code, NULLIF(a.language_code, 'OTHERS'), a.job_language_code) language_code
                , COALESCE(fa.Document_type, NULLIF(a.job_document_type, 'OTHERS'), a.document_type_code) Document_type
        FROM TEXT_LINES A 
        LEFT OUTER JOIN DOCUMENT_SCAN_AI_LANGUAGES l 
            ON l.iso_code IN (a.language_code, a.job_language_code)
            AND l.config_id = a.config_id
        LEFT OUTER JOIN DOCUMENT_SCAN_AI_FIELD_ALIAS fa 
        	on UPPER(a.text_line) LIKE UPPER(fa.field_alias||'%') 
			and fa.config_id = a.config_id
			and fa.language_code IN (a.language_code, a.job_language_code)
			and fa.Document_type in (a.job_document_type, a.document_type_code)
			and (UPPER(a.text_line) = UPPER(fa.field_alias) or substr(a.text_line, length(fa.field_alias)+1, 1) in (' ', ':'))
     ) a
) a
where RANK = 1;

CREATE OR REPLACE TRIGGER V_DOCUMENT_SCAN_AI_TEXT_LINE_VALUES_UPD
INSTEAD OF UPDATE ON V_DOCUMENT_SCAN_AI_TEXT_LINE_VALUES 
FOR EACH ROW
BEGIN
	if :old.field_label IS NULL AND :new.field_label IS NOT NULL then 
		INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code, config_id)
		values (:new.Document_type, 
				:new.field_label, 
				REGEXP_REPLACE(:new.text_line, ':.*', ''), 
				:new.language_code,
				:new.config_id);
	elsif :old.field_label IS NOT NULL AND :new.field_label IS NULL then 
		DELETE FROM DOCUMENT_SCAN_AI_FIELD_ALIAS 
		WHERE Document_type = :old.Document_type
		AND Field_label = :old.field_label
		AND field_alias = REGEXP_REPLACE(:old.text_line, ':.*', '')
		AND language_code = :old.language_code
		AND config_id = :old.config_id;
	end if;
END;
/


