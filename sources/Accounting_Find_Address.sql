CREATE OR REPLACE FUNCTION Document_Scan_AI_Find_Address (
	p_Search IN VARCHAR2,						-- search string with name and address
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
)
RETURN NUMBER 
IS 
    l_Workspace_Name 	varchar2(100) := 'KITZBUEHEL_ALPS';
	l_Client_address_id WECO_TOWER1.ADRESSEN_BT.ID%TYPE;
	l_Client_Name		VARCHAR2(1000);
	l_Client_Address	VARCHAR2(1000);
	l_Client_Logo		VARCHAR2(1000);
	l_Client_Email		WECO_TOWER1.ADRESSEN_BT.EMAIL%TYPE;
	l_Client_TaxID		WECO_TOWER1.MANDANTEN_BT.USTIDNR%TYPE;
	l_Client_IBAN 		WECO_TOWER1.BANKVERBINDUNG_BT.IBAN%TYPE;
	l_Client_SWIFTBIC	WECO_TOWER1.BANKVERBINDUNG_BT.SWIFT_BIC%TYPE;
	l_Vendor_Phone 		WECO_TOWER1.ADRESSEN_BT.TELEFON1%TYPE;
    l_Search 			varchar2(2000);
    l_Vendor_Name_Search 	varchar2(2000);
    l_Vendor_Address_Search varchar2(2000);
    l_Vendor_Logo_Search 	varchar2(2000);
	l_address_id 		NUMBER;
    l_Count 			NUMBER := 0;

	CURSOR cr_address_email_phone(v_Email VARCHAR2, v_Phone VARCHAR2) IS
		WITH WORKSPACE AS (
			SELECT WORKSPACE$_ID 
			FROM WECO_TOWER1.USER_NAMESPACES 
			WHERE WORKSPACE_NAME = l_Workspace_Name
		)
		SELECT MAX(A.ID) ID, COUNT(DISTINCT A.MANDANTENID) CNT
		FROM WORKSPACE WS
		JOIN WECO_TOWER1.ADRESSEN_BT A ON A.WORKSPACE$_ID = WS.WORKSPACE$_ID
		JOIN WECO_TOWER1.MANDANTEN_BT M ON M.ID = A.MANDANTENID AND M.WORKSPACE$_ID = A.WORKSPACE$_ID
		WHERE (UPPER(A.EMAIL) = UPPER(v_Email)
			OR TRANSLATE( A.TELEFON1, '0-/().:,;+# ', '0' ) = v_Phone
			OR TRANSLATE( A.TELEFON2, '0-/().:,;+# ', '0' ) = v_Phone
		)
		AND (A.ID != l_Client_address_id OR l_Client_address_id IS NULL);

	CURSOR cr_address_tax_id(v_Tax_ID VARCHAR2) IS
		WITH WORKSPACE AS (
			SELECT WORKSPACE$_ID 
			FROM WECO_TOWER1.USER_NAMESPACES 
			WHERE WORKSPACE_NAME = l_Workspace_Name
		)
		SELECT MAX(A.ID) ID, COUNT(DISTINCT A.MANDANTENID) CNT
		FROM WORKSPACE WS
		JOIN WECO_TOWER1.ADRESSEN_BT A ON A.WORKSPACE$_ID = WS.WORKSPACE$_ID
		JOIN WECO_TOWER1.MANDANTEN_BT M ON M.WORKSPACE$_ID = WS.WORKSPACE$_ID AND A.MANDANTENID = M.ID
		WHERE REPLACE(M.USTIDNR, ' ') = REPLACE(v_Tax_ID, ' ')
		AND (A.ID != l_Client_address_id OR l_Client_address_id IS NULL);

	CURSOR cr_address_iban_bic(v_IBAN VARCHAR2, v_SWIFT_BIC VARCHAR2) IS
		WITH WORKSPACE AS (
			SELECT WORKSPACE$_ID 
			FROM WECO_TOWER1.USER_NAMESPACES 
			WHERE WORKSPACE_NAME = l_Workspace_Name
		)
		SELECT MAX(A.ID) ID, COUNT(DISTINCT A.MANDANTENID) CNT
		FROM WORKSPACE WS
		JOIN WECO_TOWER1.ADRESSEN_BT A ON A.WORKSPACE$_ID = WS.WORKSPACE$_ID
		JOIN WECO_TOWER1.MANDANTEN_BT M ON M.ID = A.MANDANTENID AND M.WORKSPACE$_ID = A.WORKSPACE$_ID
		JOIN WECO_TOWER1.BANKVERBINDUNG_BT BV 
			ON BV.WORKSPACE$_ID = WS.WORKSPACE$_ID AND A.MANDANTENID = BV.MANDANTENID
		WHERE REPLACE(BV.IBAN, ' ') LIKE REPLACE(v_IBAN, ' ')||'%'
		AND (BV.SWIFT_BIC LIKE v_SWIFT_BIC||'%' 
			OR v_SWIFT_BIC LIKE REPLACE(BV.SWIFT_BIC, 'X', '_')
			OR BV.SWIFT_BIC IS NULL OR v_SWIFT_BIC IS NULL)
		AND (A.ID != l_Client_address_id OR l_Client_address_id IS NULL);


	CURSOR cr_Client_address(v_Context_ID NUMBER) IS
		WITH WORKSPACE AS (
			SELECT WORKSPACE$_ID 
			FROM WECO_TOWER1.USER_NAMESPACES 
			WHERE WORKSPACE_NAME = l_Workspace_Name
		)
		SELECT AG.ADRESSENID,
				NVL(TRIM(TRANSLATE(A.NAME || ' ' || A.VORNAME, '-ÖÄÜöäüß', '-')), '-') AS CLIENT_NAME,
				NVL(TRIM(TRANSLATE(A.STRASSE || ' ' || A.PLZ || ' ' || A.ORT, '-ÖÄÜöäüß', '-')), '-') AS CLIENT_ADDRESS,
				NVL(TRIM(TRANSLATE(A.FIRMA1, '-ÖÄÜöäüß', '-')), '-') AS CLIENT_LOGO,
				A.EMAIL, M.USTIDNR, BV.IBAN, BV.SWIFT_BIC
		FROM WORKSPACE WS
		JOIN WECO_TOWER1.PROJEKTE_BT P ON P.WORKSPACE$_ID = WS.WORKSPACE$_ID
		JOIn WECO_TOWER1.AUFTRAGGEBER_BT AG ON AG.WORKSPACE$_ID = WS.WORKSPACE$_ID AND AG.ID = P.AUFTRAGGEBERID
		JOIN WECO_TOWER1.ADRESSEN_BT A ON A.WORKSPACE$_ID = WS.WORKSPACE$_ID AND A.ID = AG.ADRESSENID
		JOIN WECO_TOWER1.MANDANTEN_BT M ON M.WORKSPACE$_ID = WS.WORKSPACE$_ID AND A.MANDANTENID = M.ID
		LEFT OUTER JOIN WECO_TOWER1.BANKVERBINDUNG_BT BV 
			ON BV.WORKSPACE$_ID = WS.WORKSPACE$_ID AND A.MANDANTENID = BV.MANDANTENID
		WHERE P.ID = v_Context_ID;

	CURSOR cr_address_search(v_Vendor_Name VARCHAR2, v_Vendor_Address VARCHAR2, v_Vendor_Logo VARCHAR2, v_Search VARCHAR2) IS
		WITH WORKSPACE AS (
			SELECT WORKSPACE$_ID 
			FROM WECO_TOWER1.USER_NAMESPACES 
			WHERE WORKSPACE_NAME = l_Workspace_Name
		)
		SELECT A.ID 
		FROM (
			SELECT A.ID, FIRST_VALUE(A.ID) OVER (ORDER BY SCORE(1)+SCORE(2)+SCORE(3)+SCORE(4) DESC ) MATCH1
			FROM WORKSPACE WS
			JOIN WECO_TOWER1.ADRESSEN_BT A ON A.WORKSPACE$_ID = WS.WORKSPACE$_ID
			JOIN WECO_TOWER1.MANDANTEN_BT M ON M.ID = A.MANDANTENID AND M.WORKSPACE$_ID = A.WORKSPACE$_ID
			WHERE (CONTAINS(A.NAME, v_Vendor_Name, 1) > 1
				OR CONTAINS(A.NAME, v_Vendor_Address, 2) > 1
				OR CONTAINS(A.NAME, v_Vendor_Logo, 3) > 1
				OR CONTAINS(A.NAME, v_Search, 4) > 1
			)
		) A
		WHERE A.ID = A.MATCH1
		AND (A.ID != l_Client_address_id OR l_Client_address_id IS NULL)
		;

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
		-- before: 	<score datatype="INTEGER" algorithm="COUNT"/> 

		l_Search varchar2(32767);
	begin
		-- remove special characters; irrelevant for full text search
		l_search := translate( p_search, '-[<>{}/()*%&!$?.:,;\+#]', ' ' );
		return apex_string.format( c_xml, p_Language, l_Search );
	end oracle_text_token_search;
