CREATE TABLE if not exists dwh_dim_terminals_his(
                    id serial primary key,
                    terminal_id varchar(128),
                    terminal_type varchar(128),
                    terminal_city varchar(128),
                    terminal_address varchar(128),
                    deleted_flg integer default 0,
                    effective_from timestamp default current_timestamp,
                    effective_to timestamp default (to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS'))
               );
drop view if exists v_dwh_dim_terminals_his;
CREATE VIEW v_dwh_dim_terminals_his as
                    select
                    terminal_id,
                    terminal_type,
                    terminal_city,
                    terminal_address
                from dwh_dim_terminals_his 
                where current_timestamp between effective_from and effective_to
                and deleted_flg = 0;
CREATE TABLE if not exists dwh_dim_clients_his(
                    client_id varchar(128),
                    last_name varchar(128),
                    first_name varchar(128),
                    patronymic varchar(128),
                    date_of_birth date,
                    passport_num varchar(128),
                    passport_valid_to timestamp,
                    phone varchar(128),
                    deleted_flg integer default 0,
                    effective_from timestamp default current_timestamp, 
                    effective_to timestamp default (to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS'))
               );
drop view if exists v_dwh_dim_clients_his;
CREATE VIEW v_dwh_dim_clients_his as
                    select
                    client_id,
                    last_name,
                    first_name,
                    patronymic,
                    date_of_birth,
                    passport_num,
                    passport_valid_to,
                    phone
                from dwh_dim_clients_his 
                where current_timestamp between effective_from and effective_to
                and deleted_flg = 0;
CREATE TABLE if not exists dwh_dim_cards_his(
                    card_num varchar(128),
                    account varchar(128),
                    deleted_flg integer default 0,
                    effective_from timestamp default current_timestamp,
                    effective_to timestamp default (to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS'))
               );
drop view if exists v_dwh_dim_cards_his;
CREATE VIEW v_dwh_dim_cards_his as
                    select
                    card_num,
                    account
                from dwh_dim_cards_his 
                where current_timestamp between effective_from and effective_to
                and deleted_flg = 0;
CREATE TABLE if not exists dwh_dim_accounts_his(
                    account varchar(128),
                    valid_to timestamp,
                    client varchar(128),
                    deleted_flg integer default 0,
                    effective_from timestamp default current_timestamp,
                    effective_to timestamp default (to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS'))
               );
drop view if exists v_dwh_dim_accounts_his;
CREATE VIEW v_dwh_dim_accounts_his as
                    select
                    account,
                    valid_to,
                    client
                from dwh_dim_accounts_his 
                where current_timestamp between effective_from and effective_to
                and deleted_flg = 0;
