-- DROP TABLE command
DROP TABLE IF EXISTS public.warranty;
DROP TABLE IF EXISTS public.sales;
DROP TABLE IF EXISTS public.products;
DROP TABLE IF EXISTS public.category;  --parent
DROP TABLE IF EXISTS public.stores;    --parent

-- CREATE TABLE commands

CREATE TABLE public.stores(
store_id VARCHAR(10) PRIMARY KEY,
store_name	VARCHAR(30),
city	VARCHAR(25),
country VARCHAR(25)
);

DROP TABLE IF EXISTS public.category;
CREATE TABLE public.category
(category_id VARCHAR(10) PRIMARY KEY,
category_name VARCHAR(20)
);

CREATE TABLE public.products
(
product_id	VARCHAR(10) PRIMARY KEY,
product_name	VARCHAR(35),
category_id	VARCHAR(10),
launch_date	date,
price FLOAT,
CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES public.category(category_id)
);

CREATE TABLE public.sales
(
sale_id	VARCHAR(15) PRIMARY KEY,
sale_date	DATE,
store_id	VARCHAR(10), -- this fk
product_id	VARCHAR(10), -- this fk
quantity INT,
CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES public.stores(store_id),
CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES public.products(product_id)
);

CREATE TABLE public.warranty
(
claim_id VARCHAR(10) PRIMARY KEY,	
claim_date	date,
sale_id	VARCHAR(15),
repair_status VARCHAR(15),
CONSTRAINT fk_orders FOREIGN KEY (sale_id) REFERENCES public.sales(sale_id)
);

-- Set ownership of the tables to the postgres user
ALTER TABLE public.stores OWNER to postgres;
ALTER TABLE public.category OWNER to postgres;
ALTER TABLE public.products OWNER to postgres;
ALTER TABLE public.sales OWNER to postgres;
ALTER TABLE public.warranty OWNER to postgres;

--Create indexes on foreign key columns for better performance
CREATE INDEX idx_category_id ON public.category (category_id);
CREATE INDEX idx_store_id ON public.stores (store_id);
CREATE INDEX idx_product_id ON public.products (product_id);
CREATE INDEX idx_sale_id ON public.sales (sale_id);

-- Success Message
SELECT 'Schema created successful' as Success_Message;