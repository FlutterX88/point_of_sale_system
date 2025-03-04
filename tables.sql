-- Table: properties

CREATE TABLE properties (
    sno SERIAL PRIMARY KEY,                     -- Auto-incremented serial number
    property_id VARCHAR(50) UNIQUE NOT NULL,    -- Property ID (WIPLdatemonthyearhoursec format)
    property_name VARCHAR(255) NOT NULL,        -- Property name
    address TEXT NOT NULL,                     -- Property address
    contact_number VARCHAR(20) NOT NULL,       -- Property contact number
    email VARCHAR(255),                        -- Property email address
    business_hours VARCHAR(255),               -- Business hours for the property
    tax_reg_no VARCHAR(50),                    -- Tax Registration Number
    state VARCHAR(100),                        -- Property state
    district VARCHAR(100),                     -- Property district
    country VARCHAR(100),                      -- Property country
    currency VARCHAR(10),                      -- Currency used for transactions (e.g., ₹, $, €)
    is_saved BOOLEAN DEFAULT FALSE,            -- Whether the property data is saved
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP   -- Timestamp for updates
);

-- Table: user_login
CREATE TABLE user_login (
    user_id SERIAL PRIMARY KEY,              -- Auto-incrementing unique ID
    username VARCHAR(50) UNIQUE NOT NULL,    -- Unique username (mandatory)
    full_name VARCHAR(255) NOT NULL,         -- Full Name
    password_hash TEXT NOT NULL,             -- Password hash (mandatory)
    dob DATE,                                -- Date of birth
    mobile VARCHAR(15),                      -- Mobile number (optional)
    email VARCHAR(100) UNIQUE NOT NULL,      -- Unique email (mandatory)
    outlet VARCHAR(100),                     -- Outlet associated with the user
    property_id VARCHAR(50) NOT NULL,        -- Associated property ID (mandatory, matches properties table type)
    join_date DATE DEFAULT CURRENT_DATE,     -- Date of joining (default to current date)
    role VARCHAR(50),                        -- Role of the user (e.g., Admin, Manager, etc.)
    status BOOLEAN DEFAULT TRUE,             -- Account status: TRUE for active, FALSE for inactive
    updated_at TIMESTAMP DEFAULT NOW(),      -- Timestamp for the last update
    created_at TIMESTAMP DEFAULT NOW()     -- Timestamp for account creation,
);

-- Table: waiters
CREATE TABLE waiters (
    waiter_id SERIAL PRIMARY KEY,                -- Auto-incremented unique ID
    property_id VARCHAR(50) NOT NULL,           -- Associated property ID (foreign key)
    selected_outlet VARCHAR(100),               -- Outlet associated with the waiter
    waiter_name VARCHAR(255) NOT NULL,          -- Waiter name (mandatory)
    contact_number VARCHAR(15),                 -- Waiter contact number (optional)
    hire_date DATE DEFAULT CURRENT_DATE,        -- Date of hire (default to current date)
    status VARCHAR(50) DEFAULT 'active',        -- Waiter status (default to 'active')
    is_saved BOOLEAN DEFAULT FALSE,             -- Whether the data is saved
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for updates
);

-- Table: bill_config
CREATE TABLE bill_config (
    config_id SERIAL PRIMARY KEY,                 -- Auto-incrementing unique ID
    property_id VARCHAR(50) NOT NULL,            -- Associated property ID (foreign key)
    selected_outlet VARCHAR(100),                -- Outlet associated with the configuration
    bill_prefix VARCHAR(50) DEFAULT '',          -- Bill prefix
    bill_suffix VARCHAR(50),                     -- Bill suffix (optional)
    starting_bill_number INT DEFAULT 1,          -- Starting bill number
    series_start_date DATE,                      -- Series start date
    currency_symbol VARCHAR(10) DEFAULT '₹',     -- Currency symbol
    date_format VARCHAR(20) DEFAULT 'dd-MM-yyyy',-- Date format for billing
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for updates
);

