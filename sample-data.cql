CREATE KEYSPACE IF NOT EXISTS sample_ks
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE sample_ks;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    name TEXT,
    email TEXT,
    signup_date DATE
);

INSERT INTO users (id, name, email, signup_date)
VALUES (uuid(), 'Alice', 'alice@example.com', '2023-01-01');

INSERT INTO users (id, name, email, signup_date)
VALUES (uuid(), 'Bob', 'bob@example.com', '2023-02-15');

INSERT INTO users (id, name, email, signup_date)
VALUES (uuid(), 'Charlie', 'charlie@example.com', '2023-03-10');