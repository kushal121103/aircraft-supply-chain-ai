USE Airlinesupplychaindb
GO

--SELECT * FROM [dbo].[parts_master]
--SELECT * FROM [dbo].[purchase_orders]
--SELECT * FROM [dbo].[quality_incidents]
--SELECT * FROM [dbo].[supply_chain_history]


                                         --Module 1 — Data Quality Analysis--


--Q1)Write SQL queries to display the total number of records present in each of tables
/*
SELECT COUNT(*) AS total_record FROM [dbo].[parts_master]
SELECT COUNT(*) AS total_record FROM [dbo].[purchase_orders]
SELECT COUNT(*) AS total_record FROM [dbo].[quality_incidents]
SELECT COUNT(*) AS total_record FROM [dbo].[supply_chain_history]
*/
--Q2)Write a SQL query to identify duplicate part_id values in the parts_master table.
/*
SELECT part_id,COUNT(*) AS duplicated_id FROM [dbo].[parts_master]
GROUP BY part_id
HAVING COUNT(*)>1
*/
--Q3)Write a SQL query to identify duplicate po_id values in the purchase_orders table.
/*
SELECT po_id ,COUNT(*) AS duplicated_id
FROM [dbo].[purchase_orders]
GROUP BY po_id
HAVING COUNT(*)>1
*/
--Q4)Find all records where:supplier_id_primary is NULL Empty String ('') Return all columns.
/*
SELECT * FROM [dbo].[parts_master]
WHERE supplier_id_primary IS NULL
OR 
supplier_id_primary=''
*/
--Q5)Find all spare parts where:lead_time_days is NULL,OR lead_time_days <= 0
/*
SELECT part_id,part_family,lead_time_days  FROM [dbo].[parts_master]
WHERE lead_time_days IS NULL
OR
lead_time_days<=0
*/
--Q6)The Finance team wants to ensure that all spare parts have a valid unit cost.If:unit_cost is NULL,unit_cost <= 0
/*
SELECT part_id,part_family,unit_cost FROM [dbo].[parts_master]
WHERE unit_cost IS NULL
OR
unit_cost <=0
*/
--Q7)Find all purchase orders where:received_qty > ordered_qty
/*
SELECT po_id,supplier_id,part_id,ordered_qty,received_qty FROM [dbo].[purchase_orders]
WHERE received_qty>ordered_qty
*/
--Q8)Find all purchase orders where:purchase_orders.part_id does NOT exist in parts_master.part_id.
/*
SELECT * FROM [dbo].[purchase_orders] o
LEFT JOIN [dbo].[parts_master] m ON o.part_id=m.part_id
WHERE m.part_id IS NULL
*/
--Q9)How many spare parts are supplied by High, Medium, and Low risk suppliers?
/*
SELECT supplier_risk_class,
       COUNT(*) AS total_parts
FROM [dbo].[parts_master]
GROUP BY supplier_risk_class
ORDER BY total_parts DESC
*/
--Q10)The Procurement Manager wants to know which purchase orders were delivered late.
/*
SELECT po_id,part_id,supplier_id,promised_date,receipt_date 
FROM [dbo].[purchase_orders]
WHERE receipt_date>promised_date

SELECT SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END ) AS delayed_delivery
FROM [dbo].[purchase_orders]
WHERE receipt_date>promised_date
*/
--Q11)Which supplier is responsible for the highest number of delayed deliveries?
/*
SELECT supplier_id,COUNT(*) AS delayed_deliveries 
FROM [dbo].[purchase_orders]
WHERE receipt_date>promised_date
GROUP BY supplier_id
ORDER BY delayed_deliveries  DESC
*/
--Q12)We're experiencing frequent aircraft maintenance delays.whether supplier delays are responsible
/*
SELECT 
ROUND(
      SUM(
          CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS delayed_percent
FROM [dbo].[purchase_orders]

SELECT AVG(DATEDIFF(day,promised_date,receipt_date)) AS avg_day_delay FROM [dbo].[purchase_orders]
*/


                                      --Module 2 – Supplier Performance Analytics--