-- Table: categories
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,                 -- Auto-incrementing unique ID for the category
    property_id VARCHAR(50) NOT NULL,              -- Property ID (mandatory, foreign key)
    outlet VARCHAR(100) NOT NULL,                  -- Outlet name (mandatory)
    category_name VARCHAR(255) NOT NULL,           -- Name of the category
    category_description TEXT,                     -- Description of the category
    sub_category_name VARCHAR(255),                -- Name of the subcategory
    sub_category_description TEXT,                 -- Description of the subcategory
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp for creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp for updates
);

-- Table: subcategories
CREATE TABLE subcategories (
    sub_category_id SERIAL PRIMARY KEY,           -- Auto-incremented unique ID
    property_id VARCHAR(50) NOT NULL,             -- Associated property ID (foreign key)
    outlet VARCHAR(100),                          -- Outlet associated with the subcategory
    category_id INT NOT NULL,                     -- Associated category ID (foreign key)
    sub_category_name VARCHAR(255) NOT NULL,      -- Subcategory name (mandatory)
    sub_category_description TEXT,                -- Subcategory description
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp for creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for updates
);

-- Table: DateConfig
CREATE TABLE date_config (
    date_config_id SERIAL PRIMARY KEY,           -- Auto-incremented unique ID
    property_id VARCHAR(50) NOT NULL,             -- Associated property ID (foreign key)
    outlet VARCHAR(100),                          -- Outlet associated with the date config
    selected_date DATE,                           -- Date configuration (mandatory)
    description TEXT,                             -- Description of the date configuration
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP   -- Timestamp for updates
);


-- Table: GuestRecord
CREATE TABLE guest_record (
    guest_id SERIAL PRIMARY KEY,              -- Auto-incremented unique ID
    date_joined DATE NOT NULL,                -- Date when the guest joined
    guest_name VARCHAR(255) NOT NULL,         -- Guest's name
    guest_address TEXT NOT NULL,              -- Guest's address
    phone_number VARCHAR(20) NOT NULL,        -- Phone number
    email VARCHAR(255) UNIQUE NOT NULL,       -- Email (unique)
    anniversary DATE,                         -- Anniversary date (optional)
    dob DATE,                                 -- Date of birth
    gst_no VARCHAR(50),                       -- GST Number
    company_name VARCHAR(255),                -- Company name
    discount DECIMAL(5, 2),                   -- Discount (percentage)
    g_suggestion TEXT,                        -- Guest suggestions or comments
    property_id VARCHAR(50) NOT NULL,         -- Associated Property ID (Foreign Key)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for record updates
);

-- Table: HappyHour
CREATE TABLE happy_hour_config (
    id SERIAL PRIMARY KEY,                -- Auto-incremented unique ID
    property_id VARCHAR(50) NOT NULL,      -- Associated Property ID (Foreign Key)
    selected_outlet VARCHAR(100),         -- Outlet associated with the happy hour
    selected_happy_hour VARCHAR(255),     -- Happy hour name or description
    start_time TIME,                      -- Happy hour start time
    end_time TIME,                        -- Happy hour end time
    selected_items TEXT,                  -- Selected items for happy hour (can be a comma-separated list or JSON)
    discount DECIMAL(5, 2),               -- Discount percentage for happy hour
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for updates
);

-- Table: inventory
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,                      -- Auto-incremented unique ID
    property_id VARCHAR(50) NOT NULL,            -- Associated Property ID (Foreign Key)
    selected_outlet VARCHAR(100),               -- Outlet associated with the inventory transaction
    selected_item VARCHAR(255) NOT NULL,        -- Item name being updated
    quantity INT DEFAULT 0,                     -- Quantity of the item being credited or debited
    transaction_type VARCHAR(10),               -- Type of transaction: 'credit' or 'debit'
    selected_date DATE,                         -- Date of the transaction
    description TEXT,                           -- Description or notes about the inventory transaction
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp for updates
);

