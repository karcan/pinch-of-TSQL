/*
Procedure	:	dbo.kSql_CheckIdentificationWithMernis
Create Date	:	2021.05.17
Author		:	Karcan Ozbal

Description	:	Checks identity for Turkish citizens with the mernis service.

Parameter(s):	@IdentificationNumber	:	11 character identification number
				@FirstName				:	First name of person.
				@LastName				:	Last name of person.
				@BirthYear				:	Birth year of person.
				@Result (bit OUTPUT)	:	true / false result of check.

Usage		:	DECLARE @Output bit
				EXEC kSql_CheckIdentificationWithMernis 11111111111, 'Karcan', 'Özbal' , 1993, @Output OUTPUT
				SELECT @Output as Result

Dependencies:	Ole Automation:
					sp_configure 'show advanced options', 1;
					GO
					RECONFIGURE;
					GO
					sp_configure 'Ole Automation Procedures', 1;
					GO
					RECONFIGURE;
					GO

				Chilkat ActiveX:
					https://www.chilkatsoft.com/downloads_ActiveX.asp

Summary of Commits : 
############################################################################################
Date(yyyy-MM-dd hh:mm)		Author				Commit
--------------------------	------------------	--------------------------------------------
2021.05.17 19:00			Karcan Ozbal		first commit.. 
2021.05.17 19:18			Karcan Ozbal		fixed some indent problem.
############################################################################################

*/
CREATE PROCEDURE [dbo].[kSql_CheckIdentificationWithMernis] @IdentificationNumber char(11), @FirstName varchar(25) , @LastName varchar(25) , @BirthYear varchar(4), @Result bit OUTPUT
AS
BEGIN
	DECLARE @HR int
	DECLARE @ResponseStatus int
	DECLARE @RequestBody nvarchar(550)

	SET @FirstName = UPPER(@FirstName)
	SET @LastName = UPPER(@LastName)

	DECLARE @Http int
	EXEC @hr = sp_OACreate 'Chilkat_9_5_0.Http', @Http OUT
	IF @hr <> 0
	BEGIN
		PRINT 'INSTALL ActiveX on chilkatsoft.com'
		RETURN
	END

	DECLARE @SoapXML int
	EXEC @hr = sp_OACreate 'Chilkat_9_5_0.Xml', @SoapXML OUT

	EXEC sp_OASetProperty @SoapXML, 'Tag', 'soap12:Envelope'
	DECLARE @success int
	EXEC sp_OAMethod @SoapXML, 'AddAttribute', @success OUT, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance'
	EXEC sp_OAMethod @SoapXML, 'AddAttribute', @success OUT, 'xmlns:xsd', 'http://www.w3.org/2001/XMLSchema'
	EXEC sp_OAMethod @SoapXML, 'AddAttribute', @success OUT, 'xmlns:soap12', 'http://www.w3.org/2003/05/soap-envelope'

	EXEC sp_OAMethod @SoapXML, 'NewChild2', NULL, 'soap12:Body', ''
	EXEC sp_OAMethod @SoapXML, 'GetChild2', @success OUT, 0
	EXEC sp_OAMethod @SoapXML, 'NewChild2', NULL, 'TCKimlikNoDogrula', ''
	EXEC sp_OAMethod @SoapXML, 'GetChild2', @success OUT, 0
	EXEC sp_OAMethod @SoapXML, 'AddAttribute', @success OUT, 'xmlns', 'http://tckimlik.nvi.gov.tr/WS'
	EXEC sp_OAMethod @SoapXML, 'NewChild2', NULL, 'TCKimlikNo', @IdentificationNumber
	EXEC sp_OAMethod @SoapXML, 'NewChild2', NULL, 'Ad', @FirstName
	EXEC sp_OAMethod @SoapXML, 'NewChild2', NULL, 'Soyad', @LastName
	EXEC sp_OAMethod @SoapXML, 'NewChild2', NULL, 'DogumYili', @BirthYear
	EXEC sp_OAMethod @SoapXML, 'GetRoot2', NULL

	EXEC sp_OAMethod @Http, 'SetRequestHeader', NULL, 'Content-Type', 'application/soap+xml'

	EXEC sp_OAMethod @SoapXML, 'GetXml', @RequestBody OUT

	DECLARE @req int
	EXEC @hr = sp_OACreate 'Chilkat_9_5_0.HttpRequest', @req OUT
	--PRINT @RequestBody

	DECLARE @resp int
	EXEC sp_OAMethod @Http, 'PostXml', @resp OUT, 'https://tckimlik.nvi.gov.tr/Service/KPSPublic.asmx', @RequestBody, 'utf-8'

	EXEC sp_OAGetProperty @resp, 'StatusCode', @ResponseStatus OUT
	PRINT 'Response Status Code = ' + CAST(@ResponseStatus as VARCHAR)

	DECLARE @respXml int
	EXEC @hr = sp_OACreate 'Chilkat_9_5_0.Xml', @respXml OUT

	EXEC sp_OAGetProperty @resp, 'BodyStr', @RequestBody OUT
	EXEC sp_OAMethod @respXml, 'LoadXml', @success OUT, @RequestBody
	EXEC @hr = sp_OADestroy @resp

	PRINT 'Response XML:'
	EXEC sp_OAMethod @respXml, 'GetXml', @RequestBody OUT
	--PRINT @RequestBody

	EXEC @hr = sp_OADestroy @Http
	EXEC @hr = sp_OADestroy @SoapXML
	EXEC @hr = sp_OADestroy @respXml

	DECLARE @Response XML

	SELECT @Response = REPLACE(@RequestBody,'<?xml version="1.0" encoding="utf-8"?>','')

	SELECT  TOP(1) @Result = x.Rec.query('/').value('.','bit') 
	FROM  @Response.nodes('/') as x(Rec);

	RETURN 
END