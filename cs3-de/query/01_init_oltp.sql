CREATE SCHEMA IF NOT EXISTS oltp;

-- Metadata tracking table
CREATE TABLE IF NOT EXISTS oltp._ingestion_metadata (
    ingest_id SERIAL PRIMARY KEY,
    source_file VARCHAR(255) NOT NULL,
    records_loaded INT NOT NULL,
    loaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL
);

-- Core Reference Tables
CREATE TABLE IF NOT EXISTS oltp.countries (
    CountryID INT PRIMARY KEY,
    CountryName VARCHAR(100) NOT NULL,
    Continent VARCHAR(50),
    Region VARCHAR(50),
    Subregion VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS oltp.state_provinces (
    StateProvinceID INT PRIMARY KEY,
    StateProvinceCode VARCHAR(10) NOT NULL,
    StateProvinceName VARCHAR(100) NOT NULL,
    CountryID INT REFERENCES oltp.countries(CountryID),
    SalesTerritory VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS oltp.cities (
    CityID INT PRIMARY KEY,
    CityName VARCHAR(100) NOT NULL,
    StateProvinceID INT REFERENCES oltp.state_provinces(StateProvinceID)
);

CREATE TABLE IF NOT EXISTS oltp.customer_categories (
    CustomerCategoryID INT PRIMARY KEY,
    CustomerCategoryName VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.buying_groups (
    BuyingGroupID INT PRIMARY KEY,
    BuyingGroupName VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(150) NOT NULL,
    CustomerCategoryID INT REFERENCES oltp.customer_categories(CustomerCategoryID),
    BuyingGroupID INT REFERENCES oltp.buying_groups(BuyingGroupID),
    DeliveryCityID INT REFERENCES oltp.cities(CityID),
    CreditLimit NUMERIC(18, 2),
    ValidFrom TIMESTAMP NOT NULL,
    ValidTo TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.people (
    PersonID INT PRIMARY KEY,
    FullName VARCHAR(150) NOT NULL,
    IsPermittedToLogon BOOLEAN,
    IsSalesperson BOOLEAN
);

CREATE TABLE IF NOT EXISTS oltp.colors (
    ColorID INT PRIMARY KEY,
    ColorName VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.package_types (
    PackageTypeID INT PRIMARY KEY,
    PackageTypeName VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.stock_items (
    StockItemID INT PRIMARY KEY,
    StockItemName VARCHAR(150) NOT NULL,
    SupplierID INT,
    ColorID INT REFERENCES oltp.colors(ColorID),
    UnitPackageID INT REFERENCES oltp.package_types(PackageTypeID),
    Brand VARCHAR(50),
    UnitPrice NUMERIC(18, 2) NOT NULL,
    TaxRate NUMERIC(18, 3) NOT NULL
);

-- Transaction Tables
CREATE TABLE IF NOT EXISTS oltp.orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT REFERENCES oltp.customers(CustomerID),
    SalespersonPersonID INT REFERENCES oltp.people(PersonID),
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE
);

CREATE TABLE IF NOT EXISTS oltp.order_lines (
    OrderLineID INT PRIMARY KEY,
    OrderID INT REFERENCES oltp.orders(OrderID),
    StockItemID INT REFERENCES oltp.stock_items(StockItemID),
    Description VARCHAR(255),
    Quantity INT NOT NULL,
    UnitPrice NUMERIC(18, 2),
    TaxRate NUMERIC(18, 3)
);

CREATE TABLE IF NOT EXISTS oltp.invoices (
    InvoiceID INT PRIMARY KEY,
    OrderID INT REFERENCES oltp.orders(OrderID),
    CustomerID INT REFERENCES oltp.customers(CustomerID),
    BillToCustomerID INT,
    DeliveryMethodID INT,
    ContactPersonID INT,
    AccountsPersonID INT,
    SalespersonPersonID INT REFERENCES oltp.people(PersonID),
    InvoiceDate DATE NOT NULL,
    CustomerPurchaseOrderNumber VARCHAR(50),
    IsCreditNote BOOLEAN,
    CreditNoteReason VARCHAR(255),
    Comments TEXT,
    DeliveryInstructions TEXT,
    InternalComments TEXT,
    TotalDryItems INT,
    TotalChillerItems INT,
    DeliveryRun VARCHAR(50),
    RunPosition VARCHAR(50),
    ReturnedDeliveryData TEXT,
    ConfirmedDeliveryTime TIMESTAMP,
    ConfirmedReceivedBy VARCHAR(150),
    LastEditedBy INT,
    LastEditedWhen TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oltp.invoice_lines (
    InvoiceLineID INT PRIMARY KEY,
    InvoiceID INT REFERENCES oltp.invoices(InvoiceID),
    StockItemID INT REFERENCES oltp.stock_items(StockItemID),
    Description VARCHAR(255),
    PackageTypeID INT REFERENCES oltp.package_types(PackageTypeID),
    Quantity INT NOT NULL,
    UnitPrice NUMERIC(18, 2),
    TaxRate NUMERIC(18, 3),
    TaxAmount NUMERIC(18, 2),
    LineProfit NUMERIC(18, 2),
    ExtendedPrice NUMERIC(18, 2)
);