-- Table: items
CREATE TABLE items (
    item_id SERIAL PRIMARY KEY,                 -- Auto-incremented unique ID
    item_code VARCHAR(50) UNIQUE NOT NULL,      -- Item code (unique)
    item_name VARCHAR(255) NOT NULL,            -- Item name
    category VARCHAR(100),                      -- Category of the item
    brand VARCHAR(100),                         -- Brand of the item
    subcategory_id VARCHAR(50),                 -- Subcategory associated with the item
    outlet VARCHAR(100),                        -- Outlet associated with the item
    description TEXT,                           -- Description of the item
    price DECIMAL(10, 2),                       -- Price of the item
    tax_rate DECIMAL(5, 2),                     -- Tax rate for the item
    discount_percentage DECIMAL(5, 2),         -- Discount percentage on the item
    stock_quantity INT,                         -- Stock quantity of the item
    reorder_level INT,                          -- Reorder level for the item
    is_active BOOLEAN DEFAULT TRUE,             -- Whether the item is active or not
    on_sale BOOLEAN DEFAULT FALSE,              -- Whether the item is on sale
    happy_hour BOOLEAN DEFAULT FALSE,           -- Whether the item is eligible for happy hour
    discountable BOOLEAN DEFAULT TRUE,          -- Whether the item is eligible for discounts
    property_id VARCHAR(50) NOT NULL,           -- Associated Property ID (Foreign Key)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp for updates
);


-- Table: Kot-Config
CREATE TABLE kot_configs (
    kot_id SERIAL PRIMARY KEY,           -- Auto-incremented unique ID for KOT config
    kot_starting_number INT,             -- KOT starting number
    start_date DATE,                     -- Start date for the KOT configuration
    selected_outlet VARCHAR(100),        -- Outlet associated with the KOT configuration
    property_id VARCHAR(50) NOT NULL,    -- Property ID for association (Foreign Key)
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Date when the KOT config was updated
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp for record creation
);


-- Table: outlet_configurations
CREATE TABLE outlet_configurations (
    id SERIAL PRIMARY KEY,
    property_id VARCHAR(100) NOT NULL,  -- Link to property
    outlet_name VARCHAR(255) NOT NULL,  -- Name of the outlet
    address TEXT NOT NULL,  -- Address of the outlet
    city VARCHAR(255) NOT NULL,  -- City of the outlet
    country VARCHAR(255) NOT NULL,  -- Country of the outlet
    state VARCHAR(255) NOT NULL,  -- State of the outlet
    contact_number VARCHAR(15) NOT NULL,  -- Contact number for the outlet
    manager_name VARCHAR(255) NOT NULL,  -- Name of the outlet manager
    opening_hours VARCHAR(255) NOT NULL,  -- Opening hours of the outlet
    currency VARCHAR(10) NOT NULL,  -- Currency used at the outlet
    is_saved BOOLEAN DEFAULT FALSE,  -- Flag to indicate whether configuration is saved
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for record updates
);


-- Table: printer_config
CREATE TABLE printer_config (
    id SERIAL PRIMARY KEY,  -- Unique printer configuration ID
    printer_number VARCHAR(255) NOT NULL,  -- Printer number (identifier)
    printer_name VARCHAR(255) NOT NULL,  -- Printer name
    printer_type VARCHAR(255) NOT NULL,  -- Type of the printer (e.g., thermal, dot matrix)
    ip_address VARCHAR(15) NOT NULL,  -- IP address of the printer
    port VARCHAR(5) NOT NULL,  -- Port number for the printer connection
    status VARCHAR(50) NOT NULL,  -- Printer status (e.g., active, inactive)
    property_id VARCHAR(100) NOT NULL,  -- Property ID where the printer is located
    outlet_name VARCHAR(255) NOT NULL,  -- Name of the outlet where the printer is used
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for record updates
);


