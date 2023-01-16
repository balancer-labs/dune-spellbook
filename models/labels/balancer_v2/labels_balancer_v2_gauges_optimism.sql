{{config(alias='balancer_v2_gauges_optimism',
        post_hook='{{ expose_spells(\'["optimism"]\',
                                    "sector",
                                    "labels",
                                    \'["jacektrocinski"]\') }}')}}

SELECT
    'optimism' AS blockchain,
    gauge.gauge AS address,
    'op:' || streamer.pool AS name,
    'balancer_v2_gauges' AS category,
    'balancerlabs' AS contributor,
    'query' AS source,
    TIMESTAMP('2022-01-13') AS created_at,
    NOW() AS updated_at
FROM
    {{ source('balancer_ethereum', 'OptimismRootGaugeFactory_evt_OptimismRootGaugeCreated') }} gauge
    LEFT JOIN {{ source('balancer_optimism', 'ChildChainLiquidityGaugeFactory_evt_RewardsOnlyGaugeCreated') }} streamer ON gauge.recipient = streamer.streamer
UNION ALL
SELECT
    'optimism' AS blockchain,
    gauge.gauge AS address,
    'op:' || streamer.pool AS name,
    'balancer_v2_gauges' AS category,
    'balancerlabs' AS contributor,
    'query' AS source,
    TIMESTAMP('2022-01-13') AS created_at,
    NOW() AS updated_at
FROM
    {{ source('balancer_ethereum', 'CappedOptimismRootGaugeFactory_evt_GaugeCreated') }} gauge
    INNER JOIN {{ source('balancer_ethereum', 'CappedOptimismRootGaugeFactory_call_create') }} call ON call.call_tx_hash = gauge.evt_tx_hash
    LEFT JOIN {{ source('balancer_optimism', 'ChildChainLiquidityGaugeFactory_evt_RewardsOnlyGaugeCreated') }} streamer ON streamer.streamer = call.recipient;

