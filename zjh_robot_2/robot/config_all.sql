
DELETE FROM `config_mgzjh_robot` WHERE 1=1;
INSERT INTO `config_mgzjh_robot` (`userid`, `username`, `pwd`, `nick`, `phone`, `imei`, `imsi`, `email`, `addr`, `avatar`, `gender`, `balance`, `state`, `channel`, `subChannel`) 
VALUES 
(1,'testzjh1001','a123123','我来自金星01','13521943211','xxxximei00001','yyyyimsi00001','zzz@163b.com01','武林银泰01','av131',1,1000,0,'ch001','sch001'),
(2,'testzjh1002','a123123','我来自金星02','13521943212','xxxximei00002','yyyyimsi00002','zzz@163b.com02','武林银泰02','av132',1,1000,0,'ch002','sch002'),
(3,'testzjh1003','a123123','我来自金星03','13521943213','xxxximei00003','yyyyimsi00003','zzz@163b.com03','武林银泰03','av133',1,1000,0,'ch003','sch003'),
(4,'testzjh1004','a123123','我来自金星04','13521943214','xxxximei00004','yyyyimsi00004','zzz@163b.com04','武林银泰04','av134',1,1000,0,'ch004','sch004'),
(5,'testzjh1005','a123123','我来自金星05','13521943215','xxxximei00005','yyyyimsi00005','zzz@163b.com05','武林银泰05','av135',1,1000,0,'ch005','sch005'),
(6,'testzjh1006','a123123','我来自金星06','13521943216','xxxximei00006','yyyyimsi00006','zzz@163b.com06','武林银泰06','av136',1,1000,0,'ch006','sch006'),
(7,'testzjh1007','a123123','我来自金星07','13521943217','xxxximei00007','yyyyimsi00007','zzz@163b.com07','武林银泰07','av137',1,1000,0,'ch007','sch007'),
(8,'testzjh1008','a123123','我来自金星08','13521943218','xxxximei00008','yyyyimsi00008','zzz@163b.com08','武林银泰08','av138',1,1000,0,'ch008','sch008'),
(9,'testzjh1009','a123123','我来自金星09','13521943219','xxxximei00009','yyyyimsi00009','zzz@163b.com09','武林银泰09','av139',1,1000,0,'ch009','sch009'),
(10,'testzjh1010','a123123','我来自金星10','13521943220','xxxximei00010','yyyyimsi00010','zzz@163b.com10','武林银泰10','av140',1,1000,0,'ch010','sch010'),
(11,'testzjh1011','a123123','我来自金星11','13521943221','xxxximei00011','yyyyimsi00011','zzz@163b.com11','武林银泰11','av141',1,1000,0,'ch011','sch011'),
(12,'testzjh1012','a123123','我来自金星12','13521943222','xxxximei00012','yyyyimsi00012','zzz@163b.com12','武林银泰12','av142',1,1000,0,'ch012','sch012'),
(13,'testzjh1013','a123123','我来自金星13','13521943223','xxxximei00013','yyyyimsi00013','zzz@163b.com13','武林银泰13','av143',1,1000,0,'ch013','sch013'),
(14,'testzjh1014','a123123','我来自金星14','13521943224','xxxximei00014','yyyyimsi00014','zzz@163b.com14','武林银泰14','av144',1,1000,0,'ch014','sch014'),
(15,'testzjh1015','a123123','我来自金星15','13521943225','xxxximei00015','yyyyimsi00015','zzz@163b.com15','武林银泰15','av145',1,1000,0,'ch015','sch015'),
(16,'testzjh1016','a123123','我来自金星16','13521943226','xxxximei00016','yyyyimsi00016','zzz@163b.com16','武林银泰16','av146',1,1000,0,'ch016','sch016'),
(17,'testzjh1017','a123123','我来自金星17','13521943227','xxxximei00017','yyyyimsi00017','zzz@163b.com17','武林银泰17','av147',1,1000,0,'ch017','sch017'),
(18,'testzjh1018','a123123','我来自金星18','13521943228','xxxximei00018','yyyyimsi00018','zzz@163b.com18','武林银泰18','av148',1,1000,0,'ch018','sch018'),
(19,'testzjh1019','a123123','我来自金星19','13521943229','xxxximei00019','yyyyimsi00019','zzz@163b.com19','武林银泰19','av149',1,1000,0,'ch019','sch019'),
(20,'testzjh1020','a123123','我来自金星20','13521943230','xxxximei00020','yyyyimsi00020','zzz@163b.com20','武林银泰20','av150',1,1000,0,'ch020','sch020')
ON DUPLICATE KEY UPDATE `username` = VALUES(`username`), `pwd` = VALUES(`pwd`), `nick` = VALUES(`nick`), `phone` = VALUES(`phone`), `imei` = VALUES(`imei`), `imsi` = VALUES(`imsi`), `email` = VALUES(`email`), `addr` = VALUES(`addr`), `avatar` = VALUES(`avatar`), `gender` = VALUES(`gender`), `balance` = VALUES(`balance`), `state` = VALUES(`state`), `channel` = VALUES(`channel`), `subChannel` = VALUES(`subChannel`);
