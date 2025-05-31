-- Trigger = When an event happens, do something
--           ex. (INSERT, UPDATE, DELETE)
--           checks data, handles errors, auditing table

CREATE DATABASE mhs;

USE mhs

CREATE TABLE mahasiswa (
	nim VARCHAR(45),
	nama VARCHAR(255),
	tanggal_masuk DATE);
	
CREATE TABLE log_masuk (
	nim VARCHAR(45),
	tanggal_masuk DATE
)
	
DELIMITER //
CREATE TRIGGER catat_tanggal_masuk
AFTER INSERT ON mahasiswa
FOR EACH ROW
BEGIN
	INSERT INTO log_masuk VALUES
	(new.nim, CURDATE());
END //

DROP TRIGGER catat_tanggal_masuk

INSERT INTO mahasiswa(nim, nama) VALUES('123', 'rakha');


DELIMITER //
CREATE TRIGGER update_nim
AFTER UPDATE ON mahasiswa
FOR EACH ROW
BEGIN
 
 UPDATE log_masuk SET nim = new.nim 
 WHERE nim = old.nim;
END //

UPDATE mahasiswa SET nim = '345' WHERE nim = '123';

CREATE TABLE log_keluar(nim VARCHAR(45), tanggal_keluar DATE);

DELIMITER //
CREATE TRIGGER catat_keluar
AFTER DELETE ON mahasiswa
FOR EACH ROW
BEGIN
	INSERT INTO log_keluar VALUES(
	old.nim, CURDATE());
END //

DELETE FROM mahasiswa WHERE nim = '345';


DELIMITER //
CREATE TRIGGER cek_panjang_nim
BEFORE INSERT ON mahasiswa
FOR EACH ROW
BEGIN
	IF LENGTH(new.nim) < 8 THEN
		SIGNAL SQLSTATE'45000'
		SET MESSAGE_TEXT = 
		"Panjang NIM harus lebih dari 8 angka";
	END IF;
END //

INSERT INTO mahasiswa(nim, nama) VALUES(
'123456789', 'rakha');