DELETE FROM DOCUMENT_SCAN_AI_FIELD_ALIAS WHERE config_id = 1 and language_code = 'DEU';
/*
----------------------
Query für Alias-Namen:
select Field_Label||':' Field_Label, LISTAGG(field_alias, ', ') WITHIN GROUP (ORDER BY field_alias) list
from DOCUMENT_SCAN_AI_FIELD_ALIAS
where Language_Code = 'DEU'
group by Field_Label
order by Field_Label;
*/

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerName',	'Name des Auftraggebers', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerName',	'Kundenname', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kundennummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kunden-Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kunden-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kundennr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kundennr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kd Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Kdn-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerId',	'Ihre Kundennummer', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PurchaseOrder',	'Bestellnummer', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnungs-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnung Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnungsnummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnungsnr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnung-Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnung-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechnung', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Belegnummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Beleg-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Beleg Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Re.- Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Rechn.-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Re-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Re-Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'RG Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Schlussrechnungsnummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'Zahlungsreferenz', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'HONORARNOTE NR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'HONORARNOTE NR.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceId',	'HONORARNOTE', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceDate',	'Datum', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceDate',	'Rechnungsdatum', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceDate',	'Leistungsdatum', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'Fllig am', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'Flligkeit', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'Falligkeit', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'Flligkeitsdatum', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'Falligkeitsdatum', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'Zahlungstermin', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'DueDate',	'zahlbar bis', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'EmpfngerIn', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'EmpfngerIn Name/Firma', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'Empfangerin Name/firma', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'Name des Empfngers', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'Abs', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'Absender', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorName',	'Lieferantenname', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UID', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UID Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UID Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UID-Nr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UID-Nr', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UID-Nummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'Unsere UID-Nummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'Unsere UID- Nummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'Umsatzsteuer-ID', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'Unsere UID', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'USt.-ID', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'UST-ID NR.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorTaxId',	'Ust-IdNr (VAT n )', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorAddress',	'Lieferantenadresse', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorAddressRecipient',	'Lieferantenadresse Empfnger', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerAddress',	'Kundenadresse', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'CustomerAddressRecipient',	'Kundenadresse Empfnger', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BillingAddress',	'Rechnungsadresse', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BillingAddressRecipient',	'Rechnungsadresse Empfnger', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ShippingAddress',	'Lieferadresse', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ShippingAddressRecipient',	'Lieferadresse Empfnger', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PaymentTerm',	'Zahlungsbedingungen', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PaymentTerm',	'Zahlungsbedingung', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PaymentTerm',	'Zahlungsziel', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Netto Gesamtbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Netto EUR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Netto in EUR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Gesamt EUR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Netto Euro', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Betrag Netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Betrag netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Nettosumme', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Nettobetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Rechnungsbetrag netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Gesamtbetrag netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Betrag exkl. USt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Zwischensumme Netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Rechnungssumme netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Summe Netto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Zwischensumme', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'SubTotal',	'Summe', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalTax',	'Gesamtsteuer', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TaxRate',	'Ust%', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TaxRate',	'Ust %', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TaxRate',	'% Umsatzsteuer', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Gesamtmehrwertsteuer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Mehrwertsteuer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'+ MwSt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'MwSt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'MwSt.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'MwSt EUR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Mwst.-Betrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'USt.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Ust. 10%', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Ust-Betr.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'20 % USt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'20% USt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'20 % MWST', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'20% MwSt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Betrag Ust. 20%', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Betrag USt. 20%', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'zzgl. Umsatzsteuer 20%', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'zuziglich 19% MwSt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Umsatzsteuer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Betrag 20 %USt.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'Summe USt (EUR)', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'20% Umsatzsteuer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'+ 20 % Umsatzsteuer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'zzgl. 20% gesetzlicher MwSt.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'TotalVAT',	'20 % Mehrwertsteuer', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Rechnungsumme Brutto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Endbetrag EUR (brutto)', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamtsumme', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamtbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamtbetrag brutto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamtbetrag (inkl. USt)', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamt EUR inkl. MwSt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamt-Summe', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Summe', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Summe Brutto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Summe Brutto (EUR)', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Gesamt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'= Gesamt', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Rechnungsbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Rechnungsbetrag in EUR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'anweisbarer Betrag brutto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Zu begleichende Forderungen', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Rechnungsbetrag bto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'NACHTRAGSPRAMIE', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Brutto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Brutto in EUR', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Betrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'[Cent', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceTotal',	'Icent', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Summe', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Flliger Betrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Zahlungsbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Zu zahlender Betrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Zu zahlender Betrag in Euro', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'berweisungsbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Wir ersuchen um berweisung auf unser Konto', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'ein Kostenrestbetrag in Hhe von', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Rest', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'offener Gesamtbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Zahlbar', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'AmountDue',	'Offener Betrag', 'DEU');


INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceAddress',	'Serviceadresse', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceAddress',	'Dienstleistungsadresse', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceAddress',	'Serviceanschrift', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceAddressRecipient',	'Serviceadresse Empfnger', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'RemittanceAddress',	'Zahlungsadresse', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'RemittanceAddressRecipient',	'Zahlungsadresse Empfnger', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ShippingCost',	'Versandkosten', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceStartDate',	'Service Startdatum', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceStartDate',	'Startdatum der Dienstleistung', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceStartDate',	'Dienstleistungsbeginn', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceStartDate',	'Leistungszeitraum von', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceStartDate',	'Lieferung/Leistung vom', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceEndDate',	'Service Enddatum', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceEndDate',	'Enddatum der Dienstleistung', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'ServiceEndDate',	'Dienstleistungsende', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PreviousUnpaidBalance',	'Restforderung', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PreviousUnpaidBalance',	'Vorschreibungsbetrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PreviousUnpaidBalance',	'Vorheriger unbezahlter Betrag', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'PreviousUnpaidBalance',	'Vorheriger offener Betrag', 'DEU');

-- extra custom field types
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceReceiptDate','EINGEGANGEN', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoiceReceiptDate', 'EINGANG', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'InvoicePaidDate', 'BEZAHLT', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorEmail',	'Lieferanten E-Mail', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorEmail',	'E-Mail', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorEmail',	'Email', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorEmail',	'E-Mail-Adresse', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorPhone',	'Telefon', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorPhone',	'Tel.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorPhone',	'Tel', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorMobil',	'Mobil', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'VendorMobil',	'Mobil.', 'DEU');



INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC.', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'Swift Code', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC-Code', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'Swift', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'SWIFT Code', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC (SWIFT-Code) der Empfngerbank', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC(SWIFT-Code) der Empfngerbank', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC(SWIFT-Code) der Empfangerbank', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'SWIFT/BIC', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankBIC',	'BIC/SWIFT Empfngerbank', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankIBAN',	'IBAN (EUR)', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankIBAN',	'IBAN', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankIBAN',	'IBAN Code', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankIBAN',	'IBAN-Code', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankIBAN',	'IBAN Nummer', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankIBAN',	'IBANEmpfngerin', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'Ignored',	'IBAN KontoinhaberIn/Auftraggeberin', 'DEU');
INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'Ignored',	'IBANKontomhaberIn/Auftraggeberin', 'DEU');

INSERT INTO DOCUMENT_SCAN_AI_FIELD_ALIAS (Document_type, Field_label, field_alias, language_code)
VALUES ('INVOICE', 'BankPurpose',	'Verwendungszweck', 'DEU');
COMMIT;
