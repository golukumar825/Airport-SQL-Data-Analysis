#### PROJECT

create database airport_db;
use airport_db;
show tables;
select * from airports2;

## problem statement 1
select origin_airport, destination_airport, sum(passengers) as total_passengers
from airports2 
group by origin_airport,destination_airport
order by total_passengers desc;


## problem staement 2

select origin_airport, destination_airport, avg(cast(passengers as float)/nullif(seats,0)) as average_pasengers__utilization
from airports2 
group by origin_airport,destination_airport
order by average_pasengers__utilization desc;

## problem statement 3
select origin_airport, destination_airport, sum(passengers) as total_passengers
from airports2 
group by origin_airport,destination_airport
order by total_passengers desc
limit 3;

## problem statement 4
select origin_city, count(flights) as total_flights, sum(passengers) as total_passengers
from airports2 
group by origin_city
order by origin_city desc;     ## we can do also order by total_passengers

## problem statement 5

select origin_airport, sum(distance) as total_distance
from airports2 
group by origin_airport
order by  origin_airport desc;

## problem statement 6
select year(fly_date), month(fly_date), sum(passengers), count(flights), avg(distance) as total_distance
from airports2
group by year(fly_date), month(fly_date)
order by year(fly_date) desc, month(fly_date) desc;

## problem statement 7

select origin_airport, destination_airport, sum(passengers) as total_passengers, sum(seats) as total_seats,
   ((sum(passengers) * 1.0)/nullif(sum(seats),0)) as passengers_to_seats_ratio     ## either you choose cast for float or multiply by 1.0
from airports2 
group by origin_airport,destination_airport
having passengers_to_seats_ratio < 0.5
order by  passengers_to_seats_ratio;

## problem statement 8

select origin_airport, count(flights) as total_flights
from airports2 
group by  origin_airport
order by origin_airport desc
limit 4;

## problem statement 9

select origin_city, count(flights) as total_flights, sum(passengers) as total_passengers
from airports2 
where destination_city = "bend,OR" and origin_city <> "bend,OR"
group by  origin_city
order by total_passengers desc, total_flights desc
limit 100;


## problem statement 10

select origin_airport, destination_airport, max(distance) as long_distance
from airports2 
group by origin_airport,destination_airport
order by long_distance desc
limit 1;

## problem statement 11

with monthly_flights as
(select month(Fly_date) as months, count(Flights) as total_flights
from airports2
group by months)
select months, total_flights,
case 
when total_flights = (select max(total_flights) from  monthly_flights) then 'most busy'
when total_flights = (select min(total_flights) from  monthly_flights) then 'least busy'
else null
end as status
from  monthly_flights
where  total_flights = (select max(total_flights) from  monthly_flights) or
	   total_flights = (select min(total_flights) from  monthly_flights) ;


## problem statement 12

with passenegers_summary as
(select origin_airport, destination_airport, year(fly_date) as year, sum(passengers) as total_passengers
from airports2 
group by origin_airport, destination_airport,  year(fly_date)),

 passengers_growth as
 (select  origin_airport, destination_airport,  year, total_passengers,
lag(total_passengers) over (partition by origin_airport, destination_airport order by year) as previous_year_passengers
 from passenegers_summary)
 
select origin_airport, destination_airport,  year,  total_passengers, previous_year_passengers,
case when previous_year_passengers is not null then
  ((total_passengers - previous_year_passengers) * 100.0/nullif(previous_year_passengers,0))
     end as percentage_growth
 from passengers_growth
order by origin_airport desc, destination_airport desc,  year desc;

## problem statement 13


with flights_summary as
(select origin_airport, destination_airport, year(fly_date) as year, count(flights) as total_flights
from airports2 
group by origin_airport, destination_airport, year(fly_date)),

flight_growth as
(select  origin_airport, destination_airport,  year,  total_flights,
lag(total_flights) over (partition by origin_airport, destination_airport order by year) as previous_year_flights
 from flights_summary),
 
growth_rates as 
(select  origin_airport, destination_airport, year, total_flights, previous_year_flights,
case when  previous_year_flights is not NULL and  previous_year_flights>0  then
		((total_flights - previous_year_flights) * 100.0/(previous_year_flights))
        else null
        end as growth_rate,
        case when  previous_year_flights is not NULL and total_flights > previous_year_flights then
		1
        else 0
        end as growth_indicator
from flight_growth)

select  origin_airport, destination_airport,
        min(growth_rate) as minimum_growth_rate,
		max(growth_rate) as maximumgrowth_rate
        from growth_rates 
        where growth_indicator = 1
        group by  origin_airport, destination_airport
        having min(growth_indicator = 1)
        order by origin_airport, destination_airport;