-- Table: reservation
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,  -- Unique reservation ID
    guest_name VARCHAR(255) NOT NULL,  -- Guest name
    contact_info VARCHAR(255),  -- Contact information of the guest
    address TEXT,  -- Address of the guest
    email VARCHAR(255),  -- Email address of the guest
    reservation_date DATE NOT NULL,  -- Date of the reservation
    reservation_time TIME NOT NULL,  -- Time of the reservation
    table_no VARCHAR(50),  -- Table number for the reservation
    status VARCHAR(50) NOT NULL,  -- Reservation status (e.g., confirmed, canceled)
    remark TEXT,  -- Additional remarks for the reservation
    property_id VARCHAR(100) NOT NULL,  -- Property ID where the reservation was made
    outlet_name VARCHAR(255) NOT NULL,  -- Name of the outlet for the reservation
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for record updates
);

-- Table: servicecharge_config
CREATE TABLE servicecharge_config (
    id SERIAL PRIMARY KEY,  -- Unique ID for the service charge configuration
    property_id VARCHAR(100) NOT NULL,  -- Property ID the service charge is applied to
    service_charge DECIMAL(5, 2) NOT NULL,  -- Percentage of service charge to apply
    outlet_name VARCHAR(255) NOT NULL,  -- The Name of the outlet (referencing outlet_configurations.outlet_name)
    min_amount DECIMAL(10, 2) NOT NULL,  -- Minimum amount for the service charge to apply
    max_amount DECIMAL(10, 2) NOT NULL,  -- Maximum amount for the service charge to apply
    apply_on VARCHAR(50) DEFAULT 'all bills',  -- Condition to apply the charge (e.g., 'all bills', 'certain items')
    status VARCHAR(50) DEFAULT 'active',  -- Status of the service charge configuration
    start_date DATE NOT NULL,  -- Start date from which the service charge is valid
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for when the record is created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for when the record is updated
);


-- Table: packingcharge_config
CREATE TABLE packingcharge_config (
    id SERIAL PRIMARY KEY,  -- Unique ID for the service charge configuration
    property_id VARCHAR(100) NOT NULL,  -- Property ID the service charge is applied to
    packing_charge DECIMAL(5, 2) NOT NULL,  -- Percentage of service charge to apply
    outlet_name VARCHAR(255) NOT NULL,  -- The Name of the outlet (referencing outlet_configurations.outlet_name)
    min_amount DECIMAL(10, 2) NOT NULL,  -- Minimum amount for the service charge to apply
    max_amount DECIMAL(10, 2) NOT NULL,  -- Maximum amount for the service charge to apply
    apply_on VARCHAR(50) DEFAULT 'all bills',  -- Condition to apply the charge (e.g., 'all bills', 'certain items')
    status VARCHAR(50) DEFAULT 'active',  -- Status of the service charge configuration
    start_date DATE NOT NULL,  -- Start date from which the service charge is valid
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for when the record is created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for when the record is updated
);

