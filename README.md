# ✈️ Airline On-Time Performance & Reliability Analysis

An end-to-end **SQL + Power BI + Excel** data analytics project analyzing airline flight operations, delays, cancellations, route performance, carrier reliability, and departure-hour patterns.

---

## 📊 Project Overview

This project analyzes airline flight data to understand operational performance and identify patterns in:

- Flight delays
- Flight cancellations
- Airline reliability
- Route performance
- Flight volume
- Departure-hour performance
- Median delay
- Operational risk

The analysis was performed using **SQL** and the results were transformed into an interactive **4-page Power BI dashboard**.

---

## 🛠️ Tools & Technologies

- **SQL / MySQL** — Data analysis, transformation and aggregation
- **Power BI** — Interactive dashboard and visualization
- **DAX** — KPI and analytical calculations
- **Excel** — Data handling and supporting analysis

---

# 🗄️ SQL Analysis

SQL was used as the primary analytical layer of the project.

### Data Validation

Performed checks for:

- Total flight records
- Operated flights
- Cancelled flights
- Missing values
- Airline data
- Airport data

### Feature Engineering

Created a `departure_hour` field from scheduled departure time to enable hourly performance analysis.

### Airline Analysis

Calculated:

- Operated flights
- Delayed flights
- Delay rate
- Average delay
- Cancellation rate
- Median delay

### Route Analysis

Analyzed:

- Origin and destination airports
- Flight volume
- Delayed flights
- Delay rate
- Cancellation rate
- Route reliability

Routes were also categorized into:

- Low Volume
- Medium Volume
- High Volume

### Hourly Analysis

Analyzed airline operations by departure hour using:

- Scheduled flights
- Operated flights
- Delayed flights
- Delay rate
- Cancellation rate
- Average delay

### Median Delay

Used SQL window functions including:

- `ROW_NUMBER()`
- `COUNT() OVER()`
- `PARTITION BY`

to calculate median delay for carriers and routes.

### Reliability Score

Created a custom reliability score based on:

| Metric | Weight |
|---|---:|
| Delay Rate | 50% |
| Cancellation Rate | 30% |
| Median Delay | 20% |

A higher score represents better operational reliability.

---

# 📊 Power BI Dashboard

The final Power BI report contains **4 analytical pages**.

## Page 1 — Executive Reliability Overview

Provides a high-level overview of airline operational performance.

Includes:

- Executive KPIs
- Carrier reliability analysis
- Departure-hour delay analysis
- Route volume vs delay analysis
- Destination reliability

---

## Page 2 — Route Performance Analysis

Focuses on route-level performance.

Includes:

- Top 10 routes by delay rate
- Top 10 routes by flight volume
- Route reliability
- Route-level KPIs
- Route performance comparisons

---

## Page 3 — Carrier & Hour Reliability

Analyzes carrier and departure-hour performance.

Includes:

- Carrier delay analysis
- Hourly delay analysis
- Reliability comparisons
- Median delay analysis
- Operational performance indicators

---

## Page 4 — Executive Reliability Scorecard

Provides a detailed operational scorecard.

Includes:

- Reliability KPIs
- 10 least reliable routes
- Least reliable carriers
- Hourly reliability scorecard
- Key operational insights

Conditional formatting is used to highlight performance differences.

---

# 📈 Key Metrics

The project analyzes:

- Total Flights
- Operated Flights
- Cancelled Flights
- Delayed Flights
- Delay Rate
- Cancellation Rate
- Average Delay
- Median Delay
- Flight Volume
- Reliability Score

---

# 💡 Business Questions

The dashboard helps answer questions such as:

1. Which carriers have the highest delay rates?
2. Which carriers are least reliable?
3. Which routes experience the highest delays?
4. Which routes have the highest flight volumes?
5. Which departure hours have higher delay rates?
6. Which carriers have higher median delays?
7. Which routes represent potential operational risk?
8. How does route volume relate to delay performance?

---

# 📷 Dashboard Preview

## Page 1 — Executive Reliability Overview

![Page 1](Dashboard/Page_1.png)

## Page 2 — Route Performance Analysis

![Page 2](Dashboard/Page_2.png)

## Page 3 — Carrier & Hour Reliability

![Page 3](Dashboard/Page_3.png)

## Page 4 — Executive Reliability Scorecard

![Page 4](Dashboard/Page_4.png)

---

# 📁 Repository Structure

```text
Airline-On-Time-Performance-Analysis/
│
├── SQL/
│   └── airline_analysis_clean.sql
│
├── Dashboard/
│   ├── Page_1.png
│   ├── Page_2.png
│   ├── Page_3.png
│   └── Page_4.png
│
├── Airline_Analysis.pbix
│
└── README.md
