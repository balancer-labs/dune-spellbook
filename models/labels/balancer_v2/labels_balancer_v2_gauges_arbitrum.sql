{{config(alias='balancer_v2_gauges_arbitrum',
        post_hook='{{ expose_spells(\'["arbitrum"]\',
                                    "sector",
                                    "labels",
                                    \'["jacektrocinski"]\') }}')}}

SELECT
    'arbitrum' AS blockchain,
    gauge.gauge AS address,
    'arb:' || streamer.pool AS name,
    'balancer_v2_gauges' AS category,
    'balancerlabs' AS contributor,
    'query' AS source,
    TIMESTAMP('2022-01-13') AS created_at,
    NOW() AS updated_at
FROM
    {{ source('balancer_ethereum', 'ArbitrumRootGaugeFactory_evt_ArbitrumRootGaugeCreated') }} gauge
    LEFT JOIN {{ source('balancer_arbitrum', 'ChildChainLiquidityGaugeFactory_evt_RewardsOnlyGaugeCreated') }} streamer ON gauge.recipient = streamer.streamer
UNION ALL
SELECT
    'arbitrum' AS blockchain,
    gauge.gauge AS address,
    'arb:' || streamer.pool AS name,
    'balancer_v2_gauges' AS category,
    'balancerlabs' AS contributor,
    'query' AS source,
    TIMESTAMP('2022-01-13') AS created_at,
    NOW() AS updated_at
FROM
    {{ source('balancer_ethereum', 'CappedArbitrumRootGaugeFactory_evt_GaugeCreated') }} gauge
    INNER JOIN {{ source('balancer_ethereum', 'CappedArbitrumRootGaugeFactory_call_create') }} call ON call.call_tx_hash = gauge.evt_tx_hash
    LEFT JOIN {{ source('balancer_arbitrum', 'ChildChainLiquidityGaugeFactory_evt_RewardsOnlyGaugeCreated') }} streamer ON streamer.streamer = call.recipient;