-- Table: discount_config
CREATE TABLE discount_config (
    id SERIAL PRIMARY KEY,  
    property_id VARCHAR(100) NOT NULL,  
    discount_type VARCHAR(50) NOT NULL DEFAULT 'percentage',  -- 'percentage' or 'fixed'
    discount_value DECIMAL(5, 2) NOT NULL,  
    min_amount DECIMAL(10, 2) NOT NULL,  
    max_amount DECIMAL(10, 2) NOT NULL,  
    outlet_name VARCHAR(255) NOT NULL,  -- The Name of the outlet (referencing outlet_configurations.outlet_name)
    apply_on VARCHAR(50) DEFAULT 'all bills',  
    status VARCHAR(50) DEFAULT 'active',  
    start_date DATE NOT NULL,  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- Table: platform_fee
CREATE TABLE platformfees_config (
    id SERIAL PRIMARY KEY,  
    property_id VARCHAR(100) NOT NULL,  
    platform_fee DECIMAL(5, 2) NOT NULL,  
    fee_type VARCHAR(50) NOT NULL DEFAULT 'percentage',  -- 'percentage' or 'fixed'
    min_amount DECIMAL(10, 2) NOT NULL,  
    max_amount DECIMAL(10, 2) NOT NULL,  
    apply_on VARCHAR(50) DEFAULT 'all transactions',  
    outlet_name VARCHAR(255) NOT NULL,  -- The Name of the outlet (referencing outlet_configurations.outlet_name)
    status VARCHAR(50) DEFAULT 'active',  
    start_date DATE NOT NULL,  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- Table: delivery_fee
CREATE TABLE deliverycharge_config (
    id SERIAL PRIMARY KEY,  
    property_id VARCHAR(100) NOT NULL,  
    delivery_charge DECIMAL(5, 2) NOT NULL,  
    outlet_name VARCHAR(255) NOT NULL,  
    min_amount DECIMAL(10, 2) NOT NULL,  
    max_amount DECIMAL(10, 2) NOT NULL,  
    apply_on VARCHAR(50) DEFAULT 'all bills',  
    status VARCHAR(50) DEFAULT 'active',  
    start_date DATE NOT NULL,  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);





-- Table: table_configurations
CREATE TABLE table_configurations (
    id SERIAL PRIMARY KEY,               -- Unique ID for the table configuration
    table_no VARCHAR(255) NOT NULL,      -- Table number (unique for the outlet)
    seats INT DEFAULT 2,                 -- Number of seats at the table
    status VARCHAR(50) DEFAULT 'Vacant', -- Status of the table (Vacant, Occupied, Reserved, etc.)
    outlet_name VARCHAR(255) NOT NULL,   -- Name of the outlet to associate the table with a specific outlet
    property_id VARCHAR(100) NOT NULL,            -- Property ID to associate the table with a specific property
    category VARCHAR(100),               -- Category of the table (e.g., Regular, VIP, etc.)
    location VARCHAR(255),               -- Location description of the table (e.g., Patio, Main Hall, etc.)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for when the table configuration is created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP   -- Timestamp for when the table configuration was last updated
);


-- Table: tax_config
CREATE TABLE tax_config (
    id SERIAL PRIMARY KEY,  -- Unique ID for the tax configuration
    tax_name VARCHAR(255) NOT NULL,  -- Name of the tax (e.g., GST, VAT, etc.)
    tax_percentage DECIMAL(5, 2) NOT NULL CHECK (tax_percentage > 0 AND tax_percentage <= 100),  -- Tax percentage with constraints
    tax_type VARCHAR(50) NOT NULL,  -- Type of the tax (e.g., inclusive or exclusive)
    outlet_name VARCHAR(255) NOT NULL,  -- Name of the outlet where this tax configuration applies
    property_id VARCHAR(100) NOT NULL,  -- Property ID to associate the tax configuration with a specific property
    greater_than DECIMAL(10, 2) DEFAULT 0.00,  -- Minimum value for which tax applies
    less_than DECIMAL(10, 2) DEFAULT 0.00,  -- Maximum value for which tax applies
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for when the tax configuration is created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for when the tax configuration was last updated
    CHECK (tax_percentage > 0 AND tax_percentage <= 100)  -- Ensure tax percentage is between 0 and 100
);


-- Table: user_permissions
CREATE TABLE user_permissions (
    id SERIAL PRIMARY KEY,  -- Unique ID for the user permission entry
    user_id INT NOT NULL,  -- User ID (referring to the user_id in the user_login table)
    username varchar(50) NOT NULL, -- User name (referring to the username in the user_login table)
    outlet_id INT NOT NULL,  -- The ID of the outlet (referencing outlet_configurations.outlet_id)
    outlet_name VARCHAR(255) NOT NULL,  -- The Name of the outlet (referencing outlet_configurations.outlet_name)
    permission_name VARCHAR(255) NOT NULL,  -- The name of the permission (e.g., 'View Sales', 'Generate KOT')
    property_id VARCHAR(100) NOT NULL,  -- The property ID to associate the permission with a specific property
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp when the permission is assigned
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp when the permission is updated
    CONSTRAINT user_permission_unique UNIQUE (user_id, outlet_id, permission_name, property_id)  -- Ensure unique permissions per user
);


-- Table: orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL,
    table_number INT NOT NULL,
    waiter_name VARCHAR(255),
    person_count INT,
    remarks TEXT,
    property_id INT,
    guest_id INT,
    customer_name VARCHAR(255),
    customer_contact VARCHAR(20),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    payment_date TIMESTAMP,
    transaction_id VARCHAR(255),
    tax_percentage DECIMAL(5, 2),
    tax_value DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    discount_percentage DECIMAL(5, 2),
    total_discount_value DECIMAL(10, 2),
    service_charge_per DECIMAL(5, 2),
    total_service_charge DECIMAL(10, 2),
    total_happy_hour_discount DECIMAL(10, 2),
    subtotal DECIMAL(10, 2),
    total DECIMAL(10, 2),
    cashier VARCHAR(255),
    status VARCHAR(50),
    order_type VARCHAR(50),
    order_notes TEXT,
    is_priority_order BOOLEAN,
    customer_feedback TEXT,
    staff_id INT,
    order_cancelled_by INT,
    cancellation_reason TEXT,
    created_by INT,
    updated_by INT,
    delivery_address TEXT,
    delivery_time TIMESTAMP,
    order_received_time TIMESTAMP,
    order_ready_time TIMESTAMP,
    served_by VARCHAR(255),
    payment_method_details TEXT,
    dining_case BOOLEAN,
    packing_case BOOLEAN,
    complimentary_case BOOLEAN,
    cancelled_case BOOLEAN,
    modified_case BOOLEAN,
    bill_generated BOOLEAN,
    bill_generated_at TIMESTAMP,
    bill_payment_status VARCHAR(50),
    partial_payment DECIMAL(10, 2),
    final_payment DECIMAL(10, 2),
    order_type_change BOOLEAN,
    modified_by INT,
    modify_reason TEXT,
    refund_status VARCHAR(50),
    refund_amount DECIMAL(10, 2),
    refund_date TIMESTAMP,
    refund_processed_by INT,
    refund_reason TEXT,
    outlet_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for record updates
  );



-- Table: order_items
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    item_category VARCHAR(255),
    item_quantity INT,
    item_rate DECIMAL(10, 2),
    item_amount DECIMAL(10, 2),
    item_tax DECIMAL(10, 2),
    total_item_value DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp for record creation
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Timestamp for record updates
    property_id VARCHAR(255) NOT NULL,
    outlet_name VARCHAR(255) NOT NULL
  );
  
