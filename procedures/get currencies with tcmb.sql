/*
Procedure	:	dbo.kSql_GetCurrencyValuesWithTcmb
Create Date	:	2021.05.20
Author		:	Karcan Ozbal

Description	:	List of all currency and cross values. 

Parameter(s):	@Date		:	Date for Currencies
				@WithCross	:	1/0 for cross currencies.

Usage		:	DECLARE @Date DATE = GETDATE()
				EXEC dbo.kSql_GetCurrencyValuesWithTcmb @Date = @Date , @WithCross = 1

Dependencies:	Ole Automation:
					sp_configure 'show advanced options', 1;
					GO
					RECONFIGURE;
					GO
					sp_configure 'Ole Automation Procedures', 1;
					GO
					RECONFIGURE;
					GO

Summary of Commits : 
############################################################################################
Date(yyyy-MM-dd hh:mm)		Author				Commit
--------------------------	------------------	--------------------------------------------
2021.05.20 22:40			Karcan Ozbal		first commit.. 
############################################################################################

*/
CREATE PROCEDURE [dbo].[kSql_GetCurrencyValuesWithTcmb] @Date date, @WithCross bit
AS
	Declare @tempXML table (XML varchar(max));
	DECLARE @Currencies table (CurrencyDate DATE, Symbol VARCHAR(3), CurrencyNameTr VARCHAR(50), CurrencyNameEn VARCHAR(50), Unit TINYINT, ForexBuying DECIMAL(18,4), ForexSelling DECIMAL(18,4), BanknoteBuying DECIMAL(18,4) , BanknoteSelling DECIMAL(18,4))
	Declare @XML XML,
			@Object int,
			@Result int,
			@Description varchar(255),
			@HTTPStatus int,
			@URL varchar(255)

	SET @URL = 'https://www.tcmb.gov.tr/kurlar/'
	SELECT @URL += FORMAT(@Date,'yyyy') + FORMAT(@Date,'MM') + '/' + FORMAT(@Date,'dd') + FORMAT(@Date,'MM') + FORMAT(@Date,'yyyy') + '.xml'

	EXEC @Result = sp_OACreate 'MSXML2.XMLHttp', @Object OUT;
	EXEC @Result = sp_OAMethod @Object, 'Open', NULL , 'GET' , @URL , false;
	EXEC @Result = sp_OAMethod @Object, send;
	EXEC @Result = sp_OAGetProperty @Object, 'status' , @HTTPStatus OUT; 

	IF @HTTPStatus != 200
	BEGIN
		RAISERROR('HTTP Error' , 16 , 1);
		RETURN;
	END

	INSERT INTO @tempXML
	EXECUTE @Result = sp_OAGetProperty @Object, 'responseXML.xml';

	SELECT @XML = XML FROM @tempXML

	INSERT INTO @Currencies
	SELECT Date.Date as [Date],
	x.Rec.value('./@CurrencyCode', 'varchar(3)') Symbol,
	x.Rec.query('./Isim').value('.','varchar(50)') as DescriptionTr,
	x.Rec.query('./CurrencyName').value('.','varchar(50)') as DescriptionEn,
	x.Rec.query('./Unit').value('.','tinyint') as Unit,
	x.Rec.query('./ForexBuying').value('.','float') as ForexBuying,
	x.Rec.query('./ForexSelling').value('.','float') as ForexSelling,
	x.Rec.query('./BanknoteBuying').value('.','float') as BanknoteBuying,
	x.Rec.query('./BanknoteSelling').value('.','float') as BanknoteSelling
	from @XML.nodes('/Tarih_Date/Currency') as x(Rec)
	OUTER APPLY (select top(1) x.Rec.value('@Date', 'DATE') as [Date]
	from @XML.nodes('/Tarih_Date') as x(Rec)) as Date

	SELECT CurrencyDate , 
	Symbol, 
	0 as isCross , 
	CurrencyNameTr , 
	CurrencyNameEn , 
	Unit , 
	CAST(ISNULL(ForexBuying,0) AS DECIMAL(18,4)), 
	CAST(ISNULL(ForexSelling,0) AS DECIMAL(18,4)), 
	CAST(ISNULL(BanknoteBuying,0) AS DECIMAL(18,4)), 
	CAST(ISNULL(BanknoteSelling,0) AS DECIMAL(18,4))
	FROM @Currencies
		UNION ALL
	SELECT r2.CurrencyDate , 
	r1.Symbol + '/' + r2.Symbol, 
	1 as isCross , 
	r1.CurrencyNameTr + '/' + r2.CurrencyNameTr , 
	r1.CurrencyNameEn + '/' + r2.CurrencyNameEn , 
	r2.Unit , 
	CAST(ISNULL(r1.ForexBuying / NULLIF(r2.ForexBuying,0),0) AS DECIMAL(18,4)), 
	CAST(ISNULL(r1.ForexSelling / NULLIF(r2.ForexSelling,0),0) AS DECIMAL(18,4)), 
	CAST(ISNULL(r1.BanknoteBuying / NULLIF(r2.BanknoteBuying,0),0) AS DECIMAL(18,4)), 
	CAST(ISNULL(r1.BanknoteSelling / NULLIF(r2.BanknoteSelling,0),0) AS DECIMAL(18,4))
	FROM @Currencies as r1
	OUTER APPLY (SELECT * FROM @Currencies as r2 WHERE r2.Symbol != r1.Symbol) as r2
	WHERE @withCross = 1