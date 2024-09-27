USE locationVoitures;
GO

CREATE OR ALTER TRIGGER TR_UnSeulEnregistrementTableTarif
ON tarifLocation
INSTEAD OF INSERT
AS
BEGIN
	IF EXISTS(SELECT 1 FROM tarifLocation)
	BEGIN
		RAISERROR('La table tarifLocation peut contenir un seul enregistrement, essayez de mettre à jour (update)?',11,1);
	END
	INSERT INTO tarifLocation(fraisBase,fraisEssenceParLitreManquant,fraisBaseFixeEssence,fraisNettoyage,tauxTPS,tauxTVQ)
		SELECT
			fraisBase
			,fraisEssenceParLitreManquant
			,fraisBaseFixeEssence
			,fraisNettoyage
			,tauxTPS
			,tauxTVQ
		FROM inserted;
END

GO
CREATE OR ALTER TRIGGER TR_Update_DateFinReelle_sur_Location
ON [location]
AFTER UPDATE
AS
BEGIN
	IF UPDATE (dateFinReelle)
	BEGIN
		DECLARE @clientId UNIQUEIDENTIFIER = (SELECT clientId FROM [location]
											  WHERE dateFinReelle = (SELECT dateFinReelle FROM inserted));

		DECLARE @locationId INT = (SELECT locationId FROM [location]
								   WHERE dateFinReelle = (SELECT dateFinReelle FROM inserted));		
		
		DECLARE @nextfactureId INT = (SELECT MAX(factureId) + 1 FROM facture);

		DECLARE @montantHorsTaxes DECIMAL(7,2) = dbo.FCT_CalculeMontantTotalHorsTaxes(@nextfactureId);
		DECLARE @montantTPS DECIMAL(7,2) = dbo.FCT_CalculeMontantTPS(@nextfactureId);
		DECLARE @montantTVQ DECIMAL(7,2) = dbo.FCT_CalculeMontantTVQ(@nextfactureId);

		INSERT INTO facture (factureId,locationId, clientId, dateFacture, montantHorsTaxes, montantTaxesTVQ, montantTaxesTPS)
			         VALUES (@nextfactureId,@locationId, @clientId, GETDATE(), @montantHorsTaxes, @montantTVQ, @montantTPS);
          
	END;
END;
GO

-- trigger ligne facture 1 frais de base
CREATE OR ALTER TRIGGER TR_Update_factureLigneFraisBase
ON facture
AFTER INSERT
AS 
BEGIN
    DECLARE @nextFactureLigneId INT = (SELECT MAX(factureLigneId) + 1 FROM factureLigne);
    DECLARE @factureId INT = (SELECT factureId FROM inserted);
    DECLARE @fraisbase DECIMAL(7,2) = (SELECT fraisBase FROM tarifLocation);
    DECLARE @locationId INT = (SELECT locationId FROM inserted);
    DECLARE @nbJoursLocation INT = dbo.FCT_ObtenirNbJoursLocation(@locationId);
    DECLARE @description VARCHAR(80) = 'Frais de base et nombre de jour de location.'
    DECLARE @tauxTVQ DECIMAL(3,2) = (SELECT tauxTVQ FROM tarifLocation);
    DECLARE @tauxTPS DECIMAL(3,2) = (SELECT tauxTPS FROM tarifLocation);

    INSERT INTO factureLigne (factureLigneId, factureId, prixUnitaire, quantite, [description], tauxTaxesTVQ, tauxTaxesTPS)
                VALUES (@nextFactureLigneId, @factureId, @fraisbase, @nbJoursLocation, @description, @tauxTVQ, @tauxTPS);
END;
GO

-- trigger ligne facture 2 frais nettoyage
CREATE OR ALTER TRIGGER TR_Update_factureLigneNettoyage
ON facture
AFTER INSERT
AS
BEGIN
    DECLARE @nextFactureLigneId INT = (SELECT MAX(factureLigneId) + 1 FROM factureLigne);
    DECLARE @factureId INT = (SELECT factureId FROM inserted);
    
    DECLARE @locationId INT = (SELECT locationId FROM inserted);
    DECLARE @fraisNettoyage DECIMAL(7,2) = dbo.FCT_CalculFraisNettoyage(@locationId);

	DECLARE @nbJoursLocation INT = dbo.FCT_ObtenirNbJoursLocation(@locationId)
    DECLARE @description VARCHAR(80) = 'Frais de nettoyage.'
    DECLARE @tauxTVQ DECIMAL(3,2) = (SELECT tauxTVQ FROM tarifLocation);
    DECLARE @tauxTPS DECIMAL(3,2) = (SELECT tauxTPS FROM tarifLocation);

    INSERT INTO factureLigne (factureLigneId, factureId, prixUnitaire, quantite, [description], tauxTaxesTVQ, tauxTaxesTPS)
                VALUES (@nextFactureLigneId, @factureId, @fraisNettoyage, @nbJoursLocation, @description, @tauxTVQ, @tauxTPS);
END
GO
    
-- trigger ligne facture 3 frais essence
CREATE OR ALTER TRIGGER TR_Update_factureLigneEssence
ON facture
AFTER INSERT
AS 
BEGIN
    DECLARE @nextFactureLigneId INT = (SELECT MAX(factureLigneId) + 1 FROM factureLigne);
    DECLARE @factureId INT = (SELECT factureId FROM inserted);

    DECLARE @locationId INT = (SELECT locationId FROM inserted);
    DECLARE @fraisEssence DECIMAL(7,2) = dbo.FCT_CalculeFraisEssence(@locationId);

	DECLARE @nbJoursLocation INT = dbo.FCT_ObtenirNbJoursLocation(@locationId)
    DECLARE @description VARCHAR(80) = 'Frais d''essence.'
    DECLARE @tauxTVQ DECIMAL(3,2) = (SELECT tauxTVQ FROM tarifLocation);
    DECLARE @tauxTPS DECIMAL(3,2) = (SELECT tauxTPS FROM tarifLocation);

    INSERT INTO factureLigne (factureLigneId, factureId, prixUnitaire, quantite, [description], tauxTaxesTVQ, tauxTaxesTPS)
                VALUES (@nextFactureLigneId, @factureId, @fraisEssence, @nbJoursLocation, @description, @tauxTVQ, @tauxTPS);
END