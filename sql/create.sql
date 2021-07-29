-- dim_passengers - справочник пассажиров
CREATE TABLE IF NOT EXISTS dim_passengers
(
    id             serial PRIMARY KEY,
    passenger_code varchar(20) NOT NULL,
    passenger_name text        NOT NULL,
    contact_data   jsonb       NOT NULL
);

CREATE INDEX IF NOT EXISTS dim_passengers_passenger_code_index
    ON dim_passengers (passenger_code);

CREATE TABLE IF NOT EXISTS rejected_dim_passengers
(
    passenger_code varchar(20)              NOT NULL,
    passenger_name text                     NOT NULL,
    contact_data   jsonb,
    created_at     timestamp WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- dim_aircrafts - справочник самолетов
CREATE TABLE IF NOT EXISTS dim_aircrafts
(
    id            serial PRIMARY KEY,
    aircraft_code char(3) NOT NULL,
    model         text    NOT NULL,
    range         integer NOT NULL
);

CREATE INDEX IF NOT EXISTS dim_aircrafts_aircraft_code_index
    ON dim_aircrafts (aircraft_code);

CREATE TABLE IF NOT EXISTS rejected_dim_aircrafts
(
    aircraft_code char(3)                  NOT NULL,
    model         text                     NOT NULL,
    range         integer                  NOT NULL,
    created_at    timestamp WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- dim_airports - справочник аэропортов
CREATE TABLE IF NOT EXISTS dim_airports
(
    id           serial PRIMARY KEY,
    airport_code char(3)       NOT NULL,
    airport_name text          NOT NULL,
    city         text          NOT NULL,
    longitude    decimal(9, 3) NOT NULL,
    latitude     decimal(9, 3) NOT NULL,
    timezone     text          NOT NULL
);

CREATE INDEX IF NOT EXISTS dim_airports_airport_code_index
    ON dim_airports (airport_code);

CREATE TABLE IF NOT EXISTS rejected_dim_airports
(
    airport_code char(3)                  NOT NULL,
    airport_name text                     NOT NULL,
    city         text                     NOT NULL,
    longitude    decimal(9, 3)            NOT NULL,
    latitude     decimal(9, 3)            NOT NULL,
    timezone     text                     NOT NULL,
    created_at   timestamp WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- dim_tariff - справочник тарифов (Эконом/бизнес и тд)
CREATE TABLE IF NOT EXISTS dim_tariffs
(
    id          serial PRIMARY KEY,
    tariff_code varchar(10) NOT NULL
);

CREATE INDEX IF NOT EXISTS dim_tariffs_tariff_code_index
    ON dim_tariffs (tariff_code);

-- dim_calendar - справочник дат
CREATE TABLE IF NOT EXISTS dim_calendar
AS
  WITH dates AS (
      SELECT dd::date AS dt
        FROM GENERATE_SERIES
                 ('2016-01-01'::timestamp
                 , '2017-01-01'::timestamp
                 , '1 day'::interval) dd
  )
SELECT TO_CHAR(dt, 'YYYYMMDD')::int                             AS id,
       dt                                                       AS date,
       TO_CHAR(dt, 'YYYY-MM-DD')                                AS ansi_date,
       DATE_PART('isodow', dt)::int                             AS day,
       DATE_PART('week', dt)::int                               AS week_number,
       DATE_PART('month', dt)::int                              AS month,
       DATE_PART('isoyear', dt)::int                            AS iso_year,
       (DATE_PART('isodow', dt)::smallint BETWEEN 1 AND 5)::int AS week_day,
       (TO_CHAR(dt, 'YYYYMMDD')::int IN (
                                         20160101,
                                         20160102,
                                         20160103,
                                         20160104,
                                         20160105,
                                         20160106,
                                         20160107,
                                         20160108,
                                         20160222,
                                         20160223,
                                         20160307,
                                         20160308,
                                         20160501,
                                         20160502,
                                         20160503,
                                         20160509,
                                         20160612,
                                         20160613,
                                         20161104,
                                         20170101))::int        AS holiday
  FROM dates
 ORDER BY dt;

ALTER TABLE dim_calendar
    DROP CONSTRAINT IF EXISTS date_pkey;
ALTER TABLE dim_calendar
    ADD PRIMARY KEY (id);

CREATE TABLE IF NOT EXISTS fact_flights
(
    passenger_id             int                      NOT NULL REFERENCES dim_passengers (id),
    actual_departure_dt      timestamp WITH TIME ZONE NOT NULL,
    actual_departure_date_id int                      NOT NULL REFERENCES dim_calendar (id),
    actual_arrival_dt        timestamp WITH TIME ZONE NOT NULL,
    actual_arrival_date_id   int                      NOT NULL REFERENCES dim_calendar (id),
    departure_delay          int                      NOT NULL DEFAULT 0,
    arrival_delay            int                      NOT NULL DEFAULT 0,
    aircraft_id              int                      NOT NULL REFERENCES dim_aircrafts (id),
    departure_airport_id     int                      NOT NULL REFERENCES dim_airports (id),
    arrival_airport_id       int                      NOT NULL REFERENCES dim_airports (id),
    tariff_id                int                      NOT NULL REFERENCES dim_tariffs (id),
    amount                   numeric(10, 2)           NOT NULL
);

CREATE TABLE IF NOT EXISTS rejected_fact_flights
(
    passenger_code         varchar(20)              NOT NULL,
    scheduled_departure_dt timestamp WITH TIME ZONE NOT NULL,
    actual_departure_dt    timestamp WITH TIME ZONE NOT NULL,
    departure_delay        int                      NOT NULL DEFAULT 0,
    scheduled_arrival_dt   timestamp WITH TIME ZONE NOT NULL,
    actual_arrival_dt      timestamp WITH TIME ZONE NOT NULL,
    arrival_delay          int                      NOT NULL DEFAULT 0,
    aircraft_code          char(3)                  NOT NULL,
    departure_airport      char(3)                  NOT NULL,
    arrival_airport        char(3)                  NOT NULL,
    fare_conditions        varchar(10)              NOT NULL,
    amount                 numeric(10, 2)           NOT NULL,
    created_at             timestamp WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
