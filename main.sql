-- # SHOPIFY ADVANCED BUSINESS ANALYTICS - SQL QUERIES

-- ## Advanced business intelligence queries for decision making

-- ### Table Structure Definition

CREATE TABLE shopify_orders (
    admin_graphql_api_id VARCHAR(255),
    order_number VARCHAR(50),
    billing_address_country VARCHAR(100),
    billing_address_first_name VARCHAR(100),
    billing_address_last_name VARCHAR(100),
    billing_address_province VARCHAR(100),
    billing_address_zip VARCHAR(20),
    city VARCHAR(100),
    currency VARCHAR(10),
    customer_id VARCHAR(255),
    invoice_date DATE,
    gateway VARCHAR(50),
    product_id VARCHAR(255),
    product_type VARCHAR(100),
    variant_id VARCHAR(255),
    quantity INT,
    subtotal_price DECIMAL(10, 2),
    total_price_usd DECIMAL(10, 2),
    total_tax DECIMAL(10, 2)
);

-- ## 1. REVENUE ANALYTICS

-- ### Monthly Revenue Trend Analysis

SELECT
    DATE_FORMAT(invoice_date, '%Y-%m') AS month_year,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_price_usd) AS monthly_revenue,
    AVG(total_price_usd) AS avg_order_value,
    SUM(quantity) AS total_items_sold,
    SUM(total_tax) AS total_tax_collected,
    ROUND(
        SUM(total_price_usd) / COUNT(DISTINCT order_number),
        2
    ) AS revenue_per_order,
    ROUND(
        SUM(total_price_usd) / COUNT(DISTINCT customer_id),
        2
    ) AS revenue_per_customer
FROM shopify_orders
WHERE
    invoice_date >= DATE_SUB(
        CURRENT_DATE,
        INTERVAL 12 MONTH
    )
GROUP BY
    DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY month_year DESC;

-- ### Revenue Growth Rate Analysis

WITH
    monthly_revenue AS (
        SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS month_year, SUM(total_price_usd) AS revenue
        FROM shopify_orders
        GROUP BY
            DATE_FORMAT(invoice_date, '%Y-%m')
    ),
    revenue_with_lag AS (
        SELECT
            month_year,
            revenue,
            LAG(revenue) OVER (
                ORDER BY month_year
            ) AS prev_month_revenue
        FROM monthly_revenue
    )
SELECT
    month_year,
    revenue,
    prev_month_revenue,
    ROUND(
        (
            (revenue - prev_month_revenue) / prev_month_revenue * 100
        ),
        2
    ) AS growth_rate_percent
FROM revenue_with_lag
WHERE
    prev_month_revenue IS NOT NULL
ORDER BY month_year DESC;

-- ## 2. CUSTOMER BEHAVIOR ANALYTICS

-- ### Customer Lifetime Value (CLV) Analysis

SELECT
    customer_id,
    billing_address_first_name,
    billing_address_last_name,
    billing_address_country,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(total_price_usd) AS customer_lifetime_value,
    AVG(total_price_usd) AS avg_order_value,
    SUM(quantity) AS total_items_purchased,
    MIN(invoice_date) AS first_purchase_date,
    MAX(invoice_date) AS last_purchase_date,
    DATEDIFF(
        MAX(invoice_date),
        MIN(invoice_date)
    ) AS customer_lifespan_days,
    CASE
        WHEN COUNT(DISTINCT order_number) = 1 THEN 'One-time Customer'
        WHEN COUNT(DISTINCT order_number) BETWEEN 2 AND 5  THEN 'Regular Customer'
        WHEN COUNT(DISTINCT order_number) > 5 THEN 'VIP Customer'
    END AS customer_segment
FROM shopify_orders
GROUP BY
    customer_id,
    billing_address_first_name,
    billing_address_last_name,
    billing_address_country
HAVING
    COUNT(DISTINCT order_number) > 0
ORDER BY customer_lifetime_value DESC;

-- ### Customer Retention Analysis

WITH
    customer_monthly_orders AS (
        SELECT
            customer_id,
            DATE_FORMAT(invoice_date, '%Y-%m') AS order_month,
            MIN(
                DATE_FORMAT(invoice_date, '%Y-%m')
            ) OVER (
                PARTITION BY
                    customer_id
            ) AS first_order_month
        FROM shopify_orders
        GROUP BY
            customer_id,
            DATE_FORMAT(invoice_date, '%Y-%m')
    ),
    cohort_analysis AS (
        SELECT
            first_order_month AS cohort_month,
            order_month,
            PERIOD_DIFF(
                CAST(
                    REPLACE (order_month, '-', '') AS UNSIGNED
                ),
                CAST(
                    REPLACE (first_order_month, '-', '') AS UNSIGNED
                )
            ) AS period_number,
            COUNT(DISTINCT customer_id) AS customers
        FROM customer_monthly_orders
        GROUP BY
            first_order_month,
            order_month
    )
