CREATE table stg_terminals_new as 
            select 
                t1.terminal_id,
                t1.terminal_type,
                t1.terminal_city,
                t1.terminal_address
            from dwh_dim_terminals t1
            left join v_dwh_dim_terminals_his t2
            on t1.terminal_id = t2.terminal_id
            where t2.terminal_id is null ;
 CREATE table stg_cards_new as 
            select 
                t1.card_num,
                t1.account
            from dwh_dim_cards t1
            left join v_dwh_dim_cards_his t2
            on t1.card_num = t2.card_num
            where t2.card_num is null  ;
 CREATE table stg_accounts_new as 
            select 
                t1.account,
                t1.valid_to,
                t1.client
            from dwh_dim_accounts t1
            left join v_dwh_dim_accounts_his t2
            on t1.account = t2.account
            where t2.account is null  ;
 CREATE table stg_clients_new as 
            select 
                t1.client_id,
                t1.last_name,
                t1.first_name,
                t1.patronymic,
                t1.date_of_birth,
                t1.passport_num,
                t1.passport_valid_to,
                t1.phone
            from dwh_dim_clients t1
            left join v_dwh_dim_clients_his t2
            on t1.client_id = t2.client_id
            where t2.client_id is null   ;
