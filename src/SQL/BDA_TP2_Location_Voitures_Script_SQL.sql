USE master;
GO

DROP DATABASE IF EXISTS locationPretatine;
CREATE DATABASE locationPretatine;
GO

USE locationVoitures;
GO

DROP TABLE IF EXISTS client;
CREATE TABLE client
(
	clientId UNIQUEIDENTIFIER PRIMARY KEY
   ,nom VARCHAR(50) NOT NULL
   ,prenom VARCHAR(50) NOT NULL
   ,dateNaissance DATETIME NOT NULL
   ,numeroPermis VARCHAR(20) NOT NULL
   ,numeroTelephone VARCHAR(20) NOT NULL
   ,CONSTRAINT CHK_longueur_nom_minnimum_3_chars CHECK(LEN(nom) >= 3)
   ,CONSTRAINT CHK_longueur_prenomnom_minnimum_3_char CHECK(LEN(prenom) >= 3)
   ,CONSTRAINT CHK_dateNaissance_plus_que_18_ans CHECK((DATEDIFF(DAY, dateNaissance, GETDATE()) >= 365 * 18))
);

DROP TABLE IF EXISTS voiture;
CREATE TABLE voiture
(
	voitureId INT PRIMARY KEY
   ,numeroSerie VARCHAR(17) NOT NULL 
   ,marque VARCHAR(30) NOT NULL
   ,modele VARCHAR(30) NOT NULL
   ,couleur VARCHAR(30) NOT NULL
   ,dateAchat DATETIME NOT NULL
   ,dateRevision DATETIME NULL
   ,descriptionFr TEXT NULL
   ,CONSTRAINT CHK_longueur_numeroSerie_egale_17_alphaNumeriques CHECK(LEN(numeroSerie) = 17)
   ,CONSTRAINT CHK_longueur_marque_minimum_3_chars CHECK(LEN(marque) >= 3)
   ,CONSTRAINT CHK_longueur_modele_minimum_3_chars CHECK(LEN(modele) >= 3)
   ,CONSTRAINT CHK_longueur_couleur_minimum_3_chars CHECK(LEN(couleur) >= 3)
   ,CONSTRAINT CHK_dateAchat_plus_petit_ou_egale_a_aujourdhui CHECK(dateAchat <= GETDATE())
   ,CONSTRAINT CHK_daterevision_plus_petit_ou_egale_a_aujourdhui CHECK(dateRevision <= GETDATE())
   ,CONSTRAINT CHK_dateRevision_plus_grand_ou_egale_a_dateAcha CHECK(dateRevision >= dateAchat)
);

DROP TABLE IF EXISTS location;
CREATE TABLE location
(
	locationId INT PRIMARY KEY
   ,dateDebutPrevue DATETIME NOT NULL
   ,dateDebutReelle DATETIME NULL
   ,dateFinPrevue DATETIME NOT NULL
   ,dateFinReelle DATETIME NULL
   ,odometreDebut INT NOT NULL
   ,odometreFin INT NOT NULL
   ,essenceDebut INT DEFAULT 40
   ,essenceFin INT NOT NULL
   ,clientId UNIQUEIDENTIFIER  
   ,voitureId INT
   ,CONSTRAINT CHK_dateDebutPrevue_pasFutur CHECK (dateDebutPrevue <= GETDATE())
   ,CONSTRAINT CHK_dateDebutReelle_pasFutur CHECK (dateDebutReelle <= GETDATE())
   ,CONSTRAINT CHK_dateFinPrevue_superieur_dateDebutPrevue CHECK (dateFinPrevue > dateDebutPrevue)
   ,CONSTRAINT CHK_dateFinReelle_superieur_dateDebutReelle CHECK (dateFinReelle > dateDebutReelle)
   ,CONSTRAINT FK_clientId_client FOREIGN KEY (clientId) REFERENCES client(clientId)
   ,CONSTRAINT FK_voitureId_voiture FOREIGN KEY (voitureId) REFERENCES voiture(voitureId)
);

DROP TABLE IF EXISTS facture;
CREATE TABLE facture
(
	factureId INT PRIMARY KEY
   ,locationId INT
   ,clientId UNIQUEIDENTIFIER 
   ,dateFacture DATETIME
   ,montantHorsTaxes DECIMAL(7,2)
   ,descriptions TEXT 
   ,montantTaxesTVQ  DECIMAL(7,2)
   ,montantTaxesTPS  DECIMAL(7,2)
   ,montantTotal AS (montantHorsTaxes + montantTaxesTVQ + montantTaxesTPS) --calcul dans la table depuis montant hors taxes
   ,CONSTRAINT CHK_dateFacture_pasFutur CHECK (dateFacture <= GETDATE())
   ,CONSTRAINT FK_locationId_location FOREIGN KEY (locationId) REFERENCES [location](locationId)
   ,CONSTRAINT FK_clientId_client FOREIGN KEY (clientId) REFERENCES client(clientId)
);


DROP TABLE IF EXISTS factureLigne;
CREATE TABLE factureLigne
(
	factureLigneId INT PRIMARY KEY
   ,factureId INT
   ,prixUnitaire DECIMAL(7,2) NOT NULL
   ,quantite INT NOT NULL
   ,[description] TEXT NULL
   ,tauxTaxesTVQ DECIMAL(6,5) NOT NULL
   ,tauxTaxesTPS DECIMAL(6,5) NOT NULL
   ,CONSTRAINT FK_factureId_facture2 FOREIGN KEY (factureId) REFERENCES facture(factureId)
   ,CONSTRAINT CHK_quantite_min1 CHECK (quantite>=1)
);