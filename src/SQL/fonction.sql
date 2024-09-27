USE locationVoitures;

-------------------------- Fonction pour obtenir le nombre de jours de la location --------------------------------------

GO
CREATE OR ALTER FUNCTION FCT_ObtenirNbJoursLocation(@locationId INT)
RETURNS INT
AS
BEGIN
	DECLARE @nbJoursLocationReel INT
	, @nbJoursLocationPrevue INT;

	SET @nbJoursLocationPrevue = (SELECT DATEDIFF(DAY,dateDebutPrevue,dateFinPrevue) AS nbJoursPrevue FROM [location]);
	SET @nbJoursLocationReel = (SELECT DATEDIFF(DAY,dateDebutReelle,dateFinReelle) AS nbJoursReel FROM [location]);

	IF(@nbJoursLocationPrevue > @nbJoursLocationReel)
	BEGIN
		RETURN @nbJoursLocationPrevue;
	END

	RETURN @nbJoursLocationReel;
END

------------- Fonction pour obtenir la quantite d'essence restante en litre de la location ----------------------------

GO
CREATE OR ALTER FUNCTION FCT_ObtenirQuantiteEssenceRestante(@p_locationId INT)
RETURNS INT
AS
BEGIN
	RETURN 
	(
		SELECT essenceFin - essenceDebut
		FROM [location]
		WHERE locationId = @p_locationId
	);
END

------------ Fonction pour calculer les frais de base par jour -----------------------------------------
GO	
CREATE OR ALTER FUNCTION FCT_CalculFraisBaseLocationParJour(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN

	DECLARE @fraisBaseJours DECIMAL(5,2);

	SET @fraisBaseJours = (dbo.FCT_ObtenirNbJoursLocation(@p_locationId)) * (SELECT fraisBase FROM tarifLocation);

	RETURN @fraisBaseJours;
END

------------------------ Fonction pour determiner si il y a des frais d'essence  ------------------------------------
GO
CREATE OR ALTER FUNCTION FCT_ADesFraisEssence(@p_locationId INT)
RETURNS BIT
AS
BEGIN
	DECLARE @quantiteEssenceRestante INT;
	SET @quantiteEssenceRestante = dbo.FCT_ObtenirQuantiteEssenceRestante(@p_locationId);
	
	IF(@quantiteEssenceRestante<40)
	BEGIN
		RETURN 1;
	END
	RETURN 0;
END

------------------------ Fonction pour calculer les frais d'essence ---------------------------------------------
GO
CREATE OR ALTER FUNCTION FCT_CalculeFraisEssence(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	 DECLARE @tarifFraisEssenceLitre DECIMAL(5,2)
	 , @tarifFraisFixeEssence DECIMAL(5,2)
	 , @fraisEssenceTotal DECIMAL(7,2);

	 SET @tarifFraisEssenceLitre = (SELECT fraisEssenceParLitreManquant FROM tarifLocation);
	 SET @tarifFraisFixeEssence = (SELECT fraisBaseFixeEssence FROM tarifLocation);
	 SET @fraisEssenceTotal = 
	 (
		dbo.FCT_ObtenirQuantiteEssenceRestante(@p_locationId) * 
		@tarifFraisEssenceLitre + 
		@tarifFraisFixeEssence
	 );

	 RETURN @fraisEssenceTotal;
END

--------------- Fonction pour determiner si il y a des frais de nettoyage ------------------------------------
GO
CREATE OR ALTER FUNCTION FCT_ADesFraisDeNettoyage(@locationId INT)
RETURNS BIT
AS
BEGIN

	DECLARE @nbJoursLocation INT;
	SET @nbJoursLocation = dbo.FCT_ObtenirNbJoursLocation(@locationId);

	IF(@nbJoursLocation>1)
	BEGIN
		RETURN 1;
	END
	RETURN 0;
END

------------------ Fonction pour calculer les frais de nettoyage -------------------------------------------
GO
CREATE OR ALTER FUNCTION FCT_CalculFraisNettoyage(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @tarifFraisNettoyage DECIMAL(5,2);

	SET @tarifFraisNettoyage = (SELECT fraisNettoyage FROM tarifLocation);

	RETURN @tarifFraisNettoyage;
END
	
	-----===== Les 3 fonctions générales =====-----
-- FCT calcule du montant total hors taxes
GO
CREATE OR ALTER FUNCTION FCT_CalculeMontantTotalHorsTaxes(@p_locationId INT) 
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @fraisDeBase DECIMAL(7,2) = dbo.FCT_CalculFraisBaseLocationParJour(@p_locationId);
	DECLARE @fraisDeNettoyage DECIMAL(7,2) = 0;
	DECLARE @fraisEssence DECIMAL(7,2) = 0;

	IF dbo.FCT_ADesFraisDeNettoyage(@p_locationId) = 1
	BEGIN
		SET @fraisDeNettoyage  = dbo.FCT_CalculFraisNettoyage(@p_locationId);
	END
	IF dbo.FCT_ADesFraisEssence(@p_locationId) = 1
	BEGIN
		SET @fraisEssence = dbo.FCT_CalculeFraisEssence(@p_locationId);
	END

	DECLARE @montantTotalHorsTaxes DECIMAL(7,2) = @fraisDeBase + @fraisDeNettoyage + @fraisEssence;

	RETURN @montantTotalHorsTaxes;
END
GO

--FCT calcule du montant total TPS
CREATE OR ALTER FUNCTION FCT_CalculeMontantTPS(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @MontantTotalHorsTaxes DECIMAL(6,5) = (SELECT montantHorsTaxes  FROM facture
									  WHERE locationId = @p_locationId);

	DECLARE @tauxTPS DECIMAL(6,5) = (SELECT tauxTPS FROM tarifLocation);  

	DECLARE @montantTPS DECIMAL(7,2) = @MontantTotalHorsTaxes * @tauxTPS;

	RETURN @montantTPS;
END
GO

--FCT calcule du montant total TVQ
CREATE OR ALTER FUNCTION FCT_CalculeMontantTVQ(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @MontantTotalHorsTaxes DECIMAL(6,5) = (SELECT montantHorsTaxes  FROM facture
									  WHERE locationId = @p_locationId);
 
	DECLARE @tauxTVQ DECIMAL(6,5) = (SELECT tauxTVQ FROM tarifLocation); 


	DECLARE @montantTVQ DECIMAL(7,2) = @MontantTotalHorsTaxes * @tauxTVQ;
	

	RETURN @montantTVQ;
END
GO
	


	