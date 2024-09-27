## Relations

- Une facture a 1 locations
- Une facture a 0 ou plusieurs factureLigne
- Une location a 1 client
- Une location a 0 ou 1 facture
- Une location a 1 voiture
- Une factureLigne a 1 facture
- Une voiture a 0 ou plusieurs locations
- Un client a 0 ou plusieurs locations

## Affectation des types

### - Client

- clientId UNIQUEIDENTIFIER PK  (NEWID())
- nom VARCHAR(50) NOT NULL
- prenom VARCHAR(50) NOT NULL
- dateNaissance DATETIME() NOT NULL
- numeroPermis VARCHAR(20) NOT NULL
- numeroTelephone VARCHAR(20) NOT NULL

### - Location

- locationId INT PK
- dateDebutPrevue DATETIME() 
- dateDebutReelle DATETIME()
- dateFinPrevue DATETIME()
- dateFinReelle DATETIME()
- odometreDebut INT NOT NULL
- odometreFin INT NOT NULL
- essenceDebut INT NOT NULL
- essenceFin INT NOT NULL
- clientId FK
- voitureId FK
- factureId FK

### - Voiture

- numeroSerie VARCHAR(20) PK 
- marque VARCHAR(30) NOT NULL
- modele VARCHAR(30) NOT NULL
- couleur VARCHAR(30) NOT NULL
- dateAchat DATETIME() NOT NULL
- dateRevision DATETIME NULL
- descriptionFr  TEXT NULL

### - Facture

- factureId INT PK 
- dateFacture DATETIME() NOT NULL
- montantHorsTaxes DECIMAL(7,2) NOT NULL
- description TEXT NULL
- montantTaxesTVQ  DECIMAL(7,2) NOT NULL
- montantTaxesTPS  DECIMAL(7,2) NOT NULL
- montantTotal DECIMAL(7,2) NOT NULL (calcul dans la table depuis montant hors taxes)

### - FactureLigne

- factureLigneId INT PK
- prixUnitaire DECIMAL(7,2) NOT NULL
- quantite INT NOT NULL
- description TEXT NULL
- tauxTaxesTVQ DECIMAL(6,5) NOT NULL
- tauxTaxesTPS DECIMAL(6,5) NOT NULL


## Chaine trigger et fonctions mise à jour colonne `dateFinReelle` de `[location]`

### trigger TR_CreationFactureLorsUpdateDateFinReelle
- UPDATE la table facture et INSERT seulement un `factureId`.
- Appel une fonction qui va appeler les fonctions qui calcules tous les frais applicable au besoin (IF(booléen))
- Retour des valeurs des fonctions et calcule des `montantHorsTaxes`, `montantTaxesTVQ` et `montantTaxesTPS`.
- INSERT des nouvelles `factureLigne` pour chaque résultats avec les FK = nouveau `factureId`.
- UPDATE la ligne du nouveau `factureId` avec les retour des fonction.

### Chaque fonction un `montantHorsTaxes`, un `montantTaxesTVQ` et `montantTaxesTPS`.
