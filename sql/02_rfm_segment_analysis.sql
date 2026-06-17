use customer_retention ;
select * from rfm_segments;

-- Verify import was successful
SELECT
    COUNT(*)                    AS total_customers,
    COUNT(DISTINCT Segment)     AS total_segments,
    ROUND(SUM(Monetary), 2)     AS total_revenue,
    MIN(Recency)                AS min_recency,
    MAX(Recency)                AS max_recency
FROM rfm_segments;

-- =========================================
-- QUERY 1 : SEGMENT OVERVIEW WITH FULL BUSINESS METRICS
-- =========================================

-- Business question: What is the complete picture of every segment?
-- SQL concept: GROUP BY, multiple aggregations, window function for percentage
-- Finding:  Champions and Loyal Customers represent only 41.5% of customers but generate 83.1% of total revenue.


SELECT
    Segment,
    COUNT(*)                                        AS customer_count,
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER (), 1)                 AS customer_pct,
    ROUND(SUM(Monetary), 2)                         AS total_revenue,
    ROUND(SUM(Monetary) * 100.0 /
          SUM(SUM(Monetary)) OVER (), 1)            AS revenue_pct,
    ROUND(AVG(Recency), 0)                          AS avg_recency_days,
    ROUND(AVG(Frequency), 1)                        AS avg_frequency,
    ROUND(AVG(Monetary), 2)                         AS avg_monetary,
    ROUND(AVG(avg_order_value), 2)                  AS avg_order_value
FROM rfm_segments
GROUP BY Segment
ORDER BY total_revenue DESC;

-- Observation

-- The segment analysis reveals a significant concentration of business value among the top-performing customer groups. Although Champions and 
-- Loyal Customers account for only 41.5% of the customer base (2,435 customers), they generate approximately £14.43 million, representing 83.1% of
--  total revenue.

-- Champions alone contribute 68.3% of total revenue (£11.86 million) while representing just 22.1% of customers, highlighting their critical 
-- importance to the business. In contrast, segments such as Hibernating (13.2% of customers) contribute only 0.7% of revenue, indicating that 
-- not all customer groups have equal business value.

-- From a strategic perspective, the company should prioritize retaining Champions and Loyal Customers while implementing targeted re-engagement
-- campaigns for high-value inactive segments such as Cannot Lose Them and At Risk.

-- =========================================
-- QUERY 2 : REVENUE CONCENTRATION RISK
-- =========================================

-- Business question: How dangerous is our dependency on Champions?
-- SQL concept: CASE WHEN for grouping, SUM, window function percentage
-- Finding: Champions account for only 22.1% of customers but generate 68.3% of total revenue, indicating a high concentration of business value.

select 
case
when Segment = 'Champions' then 'Champions'
else 'All other segments'
end as customers_group,
count(*) as customer_count,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as customer_pct,
round(sum(Monetary),2) as revenue,
ROUND(SUM(Monetary) * 100.0 / SUM(SUM(Monetary)) OVER (), 1)  AS revenue_pct
from rfm_segments
group by 
case
when Segment = 'Champions' then 'Champions'
else 'All other segments'
end
order by revenue desc;

-- Observation

-- The analysis reveals that the business is heavily dependent on its Champion customers. Although Champions represent only 1,297 customers 
-- (22.1% of the customer base), they generate approximately £11.86 million, accounting for 68.3% of total revenue.

-- In comparison, the remaining 4,581 customers (77.9% of the customer base) collectively generate only £5.52 million, representing 31.7% of 
-- total revenue.

-- This indicates a high level of revenue concentration, where losing even a small portion of Champion customers could have a significant financial 
-- impact. As a result, customer retention strategies such as VIP programs, exclusive rewards, and personalized engagement should be prioritized to 
-- protect this critical revenue segment.


-- =========================================
-- QUERY 3 : AT RISK REVENUE EXPOTURE BY PRIORITY TIER
-- =========================================

