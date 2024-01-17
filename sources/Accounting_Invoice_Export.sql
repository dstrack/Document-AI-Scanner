declare 
	v_count NUMBER;
	v_stat VARCHAR2(32767);
	v_Schema VARCHAR2(50) := 'PLAYGROUND';
begin
	SELECT COUNT(*) INTO v_count
	FROM USER_OBJECTS WHERE OBJECT_NAME = 'V_DOCUMENT_SCAN_AI_INVOICES';
	if v_count = 0 then 
		v_stat := 'CREATE OR REPLACE SYNONYM V_DOCUMENT_SCAN_AI_INVOICES FOR '||v_Schema||'.V_DOCUMENT_SCAN_AI_INVOICES';
		EXECUTE IMMEDIATE v_Stat;
	end if;
	SELECT COUNT(*) INTO v_count
	FROM USER_OBJECTS WHERE OBJECT_NAME = 'V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE';
	if v_count = 0 then 
		v_stat := 'CREATE OR REPLACE SYNONYM V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE FOR '||v_Schema||'.V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE';
		EXECUTE IMMEDIATE v_Stat;
	end if;
	SELECT COUNT(*) INTO v_count
	FROM USER_OBJECTS WHERE OBJECT_NAME = 'V_DOCUMENT_SCAN_AI_DOC_FILES';
	if v_count = 0 then 
		v_stat := 'CREATE OR REPLACE SYNONYM V_DOCUMENT_SCAN_AI_DOC_FILES FOR '||v_Schema||'.V_DOCUMENT_SCAN_AI_DOC_FILES';
		EXECUTE IMMEDIATE v_Stat;
	end if;
end;
/
/*
CREATE OR REPLACE SYNONYM V_DOCUMENT_SCAN_AI_INVOICES FOR PLAYGROUND.V_DOCUMENT_SCAN_AI_INVOICES;
CREATE OR REPLACE SYNONYM V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE FOR PLAYGROUND.V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE;
CREATE OR REPLACE SYNONYM V_DOCUMENT_SCAN_AI_DOC_FILES FOR PLAYGROUND.V_DOCUMENT_SCAN_AI_DOC_FILES;

DROP SYNONYM V_DOCUMENT_SCAN_AI_INVOICES;
DROP SYNONYM V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE;
DROP SYNONYM V_DOCUMENT_SCAN_AI_DOC_FILES;
*/

declare 
	v_count NUMBER;
	v_stat VARCHAR2(32767);
begin
	SELECT COUNT(*) INTO v_count
	FROM USER_TAB_COLUMNS WHERE TABLE_NAME = 'BELEGZAHLUNG_BT' AND COLUMN_NAME = 'SCAN_JOB_ID';
	if v_count = 0 then 
		v_stat := q'[
		ALTER TABLE BELEGZAHLUNG_BT ADD (
			scan_job_id 		NUMBER,
			scan_document_id	NUMBER
		)
		]';
		EXECUTE IMMEDIATE v_Stat;
	end if;
end;
/