SELECT
    cohort_month,
    period_number,
    customers,
    FIRST_VALUE(customers) OVER (
        PARTITION BY
            cohort_month
        ORDER BY period_number
    ) AS cohort_size,
    ROUND(
        customers * 100.0 / FIRST_VALUE(customers) OVER (
            PARTITION BY
                cohort_month
            ORDER BY period_number
        ),
        2
    ) AS retention_rate
FROM cohort_analysis
ORDER BY cohort_month, period_number;

-- ## 3. PRODUCT PERFORMANCE ANALYTICS

-- ### Top Performing Products Analysis

SELECT
    product_id,
    product_type,
    COUNT(DISTINCT order_number) AS orders_count,
    SUM(quantity) AS total_quantity_sold,
    SUM(total_price_usd) AS total_revenue,
    AVG(total_price_usd) AS avg_selling_price,
    ROUND(
        SUM(total_price_usd) / SUM(quantity),
        2
    ) AS price_per_unit,
    COUNT(DISTINCT customer_id) AS unique_customers,
    RANK() OVER (
        ORDER BY SUM(total_price_usd) DESC
    ) AS revenue_rank
FROM shopify_orders
GROUP BY
    product_id,
    product_type
HAVING
    SUM(quantity) > 0
ORDER BY total_revenue DESC
LIMIT 20;

-- ### Product Category Performance

SELECT
    product_type,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(quantity) AS total_quantity_sold,
    SUM(total_price_usd) AS total_revenue,
    AVG(total_price_usd) AS avg_order_value,
    ROUND(
        SUM(total_price_usd) / COUNT(DISTINCT order_number),
        2
    ) AS revenue_per_order,
    ROUND(
        SUM(total_price_usd) * 100.0 / SUM(SUM(total_price_usd)) OVER (),
        2
    ) AS revenue_contribution_percent
FROM shopify_orders
GROUP BY
    product_type
ORDER BY total_revenue DESC;

-- ## 4. GEOGRAPHICAL ANALYTICS

-- ### Sales Performance by Country

SELECT
    billing_address_country,
    billing_address_province,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(total_price_usd) AS total_revenue,
    AVG(total_price_usd) AS avg_order_value,
    SUM(quantity) AS total_items_sold,
    ROUND(
        SUM(total_price_usd) * 100.0 / SUM(SUM(total_price_usd)) OVER (),
        2
    ) AS revenue_share_percent,
    RANK() OVER (
        ORDER BY SUM(total_price_usd) DESC
    ) AS country_rank
FROM shopify_orders
GROUP BY
    billing_address_country,
    billing_address_province
HAVING
    COUNT(DISTINCT order_number) >= 5
ORDER BY total_revenue DESC;

-- ### City-wise Market Penetration

SELECT
    billing_address_country,
    city,
    COUNT(DISTINCT customer_id) AS customer_base,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(total_price_usd) AS market_value,
    AVG(total_price_usd) AS avg_order_value,
    ROUND(
        COUNT(DISTINCT order_number) * 1.0 / COUNT(DISTINCT customer_id),
        2
    ) AS orders_per_customer,
    CASE
        WHEN SUM(total_price_usd) > 10000 THEN 'High Value Market'
        WHEN SUM(total_price_usd) BETWEEN 5000 AND 10000  THEN 'Medium Value Market'
        ELSE 'Emerging Market'
    END AS market_classification
FROM shopify_orders
GROUP BY
    billing_address_country,
    city
HAVING
    COUNT(DISTINCT customer_id) >= 3
ORDER BY market_value DESC;

-- ## 5. PAYMENT GATEWAY ANALYTICS

-- ### Payment Gateway Performance

SELECT
    gateway,
    COUNT(DISTINCT order_number) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_price_usd) AS total_volume,
    AVG(total_price_usd) AS avg_transaction_value,
    ROUND(
        COUNT(DISTINCT order_number) * 100.0 / SUM(COUNT(DISTINCT order_number)) OVER (),
        2
    ) AS transaction_share_percent,
    ROUND(
        SUM(total_price_usd) * 100.0 / SUM(SUM(total_price_usd)) OVER (),
        2
    ) AS volume_share_percent,
    MIN(total_price_usd) AS min_transaction,
    MAX(total_price_usd) AS max_transaction
FROM shopify_orders
GROUP BY
    gateway
ORDER BY total_volume DESC;

-- ## 6. BUSINESS INTELLIGENCE QUERIES

-- ### RFM Analysis (Recency, Frequency, Monetary)

