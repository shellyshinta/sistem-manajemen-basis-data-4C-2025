USE peternakan_bebek_2
-- no 1

DELIMITER //
CREATE PROCEDURE TampilkanProduksiTelur(
    IN tanggal_awal DATE,
    IN jumlah_hari INT
)
BEGIN
    SELECT 
        pt.id_produksi,
        pt.tanggal_produksi_telur,
        pt.jumlah_telur,
        k.nama_kandang,
        k.lokasi,
        p.nama_peternak
    FROM produksi_telur pt
    JOIN kandang k ON pt.id_kandang = k.id_kandang
    JOIN peternak p ON k.id_peternak = p.id_peternak
    WHERE pt.tanggal_produksi_telur >= tanggal_awal
      AND pt.tanggal_produksi_telur <= DATE_ADD(tanggal_awal, INTERVAL jumlah_hari DAY)
    ORDER BY pt.tanggal_produksi_telur;
END //
DELIMITER ;

CALL TampilkanProduksiTelur('2025-05-01', 7);
CALL TampilkanProduksiTelur('2025-02-01', 30);
-- DROP PROCEDURE jika ingin dihapus
DROP PROCEDURE TampilkanProduksiTelur;


-- no 2

DELIMITER //

CREATE PROCEDURE HapusPembelianLebihSetahun()
BEGIN
    DELETE FROM detail_pembelian
    WHERE 
        status_pembelian = 'lunas'  
        AND DATEDIFF(CURDATE(), tanggal) >= 365;  
END //

DELIMITER ;

-- Contoh pemanggilan prosedur
CALL HapusPembelianLebihSetahun();

-- Cek isi tabel setelah pemanggilan
SELECT * FROM detail_pembelian;

-- Drop prosedurnya jika tidak digunakan lagi
DROP PROCEDURE HapusPembelianLebihSetahun;

SELECT DISTINCT status_pembelian FROM detail_pembelian;

-- dateiff berdasarkan hari 

-- no 3

DELIMITER //
CREATE PROCEDURE UbahStatus7Pembelian()
BEGIN
    UPDATE detail_pembelian
    SET status_pembelian = 'lunas'
    WHERE status_pembelian = 'belum lunas'
    LIMIT 7;
END //
DELIMITER ;

-- Contoh pemanggilan
CALL UbahStatus7Pembelian();

-- Cek hasilnya
SELECT * FROM detail_pembelian;

-- Hapus prosedur jika tidak digunakan lagi
 DROP PROCEDURE UbahStatus7Pembelian;
 
 -- no4
 
DELIMITER //
CREATE PROCEDURE EditTanggalPembelianJikaTidakAktif(
    IN id INT,
    IN tanggal_baru DATE
)
BEGIN
    DECLARE hasil VARCHAR(200); -- Variabel untuk menyimpan pesan hasil
    
    UPDATE detail_pembelian
    SET tanggal = tanggal_baru
    WHERE id_pembeli = id
      AND NOT EXISTS (  -- Hanya update jika tidak ada transaksi aktif
          SELECT 1 FROM detail_pembelian
          WHERE id_pembeli = id 
            AND status_pembelian IN ('belum lunas', 'belum dibayar')
      );
    
    SET hasil = 'Selesai menjalankan prosedur. Jika data tidak berubah, kemungkinan pembeli masih punya transaksi aktif.';
    SELECT hasil AS message;
END //
DELIMITER ;

-- Contoh pemanggilan:
CALL EditTanggalPembelianJikaTidakAktif(3, '2025-04-12');
SELECT * FROM detail_pembelian
 
-- Hapus prosedur jika tidak digunakan lagi 
DROP PROCEDURE EditTanggalPembelianJikaTidakAktif;

-- no 5

