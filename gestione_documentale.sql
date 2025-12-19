CREATE DATABASE gestione_documentale
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Seleziona il database
USE gestione_documentale;

-- ============================================
-- TABELLA: RUOLI
-- Contiene i ruoli degli utenti (user, admin, manager)
-- ============================================
CREATE TABLE ruoli (
    id_ruolo INT AUTO_INCREMENT PRIMARY KEY,
    nome_ruolo VARCHAR(50) NOT NULL UNIQUE,
    descrizione TEXT,
    data_creazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: PERMESSI
-- Definisce i permessi associati a ogni ruolo
-- ============================================
CREATE TABLE permessi (
    id_permesso INT AUTO_INCREMENT PRIMARY KEY,
    id_ruolo INT NOT NULL,
    puo_visualizzare BOOLEAN DEFAULT FALSE,
    puo_modificare BOOLEAN DEFAULT FALSE,
    puo_aggiungere BOOLEAN DEFAULT FALSE,
    puo_rimuovere BOOLEAN DEFAULT FALSE,
    gestisce_utenti BOOLEAN DEFAULT FALSE,
    data_creazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ruolo) REFERENCES ruoli(id_ruolo) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: UTENTI
-- Contiene tutti gli utenti dell'azienda
-- ============================================
CREATE TABLE utenti (
    id_utente INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL COMMENT 'Hash della password (usare password_hash in PHP)',
    nome VARCHAR(100) NOT NULL,
    cognome VARCHAR(100) NOT NULL,
    id_ruolo INT NOT NULL,
    telefono VARCHAR(20),
    avatar VARCHAR(255),
    ultimo_accesso DATETIME,
    attivo BOOLEAN DEFAULT TRUE,
    data_creazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_modifica TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ruolo) REFERENCES ruoli(id_ruolo) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_email (email),
    INDEX idx_ruolo (id_ruolo),
    INDEX idx_attivo (attivo)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: SERVER
-- Informazioni sul server di archiviazione
-- ============================================
CREATE TABLE server (
    id_server INT AUTO_INCREMENT PRIMARY KEY,
    nome_server VARCHAR(100) NOT NULL,
    indirizzo_ip VARCHAR(45),
    percorso_base VARCHAR(500) NOT NULL COMMENT 'Percorso root per i documenti',
    capacita_totale_gb DECIMAL(10,2) COMMENT 'Capacità totale in GB',
    spazio_usato_gb DECIMAL(10,2) DEFAULT 0 COMMENT 'Spazio utilizzato in GB',
    stato ENUM('attivo', 'manutenzione', 'offline') DEFAULT 'attivo',
    descrizione TEXT,
    data_creazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_modifica TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_stato (stato)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: TIPI_DOCUMENTO
-- Classificazione dei tipi di documenti
-- ============================================
CREATE TABLE tipi_documento (
    id_tipo INT AUTO_INCREMENT PRIMARY KEY,
    nome_tipo VARCHAR(100) NOT NULL UNIQUE,
    descrizione TEXT,
    icona VARCHAR(50) COMMENT 'Emoji o nome icona',
    colore VARCHAR(7) COMMENT 'Colore HEX per UI',
    estensioni_ammesse VARCHAR(255) COMMENT 'Es: pdf,doc,docx,xls',
    attivo BOOLEAN DEFAULT TRUE,
    ordine INT DEFAULT 0,
    data_creazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_attivo (attivo),
    INDEX idx_ordine (ordine)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: DOCUMENTI
-- Archivio principale dei documenti
-- ============================================
CREATE TABLE documenti (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    nome_file VARCHAR(255) NOT NULL,
    nome_originale VARCHAR(255) NOT NULL COMMENT 'Nome file originale caricato',
    percorso VARCHAR(500) NOT NULL,
    estensione VARCHAR(10),
    mime_type VARCHAR(100),
    dimensione_bytes BIGINT COMMENT 'Dimensione in bytes',
    id_tipo INT NOT NULL,
    id_server INT NOT NULL,
    id_utente_creatore INT NOT NULL,
    id_utente_modifica INT,
    descrizione TEXT,
    tags VARCHAR(500) COMMENT 'Tags separati da virgola',
    anno_riferimento YEAR COMMENT 'Anno di riferimento del documento',
    mese_riferimento TINYINT COMMENT 'Mese di riferimento (1-12)',
    numero_documento VARCHAR(100) COMMENT 'Es: numero fattura',
    importo DECIMAL(15,2) COMMENT 'Importo se applicabile',
    stato ENUM('bozza', 'attivo', 'archiviato', 'eliminato') DEFAULT 'attivo',
    checksum_md5 VARCHAR(32) COMMENT 'Per verifica integrità',
    data_documento DATE COMMENT 'Data del documento',
    data_caricamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_modifica TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_tipo) REFERENCES tipi_documento(id_tipo) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_server) REFERENCES server(id_server) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_utente_creatore) REFERENCES utenti(id_utente) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_utente_modifica) REFERENCES utenti(id_utente) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_tipo (id_tipo),
    INDEX idx_server (id_server),
    INDEX idx_creatore (id_utente_creatore),
    INDEX idx_stato (stato),
    INDEX idx_anno (anno_riferimento),
    INDEX idx_data_documento (data_documento),
    INDEX idx_nome_file (nome_file),
    FULLTEXT idx_ricerca (nome_file, descrizione, tags)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: LOG_ATTIVITA
