USE locationVoitures;

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
		SELECT DATEDIFF(DAY,dateDebutReelle,dateFinReelle) AS nbJours
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

	SET @fraisBaseJours = (SELECT * FROM FCT_ObtenirNbJoursLocations(@p_locationId)) * (SELECT fraisBase FROM tarifLocation);

	RETURN @fraisBaseJours;
END

------------------------ Fonction pour determiner si il y a des frais d'essence  ------------------------------------
GO
CREATE OR ALTER FUNCTION FCT_ADesFraisEssence(@p_locationId INT)
RETURNS BIT
AS
BEGIN
	DECLARE @quantiteEssenceRestante INT;
	SET @quantiteEssenceRestante = (SELECT * FROM FCT_ObtenirQuantiteEssenceRestante(@p_locationId));
	
	IF(@quantiteEssenceRestante<40)
	BEGIN
		RETURN 1;
	END
	RETURN 0;
END

------------------------ Fonction pour calculer les frais d'essence ---------------------------------------------
GO
CREATE OR ALTER FUNCTION FCT_CalculerFraisEssence(@p_locationId INT)
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
		(SELECT * FROM FCT_ObtenirQuantiteEssenceRestante(@p_locationId)) * 
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
	SET @nbJoursLocation = (SELECT * FROM FCT_ObtenirNbJoursLocation(@locationId));

	IF(@nbJoursLocation>1)
	BEGIN
		RETURN 1;
	END
	RETURN 0;
END
GO

-----===== Les 3 fonctions générales =====-----

CREATE OR ALTER FUNCTION FCT_CalculeMontantTotalHorsTaxes(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @fraisDeBase DECIMAL(7,2) = FCT_CalculFraisBaseLocationParJour(@p_locationId);
	DECLARE @fraisDeNettoyage DECIMAL(7,2) = 0;
	DECLARE @fraisEssence DECIMAL(7,2) = 0;

	IF FCT_AdesFraisDeNettoyage(@p_locationId) = 1
	BEGIN
		SET @fraisDeNettoyage  = FCT_CalculeFraisDeNettoyage(@p_locationId);
	END
	IF FCT_ADesFraisEssence(@p_locationId) = 1
	BEGIN
		SET@fraisEssence = FCT_CalculeFraisEssence(@p_locationId);
	END

	DECLARE @montantTotalHorsTaxes DECIMAL(7,2) = @fraisDeBase + @fraisDeNettoyage + @fraisEssence;

	RETURN @montantTotalHorsTaxes;
END
GO

CREATE OR ALTER FUNCTION FCT_CalculeMontantTPS(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @MontantTotalHorsTaxes = (SELECT montantHorsTaxes  FROM facture
									  WHERE locationId = @p_locationId);

	DECLARE @tauxTPS DECIMAL(6,5) = (SELECT tauxTPS FROM tarifLocation);  

	DECLARE @montantTPS DECIMAL(7,2) = @MontantTotalHorsTaxes * @tauxTPS;

	RETURN @montantTPS;
END
GO

CREATE OR ALTER FUNCTION FCT_CalculeMontantTVQ(@p_locationId INT)
RETURNS DECIMAL(7,2)
AS
BEGIN
	DECLARE @MontantTotalHorsTaxes = (SELECT montantHorsTaxes  FROM facture
									  WHERE locationId = @p_locationId);
 
	DECLARE @tauxTVQ DECIMAL(6,5) = (SELECT tauxTVQ FROM tarifLocation); 


	DECLARE @montantTVQ DECIMAL(7,2) = @MontantTotalHorsTaxes * @tauxTVQ;
	

	RETURN @montantTVQ;
END
GO




-----=======  DAH TRIGGER  =======-----

CREATE OR ALTER TRIGGER TR_Update_DateFinReelle_sur_Location
ON [location]
AFTER UPDATE
AS
BEGIN
	IF UPDATE (dateFinReelle)
	BEGIN
		DECLARE @cliendId UNIQUEIDENTIFIER = (SELECT cliendId FROM [location]
											  WHERE dateFinReelle = (SELECT dateFinReelle FROM inserted));

		DECLARE @locationId INT = (SELECT locationId FROM [location]
								   WHERE dateFinReelle = (SELECT dateFinReelle* FROM inserted));		
		
		DECLARE @nextfactureId INT = (SELECT MAX(factureId) + 1 FROM facture);

		INSERT INTO facture (factureId)
					VALUES (@nextfactureId);

		DECLARE @montantHorsTaxes DECIMAL(7,2) = FCT_CalculeMontantHorsTaxes(@nextfactureId);
		DECLARE @montantTPS DECIMAL(7,2) = FCT_CalculeMontantTPS(@nextfactureId);
		DECLARE @montantTVQ DECIMAL(7,2) = FCT_CalculeMontantTVQ(@nextfactureId);

		INSERT INTO facture (locationId, clientId, dateFacture, montantHorsTaxes, montantTaxesTVQ, montantTaxesTPS)
			         VALUES (@locationId, @cliendId, GETDATE(), @montantHorsTaxes, @montantTVQ, @montantTPS);

-- pas complet
		--update facture lignes
	END;
END;
GO