BEGIN 
	if p_Context_ID IS NOT NULL then 
		OPEN cr_Client_address(p_Context_ID);
		FETCH cr_Client_address INTO l_Client_address_id, l_Client_Name, l_Client_Address, l_Client_Logo,
				l_Client_Email, l_Client_TaxID, l_Client_IBAN, l_Client_SWIFTBIC;
		CLOSE cr_Client_address;	
	end if;

	if p_Search_Project_Client = 'N' then 
		l_Vendor_Phone := translate( p_Phone, '0-/().:,;+# ', '0' );
		if p_Email != nvl(l_Client_Email,'-') or l_Vendor_Phone IS NOT NULL then 
			OPEN cr_address_email_phone(p_Email, l_Vendor_Phone);
			FETCH cr_address_email_phone INTO l_address_id, l_Count;
			CLOSE cr_address_email_phone;
		end if;
		if p_Tax_ID != nvl(l_Client_TaxID, '-') and l_Count != 1 then 
			OPEN cr_address_tax_id(p_Tax_ID);
			FETCH cr_address_tax_id INTO l_address_id, l_Count;
			CLOSE cr_address_tax_id;
		end if;
		if p_IBAN IS NOT NULL and l_Count != 1 then 
			OPEN cr_address_iban_bic(p_IBAN, p_SWIFT_BIC);
			FETCH cr_address_iban_bic INTO l_address_id, l_Count;
			CLOSE cr_address_iban_bic;
		end if;
		if l_Count != 1 and coalesce(p_Vendor_Name, p_Vendor_Address, p_Vendor_Logo, p_Search) IS NOT NULL then 
			l_Vendor_Name_Search    := case when INSTR(UPPER(p_Vendor_Name), UPPER(l_Client_Name)) = 0 then p_Vendor_Name else 'x2' end;
			l_Vendor_Address_Search := case when INSTR(UPPER(p_Vendor_Address), UPPER(l_Client_Address)) = 0 then p_Vendor_Address else 'x3' end;
			l_Vendor_Logo_Search    := case when INSTR(UPPER(p_Vendor_Logo), UPPER(l_Client_Logo)) = 0 then p_Vendor_Logo else 'x4' end;
			apex_debug.message('cr_address_search - Search: %s, Name_Search: %s, Address_Search: %s, Logo_Search: %s',
								l_Search, l_Vendor_Name_Search, l_Vendor_Address_Search, l_Vendor_Logo_Search);
			l_Search                := oracle_text_token_search(nvl(p_Search,'x1'), p_Language);
			l_Vendor_Name_Search    := oracle_text_token_search(l_Vendor_Name_Search, p_Language);
			l_Vendor_Address_Search := oracle_text_token_search(l_Vendor_Address_Search, p_Language);
			l_Vendor_Logo_Search    := oracle_text_token_search(l_Vendor_Logo_Search, p_Language);
			OPEN cr_address_search(l_Vendor_Name_Search, l_Vendor_Address_Search, l_Vendor_Logo_Search, l_Search);
			FETCH cr_address_search INTO l_address_id;
			CLOSE cr_address_search;
		end if;
	elsif l_Client_address_id IS NOT NULL then
		l_address_id := l_Client_address_id;
	elsif p_Search IS NOT NULL then
		l_Search := oracle_text_token_search(p_Search, p_Language);
		OPEN cr_address_search(l_Vendor_Name_Search, l_Vendor_Address_Search, l_Vendor_Logo_Search, l_Search);
		FETCH cr_address_search INTO l_address_id;
		CLOSE cr_address_search;
	end if;
	RETURN l_address_id;
exception when NO_DATA_FOUND then
	RETURN NULL;
END Document_Scan_AI_Find_Address;
/