-- Tracciamento di tutte le operazioni
-- ============================================
CREATE TABLE log_attivita (
    id_log BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT,
    id_documento INT,
    azione ENUM('login', 'logout', 'visualizza', 'crea', 'modifica', 'elimina', 'download', 'upload', 'ripristina', 'gestione_utenti') NOT NULL,
    descrizione TEXT,
    indirizzo_ip VARCHAR(45),
    user_agent VARCHAR(500),
    dati_precedenti JSON COMMENT 'Snapshot dati prima della modifica',
    dati_nuovi JSON COMMENT 'Snapshot dati dopo la modifica',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_documento) REFERENCES documenti(id_documento) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_utente (id_utente),
    INDEX idx_documento (id_documento),
    INDEX idx_azione (azione),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA: SESSIONI (opzionale per gestione sessioni)
-- ============================================
CREATE TABLE sessioni (
    id_sessione VARCHAR(128) PRIMARY KEY,
    id_utente INT NOT NULL,
    indirizzo_ip VARCHAR(45),
    user_agent VARCHAR(500),
    dati_sessione TEXT,
    data_creazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_scadenza DATETIME NOT NULL,
    attiva BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_utente (id_utente),
    INDEX idx_scadenza (data_scadenza)
) ENGINE=InnoDB;

-- ============================================
-- INSERIMENTO DATI INIZIALI
-- ============================================

-- Inserimento Ruoli
INSERT INTO ruoli (nome_ruolo, descrizione) VALUES
('user', 'Utente base - può solo visualizzare i documenti'),
('admin', 'Amministratore - può visualizzare e modificare i documenti'),
('manager', 'Manager - accesso completo: visualizza, modifica, aggiunge, rimuove documenti e gestisce utenti');

-- Inserimento Permessi per ogni ruolo
INSERT INTO permessi (id_ruolo, puo_visualizzare, puo_modificare, puo_aggiungere, puo_rimuovere, gestisce_utenti) VALUES
(1, TRUE, FALSE, FALSE, FALSE, FALSE),  -- user: solo visualizzazione
(2, TRUE, TRUE, TRUE, TRUE, FALSE),     -- admin: visualizza, modifica, aggiunge, rimuove (NO gestione utenti)
(3, TRUE, TRUE, TRUE, TRUE, TRUE);      -- manager: accesso completo + gestione utenti

-- Inserimento Server predefinito
INSERT INTO server (nome_server, indirizzo_ip, percorso_base, capacita_totale_gb, descrizione) VALUES
('Server Principale', '192.168.1.100', '/var/www/documenti/', 1000.00, 'Server principale di archiviazione documenti aziendali');

-- Inserimento Tipi Documento
INSERT INTO tipi_documento (nome_tipo, descrizione, icona, colore, estensioni_ammesse, ordine) VALUES
('Fatture', 'Fatture attive e passive', '🧾', '#EF4444', 'pdf,xml,p7m', 1),
('Contratti', 'Contratti con clienti e fornitori', '📑', '#3B82F6', 'pdf,doc,docx,p7m', 2),
('Preventivi', 'Preventivi e offerte commerciali', '💰', '#22C55E', 'pdf,doc,docx,xls,xlsx', 3),
('Acquisti', 'Ordini e documenti di acquisto', '🛒', '#EAB308', 'pdf,xls,xlsx', 4),
('Bollettini', 'Bollettini e ricevute di pagamento', '📬', '#A855F7', 'pdf,jpg,png', 5),
('Excel', 'Fogli di calcolo e report', '📊', '#10B981', 'xls,xlsx,csv', 6),
('Report', 'Report e analisi', '📝', '#EC4899', 'pdf,doc,docx,ppt,pptx', 7),
('Allegati', 'Allegati e documenti vari', '📎', '#F97316', 'pdf,doc,docx,jpg,png,zip', 8),
('DDT', 'Documenti di trasporto', '🚚', '#06B6D4', 'pdf,xml', 9),
('Note di Credito', 'Note di credito e rettifiche', '📄', '#8B5CF6', 'pdf,xml,p7m', 10);