-- Table: staff
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    staff_name VARCHAR(255),
    role VARCHAR(255)
  );

-- Table: order_cancellations
CREATE TABLE order_cancellations (
    cancellation_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    cancelled_by INT REFERENCES staff(staff_id),
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP
  );

-- Table: order_modifications
CREATE TABLE order_modifications (
    modification_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    modified_by INT REFERENCES staff(staff_id),
    modification_reason TEXT,
    modified_at TIMESTAMP
  );

  -- Table: bills
CREATE TABLE bills (
    id SERIAL PRIMARY KEY,
    bill_number VARCHAR(50) UNIQUE NOT NULL, -- Unique bill number
    total_amount NUMERIC(10, 2), -- Base total billing amount
    discount_value NUMERIC(10, 2), -- Total discount value
    tax_value NUMERIC(10, 2), -- Tax value
    service_charge_value NUMERIC(10, 2), -- Service charge value
    packing_charge NUMERIC(10, 2), -- Packing charge
    delivery_charge NUMERIC(10, 2), -- Delivery charge
    other_charge NUMERIC(10, 2), -- Other charges
    grand_total NUMERIC(10, 2), -- Grand total (calculated as Total - Discounts + All Charges)
    bill_generated_at TIMESTAMP, -- Bill generation timestamp
    guestName varchar (100),
    pax int,
    guestId varchar (50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Record creation timestamp
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Last update timestamp
);

  -- Table: payments
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,                  -- Unique identifier for each payment record
    bill_id INT NOT NULL,                   -- Reference to the related bill
    payment_method VARCHAR(50) NOT NULL,    -- Payment method (e.g., Cash, UPI, Card, etc.)
    payment_amount NUMERIC(10, 2) NOT NULL, -- Amount paid using this method
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp of payment
    transaction_id VARCHAR(100),           -- Transaction ID (for online payments)
    remarks TEXT,                          -- Any additional remarks about the payment
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when record is created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamp when record is updated
	outlet_name VARCHAR(255),
	property_id VARCHAR(50) NOT NULL,        -- Associated property ID (mandatory, matches properties table type)
	CONSTRAINT fk_bill FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE
);