CREATE OR REPLACE VIEW V_DOCUMENT_SCAN_AI_INVOICE_EXPORT (
	DOCUMENT_ID, JOB_ID, FILE_NAME, DOC_USTIDNR, WORKSPACE$_ID, 
	EINGANGSDATUM, FAELLIGKEITSDATUM, BELEGDATUM, BELEGJAHR, 
	ABRECHNUNGSJAHR, POSTEN_NR, FORDERUNG, GEAENDERTE_FORDERUNG, 
	PROJEKTEID, ADRESSENID, RECHNUNGSTEXT, 
	LFD_NR_KEY, EMPFAENGERID, AUFTRAGEGEBER, KOSTENSTELLENID, 
	WAEHRUNGFORDERUNG, WAEHRUNGZAHLBETRAG, PRUEFERID, PRUEFERID2, 
	UST_CODE, UST_CODE2, STATUSID, STELLERID, USTIDNR, FIBU_NR, RECHNUNGSSTELLER, 
	WERKVERTRAGID, KOSTENARTENID, KOSTENART, BANKVERBINDUNGID, IBAN
) AS
WITH WORKSPACE AS (
	SELECT WORKSPACE$_ID FROM USER_NAMESPACES 
	WHERE WORKSPACE_NAME = 'KITZBUEHEL_ALPS'
), IMPORT_DOCS AS (
    SELECT I.Context_Id       PROJEKTEID, 
		I.Vendoraddress_Id	  ADRESSENID,
		COALESCE(I.Invoice_Receipt_Date, I.Invoice_Date+1, I.Creation_Date)  EINGANGSDATUM,
		I.Due_Date            FAELLIGKEITSDATUM, 
		I.Invoice_Date        BELEGDATUM, 
		TO_CHAR(NVL(I.Invoice_Date, I.Creation_Date), 'YYYY') BELEGJAHR,
		TO_CHAR(NVL(I.Invoice_Date, I.Creation_Date), 'YYYY') ABRECHNUNGSJAHR,
		SUBSTR(I.Invoice_Id, 1, 20)	POSTEN_NR, 
		NVL(I.Invoice_Total, 0.01) FORDERUNG,
		NVL(I.Invoice_Total, 0.01) GEAENDERTE_FORDERUNG,
		I.Vendor_Tax_Id       	USTIDNR,
		I.FILE_NAME 			FILE_NAME,
		I.JOB_ID				JOB_ID,
		I.DOCUMENT_ID 			DOCUMENT_ID,
		AG.NAME             	AUFTRAGEGEBER,
		P.AUFTRAGGEBERID    	EMPFAENGERID, 
		P.KOSTENSTELLENID   	KOSTENSTELLENID, 
		NVL(P.Waehrung, V.WAEHRUNG_KUERZEL) WAEHRUNGFORDERUNG,  
		NVL(P.Waehrung, V.WAEHRUNG_KUERZEL)	WAEHRUNGZAHLBETRAG,  
		P.Hauptverantwortlicher1_Id PRUEFERID, 
		P.Hauptverantwortlicher2_Id PRUEFERID2,
		V.UMSATZSTEUERCODE  	UST_CODE,
		V.UMSATZSTEUERCODE  	UST_CODE2,
		P.WORKSPACE$_ID			WORKSPACE$_ID
	FROM WORKSPACE WS 
    CROSS JOIN V_DOCUMENT_SCAN_AI_INVOICES I
	JOIN VORGABEN_BT V ON V.WORKSPACE$_ID = WS.WORKSPACE$_ID
    LEFT OUTER JOIN PROJEKTE_BT P ON P.WORKSPACE$_ID = WS.WORKSPACE$_ID AND I.Context_Id = P.Id
	LEFT OUTER JOIN AUFTRAGGEBER_BT AG ON AG.ID = P.AUFTRAGGEBERID AND AG.WORKSPACE$_ID = WS.WORKSPACE$_ID
), IMPORT_DESCRIPTION AS (
	SELECT DOCUMENT_ID, JOB_ID, 
		SUBSTR(NVL(LISTAGG(Description, chr(13) ON OVERFLOW TRUNCATE)  
			WITHIN GROUP (ORDER BY page_number, line_number), file_name), 1, 180) RECHNUNGSTEXT
	from V_DOCUMENT_SCAN_AI_LINE_ITEM_INVOICE
	group by document_id, job_id, file_name
), PROJECT_ADRRESS AS (
	SELECT
		P.Id                PROJEKTEID, 
        P.WORKSPACE$_ID     WORKSPACE$_ID,
		A.MANDANTENID       STELLERID,
		M.USTIDNR           USTIDNR,
		M.KREDITORENID      FIBU_NR,
		M.NAME              RECHNUNGSSTELLER,
		W.ID                WERKVERTRAGID,
		W.KOSTENARTENID     KOSTENARTENID,
		K.BEZEICHNUNG       KOSTENART,
		A.ID                ADRESSENID,
		B.ID                BANKVERBINDUNGID,
		B.IBAN              IBAN, 
		DENSE_RANK() OVER (PARTITION BY A.MANDANTENID, P.AUFTRAGGEBERID 
			ORDER BY W.ID, B.AUFTRAGGEBERID NULLS LAST, B.ERFASST_DATUM DESC) RANK
	FROM WORKSPACE WS
    JOIN PROJEKTE_BT P ON P.WORKSPACE$_ID = WS.WORKSPACE$_ID
	JOIN WERKVERTRAG_BT W ON W.PROJEKTEID = P.ID AND W.WORKSPACE$_ID = WS.WORKSPACE$_ID
	LEFT OUTER JOIN MANDANTEN_BT M ON W.AUFTRAGNEHMERID = M.ID AND M.WORKSPACE$_ID = WS.WORKSPACE$_ID
	LEFT OUTER JOIN ADRESSEN_BT A ON M.ID = A.MANDANTENID AND A.WORKSPACE$_ID = WS.WORKSPACE$_ID
	LEFT OUTER JOIN BANKVERBINDUNG_BT B
		ON B.MANDANTENID = A.MANDANTENID AND B.WORKSPACE$_ID = WS.WORKSPACE$_ID
		AND (B.AUFTRAGGEBERID = P.AUFTRAGGEBERID OR B.AUFTRAGGEBERID IS NULL)
	LEFT OUTER JOIN KOSTENARTEN_BT K ON W.KOSTENARTENID = K.ID AND K.WORKSPACE$_ID = WS.WORKSPACE$_ID
	UNION ALL 
	SELECT
		P.Id                PROJEKTEID, 
        P.WORKSPACE$_ID     WORKSPACE$_ID,
		A.MANDANTENID       STELLERID,
		M.USTIDNR           USTIDNR,
		M.KREDITORENID      FIBU_NR,
		M.NAME              RECHNUNGSSTELLER,
		NULL                WERKVERTRAGID,
		NULL                KOSTENARTENID,
		NULL                KOSTENART,
		A.ID                ADRESSENID,
		B.ID                BANKVERBINDUNGID,
		B.IBAN              IBAN, 
		DENSE_RANK() OVER (PARTITION BY A.MANDANTENID, P.AUFTRAGGEBERID 
			ORDER BY B.AUFTRAGGEBERID NULLS LAST, B.ERFASST_DATUM DESC) RANK
	FROM WORKSPACE WS
    JOIN PROJEKTE_BT P ON P.WORKSPACE$_ID = WS.WORKSPACE$_ID
	LEFT OUTER JOIN MANDANTEN_BT M ON M.WORKSPACE$_ID = WS.WORKSPACE$_ID
	LEFT OUTER JOIN ADRESSEN_BT A ON M.ID = A.MANDANTENID AND A.WORKSPACE$_ID = WS.WORKSPACE$_ID
	LEFT OUTER JOIN BANKVERBINDUNG_BT B
		ON B.MANDANTENID = A.MANDANTENID AND B.WORKSPACE$_ID = WS.WORKSPACE$_ID
		AND (B.AUFTRAGGEBERID = P.AUFTRAGGEBERID OR B.AUFTRAGGEBERID IS NULL)
	WHERE NOT EXISTS (
		SELECT 1 
		FROM WERKVERTRAG_BT W 
		WHERE W.PROJEKTEID = P.ID 
		AND W.WORKSPACE$_ID = WS.WORKSPACE$_ID
		AND W.AUFTRAGNEHMERID = M.ID 
	)
) 
SELECT D.DOCUMENT_ID,
	D.JOB_ID,
	D.FILE_NAME,
	D.USTIDNR DOC_USTIDNR,
	D.WORKSPACE$_ID,
	D.EINGANGSDATUM,
	D.FAELLIGKEITSDATUM,
	D.BELEGDATUM,
	D.BELEGJAHR,
	D.ABRECHNUNGSJAHR,
	D.POSTEN_NR,
	D.FORDERUNG, 
	D.GEAENDERTE_FORDERUNG,
	D.PROJEKTEID, 
	P.ADRESSENID,
	DS.RECHNUNGSTEXT, 
	('ER' || D.BELEGJAHR || '/' || D.EMPFAENGERID) LFD_NR_KEY,
	D.EMPFAENGERID,
	D.AUFTRAGEGEBER,
	D.KOSTENSTELLENID,
	D.WAEHRUNGFORDERUNG,
	D.WAEHRUNGZAHLBETRAG,
	D.PRUEFERID,
	D.PRUEFERID2,
	D.UST_CODE,
	D.UST_CODE2,
	10 STATUSID,
	P.STELLERID,
	P.USTIDNR,
	P.FIBU_NR,
	P.RECHNUNGSSTELLER,
	P.WERKVERTRAGID,
	P.KOSTENARTENID,
	P.KOSTENART,
	P.BANKVERBINDUNGID,
	P.IBAN
