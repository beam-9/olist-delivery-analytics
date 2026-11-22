# Where to investigate delivery delays

Start with São Paulo and Rio de Janeiro. They accounted for 1,274 of 2,453 late deliveries (51.9%) among 43,426 eligible 2017 purchases. Overall, 94.35% arrived by the promised calendar date. Prioritize by late volume to reach the most affected orders, then use delay severity and review results to decide which cases to inspect.

| Priority by dimension | Late deliveries | 90th percentile delay | Low ratings among rated late orders |
|---|---:|---:|---:|
| São Paulo | 650 | 21 days | 351 / 634 (55.36%) |
| Rio de Janeiro | 624 | 27 days | 413 / 605 (68.26%) |
| November 2017 | 904 | 24 days | 574 / 887 (64.71%) |
| Bed, bath and table | 289 | 29 days | 184 / 281 (65.48%) |

The dimensions overlap. In Rio de Janeiro, median carrier-to-delivery time was 675 hours for late orders (624 valid pairs) and 193 hours for on-time orders (5,344 pairs). Start by checking carrier handoffs and delivery scans in operational records. The longer elapsed stage identifies where to look, but these data cannot identify the cause or assign fault. See [late volume by state](charts/late-by-state.svg) and SQL 05 and 07.

## Review timing changes the result

Using the latest valid answered review before June 1, 2018, 61.54% of rated late orders scored 1–2 (1,466/2,382), versus 9.20% of rated on-time orders (3,745/40,697). Restricting review creation to the delivery date or later reduced those shares to 25.66% (156/608) and 9.18% (3,725/40,563). Late-order review coverage fell from 97.11% to 24.79%. The late versus on-time gap dropped from 52.34 to 16.48 percentage points. On-time review coverage changed from 99.33% to 99.00%. The comparison changes both the timing rule and the population. Selecting the earliest eligible answer without the timing filter changed the late share only to 61.59%. See [rating sensitivity](charts/rating-sensitivity.svg) and SQL 06.

These are historical associations. The fixed cutoff leaves 1,675 past-promise orders without observed delivery, out of 45,101 purchases. Source statuses were shipped (530), unavailable (457), canceled (265), processing (240), invoiced (175), created (4), approved (2), and delivered with no delivery timestamp (2). Those orders are excluded from the delivery rates. The extract lacks status transition times, support contact records and precise time-of-day information for many review creation records.

## Test proactive notifications

In SP and RJ, enroll open, undelivered orders the first time an existing ETA exceeds the promise while the promise is still in the future. Require a stable customer key and randomize customers 1:1 at their first eligible order. Keep later eligible orders in the same arm and account for customer clustering in analysis. The control arm receives usual practice. The treatment arm receives one proactive notification per eligible order at enrollment. Predefine the sample size and minimum detectable effect before launch.

Compare low-rating share among rated orders and review coverage among all assigned orders over 30 days from enrollment. Use the last valid 1–5 review answered in that window, with low ratings defined as 1–2. Also report low-rating submissions per assigned order, since the message can change who reviews. Analyze by assignment and report contact rates only if consistently logged. This is a proposed experiment, with no estimated notification effect from the extract.

Source: [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published by Olist. See the project README for attribution and source details.