## problem statement 14

with utilization_ratio as
(select origin_airport, sum(passengers) as total_passengers, sum(seats) as total_seats, count(flights) as total_flights,
   ((sum(passengers) * 1.0)/nullif(sum(seats),0)) as passengers_to_seats_ratio     ## either you choose cast for float or multiply by 1.0
from airports2 
group by origin_airport),

wieghted_utilization as
(select  origin_airport, total_passengers, total_seats, total_flights, passengers_to_seats_ratio,
(passengers_to_seats_ratio *  total_flights) / sum(total_flights)
over () as wieghted_utilization
from utilization_ratio)

select  origin_airport, total_passengers, total_seats, total_flights, passengers_to_seats_ratio , wieghted_utilization
from wieghted_utilization

order by wieghted_utilization desc
limit 3;

## problem statement 15

with monthly_passenger_count as
(select origin_city, month(fly_date) as month, year(fly_date) as year, sum(passengers) as total_passengers
from airports2
group by origin_city, month, year),

max_passenger_per_city as
(select origin_city, max( total_passengers) as peak_passengers
from monthly_passenger_count
group by origin_city)

select mpc.origin_city, mpc.month, mpc.year, mpc.total_passengers
from monthly_passenger_count mpc
join max_passenger_per_city mppc on
 mpc.origin_city = mppc.origin_city and
 mpc. total_passengers =  mppc.peak_passengers
order by mpc.origin_city, mpc.month, mpc.year;

## problem statement 16

with passenger_yearly_count as
(select origin_airport, destination_airport, year(fly_date) as year, sum(passengers) as total_passengers
from airports2
group by origin_airport, destination_airport, year),

yearly_declined as
(select  y1.origin_airport, y1.destination_airport, y1.year year1, y1.total_passengers passengers_year1,  
y2.year year2, y2.total_passengers passengers_year2,
((y2.total_passengers -  y1.total_passengers) *100.0/ nullif(y1.total_passengers,0)) percentage_change
from passenger_yearly_count y1 join passenger_yearly_count y2
on y1. origin_airport =  y2.origin_airport and
y1. destination_airport = y2.destination_airport and
y1.year = y2.year+1)

select origin_airport, destination_airport, year1, passengers_year1,  
 year2,  passengers_year2, percentage_change
 from yearly_declined
where percentage_change < 0     ## only get declining routes
order by percentage_change
limit 100;


## problem statement 17
with flight_stats as
(select origin_airport, destination_airport, count(flights) as total_flights, 
sum(passengers) as total_passengers, sum(seats) as total_seats,
(sum(passengers) / nullif(sum(seats),0)) as average_seat_utilization
from airports2 
group by origin_airport, destination_airport)

select  origin_airport, destination_airport, total_flights, 
 total_passengers, total_seats,
 round((average_seat_utilization * 100),2) as average_seat_utilization_percentage
 from  flight_stats
 where  total_flights >= 10 and
       round((average_seat_utilization * 100),2) < 50
        order by average_seat_utilization_percentage;
        
   ## problem statement 18    

with distance_stat as 
(select origin_city, destination_city, avg(distance) as avg_flight_distance
from airports2
group by  origin_city, destination_city)
select origin_city, destination_city, 
	round(avg_flight_distance,2) as avg_flight_distance
    from distance_stat 
    order by avg_flight_distance desc;
    
    
    
    
   ## problem statement 19   

with yearly_summary as
(select year(fly_date) as year, count(flights) as total_flights,
sum(passengers) as total_passengers
from airports2
group by  year),
 growth_summary as
(select  year, total_flights, lag(total_flights) over (order by year) as previous_year_flights,
 total_passengers, lag(total_passengers) over (order by year) as previous_year_passengers
from yearly_summary)
select year, total_flights, previous_year_flights, total_passengers, previous_year_passengers,
round(((total_flights- previous_year_flights)*100/nullif( previous_year_flights,0)),2) as percentage_flight_growth,
round(((total_passengers-previous_year_passengers )*100/nullif( previous_year_passengers,0)),2) as percentage_passenegr_growth
from growth_summary
   order by year;



## problem statement 20  
with route_distance as
(select origin_airport, destination_airport, sum(flights) as total_flights, 
sum(distance) as total_distance
from airports2
group by origin_airport, destination_airport),
weighted_route as
(select origin_airport, destination_airport, total_flights, total_distance,
 total_distance * total_flights as weighted_distance
from route_distance)
select origin_airport, destination_airport, total_flights, total_distance, weighted_distance
from weighted_route
order by weighted_distance desc
limit 3;