-- Business question: How much revenue is actively at risk right now?
-- SQL concept: WHERE with IN clause, GROUP BY, SUM, AVG, ORDER BY
-- Finding: 616 customers across At Risk and Cannot Lose Them segments
--          represent £1.51M in historical revenue — 8.7% of total revenue
--          at risk from 10.5% of the customer base.

select Segment ,count(*) as total_customers ,
round(sum(Monetary),2) as total_revenue,
ROUND(AVG(Monetary), 2)  AS avg_revenue_per_customer,
round(avg(Recency),2) as avg_inactive_days,
round(min(Monetary),2) as minimun_customer_revenue,
round(max(Monetary),2) as maximum_customer_revenue
 from rfm_segments
 where Segment in ('At Risk','Cannot Lose Them')
 group by Segment
 order by total_revenue desc;


-- The analysis identifies two critical customer groups that require immediate retention efforts: Cannot Lose Them and At Risk.

-- The Cannot Lose Them segment consists of only 223 customers, yet they have historically generated approximately £982,122 in revenue, 
-- with an average customer value of £4,404. On average, these customers have been inactive for 342 days, suggesting that many of them may 
-- already be close to churning completely. The highest-value customer in this segment alone has contributed more than £77,556.

-- Similarly, the At Risk segment contains 393 customers who have generated an additional £523,525 in historical revenue, averaging £1,332 
-- per customer. These customers have been inactive for an average of 369 days, making them strong candidates for targeted win-back campaigns.

-- Combined, these two segments represent 616 customers and approximately £1.51 million in historical revenue. Although they account for only 10.5% 
-- of the customer base, they represent a substantial revenue retention opportunity.

-- From a business perspective, these findings suggest that investing in personalized retention and re-engagement campaigns for these customers
--  could protect a significant portion of future revenue while being considerably more cost-effective than acquiring new customers.


-- =========================================
-- QUERY 4 : CHAMPION CUSTOMERS DEEP DIVE 
-- =========================================


-- Business question: Who exactly are our top 20 Champion customers?
-- SQL concept: WHERE, ORDER BY, LIMIT, clean column selection
-- Finding: The top Champion customers exhibit extremely high lifetime value, frequent purchasing behaviour, and very recent activity, 
-- making them the company's most strategically important customers.
 
 SELECT
    customer_id,
    Recency                                         AS days_since_last_purchase,
    Frequency                                       AS total_orders,
    ROUND(Monetary, 2)                              AS lifetime_revenue,
    ROUND(avg_order_value, 2)                       AS avg_order_value,
    tenure_days,
    R_Score,
    F_Score,
    M_Score,
    RFM_Total
FROM rfm_segments
WHERE Segment = 'Champions'
ORDER BY Monetary DESC
LIMIT 20;

-- Observation

-- The analysis identifies the company's top 20 Champion customers, who combine the three most desirable characteristics: they have purchased recently,
--  buy frequently, and generate exceptionally high lifetime revenue.

-- The highest-value Champion customer has generated approximately £580,987 in lifetime revenue while placing 145 orders and making a purchase
--  just 1 day before the reference date. Similarly, several other Champion customers have contributed well over £100,000 each while maintaining 
--  very high purchase frequency.

-- All customers in this list have achieved the maximum RFM score of 15 (5-5-5), confirming that they are the most engaged and valuable 
-- customers in the business.

-- From a business perspective, these customers should receive premium treatment through VIP loyalty programmes, early access to new products,
--  exclusive offers, and personalized communication. Retaining even a small number of these customers could protect a substantial portion of 
-- the company's overall revenue.



-- =========================================
-- QUERY 5 : FREQUENCY DISTRIBUTION BY SEGMENTS
-- =========================================


-- Business question: Do segments show meaningfully different purchasing behaviour, validating our scoring?
-- SQL concept: GROUP BY, AVG, MIN, MAX, ROUND, ORDER BY
-- Finding: The segments display distinct differences in purchase frequency, spending, and recency, confirming that the RFM model successfully separates customers by value and engagement.