FROM IMPORT_DOCS D 
LEFT OUTER JOIN IMPORT_DESCRIPTION DS ON D.JOB_ID = DS.JOB_ID AND D.DOCUMENT_ID = DS.DOCUMENT_ID
LEFT OUTER JOIN PROJECT_ADRRESS P ON P.ADRESSENID = D.ADRESSENID AND P.PROJEKTEID = D.PROJEKTEID AND P.RANK = 1
;

CREATE OR REPLACE VIEW V_DOCUMENT_SCAN_AI_INVOICE_UPDATE
AS
with WORKSPACE as (
	SELECT WORKSPACE$_ID FROM USER_NAMESPACES 
	WHERE WORKSPACE_NAME = 'KITZBUEHEL_ALPS'
)
select 
    apex_item.checkbox (30, B.ID, NULL, NULL, ':', 'f30_'||ROWNUM) as CHECKBOX,
	I.Context_Id     	PROJEKTEID, 
	P.AUFTRAGGEBERID	AUFTRAGGEBERID,
	I.Job_Id			JOB_ID,
	I.Document_Id 		DOCUMENT_ID,
	B.ID 				BELEGZAHLUNGID,
	B.BANKVERBINDUNGID	BANKVERBINDUNGID,
	I.Vendoraddress_Id	ADRESSENID,
	A.MANDANTENID		MANDANTENID,
	SUBSTR(I.Invoice_Id, 1, 20)	POSTEN_NR_NEU, 
	I.Invoice_Receipt_Date  EINGANG_NEU,
	I.Due_Date          FAELLIG_NEU, 
	I.Invoice_Paid_Date	ZAHLDATUM_NEU,
	I.Invoice_Date      BELEGDATUM_NEU, 
	I.Invoice_Total     FORDERUNG_NEU,
	COALESCE(I.Amount_Due, I.Invoice_Total) GEA_FORDERUNG_NEU,
	I.Vendor_Tax_Id     USTIDNR_NEU,
	I.Tax_Rate			STEUERSATZ_NEU,
	case when I.Tax_Rate = 0 
		then '001'
		else S.CODE
	end UST_CODE_NEU,
	I.Vendor_Email		EMAIL_NEU,
	I.Vendor_Phone		TELEFON1_NEU,
	I.Vendor_Mobil		TELEFON2_NEU,
	I.Bank_BIC			SWIFT_BIC_NEU,
	REPLACE(I.Bank_IBAN, ' ') IBAN_NEU,
	I.Customer_Id		KUNDEN_NR_NEU,
	I.Bank_Purpose		VERWENDUNGSZWECK_NEU,
	B.POSTEN_NR, B.EINGANGSDATUM, B.FAELLIGKEITSDATUM, B.BELEGDATUM,
	B.FORDERUNG, B.GEAENDERTE_FORDERUNG, B.UST_CODE, B.VERWENDUNGSZWECK,
	B.SECKEY_KREDITOR,
	A.TELEFON1, A.TELEFON2, A.EMAIL,
	M.NAME, M.USTIDNR,
	BV.IBAN, BV.SWIFT_BIC, BV.KD_NR
