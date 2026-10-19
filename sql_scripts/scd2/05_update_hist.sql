INSERT INTO dwh_dim_terminals_his (
                terminal_id,terminal_type, terminal_city, terminal_address
                                          ) 
        select 
                 terminal_id, terminal_type, terminal_city, terminal_address
        from stg_terminals_new;
UPDATE dwh_dim_terminals_his
        set effective_to = date_trunc('second',now() - interval '1 second')
        where terminal_id in (select terminal_id from stg_terminals_update) 
        and effective_to = to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS');
INSERT INTO dwh_dim_terminals_his (
                terminal_id, terminal_type, terminal_city, terminal_address
                ) 
        select 
                 terminal_id, terminal_type, terminal_city, terminal_address
        from stg_terminals_update;
UPDATE dwh_dim_terminals_his
        set effective_to = date_trunc('second',now() - interval '1 second')
        where terminal_id in (select terminal_id from stg_terminals_del)  
        and effective_to = to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS');
 INSERT INTO dwh_dim_terminals_his (
                 terminal_id,terminal_type, terminal_city, terminal_address, deleted_flg
                                          ) 
        select 
                 terminal_id,terminal_type, terminal_city, terminal_address, 1
        from stg_terminals_del;
INSERT INTO dwh_dim_cards_his (card_num, account) 
        select 
                card_num, account
        from stg_cards_new;
 UPDATE dwh_dim_cards_his
        set effective_to = date_trunc('second',now() - interval '1 second')
        where card_num in (select card_num from stg_cards_del)  
        and effective_to = to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS');
INSERT INTO dwh_dim_cards_his (
                card_num, account, deleted_flg
                                          ) 
        select 
                    card_num, account, 1
        from stg_cards_del;
INSERT INTO dwh_dim_accounts_his (account, valid_to, client) 
        select 
                account, valid_to, client
        from stg_accounts_new;
UPDATE dwh_dim_accounts_his
        set effective_to = date_trunc('second',now() - interval '1 second')
        where account in (select account from stg_accounts_del)  
        and effective_to = to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS');
INSERT INTO dwh_dim_accounts_his (
                account, valid_to, client, deleted_flg
                                          ) 
        select 
                    account, valid_to, client, 1
        from stg_accounts_del;
INSERT INTO dwh_dim_clients_his (client_id,last_name,first_name,patronymic,
                                         date_of_birth,passport_num,passport_valid_to,phone) 
        select 
                client_id,last_name,first_name,patronymic,
                date_of_birth,passport_num,passport_valid_to,phone
        from stg_clients_new;
 UPDATE dwh_dim_clients_his
        set effective_to = date_trunc('second',now() - interval '1 second')
        where client_id in (select client_id from stg_clients_del)  
        and effective_to = to_timestamp('2999-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS');
 INSERT INTO dwh_dim_clients_his (
                client_id,last_name,first_name,patronymic,
                date_of_birth,passport_num,passport_valid_to,phone, deleted_flg
                                          ) 
        select 
                client_id,last_name,first_name,patronymic,
                date_of_birth,passport_num,passport_valid_to,phone, 1
        from stg_clients_del;
