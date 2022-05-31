CREATE TABLE IF NOT EXISTS `keep_garage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` LONGTEXT NOT NULL DEFAULT '0',
  `plate` varchar(50) DEFAULT NULL,
  `fakeplate` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `fuel` INT(11) DEFAULT NULL,
  `engine` FLOAT DEFAULT NULL,
  `body` FLOAT DEFAULT NULL,
  `state` INT(11) DEFAULT NULL,
  `driving_distance` INT(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;