from WORKSPACE WS
join BELEGZAHLUNG_BT B on B.WORKSPACE$_ID = WS.WORKSPACE$_ID
join V_DOCUMENT_SCAN_AI_INVOICES I on B.SCAN_DOCUMENT_ID = I.DOCUMENT_ID
join PROJEKTE_BT P on P.ID = I.Context_Id and P.WORKSPACE$_ID = WS.WORKSPACE$_ID
left outer join MANDANTEN_BT M on M.ID = B.STELLERID and M.WORKSPACE$_ID = WS.WORKSPACE$_ID
left outer join ADRESSEN_BT A on A.ID = B.ADRESSENID and A.WORKSPACE$_ID = WS.WORKSPACE$_ID
left outer join BANKVERBINDUNG_BT BV on BV.ID = B.BANKVERBINDUNGID and A.WORKSPACE$_ID = WS.WORKSPACE$_ID
left outer join STEUERSATZ_BT S on S.STEUERSATZ = I.Tax_Rate 
	and SUBSTR(S.CODE, 1, 2) = SUBSTR(BV.IBAN, 1, 2) 
	and S.WORKSPACE$_ID = WS.WORKSPACE$_ID
;


CREATE OR REPLACE VIEW V_DOCUMENT_SCAN_AI_CONTEXT AS
SELECT P.ID, P.NAME, AG.ADRESSENID
FROM USER_NAMESPACES WS
JOIN PROJEKTE_BT P ON P.WORKSPACE$_ID = WS.WORKSPACE$_ID
JOIN AUFTRAGGEBER_BT AG ON AG.WORKSPACE$_ID = WS.WORKSPACE$_ID AND AG.ID = P.AUFTRAGGEBERID
WHERE WS.WORKSPACE_NAME = 'KITZBUEHEL_ALPS'
;

