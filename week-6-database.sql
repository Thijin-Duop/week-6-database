
-- =====================================================
-- HANDS-ON LAB: BACKUPS, PITR AND REPLICATION
-- Author: Thijin Simon Duop
-- Database: bootcamp
-- System: PostgreSQL
-- =====================================================


-- =====================================================
-- STEP 1: LOGICAL BACKUP
-- Run these commands in the Linux terminal:
-- =====================================================

-- mkdir -p ~/backups

-- pg_dump -Fc -f ~/backups/bootcamp.dump bootcamp

-- Verify the backup:
-- pg_restore --list ~/backups/bootcamp.dump | head

-- Test restoration:
-- createdb bootcamp_check
-- pg_restore -d bootcamp_check ~/backups/bootcamp.dump


-- =====================================================
-- STEP 2: ENABLE WAL ARCHIVING
-- Add these settings to postgresql.conf
-- =====================================================

-- wal_level = replica
-- archive_mode = on
-- archive_command = 'cp %p /absolute/path/to/backups/wal/%f'

-- Create WAL backup directory:
-- mkdir -p ~/backups/wal

-- Restart PostgreSQL:
-- sudo systemctl restart postgresql

-- Take a base backup:
-- pg_basebackup -D ~/backups/base -Ft -z -Xs -P


-- =====================================================
-- STEP 3: SIMULATE DISASTER AND RECOVER
-- Run these SQL commands in the bootcamp database
-- =====================================================

-- Record the recovery timestamp:
SELECT NOW();

-- Simulate accidental deletion:
-- WARNING: This deletes all records in students.
-- DELETE FROM students;

-- Recovery configuration in postgresql.conf:
-- restore_command = 'cp /absolute/path/to/backups/wal/%f %p'
-- recovery_target_time = 'YYYY-MM-DD HH:MM:SS'
-- recovery_target_action = 'promote'

-- Create recovery signal file in restored data directory:
-- touch /path/to/restored/data/recovery.signal

-- Start PostgreSQL after configuring recovery:
-- sudo systemctl start postgresql

-- Verify recovered records:
-- SELECT COUNT(*) FROM students;


-- =====================================================
-- STEP 4: CREATE REPLICATION USER
-- Execute on the PRIMARY PostgreSQL server
-- =====================================================

CREATE ROLE replicator
WITH REPLICATION LOGIN
PASSWORD 'reppass';


-- =====================================================
-- STEP 5: CONFIGURE REPLICATION ACCESS
-- Add this line to pg_hba.conf
-- =====================================================

-- host replication replicator 127.0.0.1/32 scram-sha-256

-- Reload PostgreSQL configuration:
SELECT pg_reload_conf();


-- =====================================================
-- STEP 6: BUILD THE STANDBY SERVER
-- Run in the Linux terminal:
-- =====================================================

-- pg_basebackup -h 127.0.0.1 -U replicator -D ~/standby -R -P

-- Start standby on port 5433:
-- pg_ctl -D ~/standby -o "-p 5433" -l ~/standby.log start


-- =====================================================
-- STEP 7: MONITOR REPLICATION HEALTH
-- Execute on the PRIMARY PostgreSQL server
-- =====================================================

SELECT
    application_name,
    state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;


-- =====================================================
-- END OF HANDS-ON LAB
-- =====================================================
