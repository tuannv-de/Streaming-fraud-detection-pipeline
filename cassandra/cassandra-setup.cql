CREATE KEYSPACE IF NOT EXISTS money_keyspace
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS money_keyspace.transactions (
    transaction_id text,
    sender_account text,
    receiver_account text,
    amount bigint,
    timestamp timestamp,
    sender_balance_before bigint,
    receiver_balance_before bigint,
    PRIMARY KEY (transaction_id)
);
