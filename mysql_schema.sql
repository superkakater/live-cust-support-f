CREATE DATABASE IF NOT EXISTS `live-cust-support`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE `live-cust-support`;

-- =========================
-- 1) staff
-- =========================
DROP TABLE IF EXISTS `staff`;
CREATE TABLE `staff` (
  `staffId`   INT NOT NULL AUTO_INCREMENT,
  `staffName` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`staffId`),
  UNIQUE KEY `uq_staff_staffName` (`staffName`)
);

-- =========================
-- 2) user (customers)
-- =========================
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `userId`   INT NOT NULL AUTO_INCREMENT,
  `userName` VARCHAR(45) NOT NULL,
  `custId`   INT NOT NULL,
  PRIMARY KEY (`userId`),
  UNIQUE KEY `uq_user_userName` (`userName`),
  KEY `idx_user_custId` (`custId`),
  CONSTRAINT `fk_user_staff_custId`
    FOREIGN KEY (`custId`) REFERENCES `staff`(`staffId`)
    ON UPDATE CASCADE
);

-- =========================
-- 3) conversation
-- =========================
DROP TABLE IF EXISTS `conversation`;
CREATE TABLE `conversation` (
  `conversationId` INT NOT NULL AUTO_INCREMENT,
  `customerId`     INT NOT NULL,
  `staffId`        INT NOT NULL,
  `creDate`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status`         ENUM('ACTIVE','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`conversationId`),
  KEY `idx_conversation_customerId` (`customerId`),
  KEY `idx_conversation_staffId` (`staffId`),
  CONSTRAINT `fk_conversation_user_customerId`
    FOREIGN KEY (`customerId`) REFERENCES `user`(`userId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_conversation_staff_staffId`
    FOREIGN KEY (`staffId`) REFERENCES `staff`(`staffId`)
    ON UPDATE CASCADE
);

-- =========================
-- 4) message
-- =========================
DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
  `senderId`       INT NOT NULL,
  `receiverId`     INT NOT NULL,
  `content`        TEXT NOT NULL,
  `sendDate`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `conversationId` INT NOT NULL,
  PRIMARY KEY (`sendDate`, `conversationId`),
  KEY `idx_message_conversationId` (`conversationId`),
  CONSTRAINT `fk_message_conversation_conversationId`
    FOREIGN KEY (`conversationId`) REFERENCES `conversation`(`conversationId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
