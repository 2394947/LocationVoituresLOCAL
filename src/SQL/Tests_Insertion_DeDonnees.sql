---------- Donnees de tests ----------
USE locationVoitures;

------------- Tests pour la table client ----------------------------------

-- Insertion d'un nom ayant une longueur inferieure a 3 lettres
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lo','Bilibob','1999-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE nom='lo';

-- Insertion d'un prenom ayant une longueur inferieure a 3 lettres
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'Bilibob','lo','1999-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE prenom ='lo';

-- Insertion d'un nom ayant une longueur egale a 3 lettres
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lol','Bilibob','1999-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE nom ='lol';

-- Insertion d'un prenom ayant une longueur egale a 3 lettres
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lol','Bil','1999-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE prenom ='Bil';

-- Insertion d'un nom ayant une longueur superieure a 3 lettres
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lolo','Bilibob','1999-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE nom ='lolo';

-- Insertion d'un prenom ayant une longueur superieure a 3 lettres
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lol','Bili','1999-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE prenom ='Bili';

-- Insertion d'une date de naissance inferieure a 18 ans
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lol','Bili','2020-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE dateNaissance = '2020-06-07 00:00:00';

-- Insertion d'une date de naissance egale a 18 ans
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'lol','Bili','2006-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE dateNaissance = '2006-06-07 00:00:00';


-- Insertion d'une date de naissance superieure a 18 ans
INSERT INTO client(clientId,nom,prenom,dateNaissance,numeroPermis,numeroTelephone)
VALUES
	(NEWID(),'Carlito','Aranchinni','1985-06-07 00:00:00','C9902f5','581-034-2323');

SELECT * FROM client WHERE dateNaissance = '1985-06-07 00:00:00';

------------ Tests pour la table voiture -------------------------------

-- Insertion d'un numero de serie inferieur a 17 characteres alphanumeriques
INSERT INTO voiture(voitureId,numeroSerie,marque,modele,couleur,dateAchat,dateRevision)
VALUES
(1,'A2D00','Nissan','Sentra','Bleu','2009-03-15 00:00:00','2022-09-22 00:00:00');

SELECT * FROM voiture WHERE numeroSerie = 'A2D00' ;

-- Insertion d'un numero de serie egal a 17 characteres alphanumeriques
INSERT INTO voiture(voitureId,numeroSerie,marque,modele,couleur,dateAchat,dateRevision)
VALUES
(1,'A2D00B2H7J39J8HA8','Nissan','Sentra','Bleu','2009-03-15 00:00:00','2022-09-22 00:00:00');

SELECT * FROM voiture WHERE numeroSerie = 'A2D00B2H7J39J8HA8' ;

-- Insertion d'une marque inferieure a 3 lettres
INSERT INTO voiture(voitureId,numeroSerie,marque,modele,couleur,dateAchat,dateRevision)
VALUES
(3,'A2D00B2H7J398IB9I','Nissan','Se','Bleu','2009-03-15 00:00:00','2022-09-22 00:00:00');

SELECT * FROM voiture WHERE voitureId= 3 ;

