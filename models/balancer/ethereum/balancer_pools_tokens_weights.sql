{{
    config(
        alias='pools_tokens_weights',
        post_hook='{{ expose_spells(\'["ethereum"]\',
                                    "project",
                                    "balancer",
                                    \'["metacrypto", "jacektrocinski"]\') }}'
    ) 
}}

{% set event_signature = '0xa9ba3ffe0b6c366b81232caab38605a0699ad5398d6cce76f91ee809e322dafc' %}
{% set project_start_date = '2021-04-20' %}

WITH events AS (
    -- Binds
    SELECT
        call_block_number AS block_number,
        index,
        call_trace_address,
        contract_address AS pool,
        token,
        denorm
    FROM balancer_v1_ethereum.`BPool_call_bind`
    INNER JOIN ethereum.transactions ON call_tx_hash = hash
    WHERE call_success = TRUE

    UNION ALL

    -- Rebinds
    SELECT
        call_block_number AS block_number,
        index,
        call_trace_address,
        contract_address AS pool,
        token,
        denorm
    FROM balancer_v1_ethereum.`BPool_call_rebind`
    INNER JOIN ethereum.transactions ON call_tx_hash = hash
    WHERE call_success = TRUE

    UNION ALL
    
    -- Unbinds
    SELECT
        call_block_number AS block_number, 
        index,
        call_trace_address,
        contract_address AS pool,
        token,
        '0' AS denorm
    FROM balancer_v1_ethereum.`BPool_call_unbind`
    INNER JOIN ethereum.transactions ON call_tx_hash = hash
    WHERE call_success = TRUE
),
state_with_gaps AS (
    SELECT
        events.block_number,
        events.pool,
        events.token,
        events.denorm,
        LEAD(events.block_number, 1) OVER (
            PARTITION BY events.pool, events.token 
            ORDER BY events.block_number, index, call_trace_address
        ) AS next_block_number
    FROM events 
), 
settings AS (
    SELECT
        pool, 
        token, 
        denorm
    FROM state_with_gaps s
    WHERE
        next_block_number IS NULL
        AND denorm <> '0'
),
sum_denorm AS (
    SELECT
        pool,
        SUM(denorm) AS sum_denorm
    FROM state_with_gaps s
    WHERE
        next_block_number IS NULL
        AND denorm <> '0'
    GROUP BY pool
),
norm_weights AS (
    SELECT
        settings.pool AS pool_address,
        token AS token_address,
        denorm / sum_denorm AS normalized_weight
    FROM settings
    INNER JOIN sum_denorm ON settings.pool = sum_denorm.pool
)
SELECT
    pool_address AS pool_id,
    token_address,
    normalized_weight
FROM norm_weights

UNION ALL

SELECT
    c.`poolId` AS pool_id,
    tokens.token_address,
    weights.normalized_weight / POWER(1, 18)
FROM balancer_v2_ethereum.`Vault_evt_PoolRegistered` c
INNER JOIN balancer_v2_ethereum.`WeightedPoolFactory_call_create` cc ON c.evt_tx_hash = cc.call_tx_hash
    LATERAL VIEW EXPLODE(cc.tokens) tokens AS token_address
    LATERAL VIEW EXPLODE(cc.weights) weights AS normalized_weight

UNION ALL

SELECT
    c.`poolId` AS pool_id,
    tokens.token_address,
    weights.normalized_weight / POWER(1, 18)
FROM balancer_v2_ethereum.`Vault_evt_PoolRegistered` c
INNER JOIN balancer_v2_ethereum.`WeightedPool2TokensFactory_call_create` cc ON c.evt_tx_hash = cc.call_tx_hash
    LATERAL VIEW EXPLODE(cc.tokens) tokens AS token_address
    LATERAL VIEW EXPLODE(cc.weights) weights AS normalized_weight
;

