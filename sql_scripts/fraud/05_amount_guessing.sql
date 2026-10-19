 DROP VIEW if exists v_selection_amount;
    CREATE VIEW v_selection_amount as
    SELECT 
    card_num,
    SUM(CASE WHEN oper_result = 'SUCCESS' THEN 1 ELSE 0 END) AS success_count,
    SUM(CASE WHEN oper_result = 'REJECT' THEN 1 ELSE 0 END) AS reject_count,
    MAX(CASE WHEN oper_result = 'SUCCESS' 
            THEN transaction_date
            ELSE NULL END) as event_dt
    from (
        SELECT 
        card_num,
        transaction_date,
        amount,
        oper_result,
        SUM(CASE WHEN is_chain = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY card_num ORDER BY transaction_date) AS chain_id
        FROM (
            SELECT 
            card_num,
            transaction_date,
            oper_result,
            amount,
            prev_amount,
            prev_result,
            prev_date,
            EXTRACT(EPOCH FROM (transaction_date - prev_date))/60 as dt,
            CASE 
            when prev_amount > amount
            and EXTRACT(EPOCH FROM (transaction_date - prev_date))/60 <= 20 
            AND prev_result = 'REJECT' 
            THEN 1
            ELSE 0
            END AS is_chain
            FROM (
                select * from (
                    select 
                    transaction_date,
                    amount,
                    card_num,
                    oper_result,
                    LAG(amount) OVER (PARTITION BY card_num ORDER BY transaction_date) AS prev_amount,
                    LAG(oper_result) OVER (PARTITION BY card_num ORDER BY transaction_date) AS prev_result,
                    LAG(transaction_date) OVER (PARTITION BY card_num ORDER BY transaction_date) AS prev_date
                    from dwh_fact_transactions
                    order by card_num, transaction_date
                    )
            where prev_amount is not null
                        )
        )
        )
    GROUP BY card_num, chain_id
    HAVING 
    COUNT(*) > 3 
    AND SUM(CASE WHEN oper_result = 'SUCCESS' THEN 1 ELSE 0 END) = 1
    AND MAX(transaction_date) = MAX(CASE 
                                    WHEN oper_result = 'SUCCESS' 
                                    THEN transaction_date
                                    ELSE NULL END)
    and extract(minutes from AGE(MAX(transaction_date),MIN(transaction_date))) <= 20 ;
INSERT INTO REP_FRAUD (
                event_dt,passport,fio,phone,event_type
                                          ) 
        select 
                event_dt,passport,fio,phone,event_type
        from (

        select 
        t2.event_dt,
        t1.passport_num as passport,
        CONCAT(t1.last_name, ' ', t1.first_name, ' ', t1.patronymic) AS fio,
        t1.phone,
        'Попытка подбора суммы.' as event_type,
        t1.card_num
        from (
            select distinct
            t4.first_name as first_name,
            t4.last_name as last_name,
            t4.patronymic as patronymic,
            t4.phone as phone,
            t4.passport_num as passport_num,
            t1.card_num
            from dwh_fact_transactions t1
            inner join dwh_dim_cards t2
            on t1.card_num = t2.card_num
            inner join dwh_dim_accounts t3
            on t2.account = t3.account
            inner join dwh_dim_clients t4
            on t3.client = t4.client_id
            where  t1.card_num in (select card_num from v_selection_amount )
       ) t1
    inner join  v_selection_amount t2
    on t1.card_num = t2.card_num);