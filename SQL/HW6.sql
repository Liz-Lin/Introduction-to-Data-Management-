Use CS122A;
/* LastName: Lin		FirstName: Lizhen  student ID: 82226790" */

SELECT p.userid, p.publisherid, COUNT(*) AS num_degree
FROM Poster AS p  LEFT OUTER JOIN Degree AS d ON p.userid = d.userid
GROUP BY p.userid
ORDER BY COUNT(*) DESC /*Q1*/;

SELECT d.userid, u.account, COUNT(*) AS num, MIN(h.like_score) AS lowest
FROM Detector AS d  LEFT OUTER JOIN Has_read AS h ON  d.userid = h.userid, Users u
WHERE u.userid = d.userid
GROUP BY d.userid/*Q2*/;

SELECT a.userid, a.articleid, a.quality, COUNT(h.userid) AS numRead, AVG(h.like_score),COUNT(r.userid) AS numReport
FROM (Article AS a 
LEFT OUTER JOIN  Has_read AS h ON a.userid = h.article_userid AND a.articleid  = h.article_articleid
LEFT OUTER JOIN  Reports AS r ON a.userid = r.article_userid AND a.articleid  = r.article_articleid ) 
GROUP BY a.userid, a.articleid/*Q3*/;
 
DROP PROCEDURE IF EXISTS NewArticle;

DELIMITER //
CREATE PROCEDURE NewArticle(	/* Q4.a */
id INTEGER,
title VARCHAR(100),
content VARCHAR(1000))
BEGIN
DECLARE new_articleid INTEGER;
DECLARE TEMPID INTEGER;
SET new_articleid = ( SELECT COUNT(*)+1 FROM Article WHERE  userid = id);
INSERT INTO Article (userid,articleid,posting_datetime,popularity,quality,title,content ) 
VALUES ( id, new_articleid, now(), 'Regular', 'clean', title, content );
END;  //
DELIMITER ;


CALL NewArticle(2, 'WannaCry ransomware attack', 'The WannaCry ransomware attack is an ongoing cyberattack of the WannaCry ransomware cryptoworm, targeting the Microsoft Windows operating system, encrypting data and demanding ransom payments in the cryptocurrency bitcoin.');

SELECT userid, articleid, posting_datetime, popularity, quality, title
FROM Article WHERE userid = 2  /* Q4.b */;


/*  Q5 */
ALTER TABLE Poster
DROP FOREIGN KEY poster_ibfk_2; 

ALTER TABLE Poster
ADD CONSTRAINT  poster_ibfk_2
FOREIGN KEY (publisherid) REFERENCES Publisher (publisherid)
ON DELETE CASCADE  /*  Q5  */;

DROP VIEW IF EXISTS PublisherView;

CREATE VIEW PublisherView(publisherid,name,website,article_count) AS
SELECT DISTINCT p.publisherid,p.name,p.website,COUNT(*)
FROM Publisher p, Poster o, Article a
WHERE p.publisherid=o.publisherid AND o.userid=a.userid
GROUP BY p.publisherid /* Q6.a */;



SELECT publisherid,website FROM PublisherView 
WHERE article_count= (SELECT MAX(article_count) FROM PublisherView)/* Q6.b */;


DROP TRIGGER IF EXISTS update_quality;

DELIMITER //
CREATE TRIGGER update_quality	/* Q7.a */
AFTER INSERT ON Reports
FOR EACH ROW
BEGIN
DECLARE numReport  INTEGER;
SET numReport =  (SELECT COUNT(*)
FROM Article AS a LEFT OUTER JOIN Reports AS r ON a.userid = r.article_userid  
AND a.articleid =r.article_articleid
WHERE a.userid= NEW.article_userid  AND a.articleid = NEW.article_articleid
GROUP BY a.userid, a.articleid);

IF(numReport >= 10) THEN UPDATE Article
SET quality ='Junk' 
WHERE userid= NEW.article_userid  AND articleid = NEW.article_articleid ;
ELSEIF (numReport >5) THEN UPDATE Article
SET quality ='Suspicious' 
WHERE userid= NEW.article_userid  AND articleid = NEW.article_articleid ;
END IF;
END;//
DELIMITER ;

INSERT INTO Reports VALUES(21,3,2,'Kinda incorrect'), (10,4,1,'Team is not correct');
SELECT userid, articleid, quality FROM Article /* Q7.b */;

DROP TRIGGER IF EXISTS update_quality2;

DELIMITER //
CREATE TRIGGER update_quality2  /* Q8.a */
AFTER DELETE ON Reports
FOR EACH ROW
BEGIN
DECLARE numReport INTEGER;
SET numReport =(SELECT COUNT(*) 
FROM Article AS a LEFT OUTER JOIN Reports AS r ON a.userid = r.article_userid 
AND a.articleid =r.article_articleid
WHERE a.userid= OLD.article_userid AND a.articleid=OLD.article_articleid 
GROUP BY a.userid,a.articleid);
IF numReport < 6  THEN UPDATE Article
SET quality='Clean'
WHERE userid=OLD.article_userid AND articleid=OLD.article_articleid;
ELSEIF numReport < 10 THEN UPDATE Article 
SET quality='Suspicious'
WHERE userid=OLD.article_userid AND articleid=OLD.article_articleid;
END IF;
END;//
DELIMITER ;

DELETE FROM Reports 
WHERE userid= 21 AND article_userid= 3 AND article_articleid= 2;

DELETE FROM Reports 
WHERE userid= 10 AND article_userid= 4 AND article_articleid= 1;

SELECT userid, articleid, quality FROM Article /* Q8.b */;