--Q1)Supplier Delivery Performance
/*
SELECT supplier_id ,COUNT(*) AS Total_orders,
SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END) AS On_time_orders,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[purchase_orders]
GROUP BY supplier_id
ORDER BY On_time_delivery_percentage DESC 
*/
--Q2)Question 2 – Average Supplier Delay
/*
SELECT supplier_id,SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
AVG(
    CASE
        WHEN receipt_date > promised_date
        THEN DATEDIFF(day, promised_date, receipt_date)
    END
) AS Average_delay_days 
FROM [dbo].[purchase_orders]
WHERE receipt_date > promised_date
GROUP BY supplier_id
ORDER BY Average_delay_days DESC 
*/
--Q3)Supplier Quality Performance
/*
SELECT supplier_id,COUNT(incident_id) AS Total_quality_incident,SUM(scrap_qty) AS Total_scrap_quantity
FROM [dbo].[quality_incidents]
GROUP BY supplier_id 
ORDER BY Total_scrap_quantity DESC
*/
--Q4)Supplier Performance Summary
/*
WITH delivery  AS(
SELECT supplier_id,COUNT(*) AS Total_order,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
       ROUND(SUM(CASE WHEN promised_date<receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Delayed_percentage
FROM [dbo].[purchase_orders]
GROUP BY supplier_id
),
quality  AS(
SELECT supplier_id ,COUNT(incident_id) AS Total_quality_incident,
       SUM(scrap_qty) AS Total_scrap_quantity
FROM  [dbo].[quality_incidents] 
GROUP BY supplier_id

)
SELECT d.supplier_id,d.Total_order,d.Delayed_orderS,d.delayed_percentage,q.Total_quality_incident,q.Total_scrap_quantity
FROM delivery d
LEFT JOIN quality q ON q.supplier_id=d.supplier_id
ORDER BY d.delayed_percentage DESC
*/
--Q5)Best Performing Suppliers
/*
WITH best_performer AS(
SELECT supplier_id,COUNT(*) AS Total_orders,
SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END) AS On_time_orders,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[purchase_orders]
GROUP BY supplier_id)
SELECT TOP 10 DENSE_RANK() OVER(ORDER BY On_time_delivery_percentage DESC ,Total_orders DESC ) AS Rank,
supplier_id,Total_orders,On_time_orders,Delayed_orders,On_time_delivery_percentage
FROM best_performer
*/
--Q6)Worst Performing Suppliers
/*
WITH delivery AS(
SELECT supplier_id,COUNT(*) AS Total_orders,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
       ROUND(SUM(CASE WHEN promised_date<receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Delayed_percentage,
AVG(
    CASE
        WHEN receipt_date > promised_date
        THEN DATEDIFF(day, promised_date, receipt_date)
    END
) AS Average_delay_days
FROM [dbo].[purchase_orders]
GROUP BY supplier_id
),
quality AS (
SELECT supplier_id ,COUNT(incident_id) AS Total_quality_incident,
       SUM(scrap_qty) AS Total_scrap_quantity
FROM  [dbo].[quality_incidents] 
GROUP BY supplier_id),
ranking as (SELECT DENSE_RANK() OVER(ORDER BY Delayed_percentage DESC,Average_delay_days DESC,Total_scrap_quantity DESC ) AS rank,
d.supplier_id,d.Total_orders,d.Delayed_orders,d.Delayed_percentage,d.Average_delay_days,q.Total_quality_incident,q.Total_scrap_quantity
FROM delivery d
JOIN quality q ON d.supplier_id=q.supplier_id
)
SELECT * FROM ranking 
WHERE rank<=5 
*/
--Q7)Supplier Risk Class Performance Analysis
/*
WITH supplierclass AS(
SELECT  supplier_id_primary,supplier_risk_class
FROM [dbo].[parts_master]
GROUP BY supplier_risk_class,supplier_id_primary),
delivery AS(
SELECT supplier_id,COUNT(*) AS Total_orders,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
       ROUND(SUM(CASE WHEN promised_date<receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Delayed_percentage,
AVG(
    CASE
        WHEN receipt_date > promised_date
        THEN DATEDIFF(day, promised_date, receipt_date)
    END
) AS Average_delay_days
FROM [dbo].[purchase_orders]
GROUP BY supplier_id
),
quality AS (
SELECT supplier_id ,COUNT(incident_id) AS Total_quality_incident,
       SUM(scrap_qty) AS Total_scrap_quantity
FROM  [dbo].[quality_incidents] 
GROUP BY supplier_id
)
SELECT s.supplier_risk_class,COUNT(DISTINCT s.supplier_id_primary) AS Number_of_suppliers,
       SUM(d.Total_orders) AS Total_orders,SUM(d.Delayed_orders) AS Delayed_orders,ROUND(
        SUM(d.Delayed_orders) * 100.0 / SUM(d.Total_orders),
        2
    ) AS Delayed_percentage,AVG(d.Average_delay_days) AS Average_delay_days ,
       SUM(q.Total_quality_incident) AS Total_quality_incident ,SUM(q.Total_scrap_quantity) AS Total_scrap_quantity
FROM supplierclass s
LEFT JOIN delivery d ON s.supplier_id_primary=d.supplier_id
LEFT JOIN quality q ON s.supplier_id_primary=q.supplier_id
GROUP BY s.supplier_risk_class
*/
--Q8)Critical Spare Parts Supplier Analysis
/*
SELECT supplier_id_primary ,supplier_risk_class ,
SUM(CASE WHEN criticality_class='A' THEN 1 ELSE 0 END) AS critical_parts,AVG( CASE WHEN  criticality_class='A' THEN lead_time_days END) AS avg_lead_time,
AVG(CASE WHEN  criticality_class='A' THEN unit_cost END ) AS avg_unit_cost,SUM(CASE WHEN is_repairable='1' THEN 1 ELSE 0 END) AS repairable,
SUM(CASE WHEN is_repairable='0' THEN 1 ELSE 0 END) AS non_repairable
FROM [dbo].[parts_master]
GROUP BY supplier_id_primary,supplier_risk_class
ORDER BY supplier_risk_class DESC
*/
--Q9)Supplier Performance Trend Analysis
/*
SELECT YEAR(order_date) AS Order_Year,
MONTH(order_date) AS Order_Month
,supplier_id,COUNT(*) AS Total_orders,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
       ROUND(SUM(CASE WHEN promised_date<receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Delayed_percentage,
AVG(CASE WHEN receipt_date > promised_date THEN DATEDIFF(day, promised_date, receipt_date)
    END
) AS Average_delay_days
FROM [dbo].[purchase_orders]
GROUP BY supplier_id,YEAR(order_date),
MONTH(order_date) 
ORDER BY supplier_id, Order_Year, Order_Month
*/
--Q10)Executive Supplier Performance Scorecard
/*
WITH supplierclass AS(
SELECT  supplier_id_primary,supplier_risk_class,
SUM(CASE WHEN criticality_class='A' THEN 1 ELSE 0 END) AS critical_parts,
AVG( CASE WHEN  criticality_class='A' THEN lead_time_days END) AS avg_lead_time
FROM [dbo].[parts_master]
GROUP BY supplier_id_primary,supplier_risk_class),
delivery AS(
SELECT supplier_id,COUNT(*) AS Total_orders,
SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
       ROUND(SUM(CASE WHEN promised_date<receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Delayed_percentage,
AVG(
    CASE
        WHEN receipt_date > promised_date
        THEN DATEDIFF(day, promised_date, receipt_date)
    END
) AS Average_delay_days
FROM [dbo].[purchase_orders]
GROUP BY supplier_id),
quality AS (
SELECT supplier_id ,COUNT(incident_id) AS Total_quality_incident,
       SUM(scrap_qty) AS Total_scrap_quantity
FROM  [dbo].[quality_incidents] 
GROUP BY supplier_id)
SELECT supplier_id_primary,supplier_risk_class ,Total_orders,
       Delayed_orders,Delayed_percentage, Average_delay_days ,
        Total_quality_incident , Total_scrap_quantity,critical_parts,avg_lead_time
FROM supplierclass s
LEFT JOIN delivery d ON s.supplier_id_primary=d.supplier_id
LEFT JOIN quality q ON s.supplier_id_primary=q.supplier_id
*/


                                   --Module 3 – Inventory Analytics--


