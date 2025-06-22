# Shopify-Sales-Customer-Funnel-Report
Shopify Advanced Business Analytics
Overview
This repo contains SQL queries and a schema for Shopify order analytics, covering sales, customer behavior, product performance, geography, payment gateways, and predictive insights.
Table Structure

shopify_orders: Columns include admin_graphql_api_id, order_number, billing_address_*, city, currency, customer_id, invoice_date, gateway, product_*, quantity, subtotal_price, total_price_usd, total_tax.

Features

Revenue trends and growth rates.
Customer CLV, retention, and segmentation.
Top products and category performance.
Sales by country/city.
Payment gateway efficiency.
RFM and churn risk analysis.

Usage

Execute queries by section (e.g., Revenue, Customer).
Adjust filters (e.g., date ranges) as needed.
Use insights for decisions like marketing or retention.

Insights

Revenue: $4.18M transactions, $562.63 net sales, avg order $1.68.
Customers: 4,431 total, 46% repeat, $943.55 LTV.
Geography: Strong in CA, TX, NY; high-value cities >$10K.
Payments: Shopify Payments (52.67%), gift cards (16.29%).
Products: $1.5M from shoes (e.g., Climbing, Tennis).
Predictive: High churn risk >365 days inactivity.

Dashboard
![Screenshot 2025-06-22 191123](https://github.com/user-attachments/assets/aee2acd1-0f84-4e60-bd72-ec1090bac1ae)
![Screenshot 2025-06-22 191230](https://github.com/user-attachments/assets/3c83a61b-06b5-495a-9ed9-37f588749447)


Overview: Shows $4.18M net sales, 7,534 items, 46% repeat rate, and trends (peaks at $638K, $641K). Map highlights CA/TX sales clusters. Cities (e.g., Washington) and gateways (Shopify 52.67%) visualized.
Details: Table of orders (e.g., Gideon Vinden $505.13), totals $4.18M sales, $418K tax.


Contributing
Fork and submit pull requests for enhancements.
License
MIT License - see LICENSE.