CREATE OR REPLACE VIEW V_DOCUMENT_SCAN_AI_CONTEXT_FIELDS (
	ID, Client_Name, Client_Email, Client_Tax_Id,
	Client_Phone, Client_IBAN, Client_SWIFT_BIC
) AS 
SELECT P.ID 
	, A.NAME Client_Name
	, A.EMAIL Client_Email
	, M.USTIDNR Client_Tax_Id
	, A.TELEFON1 Client_Phone
	, BV.IBAN Client_IBAN
	, BV.SWIFT_BIC Client_SWIFT_BIC
FROM USER_NAMESPACES WS
JOIN PROJEKTE_BT P ON P.WORKSPACE$_ID = WS.WORKSPACE$_ID
JOIN AUFTRAGGEBER_BT AG ON AG.WORKSPACE$_ID = WS.WORKSPACE$_ID AND AG.ID = P.AUFTRAGGEBERID
JOIN WECO_TOWER1.MANDANTEN_BT M ON M.WORKSPACE$_ID = WS.WORKSPACE$_ID AND AG.MANDANTENID = M.ID
JOIN WECO_TOWER1.ADRESSEN_BT A ON A.WORKSPACE$_ID = WS.WORKSPACE$_ID AND AG.ADRESSENID = A.ID
LEFT OUTER JOIN WECO_TOWER1.BANKVERBINDUNG_BT BV ON BV.WORKSPACE$_ID = WS.WORKSPACE$_ID AND M.ID = BV.MANDANTENID
WHERE WS.WORKSPACE_NAME = 'KITZBUEHEL_ALPS'
;