--Q1)Inventory Value Analysis
/*
SELECT part_id,part_family,supplier_id_primary,supplier_risk_class,unit_cost,lead_time_days
FROM [dbo].[parts_master]
ORDER BY unit_cost DESC 
*/
--Q2)Inventory Health Analysis
/*
SELECT part_id,site_id,
AVG(on_hand_qty) AS average_on_hand_qty,
SUM(consumption_qty) AS total_consumption_qty,
SUM(backorder_qty) AS total_backorder_qty,
SUM(blocked_qty) AS total_blocked_qty,
AVG(forecast_qty)AS average_forecast_qty
FROM [dbo].[supply_chain_history]
GROUP BY part_id,site_id
ORDER BY total_backorder_qty DESC ,
average_on_hand_qty ASC 
*/

--Q3)Stock-out Risk Analysis
/*
SELECT part_id,site_id,
AVG(on_hand_qty) AS average_on_hand_qty,
SUM(consumption_qty) AS total_consumption_qty,SUM(blocked_qty) AS total_blocked_qty,
SUM(backorder_qty) AS total_backorder_qty,
AVG(forecast_qty)AS average_forecast_qty,
(CASE WHEN AVG(on_hand_qty)<AVG(forecast_qty) THEN 'High' 
      WHEN AVG(on_hand_qty)>=AVG(forecast_qty) AND SUM(blocked_qty) > 0 THEN 'Medium'
      ELSE 'Low ' END) AS stock_out_risk
FROM [dbo].[supply_chain_history]
GROUP BY part_id,site_id
ORDER BY stock_out_risk DESC 
*/
--Q4)Reorder Priority Analysis
/*
WITH cte AS(
SELECT part_id,site_id,AVG(on_hand_qty) AS average_on_hand_qty,
SUM(backorder_qty) AS total_backorder_qty,
AVG(forecast_qty)AS average_forecast_qty,
AVG(forecast_qty)-AVG(on_hand_qty) AS Inventory_Gap
FROM [dbo].[supply_chain_history]
GROUP BY part_id,site_id)
SELECT *,CASE WHEN Inventory_Gap>0 AND total_backorder_qty>0 THEN 'Immediate'
     WHEN Inventory_Gap>0 AND total_backorder_qty=0 THEN 'Monitor'
     WHEN Inventory_Gap<=0 THEN 'Normal' END AS Reorder_Priority
FROM cte 
ORDER BY  Reorder_Priority DESC
*/
--Q5)Forecast vs Actual Consumption Analysis
/*
SELECT part_id,site_id,SUM(consumption_qty) AS total_consumption_qty,AVG(forecast_qty)AS average_forecast_qty,
SUM(consumption_qty)-AVG(forecast_qty) AS Forecast_Variance,
(CASE WHEN SUM(consumption_qty)>AVG(forecast_qty) THEN 'Under Forecast'
     WHEN SUM(consumption_qty)<AVG(forecast_qty) THEN 'Over Forecast'
     WHEN SUM(consumption_qty)=AVG(forecast_qty) THEN 'Accurate'
END) AS forecast_status
FROM [dbo].[supply_chain_history]
GROUP BY part_id,site_id
*/
--Q6)Blocked Inventory Analysis
/*
WITH cte AS (SELECT part_id,site_id,AVG(on_hand_qty) AS average_on_hand_qty,
SUM(blocked_qty) AS total_blocked_qty,
(SUM(blocked_qty)*100.00)/SUM(on_hand_qty) AS blocked_percentage
FROM [dbo].[supply_chain_history]
GROUP BY part_id,site_id)
SELECT *,CASE WHEN blocked_percentage <0.30 THEN 'Critical'
              WHEN blocked_percentage BETWEEN 0.30 AND 0.10 THEN 'Warning'
              ELSE 'Healthy' 
         END AS inventory_status
FROM cte 
*/
--Q7)Planned vs Unplanned Maintenance Inventory Analysis
/*
WITH cte AS (SELECT CASE WHEN planned_maintenance=0 THEN 'Unplanned_maintenance'
            WHEN planned_maintenance=1 THEN 'Planned_maintenance'
       END AS maintenance_type,
       SUM(consumption_qty) AS Total_part_consumed,
       AVG(on_hand_qty) AS average_on_hand_qty,
       SUM(backorder_qty) AS Total_backorder_qty,
       AVG(forecast_qty) AS average_forecast_qty,
       SUM(blocked_qty) AS blocked_inventory
FROM [dbo].[supply_chain_history]
GROUP BY planned_maintenance)
SELECT *,CASE WHEN Total_backorder_qty > 0 AND average_on_hand_qty < average_forecast_qty THEN 'High Risk'
              WHEN Total_backorder_qty  > 0 THEN 'Medium Risk'
              ELSE 'Low Risk'
         END AS maintenance_risk
FROM cte
*/
--Q8)Excess Inventory Analysis
/*
WITH cte AS(
SELECT part_id,site_id,AVG(on_hand_qty) AS average_on_hand_qty,AVG(forecast_qty) AS average_forecast_qty,
       SUM(consumption_qty) AS Total_consumption_quantity,AVG(on_hand_qty)-AVG(forecast_qty) AS inventory_surplus
FROM [dbo].[supply_chain_history]
GROUP BY  part_id,site_id)
SELECT *,CASE WHEN inventory_surplus > 5 AND Total_consumption_quantity < average_on_hand_qty THEN 'Overstocked'
              WHEN inventory_surplus BETWEEN 0 AND 5 THEN 'Balanced'
              WHEN inventory_surplus<0 THEN 'Understocked'
         END AS inventory_status
FROM cte
*/
--Q9)Inventory Coverage & Safety Stock Risk Analysis
/*
WITH invencoverge AS(
SELECT part_id,site_id,AVG(on_hand_qty) AS average_on_hand_qty,AVG(forecast_qty) AS average_forecast_qty,
       SUM(consumption_qty) AS Total_consumption_quantity,ISNULL(AVG(on_hand_qty)/NULLIF(AVG(forecast_qty),0),0) AS inventory_coverage_ratio
FROM [dbo].[supply_chain_history]
GROUP BY  part_id,site_id)
SELECT *,CASE WHEN inventory_coverage_ratio<0.80 THEN 'Critical'
              WHEN inventory_coverage_ratio BETWEEN 0.80 AND 1.20 THEN 'Review'
              WHEN Inventory_coverage_ratio > 1.20 THEN 'Healthy'
         END AS safety_stock_status
FROM invencoverge
*/
--Q10)Executive Inventory Health Dashboard
/*
WITH dashboard AS (
SELECT part_id,site_id,AVG(on_hand_qty) AS average_on_hand_qty,AVG(forecast_qty) AS average_forecast_qty,
       SUM(consumption_qty) AS Total_consumption_quantity,
       SUM(backorder_qty) AS Total_backorder_qty,
       SUM(blocked_qty) AS Total_blocked_qty,
       AVG(forecast_qty)-AVG(on_hand_qty) AS inventory_gap,
       ISNULL(AVG(on_hand_qty)/NULLIF(AVG(forecast_qty),0),0) AS inventory_coverage_ratio
       FROM [dbo].[supply_chain_history]
GROUP BY  part_id,site_id)
SELECT *,CASE WHEN inventory_gap > 0 OR
                   inventory_coverage_ratio<0.80 OR 
                   Total_backorder_qty >0 THEN 'Critical'
              WHEN inventory_gap  <= 0 AND
                   inventory_coverage_ratio BETWEEN 0.80 AND 1.20 THEN 'Review'
              ELSE 'Healthy'
         END AS Overall_Inventory_Health
FROM dashboard
*/

                                     --Module 4 – Procurement Analytics--


