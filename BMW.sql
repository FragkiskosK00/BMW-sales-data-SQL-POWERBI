USE BMW; --Χρήση του BMW Database που δημιουργήσαμε

-- Δημιουργία των διαστάσεων και ορισμός κλειδιών - τύποι records

CREATE TABLE dim_model (
    model_key INT IDENTITY(1,1) PRIMARY KEY,--Χρήση IDENTITY(1,1) για την αυτόματη δημιουργία ενός αύξοντα αριθμού για κάθε εγγραφή
    model_name NVARCHAR(100), --Χρήση εντολής NVARCHAR για αναπαράσταση και άλλων δεδομένων εκτός απο λατινικούς χαρ/ες
    engine_size_L DECIMAL (3,1)
);

CREATE TABLE dim_region (
    region_key INT IDENTITY(1,1) PRIMARY KEY,
    region_name NVARCHAR(100)
);

CREATE TABLE dim_color (
    color_key INT IDENTITY(1,1) PRIMARY KEY,
    color_name NVARCHAR(50)
);

CREATE TABLE dim_fuel (
    fuel_key INT IDENTITY(1,1) PRIMARY KEY,
    fuel_type NVARCHAR(50)
);

CREATE TABLE dim_transmission (
    transmission_key INT IDENTITY(1,1) PRIMARY KEY,
    transmission_type NVARCHAR(50)
);

CREATE TABLE dim_year (
    year_key INT IDENTITY(1,1) PRIMARY KEY,
    sales_year INT
);

CREATE TABLE dim_sales_classification (
    classification_key INT IDENTITY(1,1) PRIMARY KEY,
    classification_name NVARCHAR(50)
);

--Δημιουργία πίνακα fact, ορίζοντας ξένα κλειδιά και references

CREATE TABLE fact_sales (
    sales_key BIGINT IDENTITY(1,1) PRIMARY KEY, --ορισμός BIGINT για λόγους επεκτασιμότητας, 
    --καθώς έχουμε προς το παρόν 50000 εγγραφές μπορεί στο μέλλον να προκύψουν billion εγγραφές, έτσι ο table fact_sales δεν θα λειτουργήσει σωστά.
    model_key INT FOREIGN KEY REFERENCES dim_model(model_key),
    region_key INT FOREIGN KEY REFERENCES dim_region(region_key),
    color_key INT FOREIGN KEY REFERENCES dim_color(color_key),
    fuel_key INT FOREIGN KEY REFERENCES dim_fuel(fuel_key),
    transmission_key INT FOREIGN KEY REFERENCES dim_transmission(transmission_key),
    year_key INT FOREIGN KEY REFERENCES dim_year(year_key),
    classification_key INT FOREIGN KEY REFERENCES dim_sales_classification(classification_key),
    mileage_km INT,
    price_usd DECIMAL(10,2),
    sales_volume INT
);

CREATE TABLE staging_bmw ( --Δημιουργία άλλου πίνακα για να δούμε τα δεδομένα και να τα επξεργαστούμε
    Model NVARCHAR(100),
    Year INT,
    Region NVARCHAR(100),
    Color NVARCHAR(50),
    Fuel_Type NVARCHAR(50),
    Transmission NVARCHAR(50),
    Engine_Size_L FLOAT,
    Mileage_KM INT,
    Price_USD INT,
    Sales_Volume INT,
    Sales_Classification NVARCHAR(50)
);

--Εισαγωγή αρχείου CSV και επεξεργασία

BULK INSERT staging_bmw --η μέθοδος task import data δεν μου δούλεψε οπότε έκανα bulk insert το csv αρχείο στον επεξεργάσιμο πίνακα αρχικά
FROM 'C:\Users\fragi\Desktop\BMW sales data (2010-2024) (1).csv'
WITH (
    FORMAT='CSV',
    FIRSTROW = 2, --Προσπερνάει την πρώτη γραμμή καθώς περιέχει τους τίτλους των fields
    FIELDTERMINATOR = ',', --Δηλώνω πως οι τιμές διαχωρίζονται στο csv, στην δική μου περίπτωση με κόμμα
    ROWTERMINATOR = '\n',
    TABLOCK 
);

