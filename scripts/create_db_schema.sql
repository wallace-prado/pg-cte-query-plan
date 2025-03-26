-- 1. Tenants
CREATE TABLE tenants(
    tenant_id uuid PRIMARY KEY,
    tenant_name text NOT NULL,
    created_at timestamp DEFAULT NOW()
);

-- 2. Customers
CREATE TABLE customers(
    customer_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES tenants(tenant_id),
    customer_name text NOT NULL,
    email text,
    created_at timestamptz DEFAULT NOW()
);

-- 3. Orders
CREATE TABLE orders(
    order_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES tenants(tenant_id),
    customer_id uuid NOT NULL REFERENCES customers(customer_id),
    order_number text NOT NULL,
    order_date date NOT NULL,
    order_status text NOT NULL, -- e.g., 'pending', 'shipped', 'cancelled'
    created_at timestamptz DEFAULT NOW()
);

-- 4. Order Items
CREATE TABLE order_items(
    order_item_id uuid PRIMARY KEY,
    order_id uuid NOT NULL REFERENCES orders(order_id),
    tenant_id uuid NOT NULL REFERENCES tenants(tenant_id),
    product_sku text NOT NULL,
    quantity integer NOT NULL,
    price numeric(10, 2) NOT NULL,
    created_at timestamptz DEFAULT NOW()
);

-- 5. Shipments
CREATE TABLE shipments(
    shipment_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES tenants(tenant_id),
    shipment_number text NOT NULL,
    shipped_at timestamp,
    created_at timestamptz DEFAULT NOW()
);

-- 6. Shipment Items (Join Table)
CREATE TABLE shipment_items(
    shipment_id uuid NOT NULL REFERENCES shipments(shipment_id),
    order_item_id uuid NOT NULL REFERENCES order_items(order_item_id),
    tenant_id uuid NOT NULL REFERENCES tenants(tenant_id),
    PRIMARY KEY (shipment_id, order_item_id)
);

CREATE INDEX customers_tenant_id_idx ON customers USING btree(tenant_id);

CREATE INDEX orders_tenant_id_customer_id_idx ON orders USING btree(tenant_id, customer_id);

CREATE INDEX order_items_tenant_id_orders_id_idx ON order_items USING btree(tenant_id, order_id);

CREATE INDEX orders_tenant_id_customer_id_order_id_idx ON orders USING btree(tenant_id, customer_id, order_id);