--Q1)Purchase Order Fulfillment Analysis
/*
SELECT supplier_id,COUNT(*) AS Total_purchase_order,
       SUM(ordered_qty) AS Total_ordered_qty,
       SUM(received_qty) AS Total_received_qty,
       ISNULL(SUM(received_qty *100.0)/NULLIF(SUM(ordered_qty),0),0) AS fulfillment_percentage,
       CASE WHEN ISNULL(SUM(received_qty *100.0)/NULLIF(SUM(ordered_qty),0),0) >= 98 THEN 'Excellent'
            WHEN ISNULL(SUM(received_qty *100.0)/NULLIF(SUM(ordered_qty),0),0) BETWEEN 95 AND 97.99 THEN 'Good'
            WHEN ISNULL(SUM(received_qty *100.0)/NULLIF(SUM(ordered_qty),0),0) < 95 THEN 'Need Improvement'
       END AS supplier_performance
FROM [dbo].[purchase_orders]
GROUP BY supplier_id
*/
--Q2)Supplier Lead Time Performance Analysis
/*
WITH cte AS (SELECT supplier_id,COUNT(*) AS Total_purchase_order ,SUM(CASE WHEN receipt_date>promised_date THEN 1 ELSE 0 END) AS Delayed_orders,
AVG(
    CASE
        WHEN receipt_date > promised_date
        THEN DATEDIFF(day, promised_date, receipt_date)
    END
) AS Average_delay_days ,
SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END) AS On_time_orders,
ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage 
FROM [dbo].[purchase_orders]
GROUP BY supplier_id)
SELECT *,CASE WHEN On_time_delivery_percentage  >=95 THEN 'Excellent'
              WHEN On_time_delivery_percentage Between 85 and 94.99 THEN 'Acceptable'
              WHEN On_time_delivery_percentage <85 THEN 'Poor'
         END AS procurement_status
FROM cte
*/
--Q3)Procurement Cost Efficiency Analysis   
/*
SELECT supplier_id,
COUNT(*) AS Total_purchase_order,
SUM(ordered_qty) AS Total_ordered_quantity,
SUM(ordered_qty * unit_cost) AS Total_procurement_cost,
SUM(ordered_qty * unit_cost) * 1.0 / COUNT(*) AS Average_order_value,
CASE WHEN SUM(ordered_qty * unit_cost) * 1.0 / COUNT(*)> 100000 THEN 'High Spend'
     WHEN SUM(ordered_qty * unit_cost) * 1.0 / COUNT(*) BETWEEN 50000 AND 100000 THEN 'Medium Spend'
     WHEN SUM(ordered_qty * unit_cost) * 1.0 / COUNT(*) <50000 THEN 'Low Spend'
END AS Procurement_Category
FROM  [dbo].[parts_master] m
JOIN [dbo].[purchase_orders] o ON m.part_id=o.part_id
GROUP BY supplier_id
*/
--Q4)Supplier Procurement Reliability Analysis
/*
WITH orderscte AS (
SELECT supplier_id,COUNT(*) AS Total_purchase_orders,
       SUM(ordered_qty*unit_cost) AS Total_procurement_cost,
       ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS On_Time_Delivery_Percentage
       FROM [dbo].[parts_master] m
       LEFT JOIN [dbo].[purchase_orders] o ON m.part_id=o.part_id
       GROUP BY supplier_id),
quality AS(
       SELECT supplier_id,
       COUNT(DISTINCT incident_id) AS Total_Quality_Incidents,
       SUM(scrap_qty) AS Total_Scrap_Quantity
       FROM [dbo].[quality_incidents]
       GROUP BY supplier_id )
SELECT oc .supplier_id,Total_purchase_orders,
       Total_procurement_cost,On_Time_Delivery_Percentage,
       ISNULL(Total_Quality_Incidents,0) AS Total_Quality_Incidents,
       ISNULL(Total_Scrap_Quantity,0) AS Total_Scrap_Quantity ,
       CASE WHEN On_Time_Delivery_Percentage >= 95 AND Total_Quality_Incidents <= 5 THEN 'Excellent'
            WHEN On_Time_Delivery_Percentage BETWEEN 85 AND 94.99 OR
                 Total_Quality_Incidents  BETWEEN 6 AND 15 THEN 'Good'
            ELSE 'Poor' END AS 'Procurement_Reliability'
FROM orderscte oc 
LEFT JOIN quality q ON oc.supplier_id=q.supplier_id
*/
--Q5)Emergency Procurement Analysis
/*
WITH cte AS (
SELECT supplier_id,COUNT(*) AS total_purchase_orders,
       AVG(DATEDIFF(day,order_date,promised_date)) AS average_procurement_lead_time,
       SUM(CASE WHEN DATEDIFF(day,order_date,promised_date) <=3 THEN 1 ELSE 0 END) AS urgent_purchase_orders
FROM [dbo].[purchase_orders]
GROUP BY supplier_id)
SELECT supplier_id,total_purchase_orders,average_procurement_lead_time,urgent_purchase_orders,
       ROUND((urgent_purchase_orders*100.0)/total_purchase_orders,2) AS urgent_purchase_percentage,
       CASE WHEN ROUND((urgent_purchase_orders*100.0)/total_purchase_orders,2) >30 THEN 'High'
            WHEN ROUND((urgent_purchase_orders*100.0)/total_purchase_orders,2) BETWEEN 10 AND 30 THEN 'Medium'
            WHEN ROUND((urgent_purchase_orders*100.0)/total_purchase_orders,2) <10 THEN 'LOW'
        END AS procurement_priority
FROM cte
*/
--Q6)Procurement Dependency Analysis
/*
WITH CTE AS(
SELECT supplier_id,COUNT(*) AS Total_purchase_order,
SUM(ordered_qty*unit_cost) AS Total_procurement_cost,
ROUND(SUM(ordered_qty*unit_cost*100.0)/SUM(SUM(ordered_qty*unit_cost)) OVER(),2) AS supplier_spend_percentage
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[purchase_orders] o ON o.part_id=m.part_id
GROUP BY supplier_id)
SELECT supplier_id,Total_purchase_order,Total_procurement_cost,supplier_spend_percentage,
       CASE WHEN supplier_spend_percentage >25 THEN 'High Dependency'
            WHEN supplier_spend_percentage BETWEEN 10 AND 25 THEN 'Medium Dependency'
            WHEN supplier_spend_percentage <10 THEN 'Low Dependency'
        END AS Dependency_level
FROM CTE
*/
--Q7)Procurement Cost Savings Opportunity Analysis
/*
WITH CTE AS(
SELECT supplier_id_primary AS supplier_id,COUNT(*) AS number_of_parts_supplied,
       AVG(unit_cost) AS average_unit_cost,
       AVG(AVG(unit_cost)) OVER() AS overall_average_unit_cost,
       AVG(unit_cost)-AVGXX(AVG(unit_cost)) OVER() AS cost_difference
FROM [dbo].[parts_master]
GROUP BY supplier_id_primary)
SELECT supplier_id,number_of_parts_supplied,average_unit_cost,cost_difference,
       CASE WHEN cost_difference >5000 THEN 'High'
            WHEN cost_difference BETWEEN 1000 AND 5000 THEN 'Medium'
            WHEN cost_difference <1000 THEN 'Low'
        END AS Cost_Saving_Opportunity
FROM CTE
*/
--Q8)Supplier Delivery Consistency Analysis
/*
WITH cte AS (
SELECT supplier_id,COUNT(*) AS Total_purchase_order,
       SUM(CASE WHEN promised_date>=receipt_date THEN 1 END) AS On_time_purchase_orders,
       SUM(CASE WHEN promised_date<receipt_date THEN 1 END) AS Late_purchase_orders,
       ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[purchase_orders]
GROUP BY supplier_id)
SELECT supplier_id,Total_purchase_order,On_time_purchase_orders,Late_purchase_orders,On_time_delivery_percentage,
       CASE WHEN On_time_delivery_percentage >= 95 THEN 'Highly Consistent'
            WHEN On_time_delivery_percentage Between 85 and 95 THEN 'Moderately Consistent'
            WHEN On_time_delivery_percentage < 85 THEN 'Needs Improvement' END AS 'Delivery Consistency'
FROM cte 
*/
--Q9)Supplier Procurement Trend Analysis
/*
WITH trendanalysis AS (
SELECT supplier_id,DATENAME(MONTH, order_date) as Procurement_month,COUNT(*) AS Total_purchase_orders,
       SUM(o.ordered_qty*m.unit_cost) AS Total_procurement_cost,
       SUM(o.ordered_qty*m.unit_cost)*1.0/COUNT(*) AS Average_order_value
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[purchase_orders] o ON m.part_id=o.part_id
GROUP BY supplier_id,DATENAME(MONTH, order_date) )
SELECT supplier_id,Procurement_month,Total_purchase_orders,Total_procurement_cost,Average_order_value,
       CASE WHEN Total_procurement_cost > 500000 THEN 'High Procurement'
            WHEN Total_procurement_cost Between 200000 And 500000 THEN 'Moderate Procurement'
            WHEN Total_procurement_cost < 200000 THEN 'Low Procurement' 
       END AS Monthly_Procurement_Trend
FROM trendanalysis
*/
--Q10)Executive Procurement Scorecard
/*
WITH purchase AS(
SELECT supplier_id,COUNT(*) AS Total_purchase_orders,
SUM(o.ordered_qty*m.unit_cost) AS Total_procurement_cost,
ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[purchase_orders] o
LEFT JOIN [dbo].[parts_master] m ON m.part_id=o.part_id
GROUP BY supplier_id),
quality AS(
SELECT supplier_id ,COUNT(incident_id) AS Total_quality_incident
FROM  [dbo].[quality_incidents] 
GROUP BY supplier_id)
SELECT supplier_id,Total_purchase_orders,Total_procurement_cost,On_time_delivery_percentage,Total_quality_incident,
       CASE WHEN On_time_delivery_percentage >=95 AND ISNULL(Total_quality_incident,0) <=3 THEN 'Excellent'
            WHEN On_time_delivery_percentage  BETWEEN 85 AND 95 AND ISNULL(Total_quality_incident,0) <=8 THEN 'Good'
       ELSE 'Needs Improvement'
       END AS Procurement_Performance
FROM purchase p
LEFT JOIN quality q ON p.supplier_id=q.supplier_id
*/


                                  --Module 6 -Operations & Executive Analytics --