SELECT
    Segment,
    COUNT(*)                                        AS customer_count,
    ROUND(AVG(Frequency), 1)                        AS avg_orders,
    MIN(Frequency)                                  AS min_orders,
    MAX(Frequency)                                  AS max_orders,
    ROUND(AVG(Monetary), 2)                         AS avg_spend,
    ROUND(AVG(Recency), 0)                          AS avg_recency
FROM rfm_segments
GROUP BY Segment
ORDER BY avg_orders DESC;


-- Observation

-- The analysis confirms that the RFM segmentation model successfully distinguishes customers based on their purchasing behavior.

-- Champion customers have the highest average purchase frequency and spending levels while maintaining the lowest average recency,
--  indicating that they buy often, spend heavily, and have purchased recently. In contrast, Hibernating and About to Sleep customers exhibit 
--  very low order frequency, lower average spending, and significantly longer periods since their last purchase.

-- The gradual differences across segments—such as Potential Loyalists, Loyal Customers, At Risk, and Cannot Lose Them—demonstrate that the scoring 
-- system effectively captures the customer lifecycle rather than creating arbitrary groups.

-- From a business perspective, these results validate that the RFM framework is a reliable tool for prioritizing retention strategies, 
-- identifying high-value customers, and allocating marketing resources more efficiently.



-- =========================================
-- QUERY 6 : RECENCY DISTRIBUTION BY SEGMENTS 
-- =========================================


-- Business question: How inactive are At Risk and Cannot Lose Them
--                   compared to active segments?
-- SQL concept: GROUP BY, AVG, MIN, MAX on Recency, ORDER BY
-- Finding: At Risk and Cannot Lose Them customers have not purchased for nearly a year on average, making them strong candidates for retention campaigns.


SELECT
    Segment,
    COUNT(*)                                        AS customer_count,
    ROUND(AVG(Recency), 0)                          AS avg_recency_days,
    MIN(Recency)                                    AS most_recent_days,
    MAX(Recency)                                    AS least_recent_days,
    ROUND(AVG(Recency) / 30.0, 1)                   AS avg_recency_months
FROM rfm_segments
GROUP BY Segment
ORDER BY avg_recency_days ASC;

-- Observation

-- The recency analysis clearly demonstrates a strong separation between active and inactive customer segments, confirming that the RFM model 
-- effectively captures customer engagement levels.

-- Champion customers purchased most recently, with an average recency of only 20 days (0.7 months), while Potential Loyalists and New 
-- Customers have also remained highly active with average recencies of 26 days and 30 days, respectively.

-- In contrast, the two highest-priority retention segments show significantly longer periods of inactivity. Cannot Lose Them customers 
-- have not purchased for an average of 342 days (11.4 months), while At Risk customers have been inactive for approximately 369 days (12.3 months). Despite their long inactivity, these segments have historically generated substantial revenue, making them ideal targets for personalized win-back campaigns.

-- The most disengaged groups are About to Sleep and Hibernating, with average inactivity periods of 14.7 months and 15.9 months, respectively.
--  These findings suggest that recovering these customers may require greater marketing effort and could deliver lower returns compared to focusing on high-value inactive customers.

-- Overall, the analysis confirms that customer inactivity increases progressively across the RFM segments, validating the effectiveness of
--  the segmentation model and supporting the business strategy of prioritizing Cannot Lose Them and At Risk customers for retention initiatives.


-- =========================================
-- QUERY 7 : PARETO VALIDATION
-- =========================================
 

-- Business question: Does the business follow the Pareto Principle,
--                    where a small percentage of customers generate
--                    the majority of revenue?
-- SQL concepts used: CTEs, NTILE(), Window Functions,
--                    SUM() OVER(), Running Totals
-- Finding: The top 20% of customers generate 77.2% of total revenue,
--          closely confirming the Pareto (80/20) principle.