-- Inserimento Utenti di default
-- IMPORTANTE: Cambiare le password dopo il primo accesso!
-- Tutte le password di default sono: "password"
-- Hash generato con: password_hash('password', PASSWORD_DEFAULT)

INSERT INTO utenti (email, password, nome, cognome, id_ruolo, telefono, attivo) VALUES
-- MANAGER (1 utente)
('m.rossi@azienda.it', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Marco', 'Rossi', 3, '+39 02 1234567', TRUE),

-- ADMIN (2 utenti)
('g.bianchi@azienda.it', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Giuseppe', 'Bianchi', 2, '+39 02 1234568', TRUE),
('a.ferrari@azienda.it', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Anna', 'Ferrari', 2, '+39 02 1234569', TRUE),

-- USER (2 utenti)
('l.verdi@azienda.it', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Luca', 'Verdi', 1, '+39 02 1234570', TRUE),
('s.romano@azienda.it', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Sara', 'Romano', 1, '+39 02 1234571', TRUE);

-- ============================================
-- VISTE UTILI
-- ============================================

-- Vista: Documenti con dettagli completi
CREATE VIEW v_documenti_completi AS
SELECT 
    d.id_documento,
    d.nome_file,
    d.nome_originale,
    d.percorso,
    d.estensione,
    d.dimensione_bytes,
    ROUND(d.dimensione_bytes / 1024 / 1024, 2) AS dimensione_mb,
    d.descrizione,
    d.tags,
    d.anno_riferimento,
    d.mese_riferimento,
    d.numero_documento,
    d.importo,
    d.stato,
    d.data_documento,
    d.data_caricamento,
    d.data_modifica,
    t.nome_tipo,
    t.icona AS icona_tipo,
    t.colore AS colore_tipo,
    s.nome_server,
    CONCAT(u.nome, ' ', u.cognome) AS creato_da,
    u.email AS email_creatore
FROM documenti d
JOIN tipi_documento t ON d.id_tipo = t.id_tipo
JOIN server s ON d.id_server = s.id_server
JOIN utenti u ON d.id_utente_creatore = u.id_utente;

-- Vista: Utenti con ruoli e permessi
CREATE VIEW v_utenti_permessi AS
SELECT 
    u.id_utente,
    u.email,
    u.nome,
    u.cognome,
    CONCAT(u.nome, ' ', u.cognome) AS nome_completo,
    u.telefono,
    u.ultimo_accesso,
    u.attivo,
    u.data_creazione,
    r.nome_ruolo,
    p.puo_visualizzare,
    p.puo_modificare,
    p.puo_aggiungere,
    p.puo_rimuovere,
    p.gestisce_utenti
FROM utenti u
JOIN ruoli r ON u.id_ruolo = r.id_ruolo
JOIN permessi p ON r.id_ruolo = p.id_ruolo;

-- Vista: Statistiche documenti per tipo
CREATE VIEW v_statistiche_tipo AS
SELECT 
    t.id_tipo,
    t.nome_tipo,
    t.icona,
    t.colore,
    COUNT(d.id_documento) AS totale_documenti,
    COALESCE(SUM(d.dimensione_bytes), 0) AS dimensione_totale_bytes,
    ROUND(COALESCE(SUM(d.dimensione_bytes), 0) / 1024 / 1024, 2) AS dimensione_totale_mb
FROM tipi_documento t
LEFT JOIN documenti d ON t.id_tipo = d.id_tipo AND d.stato = 'attivo'
GROUP BY t.id_tipo, t.nome_tipo, t.icona, t.colore
ORDER BY t.ordine;

-- Vista: Log attività recenti
CREATE VIEW v_log_recenti AS
SELECT 
    l.id_log,
    l.azione,
    l.descrizione,
    l.indirizzo_ip,
    l.timestamp,
    CONCAT(u.nome, ' ', u.cognome) AS utente,
    u.email AS email_utente,
    d.nome_file AS documento
FROM log_attivita l
LEFT JOIN utenti u ON l.id_utente = u.id_utente
LEFT JOIN documenti d ON l.id_documento = d.id_documento
ORDER BY l.timestamp DESC;

-- ============================================
-- STORED PROCEDURES UTILI
-- ============================================

DELIMITER //

-- Procedura: Registra attività nel log
CREATE PROCEDURE sp_registra_log(
    IN p_id_utente INT,
    IN p_id_documento INT,
    IN p_azione VARCHAR(20),
    IN p_descrizione TEXT,
    IN p_ip VARCHAR(45),
    IN p_user_agent VARCHAR(500)
)
BEGIN
    INSERT INTO log_attivita (id_utente, id_documento, azione, descrizione, indirizzo_ip, user_agent)
    VALUES (p_id_utente, p_id_documento, p_azione, p_descrizione, p_ip, p_user_agent);
END //

-- Procedura: Verifica permessi utente
CREATE PROCEDURE sp_verifica_permesso(
    IN p_id_utente INT,
    IN p_permesso VARCHAR(20),
    OUT p_autorizzato BOOLEAN
)
BEGIN
    DECLARE v_permesso BOOLEAN DEFAULT FALSE;
    
    SELECT 
        CASE p_permesso
            WHEN 'visualizza' THEN p.puo_visualizzare
            WHEN 'modifica' THEN p.puo_modificare
            WHEN 'aggiungi' THEN p.puo_aggiungere
            WHEN 'rimuovi' THEN p.puo_rimuovere
            WHEN 'gestisci_utenti' THEN p.gestisce_utenti
            ELSE FALSE
        END INTO v_permesso
    FROM utenti u
    JOIN permessi p ON u.id_ruolo = p.id_ruolo
    WHERE u.id_utente = p_id_utente AND u.attivo = TRUE;
    
    SET p_autorizzato = COALESCE(v_permesso, FALSE);
END //

-- Procedura: Aggiorna spazio server
CREATE PROCEDURE sp_aggiorna_spazio_server(IN p_id_server INT)
BEGIN
    UPDATE server s
    SET spazio_usato_gb = (
        SELECT COALESCE(SUM(d.dimensione_bytes) / 1024 / 1024 / 1024, 0)
        FROM documenti d
        WHERE d.id_server = p_id_server AND d.stato != 'eliminato'
    )
    WHERE s.id_server = p_id_server;
END //

DELIMITER ;

-- ============================================
-- TRIGGER
-- ============================================

DELIMITER //

-- Trigger: Aggiorna spazio server dopo inserimento documento
CREATE TRIGGER tr_documento_insert_spazio
AFTER INSERT ON documenti
FOR EACH ROW
BEGIN
    CALL sp_aggiorna_spazio_server(NEW.id_server);
END //

-- Trigger: Aggiorna spazio server dopo modifica documento
CREATE TRIGGER tr_documento_update_spazio
AFTER UPDATE ON documenti
FOR EACH ROW
BEGIN
    IF OLD.id_server != NEW.id_server OR OLD.dimensione_bytes != NEW.dimensione_bytes THEN
        CALL sp_aggiorna_spazio_server(OLD.id_server);
        CALL sp_aggiorna_spazio_server(NEW.id_server);
    END IF;
END //

-- Trigger: Aggiorna spazio server dopo eliminazione documento
CREATE TRIGGER tr_documento_delete_spazio
AFTER DELETE ON documenti
FOR EACH ROW
BEGIN
    CALL sp_aggiorna_spazio_server(OLD.id_server);
END //

DELIMITER ;

-- ============================================
-- INDICI AGGIUNTIVI PER PERFORMANCE
-- ============================================

-- Indice composto per ricerche frequenti
CREATE INDEX idx_doc_tipo_stato ON documenti(id_tipo, stato);
CREATE INDEX idx_doc_anno_mese ON documenti(anno_riferimento, mese_riferimento);
CREATE INDEX idx_log_utente_azione ON log_attivita(id_utente, azione);

-- ============================================
-- COMMENTI FINALI
-- ============================================

/*
NOTE IMPORTANTI:

1. PASSWORD DEFAULT:
   L'utente manager@azienda.it ha password: "password"
   (hash generato con password_hash PHP)
   CAMBIARE IMMEDIATAMENTE dopo il primo accesso!

2. BACKUP:
   Eseguire backup regolari del database e dei file.

3. SICUREZZA:
   - Usare sempre prepared statements in PHP
   - Implementare rate limiting per login
   - Usare HTTPS in produzione

4. MANUTENZIONE:
   - Pulire periodicamente log_attivita vecchi
   - Monitorare spazio server
   - Verificare integrità documenti con checksum

5. PHP - Esempio connessione:
   
   $pdo = new PDO(
       'mysql:host=localhost;dbname=gestione_documentale;charset=utf8mb4',
       'username',
       'password',
       [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
   );

*/

-- Fine script SQL
SELECT 'Database gestione_documentale creato con successo!' AS Messaggio;