CREATE OR REPLACE 
PROCEDURE Export_Invoice_Documents (
	p_Job_ID IN NUMBER
)
IS
	CURSOR c_doc IS
		SELECT * FROM V_DOCUMENT_SCAN_AI_INVOICE_EXPORT
		WHERE JOB_ID = p_Job_ID;
	l_doc				c_doc%ROWTYPE;   
    
    CURSOR c_file(v_document_id NUMBER) IS 
        SELECT * FROM V_DOCUMENT_SCAN_AI_DOC_FILES
        WHERE document_id = v_document_id;
	l_file				c_file%ROWTYPE;   
        
	l_Belegzahlung_Id 	BELEGZAHLUNG_BT.ID%TYPE;
	l_lfd_Nr			BELEGZAHLUNG_BT.LFD_NR%TYPE;
	l_blob				BLOB;
	l_doc_rowid 		ROWID;
BEGIN
	set_custom_ctx.Set_Current_Workspace (
   		p_Workspace_Name => 'KITZBUEHEL_ALPS',
   		p_Schema_Name => 'WECO_TOWER1'
   	);
   	set_custom_ctx.Set_Current_User (
		p_User_Name	=> V('APP_USER'),
   		p_Schema_Name => 'WECO_TOWER1'
	);
	OPEN	c_doc;
	loop 
		FETCH c_doc INTO l_doc;
		EXIT WHEN c_doc%NOTFOUND;
		l_lfd_Nr := weco_pack.Get_Lfd_Nr(l_doc.LFD_NR_KEY);
		INSERT INTO BELEGZAHLUNG_BT (
            EINGANGSDATUM, FAELLIGKEITSDATUM, BELEGDATUM, BELEGJAHR
			, ABRECHNUNGSJAHR, POSTEN_NR, FORDERUNG, GEAENDERTE_FORDERUNG
			, ADRESSENID, RECHNUNGSTEXT
			, LFD_NR, EMPFAENGERID, KOSTENSTELLENID
			, WAEHRUNGFORDERUNG, WAEHRUNGZAHLBETRAG, PRUEFERID, PRUEFERID2
			, UST_CODE, UST_CODE2, STATUSID, STELLERID
			, FIBU_NR, RECHNUNGSSTELLER
			, WERKVERTRAGID, BANKVERBINDUNGID
			, SCAN_JOB_ID, SCAN_DOCUMENT_ID, WORKSPACE$_ID
		) VALUES (
			l_doc.EINGANGSDATUM, l_doc.FAELLIGKEITSDATUM, l_doc.BELEGDATUM, l_doc.BELEGJAHR
			, l_doc.ABRECHNUNGSJAHR, l_doc.POSTEN_NR, l_doc.FORDERUNG, l_doc.GEAENDERTE_FORDERUNG
			, l_doc.ADRESSENID, l_doc.RECHNUNGSTEXT
			, l_lfd_Nr, l_doc.EMPFAENGERID, l_doc.KOSTENSTELLENID
			, l_doc.WAEHRUNGFORDERUNG, l_doc.WAEHRUNGZAHLBETRAG, l_doc.PRUEFERID, l_doc.PRUEFERID2
			, l_doc.UST_CODE, l_doc.UST_CODE2, l_doc.STATUSID, l_doc.STELLERID
			, l_doc.FIBU_NR, l_doc.RECHNUNGSSTELLER
			, l_doc.WERKVERTRAGID, l_doc.BANKVERBINDUNGID
			, l_doc.JOB_ID, l_doc.DOCUMENT_ID, l_doc.WORKSPACE$_ID	
		) RETURNING (ID) INTO l_Belegzahlung_Id;
		
        OPEN c_file(l_doc.document_id);
        FETCH c_file INTO l_file;
        if c_file%FOUND then 
			INSERT INTO Belegzahlung_Dokument_Bt (
				Datum, Filename, Belegzahlungid, Bild, 
				bild_thumbnail, Mime_Typ, Index_Format, Workspace$_Id	
			) VALUES (
				l_file.creation_date, l_file.file_name, l_Belegzahlung_Id, l_file.file_content,
				l_file.thumbnail_png, l_file.mime_type, l_file.index_format, l_doc.Workspace$_Id
			);        
        end if;
        CLOSE c_file;		
	end loop;
	CLOSE c_doc;
END Export_Invoice_Documents;
/
