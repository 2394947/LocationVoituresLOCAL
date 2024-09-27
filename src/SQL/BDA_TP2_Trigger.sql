USE locationVoitures;

------------- Fonction pour obtenir le nombre de jours de la location ------------------------------------------------
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

--FCT calcule du montant total TPS
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

--FCT calcule du montant total TVQ
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
-- trigger principal
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
          
	END;
END;
GO

-- trigger ligne facture 1 frais de base
CREATE OR ALTER TRIGGER TR_Update_factureLigneFraisBase
ON facture
AFTER INSERT
AS 
BEGIN
    DECLARE @nextFactureLigneId INT = (SELECT MAX(factureLigneId) + 1 FROM factureLigfne);
    DECLARE @factureId INT = (SELECT factureId FROM inserted);
    DECLARE @fraisbase DECIMAL(7,2) = (SELECT fraisBase FROM tarifLocation);
    DECLARE @locationId INT = (SELECT locationId FROM inserted);
    DECLARE @nbJoursLocation INT = FCT_ObtenirNbJoursLocation(@locationId);
    DECLARE @description TEXT = "Frais de base et nombre de jour de location."
    DECLARE @tauxTVQ DECIMAL(3,2) = (SELECT tauxTVQ FROM tarifLocation);
    DECLARE @tauxTPS DECIMAL(3,2) = (SELECT tauxTPS FROM tarifLocation);

    INSERT INTO factureLigne (factureLigneId, facturId, prixUnitaire, quantite, [description], tauxTaxesTVQ, tauxTaxesTPS)
                VALUES (@nextFactureLigneId, @factureId, @fraisbase, @nbJoursLocation, @description, @tauxTVQ, @tauxTPS);
END;
GO

-- trigger ligne facture 2 frais nettoyage
CREATE OR ALTER TRIGGER TR_Update_factureLigneNettoyage
ON facture
AFTER INSERT
AS
BEGIN
    DECLARE @nextFactureLigneId INT = (SELECT MAX(factureLigneId) + 1 FROM factureLigfne);
    DECLARE @factureId INT = (SELECT factureId FROM inserted);
    
    DECLARE @locationId INT = (SELECT locationId FROM inserted);
    DECLARE @fraisNettoyage DECIMAL(7,2) = FCT_CalculeFraisNettoyage;

    DECLARE @description TEXT = "Frais de nettoyage."
    DECLARE @tauxTVQ DECIMAL(3,2) = (SELECT tauxTVQ FROM tarifLocation);
    DECLARE @tauxTPS DECIMAL(3,2) = (SELECT tauxTPS FROM tarifLocation);

    INSERT INTO factureLigne (factureLigneId, facturId, prixUnitaire, quantite, [description], tauxTaxesTVQ, tauxTaxesTPS)
                VALUES (@nextFactureLigneId, @factureId, @fraisNettoyage, @nbJoursLocation, @description, @tauxTVQ, @tauxTPS);
END
GO
    
-- trigger ligne facture 3 frais essence
CREATE OR ALTER TRIGGER TR_Update_factureLigneEssence
ON facture
AFTER INSERT
AS 
BEGIN
    DECLARE @nextFactureLigneId INT = (SELECT MAX(factureLigneId) + 1 FROM factureLigfne);
    DECLARE @factureId INT = (SELECT factureId FROM inserted);

    DECLARE @locationId INT = (SELECT locationId FROM inserted);
    DECLARE @fraisEssence DECIMAL(7,2) = FCT_CalculerFraisEssence(@p_locationId);

    DECLARE @description TEXT = "Frais d'essence."
    DECLARE @tauxTVQ DECIMAL(3,2) = (SELECT tauxTVQ FROM tarifLocation);
    DECLARE @tauxTPS DECIMAL(3,2) = (SELECT tauxTPS FROM tarifLocation);

    INSERT INTO factureLigne (factureLigneId, facturId, prixUnitaire, quantite, [description], tauxTaxesTVQ, tauxTaxesTPS)
                VALUES (@nextFactureLigneId, @factureId, @fraisEssence, @nbJoursLocation, @description, @tauxTVQ, @tauxTPS);
END
GO