UPDATE staging_bmw --Ενημερώνουμε τον πίνακα stage
SET Region = LTRIM(RTRIM(Region)), --"Τριμάρουμε" δηλαδή βγάζουμε τα space στην αρχή των record του Region (στα αριστερά), και έπειτα στο τέλος στα 
--δεξιά αν υπάρχει κενό
    Fuel_Type = UPPER(LTRIM(RTRIM(Fuel_Type))),--Ομοίως τριμάρουμε και ταυτόχρονα τα record στο fuel type τα κάνουμε κεφαλαία
    Transmission = UPPER(LTRIM(RTRIM(Transmission)));

UPDATE staging_bmw
SET Sales_Classification = LTRIM(RTRIM(UPPER(Sales_Classification)));

SELECT * FROM staging_bmw

SELECT * 
FROM dim_fuel
WHERE fuel_type LIKE '%HYBIRD%';

UPDATE dim_fuel
SET fuel_type = 'HYBRID'
WHERE fuel_type = 'HYBIRD';

-- Εισάγουμε δεδομένα στα dimensions από τον staging_bmw

INSERT INTO dim_model (model_name, engine_size_L)
SELECT DISTINCT Model, Engine_Size_L
FROM staging_bmw

INSERT INTO dim_region (region_name)
SELECT DISTINCT Region FROM staging_bmw;

INSERT INTO dim_color (color_name)
SELECT DISTINCT Color FROM staging_bmw;

INSERT INTO dim_fuel (fuel_type)
SELECT DISTINCT Fuel_Type FROM staging_bmw;

INSERT INTO dim_transmission (transmission_type)
SELECT DISTINCT Transmission FROM staging_bmw;

INSERT INTO dim_year (sales_year)
SELECT DISTINCT Year FROM staging_bmw;

INSERT INTO dim_sales_classification (classification_name)
SELECT DISTINCT Sales_Classification FROM staging_bmw;

UPDATE dim_sales_classification
SET classification_name = UPPER(LTRIM(RTRIM(classification_name)));

SELECT * FROM dim_fuel


-- Εισάγουμε δεδομένα στο fact sales κάνωντας join απο τον st table δηλαδή τον stage_bmw

INSERT INTO fact_sales (
    model_key, region_key, color_key, fuel_key, transmission_key, year_key, classification_key,
    mileage_km, price_usd, sales_volume
)
SELECT
    m.model_key,
    r.region_key,
    c.color_key,
    f.fuel_key,
    t.transmission_key,
    y.year_key,
    s.classification_key,
    st.Mileage_KM,
    st.Price_USD,
    st.Sales_Volume
FROM staging_bmw st
JOIN dim_model m ON m.model_name = st.Model
JOIN dim_region r ON r.region_name = st.Region
JOIN dim_color c ON c.color_name = st.Color
JOIN dim_fuel f ON f.fuel_type = st.Fuel_Type
JOIN dim_transmission t ON t.transmission_type = st.Transmission
JOIN dim_year y ON y.sales_year = st.Year
JOIN dim_sales_classification s ON s.classification_name = st.Sales_Classification;

SELECT COUNT(*) FROM fact_sales; --Κοιτάζω να δω αν όλα τα NOT null διαθέσιμα records έχουν περαστεί

SELECT * 
FROM fact_sales 
WHERE model_key IS NULL OR region_key IS NULL; -- Εδώ ελέγχω αν έχει Null τιμές

SELECT *
FROM fact_sales

select * from dim_model

ALTER TABLE dim_model --Ενεργούμε πάνω στον πίνακα dim model
ALTER COLUMN engine_size_L DECIMAL(3,1); --Ορίζω εως 3 ψηφία συνολικά από τα οποία 1 μετά την υποδιαστολή στο engine size

SELECT DISTINCT Sales_Classification
FROM staging_bmw
ORDER BY Sales_Classification;