WITH customer_revenue AS (
    -- Step 1: Total revenue per customer
    SELECT
        customer_id,
        Segment,
        Monetary                                    AS total_revenue
    FROM rfm_segments
),

decile_assignment AS (
    -- Step 2: Assign each customer to a revenue decile
    -- NTILE(10) divides customers into 10 equal groups
    -- Decile 1 = highest revenue customers (top 10%)
    SELECT
        customer_id,
        Segment,
        total_revenue,
        NTILE(10) OVER (
            ORDER BY total_revenue DESC
        )                                           AS revenue_decile
    FROM customer_revenue
),

decile_summary AS (
    -- Step 3: Aggregate revenue per decile
    SELECT
        revenue_decile,
        COUNT(*)                                    AS customers,
        ROUND(SUM(total_revenue), 2)                AS decile_revenue
    FROM decile_assignment
    GROUP BY revenue_decile
)

-- Step 4: Add percentage and cumulative percentage
SELECT
    revenue_decile,
    customers,
    decile_revenue,
    ROUND(decile_revenue * 100.0 /
          SUM(decile_revenue) OVER (), 1)           AS revenue_pct,
    ROUND(
        SUM(decile_revenue) OVER (
            ORDER BY revenue_decile
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) * 100.0 /
        SUM(decile_revenue) OVER ()
    , 1)                                            AS cumulative_revenue_pct
FROM decile_summary
ORDER BY revenue_decile;

-- Business Observation

-- The decile analysis reveals a highly concentrated revenue distribution across the customer base.

-- The top revenue decile (top 10% of customers), consisting of only 588 customers, generates approximately £11.11 million, representing 63.9% of 
-- total business revenue. This indicates that a very small portion of customers contributes the majority of the company's sales.

-- When the top two deciles (20% of customers) are combined, they generate approximately £13.42 million, accounting for 77.2% of total revenue. 
-- This closely aligns with the well-known Pareto Principle (80/20 Rule), which states that a small percentage of customers typically generate most of the business value.

-- Furthermore, the cumulative analysis shows that 85% of total revenue comes from just the top 30% of customers, while the bottom 70% collectively 
-- contribute only 15% of overall sales.

-- From a business perspective, these findings suggest that customer retention efforts should primarily focus on protecting the highest-value customer
--  segments. Losing even a small percentage of these top customers could have a disproportionately large impact on company revenue, 
-- making VIP programs, personalized engagement, and loyalty initiatives critical strategic investments.


-- =========================================
-- QUERY 8 : MONTH OVER MONTH REVENUE TREND
-- =========================================

-- Business question: Is revenue growing or declining over time?
--                   Which months perform strongest?
-- SQL concept: JOIN, DATE_FORMAT, GROUP BY, LAG window function,
--              MoM growth percentage, NULLIF to avoid divide by zero
-- Finding: [fill after running]

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.invoicedate, '%Y-%m')         AS month,
        COUNT(DISTINCT o.invoice)                   AS total_orders,
        COUNT(DISTINCT o.customer_id)               AS active_customers,
        ROUND(SUM(o.revenue), 2)                    AS monthly_revenue
    FROM orders o
    GROUP BY DATE_FORMAT(o.invoicedate, '%Y-%m')
)
SELECT
    month,
    total_orders,
    active_customers,
    monthly_revenue,
    LAG(monthly_revenue)
        OVER (ORDER BY month)                       AS prev_month_revenue,
    ROUND(
        (monthly_revenue -
         LAG(monthly_revenue) OVER (ORDER BY month))
        * 100.0 /
        NULLIF(
            LAG(monthly_revenue) OVER (ORDER BY month),
        0)
    , 1)                                            AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- Business observation:
-- Look at the mom_growth_pct column.
-- Find the months with the largest positive and negative values.
-- Do they align with seasonal patterns you identified in Day 3?
-- If November shows +40% and January shows -30% -- that is your
-- seasonal peak and trough, which the business should plan around.