-- Alter order_items table
ALTER TABLE order_items
ADD COLUMN taxRate INT,
ADD COLUMN bill_number VARCHAR(50),
ADD COLUMN discount_percentage DECIMAL(10, 2),
ADD COLUMN total_discount_value DECIMAL(10, 2),
ADD COLUMN packing_charge_percentage DECIMAL(10, 2),
ADD COLUMN packing_charge DECIMAL(10, 2),
ADD COLUMN delivery_charge_percentage DECIMAL(10, 2),
ADD COLUMN delivery_charge DECIMAL(10, 2),
add Column discountable boolean;

-- Alter orders table
ALTER TABLE orders
ALTER COLUMN property_id SET DATA TYPE VARCHAR(50),
ALTER COLUMN table_number SET DATA TYPE VARCHAR(50),
ADD COLUMN bill_number VARCHAR(50),
ADD COLUMN packing_charge_percentage DECIMAL(10, 2),
ADD COLUMN packing_charge DECIMAL(10, 2),
ADD COLUMN delivery_charge_percentage DECIMAL(10, 2),
ADD COLUMN delivery_charge DECIMAL(10, 2),
Add column bill_id int;

-- Alter tax_config table
ALTER TABLE tax_config
ALTER COLUMN property_id SET DATA TYPE VARCHAR(50);

-- Alter printer_config table
ALTER TABLE printer_config
ALTER COLUMN property_id SET DATA TYPE VARCHAR(50);

-- Alter user_permissions table
ALTER TABLE user_permissions
ALTER COLUMN property_id SET DATA TYPE VARCHAR(50);

-- Alter reservation table
ALTER TABLE reservation
ALTER COLUMN table_no SET DATA TYPE VARCHAR(50),
ALTER COLUMN property_id SET DATA TYPE VARCHAR(50);

-- Alter items table
ALTER TABLE items
ALTER COLUMN subcategory_id SET DATA TYPE VARCHAR(50),
ADD COLUMN tag VARCHAR(50);

-- Alter bills table
ALTER TABLE bills
ADD COLUMN property_id VARCHAR(50),
ADD COLUMN outlet_name VARCHAR(50),
ADD COLUMN status VARCHAR(50),
ADD COLUMN table_no VARCHAR(50),
ADD COLUMN packing_charge_percentage NUMERIC(5, 2),
ADD COLUMN delivery_charge_percentage NUMERIC(5, 2),
ADD COLUMN discount_percentage NUMERIC(5, 2),
ADD COLUMN service_charge_percentage NUMERIC(5, 2);

-- Alter outlet_configurations table
ALTER TABLE outlet_configurations
ALTER COLUMN property_id SET DATA TYPE VARCHAR(50),
ALTER COLUMN property_id SET NOT NULL,
add FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE; 

-- Alter properties  table
ALTER TABLE properties 
ADD COLUMN status VARCHAR(50);


-- Trigger for table_configurations
CREATE OR REPLACE FUNCTION notify_table_update() 
RETURNS trigger AS $$
BEGIN
   -- Trigger action: Notify about the table update
   PERFORM pg_notify('table_update', 'Table configurations updated');
   RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for table_configurations
DO $$ 
BEGIN
   -- Create the trigger for the 'table_configurations' table
   EXECUTE format('
     CREATE TRIGGER table_configurations_update_trigger
     AFTER INSERT OR UPDATE OR DELETE ON public.table_configurations
    FOR EACH ROW
     EXECUTE FUNCTION notify_table_update();');
END $$;