WITH
    rfm_base AS (
        SELECT
            customer_id,
            DATEDIFF(
                CURRENT_DATE,
                MAX(invoice_date)
            ) AS recency_days,
            COUNT(DISTINCT order_number) AS frequency,
            SUM(total_price_usd) AS monetary_value
        FROM shopify_orders
        GROUP BY
            customer_id
    ),
    rfm_scores AS (
        SELECT
            customer_id,
            recency_days,
            frequency,
            monetary_value,
            NTILE(5) OVER (
                ORDER BY recency_days DESC
            ) AS recency_score,
            NTILE(5) OVER (
                ORDER BY frequency ASC
            ) AS frequency_score,
            NTILE(5) OVER (
                ORDER BY monetary_value ASC
            ) AS monetary_score
        FROM rfm_base
    )
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_segment,
    CASE
        WHEN recency_score >= 4
        AND frequency_score >= 4
        AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3
        AND frequency_score >= 3
        AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 3
        AND frequency_score <= 2 THEN 'Potential Loyalists'
        WHEN recency_score <= 2
        AND frequency_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2
        AND frequency_score <= 2
        AND monetary_score >= 3 THEN 'Can\'t Lose Them'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scores
ORDER BY monetary_value DESC;

-- ### Seasonal Sales Pattern Analysis

SELECT
    YEAR(invoice_date) AS sales_year,
    MONTH(invoice_date) AS sales_month,
    MONTHNAME(invoice_date) AS month_name,
    QUARTER(invoice_date) AS sales_quarter,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(total_price_usd) AS total_revenue,
    AVG(total_price_usd) AS avg_order_value,
    SUM(quantity) AS total_items_sold,
    ROUND(
        SUM(total_price_usd) * 100.0 / SUM(SUM(total_price_usd)) OVER (
            PARTITION BY
                YEAR(invoice_date)
        ),
        2
    ) AS monthly_revenue_share
FROM shopify_orders
GROUP BY
    YEAR(invoice_date),
    MONTH(invoice_date),
    MONTHNAME(invoice_date),
    QUARTER(invoice_date)
ORDER BY sales_year DESC, sales_month;

-- ## 7. PERFORMANCE KPIS & METRICS

-- ### Executive Dashboard Summary

SELECT
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT product_id) AS total_products,
    SUM(total_price_usd) AS total_revenue,
    SUM(quantity) AS total_items_sold,
    SUM(total_tax) AS total_tax_collected,
    ROUND(AVG(total_price_usd), 2) AS avg_order_value,
    ROUND(
        SUM(total_price_usd) / COUNT(DISTINCT customer_id),
        2
    ) AS avg_customer_value,
    ROUND(
        COUNT(DISTINCT order_number) * 1.0 / COUNT(DISTINCT customer_id),
        2
    ) AS avg_orders_per_customer,
    COUNT(
        DISTINCT billing_address_country
    ) AS countries_served,
    COUNT(DISTINCT gateway) AS payment_methods_used
FROM shopify_orders;

-- ### Daily Performance Metrics

SELECT
    invoice_date,
    COUNT(DISTINCT order_number) AS daily_orders,
    COUNT(DISTINCT customer_id) AS daily_customers,
    SUM(total_price_usd) AS daily_revenue,
    AVG(total_price_usd) AS avg_order_value,
    SUM(quantity) AS items_sold,
    LAG(SUM(total_price_usd)) OVER (
        ORDER BY invoice_date
    ) AS prev_day_revenue,
    ROUND(
        (
            (
                SUM(total_price_usd) - LAG(SUM(total_price_usd)) OVER (
                    ORDER BY invoice_date
                )
            ) / LAG(SUM(total_price_usd)) OVER (
                ORDER BY invoice_date
            ) * 100
        ),
        2
    ) AS daily_growth_rate
FROM shopify_orders
GROUP BY
    invoice_date
ORDER BY invoice_date DESC
LIMIT 30;

-- ## 8. PREDICTIVE ANALYTICS QUERIES

-- ### Customer Churn Risk Analysis

WITH
    customer_last_order AS (
        SELECT
            customer_id,
            MAX(invoice_date) AS last_order_date,
            COUNT(DISTINCT order_number) AS total_orders,
            SUM(total_price_usd) AS total_spent,
            DATEDIFF(
                CURRENT_DATE,
                MAX(invoice_date)
            ) AS days_since_last_order
        FROM shopify_orders
        GROUP BY
            customer_id
    )
SELECT
    customer_id,
    last_order_date,
    total_orders,
    total_spent,
    days_since_last_order,
    CASE
        WHEN days_since_last_order > 365 THEN 'High Risk'
        WHEN days_since_last_order BETWEEN 180 AND 365  THEN 'Medium Risk'
        WHEN days_since_last_order BETWEEN 90 AND 179  THEN 'Low Risk'
        ELSE 'Active'
    END AS churn_risk_level,
    CASE
        WHEN total_spent > 1000
        AND days_since_last_order > 90 THEN 'Priority Retention'
        WHEN total_spent > 500
        AND days_since_last_order > 60 THEN 'Standard Retention'
        ELSE 'Regular Follow-up'
    END AS retention_strategy
FROM customer_last_order
ORDER BY
    total_spent DESC,
    days_since_last_order DESC;