-- =========================================
-- QUERY 9 : SEGMENT REVENUE BY COUNTRY 
-- =========================================
-- Business question: Are high-value segments concentrated in one
--                   geography or distributed internationally?
-- SQL concept: JOIN two tables, GROUP BY multiple columns,
--              SUM, ORDER BY, LIMIT
-- Finding:  High-value customers are highly concentrated in the United Kingdom, 
-- with the majority of revenue from the Champions, Cannot Lose Them, 
-- and At Risk segments coming from the UK, while international markets 
-- contribute relatively little.

SELECT
    s.Segment,
    o.country,
    COUNT(DISTINCT s.customer_id)                   AS customers,
    ROUND(SUM(o.revenue), 2)                        AS total_revenue,
    ROUND(AVG(o.revenue), 2)                        AS avg_transaction_value
FROM rfm_segments s
JOIN orders o
    ON s.customer_id = o.customer_id
  AND s.Segment IN (
      'Champions',
      'Cannot Lose Them',
      'At Risk'
  )
GROUP BY s.Segment, o.country
ORDER BY s.Segment, total_revenue DESC
LIMIT 30;

-- Business observation:
-- This suggests that the business has a strong dependence on the UK market for both its highest-value customers
-- and its recoverable revenue opportunities.
-- From a strategic perspective:
-- Customer retention campaigns should primarily focus on the UK since protecting this market will have the greatest impact on overall revenue.
-- International markets represent growth opportunities but currently contribute only a small share of high-value customers.
-- The CRM and marketing teams should prioritize UK-based Champions and "Cannot Lose Them" customers while simultaneously exploring
--  expansion strategies to diversify geographical revenue concentration.
 
 
 
 
-- =========================================
-- QUERY 10 : THE WIN BACK CANDIDATE LIST
-- =========================================


-- Business question: Which customers should the CRM team
--                   contact this week, in priority order?
-- SQL concept: WHERE with IN, CASE WHEN for action classification,
--              ORDER BY, clean operational output
-- Finding:

SELECT
    customer_id,
    Segment,
    Recency                                         AS days_inactive,
    Frequency                                       AS total_orders,
    ROUND(Monetary, 2)                              AS lifetime_revenue,
    ROUND(avg_order_value, 2)                       AS avg_order_value,
    R_Score,
    F_Score,
    M_Score,
    CASE
        WHEN Segment = 'Cannot Lose Them'
             THEN '1 — Personal outreach this week'
        WHEN Segment = 'At Risk'
             AND Monetary >= 5000
             THEN '2 — High-value win-back priority'
        WHEN Segment = 'At Risk'
             AND Monetary >= 1000
             THEN '3 — Standard win-back campaign'
        ELSE '4 — Low-priority reactivation'
    END                                             AS recommended_action,
    CASE
        WHEN Segment = 'Cannot Lose Them'
             THEN '20% loyalty credit — personal email'
        WHEN Monetary >= 5000
             THEN '15% discount — personalised subject line'
        WHEN Monetary >= 1000
             THEN '15% discount — automated sequence'
        ELSE '10% discount — batch campaign'
    END                                             AS suggested_offer
FROM rfm_segments
WHERE Segment IN ('At Risk', 'Cannot Lose Them')
ORDER BY
    CASE Segment
        WHEN 'Cannot Lose Them' THEN 1
        ELSE 2
    END,
    Monetary DESC;

-- Business observation:
-- This analysis transforms RFM segmentation into a practical CRM strategy.
-- Rather than sending the same promotion to every inactive customer, the company can allocate marketing resources more efficiently:
-- Priority 1: Personal outreach and loyalty offers for "Cannot Lose Them" customers because losing them would have a major revenue impact.
-- Priority 2: Personalized win-back campaigns for high-value "At Risk" customers.
-- Priority 3: Automated email sequences for medium-value customers.
-- Priority 4: Low-cost batch campaigns for lower-value inactive customers.
-- This targeted approach helps maximize marketing ROI by focusing retention efforts where they can recover the greatest amount of lost revenue.