--Q1)Executive Supply Chain Health Dashboard
/*
WITH cte AS(
SELECT site_id,SUM(s.on_hand_qty*m.unit_cost) AS Total_inventory_value,
       AVG(on_hand_qty)/NULLIF(AVG(s.forecast_qty), 0)  AS Average_inventory_coverage,
       SUM(backorder_qty) AS Total_backorders,
       SUM(blocked_qty) AS blocked_inventory,
       AVG(forecast_qty)-AVG(consumption_qty) AS Forecast_accuracy_gap
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[supply_chain_history] s ON s.part_id=m.part_id
GROUP BY site_id)
SELECT site_id,Total_inventory_value,Average_inventory_coverage,blocked_inventory,Forecast_accuracy_gap,
       CASE WHEN Average_inventory_coverage >=1 AND Total_backorders < 50 AND  Forecast_accuracy_gap BETWEEN -20 AND 20 THEN 'Healthy'
            WHEN Average_inventory_coverage BETWEEN  0.8 AND 1 AND Total_backorders BETWEEN  50 AND 100 THEN 'Monitor'
            ELSE 'Critical'
       END AS  'Overall Supply Chain Health'
FROM cte
*/

--Q2)Critical Parts Availability & Operational Risk
/*
WITH riskanalysis AS(
SELECT s.site_id,COUNT(DISTINCT s.part_id) AS total_critical_parts,AVG(s.on_hand_qty) AS average_on_hand_quantity,
       AVG(s.forecast_qty) AS average_forecast_quantity,SUM(s.backorder_qty) AS total_backorders
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[supply_chain_history] s ON s.part_id=m.part_id
WHERE m.criticality_class='A'
GROUP BY s.site_id)
SELECT site_id,
       total_critical_parts,
       average_on_hand_quantity,
       average_forecast_quantity,
       total_backorders,
       CASE WHEN average_on_hand_quantity>=average_forecast_quantity AND total_backorders <20 THEN 'Low_risk'
            WHEN average_on_hand_quantity BETWEEN 0.8*average_forecast_quantity AND 1.0*average_forecast_quantity AND total_backorders BETWEEN 20 AND 50 THEN 'Medium_risk'
       ELSE 'High_risk'
       END AS 'Critical_part_risk'
FROM  riskanalysis
*/
--Q3)Executive Site Performance Scorecard
/*
WITH procurement  AS(
SELECT 
      site_id,SUM(o.ordered_qty*m.unit_cost) AS Total_procurement_cost,
      ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[purchase_orders] o ON m.part_id=o.part_id
GROUP BY site_id),
inventory  AS (
SELECT site_id,SUM(s.on_hand_qty*m.unit_cost) AS Inventory_value,SUM(s.backorder_qty) AS Total_backorders
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[supply_chain_history] s ON s.part_id=m.part_id
GROUP BY site_id),
quality  AS( 
SELECT site_id,ISNULL(COUNT(DISTINCT incident_id),0) AS Quality_incidents
FROM [dbo].[quality_incidents]
GROUP BY site_id)
SELECT p.site_id,
       Total_procurement_cost,
       On_time_delivery_percentage,
       Inventory_value,
       Total_backorders,
       Quality_incidents,
       CASE WHEN On_time_delivery_percentage >95 AND Total_backorders <30 AND Quality_incidents <=5 THEN 'Excellent'
            WHEN On_time_delivery_percentage BETWEEN 85 AND 95 AND Total_backorders BETWEEN 30 AND 70 AND Quality_incidents <=10 THEN 'Good'
            ELSE 'Needs Improvement'
       END AS Site_Performance
FROM procurement p
LEFT JOIN inventory i ON p.site_id=i.site_id
LEFT JOIN quality  q ON p.site_id=q.site_id
*/
--Q4)Executive Root Cause Analysis Dashboard
/*
WITH procurement  AS(
SELECT 
      site_id,SUM(o.ordered_qty*m.unit_cost) AS Total_procurement_cost,
      ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[purchase_orders] o ON m.part_id=o.part_id
GROUP BY site_id),
inventory  AS (
SELECT site_id,AVG(on_hand_qty)/NULLIF(AVG(s.forecast_qty), 0) AS Inventory_coverage_ratio,SUM(s.backorder_qty) AS Total_backorders
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[supply_chain_history] s ON s.part_id=m.part_id
GROUP BY site_id),
quality  AS( 
SELECT site_id,COUNT(DISTINCT incident_id)  AS Quality_incidents
FROM [dbo].[quality_incidents]
GROUP BY site_id)
SELECT p.site_id,
       Total_procurement_cost,
       On_time_delivery_percentage,
       Inventory_coverage_ratio,
       Total_backorders,
      ISNULL(q.Quality_incidents,0) AS Quality_incidents,
       CASE WHEN On_time_delivery_percentage <85 THEN 'Procurement Issue'
            WHEN Inventory_coverage_ratio <1  AND Total_backorders > 50 THEN 'Inventory Planning Issue'
            WHEN Quality_incidents > 10 THEN 'Quality Issue'
            ELSE 'Healthy Operations'
       END AS Root_Cause
FROM procurement P
LEFT JOIN inventory i ON p.site_id=i.site_id
LEFT JOIN quality  q ON p.site_id=q.site_id
*/
--Q5)COO Executive Decision Dashboard

