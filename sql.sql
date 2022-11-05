CREATE TABLE IF NOT EXISTS `keep_garage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_keep_garage_categories` int(11) NOT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` LONGTEXT NOT NULL ,
  `plate` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `fuel` TINYINT DEFAULT NULL,
  `engine` FLOAT DEFAULT NULL,
  `body` FLOAT DEFAULT NULL,
  `state` BOOLEAN NOT NULL DEFAULT TRUE,
  `is_customizable` BOOLEAN NOT NULL DEFAULT TRUE,
  `metadata` LONGTEXT DEFAULT NULL,
  `permissions` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `keep_garage_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(50) DEFAULT NULL,
  `action` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `data` TEXT DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `keep_garage_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `citizenid` TEXT DEFAULT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `grades` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;