DELIMITER //
CREATE PROCEDURE UpdateStatusPembelianBerdasarkanJumlah()
BEGIN
    -- Create temporary table for last month's transactions
    CREATE TEMPORARY TABLE TotalPembelian AS
    SELECT 
        id_pembelian,
        jumlah_telur * harga_satuan AS total_pembayaran
    FROM detail_pembelian
    WHERE tanggal >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

    -- Count qualifying transactions
    SET @jumlah_data := (SELECT COUNT(*) FROM TotalPembelian);

    -- Update only if data exists
    IF @jumlah_data > 1 THEN
        -- Calculate min and max
        SET @min_bayar := (SELECT MIN(total_pembayaran) FROM TotalPembelian);
        SET @max_bayar := (SELECT MAX(total_pembayaran) FROM TotalPembelian);

        -- Update status for smallest transaction
        UPDATE detail_pembelian
        SET status_pembelian = 'Non-Aktif'
        WHERE id_pembelian IN (
            SELECT id_pembelian FROM TotalPembelian
            WHERE total_pembayaran = @min_bayar
        );

        -- Update status for largest transaction
        UPDATE detail_pembelian
        SET status_pembelian = 'Aktif'
        WHERE id_pembelian IN (
            SELECT id_pembelian FROM TotalPembelian
            WHERE total_pembayaran = @max_bayar
        );

        -- Update status for middle transactions
        UPDATE detail_pembelian
        SET status_pembelian = 'Pasif'
        WHERE id_pembelian IN (
            SELECT id_pembelian FROM TotalPembelian
            WHERE total_pembayaran > @min_bayar AND total_pembayaran < @max_bayar
        );
    END IF;

    -- Clean up
    DROP TEMPORARY TABLE TotalPembelian;
END //
DELIMITER ;

-- panggil procedure
CALL UpdateStatusPembelianBerdasarkanJumlah();

-- Lihat hasil update status
SELECT 
    id_pembelian, tanggal, jumlah_telur, harga_satuan,
    jumlah_telur * harga_satuan AS total_pembayaran,
    status_pembelian
FROM detail_pembelian;

-- hapus procedure
DROP PROCEDURE UpdateStatusPembelianBerdasarkanJumlah

-- no 6 

DELIMITER //

CREATE PROCEDURE HitungTransaksiBerhasilBulanIni()
BEGIN
    DECLARE jumlah INT DEFAULT 0;
    DECLARE i INT DEFAULT 1;
    DECLARE total_row INT;

    -- Buat temporary table untuk simpan id transaksi yang statusnya 'lunas' dalam 1 bulan terakhir
    DROP TEMPORARY TABLE IF EXISTS TransaksiBerhasil;
    CREATE TEMPORARY TABLE TransaksiBerhasil (
        id_pembelian INT
    );

    INSERT INTO TransaksiBerhasil (id_pembelian)
    SELECT id_pembelian
    FROM detail_pembelian
    WHERE status_pembelian = 'lunas'
      AND tanggal >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

    -- Hitung jumlah baris di temporary table
    SELECT COUNT(*) INTO total_row FROM TransaksiBerhasil;

    -- Loop untuk menghitung jumlah
    WHILE i <= total_row DO
        SET jumlah = jumlah + 1;
        SET i = i + 1;
    END WHILE;

    -- Tampilkan hasil
    SELECT jumlah AS jumlah_transaksi_berhasil;

    -- Hapus temporary table
    DROP TEMPORARY TABLE IF EXISTS TransaksiBerhasil;
END //

DELIMITER ;

CALL HitungTransaksiBerhasilBulanIni();
SELECT * FROM detail_pembelian;
DROP PROCEDURE HitungTransaksiBerhasilBulanIni

SELECT * FROM detail_pembelian 
WHERE status_pembelian = 'lunas' 
AND tanggal BETWEEN CURDATE() - INTERVAL 1 MONTH AND CURDATE();

SELECT * FROM detail_pembelian 
ORDER BY tanggal DESC 
LIMIT 0, 1000;