/*
WITH procurement  AS(
SELECT 
      site_id,SUM(o.ordered_qty*m.unit_cost) AS Total_procurement_cost,
      CASE
    WHEN MAX(CASE WHEN supplier_risk_class='High' THEN 1 ELSE 0 END)=1
         THEN 'High'
    WHEN MAX(CASE WHEN supplier_risk_class='Medium' THEN 1 ELSE 0 END)=1
         THEN 'Medium'
    ELSE 'Low'
END AS Supplier_risk_class,
      ROUND(SUM(CASE WHEN promised_date>=receipt_date THEN 1 END)*100.0/COUNT(*),2) AS On_time_delivery_percentage
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[purchase_orders] o ON m.part_id=o.part_id
GROUP BY site_id),
inventory  AS (
SELECT site_id,AVG(on_hand_qty)/NULLIF(AVG(s.forecast_qty), 0) AS Inventory_coverage_ratio,SUM(s.backorder_qty) AS Total_backorders
FROM [dbo].[parts_master] m
LEFT JOIN [dbo].[supply_chain_history] s ON s.part_id=m.part_id
GROUP BY site_id),
quality  AS( 
SELECT site_id,COUNT(DISTINCT incident_id)  AS Quality_incidents
FROM [dbo].[quality_incidents]
GROUP BY site_id),
Final_score AS(
SELECT p.site_id,
       Total_procurement_cost,
       On_time_delivery_percentage,
       Inventory_coverage_ratio,
       Supplier_risk_class,
       Total_backorders,
      ISNULL(q.Quality_incidents,0) AS Quality_incidents,
       (CASE WHEN On_time_delivery_percentage <85 THEN 2 ELSE 0 END 
       +
       CASE WHEN Inventory_coverage_ratio <1 THEN 2 ELSE 0 END 
       +
       CASE WHEN Total_backorders >50 THEN 2 ELSE 0 END 
       +
       CASE WHEN ISNULL(q.Quality_incidents,0) >10 THEN 2 ELSE 0 END
       +
       CASE WHEN Supplier_risk_class='High' THEN 2 ELSE 0 END 
       +
       CASE WHEN Supplier_risk_class='Medium' THEN 1 ELSE 0 END
       +
       CASE WHEN Supplier_risk_class='Low' THEN 0  ELSE 0  END
            )
       AS Executive_Risk_Score
FROM procurement P
LEFT JOIN inventory i ON p.site_id=i.site_id
LEFT JOIN quality  q ON p.site_id=q.site_id)
SELECT *,       CASE
            WHEN Executive_Risk_Score BETWEEN 0 AND 2 THEN 'Low'
            WHEN Executive_Risk_Score BETWEEN 3 AND 5 THEN 'Medium'
            WHEN Executive_Risk_Score BETWEEN 6 AND 8 THEN 'High'
            ELSE 'Critical'
       END AS Executive_Priority
FROM Final_score
*/









