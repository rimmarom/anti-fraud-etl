INSERT INTO REP_FRAUD (
                event_dt,passport,fio,phone,event_type
                              ) 
        SELECT 
                event_dt,passport,fio,phone,event_type
        from ( 
                SELECT distinct
                min(transaction_date) over (partition by passport_num) as event_dt,
                passport_num as passport,
                concat(last_name, ' ', first_name, ' ', patronymic) as fio,
                phone,
                'Совершение операции при просроченном паспорте.' as event_type
                from (
                    SELECT
                    t4.first_name as first_name,
                    t4.last_name as last_name,
                    t4.patronymic as patronymic,
                    t4.phone as phone,
                    t4.passport_num as passport_num,
                    t1.transaction_date as transaction_date,
                    t4.passport_valid_to as passport_valid_to
                    from dwh_fact_transactions t1
                    inner join dwh_dim_cards t2
                    on t1.card_num = t2.card_num
                    inner join dwh_dim_accounts t3
                    on t2.account = t3.account
                    inner join dwh_dim_clients t4
                    on t3.client = t4.client_id
                    where  t1.transaction_date > t4.passport_valid_to
                ));