{{config(alias='balancer_v2_gauges_ethereum',
        post_hook='{{ expose_spells(\'["ethereum"]\',
                                    "sector",
                                    "labels",
                                    \'["jacektrocinski"]\') }}')}}

SELECT
    'ethereum' AS blockchain,
    gauge AS address,
    'eth:' || pool AS name,
    'balancer_v2_gauges' AS category,
    'balancerlabs' AS contributor,
    'query' AS source,
    TIMESTAMP('2022-01-13') AS created_at,
    NOW() AS updated_at
FROM
    {{ source('balancer_ethereum', 'LiquidityGaugeFactory_evt_GaugeCreated') }} gauge
UNION ALL
SELECT
    'ethereum' AS blockchain,
    gauge AS address,
    'eth:' || pool AS name,
    'balancer_v2_gauges' AS category,
    'balancerlabs' AS contributor,
    'query' AS source,
    TIMESTAMP('2022-01-13') AS created_at,
    NOW() AS updated_at
FROM
    {{ source('balancer_ethereum', 'CappedLiquidityGaugeFactory_evt_GaugeCreated') }} evt
    INNER JOIN {{ source('balancer_ethereum', 'CappedLiquidityGaugeFactory_call_create') }} call ON call.call_tx_hash = evt.evt_tx_hash;

