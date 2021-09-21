CREATE PROCEDURE [dbo].[GetCurrencyFromTCMB]		 @pDate					DATE	= NULL
AS
BEGIN
	-- Temp Tables
	BEGIN
		CREATE TABLE #CurrencyXML(
			RequestBody			  XML
		);

		CREATE TABLE #CurrencyList(
			[Date]			DATE,
			SourceSymbol		VARCHAR(3),
			TargetSymbol		VARCHAR(3),
			Quantity		TINYINT,
			ForexBuying		DECIMAL(7,5),
			ForexSelling		DECIMAL(7,5), 
			BanknoteBuying		DECIMAL(7,5), 
			BanknoteSelling		DECIMAL(7,5)
		);

		CREATE TABLE #CrossCurrencyList(
			[Date]				    DATE,
			SourceQuantity		TINYINT,
			SourceSymbol		  VARCHAR(3),
			TargetQuantity		TINYINT,
			TargetSymbol		  VARCHAR(3),
			ForexBuying			  DECIMAL(11,5),
			ForexSelling		  DECIMAL(11,5), 
			BanknoteBuying		DECIMAL(11,5), 
			BanknoteSelling		DECIMAL(11,5)
		);
	END

	-- Variables
	BEGIN
		DECLARE	@vCurrentDatetime	DATETIME = GETDATE()

		DECLARE	 @vURL			  VARCHAR(50)
				    ,@vDate			  DATE = @pDate
				    ,@vObject		  INT
				    ,@vResult		  INT
				    ,@vHttpStatus	INT
				    ,@vXMLResult	XML
	END

	-- Initialize
	BEGIN	
		IF @vDate IS NULL
		BEGIN
			IF FORMAT(@vCurrentDatetime,'HH:mm') <= '15:30'
				SET @vDate = @vCurrentDatetime - 1
			ELSE
				SET @vDate = @vCurrentDatetime
		END

		SET @vURL = 'https://www.tcmb.gov.tr/kurlar/' + FORMAT(@vDate, 'yyyyMM/ddMMyyyy') + '.xml'
	END

	-- Ole Automation (Http Request)
	BEGIN
		EXEC @vResult = sp_OACreate 'MSXML2.XMLHttp', @vObject OUT;
		EXEC @vResult = sp_OAMethod @vObject, 'Open', NULL , 'GET' , @vURL , false;
		EXEC @vResult = sp_OAMethod @vObject, send;
		EXEC @vResult = sp_OAGetProperty @vObject, 'status' , @vHTTPStatus OUT; 

		IF @vHTTPStatus != 200
		BEGIN
		
			RAISERROR('HTTP Error : ' , 16 , 1);
		END

		INSERT INTO #CurrencyXML (RequestBody)
		EXECUTE @vResult = sp_OAGetProperty @vObject, 'responseXML.xml';
	END

	-- Parsing XML to Table
	BEGIN
		SELECT @vXMLResult = RequestBody FROM #CurrencyXML

		INSERT INTO #CurrencyList ([Date], SourceSymbol, TargetSymbol, Quantity, ForexBuying, ForexSelling, BanknoteBuying, BanknoteSelling)
		SELECT 
			 [Date]				    =	@vDate
			,SourceSymbol		  =	x.Rec.value('./@CurrencyCode', 'varchar(3)')
			,TargetSymbol		  =	'TRY'
			,Quantity			    =	x.Rec.query('./Unit').value('.','tinyint')
			,ForexBuying		  =	x.Rec.query('./ForexBuying').value('.','float')
			,ForexSelling		  =	x.Rec.query('./ForexSelling').value('.','float')
			,BanknoteBuying		=	x.Rec.query('./BanknoteBuying').value('.','float')
			,BanknoteSelling	=	x.Rec.query('./BanknoteSelling').value('.','float')
		FROM 
			@vXMLResult.nodes('/Tarih_Date/Currency') as x(Rec)

	END

	-- Calculate Cross Currency
	BEGIN
		INSERT INTO #CrossCurrencyList ([Date], SourceQuantity, SourceSymbol, TargetQuantity, TargetSymbol, ForexBuying, ForexSelling, BanknoteBuying, BanknoteSelling)
		SELECT 
			[Date],
			SourceQuantity		= 1,
			SourceSymbol		  = 'TRY',
			TargetQuantity		= 1,
			TargetSymbol		  = SourceSymbol,
			ForexBuying			  = (1.0 / NULLIF(ForexBuying,0)) * Quantity,
			ForexSelling		  = (1.0 / NULLIF(ForexSelling,0)) * Quantity,
			BanknoteBuying		= (1.0 / NULLIF(BanknoteBuying,0)) * Quantity,
			BanknoteSelling		= (1.0 / NULLIF(BanknoteSelling,0)) * Quantity
		FROM 
			#CurrencyList AS c1

		UNION ALL

		SELECT 
			[Date],
			1,
			SourceSymbol,

			1,
			TargetSymbol,
			ForexBuying / Quantity,
			ForexSelling / Quantity,
			BanknoteBuying / Quantity,
			BanknoteSelling / Quantity
		FROM 
			#CurrencyList AS c1
		
		UNION ALL

		SELECT
			c1.[Date],
			1,
			c1.SourceSymbol,

			1,
			c2.SourceSymbol,
			(c1.ForexBuying / c1.Quantity) / (NULLIF(c2.ForexBuying,0) / c2.Quantity),
			(c1.ForexSelling / c1.Quantity) / (NULLIF(c2.ForexSelling,0) / c2.Quantity ),
			(c1.BanknoteBuying / c1.Quantity) / (NULLIF(c2.BanknoteBuying,0) / c2.Quantity ),
			(c1.BanknoteSelling / c1.Quantity) / (NULLIF(c2.BanknoteSelling,0) / c2.Quantity )
		FROM
			#CurrencyList AS c1
			CROSS APPLY (
				SELECT
					*
				FROM
					#CurrencyList AS c2 
				WHERE
					c2.SourceSymbol != c1.SourceSymbol
			) AS c2



		SELECT * FROM #CrossCurrencyList
	END

	-- DEALLOCATE
	BEGIN
		IF OBJECT_ID('tempdb..#CurrencyXML') IS NOT NULL
			DROP TABLE #CurrencyXML;

		IF OBJECT_ID('tempdb..#CurrencyList') IS NOT NULL
			DROP TABLE #CurrencyList;

		IF OBJECT_ID('tempdb..#CrossCurrencyList') IS NOT NULL
			DROP TABLE #CrossCurrencyList;
	END
END
