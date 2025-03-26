CREATE OR REPLACE PROCEDURE cleanup_test_data()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Disable triggers temporarily to handle FK constraints if needed
    -- For TRUNCATE CASCADE to work, you can also use CASCADE in each statement
    TRUNCATE TABLE
        shipment_items,
        shipments,
        order_items,
        orders,
        customers,
        tenants
    RESTART IDENTITY
CASCADE;
    RAISE NOTICE 'Test data cleaned up successfully.';
END;
$$;

CREATE OR REPLACE PROCEDURE generate_test_data(p_num_tenants integer, p_customers_per_tenant integer, p_orders_per_tenant integer, p_min_items_per_order integer, p_max_items_per_order integer, p_min_items_per_shipment integer, p_max_items_per_shipment integer)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_id uuid;
    v_customer_id uuid;
    v_order_id uuid;
    v_order_item_id uuid;
    v_shipment_id uuid;
    v_customer_ids uuid[];
    v_order_item_ids uuid[];
    v_order_number text;
    v_shipment_number text;
    i int;
    j int;
    k int;
    l int;
    n_items integer;
    n_ship_items integer;
BEGIN
    FOR i IN 1..p_num_tenants LOOP
        -- Insert tenant
        v_tenant_id := gen_random_uuid();
        INSERT INTO tenants(tenant_id, tenant_name)
            VALUES (v_tenant_id, 'Tenant ' || i);
        -- Insert customers
        v_customer_ids := ARRAY[]::uuid[];
        FOR j IN 1..p_customers_per_tenant LOOP
            v_customer_id := gen_random_uuid();
            v_customer_ids := array_append(v_customer_ids, v_customer_id);
            INSERT INTO customers(customer_id, tenant_id, customer_name, email)
                VALUES (v_customer_id, v_tenant_id, 'Customer ' || j || ' (T' || i || ')', 'customer' || j || '@tenant' || i || '.com');
        END LOOP;
        -- Insert orders
        FOR j IN 1..p_orders_per_tenant LOOP
            v_order_id := gen_random_uuid();
            v_order_number := 'ORD-' || i || '-' || j;
            v_customer_id := v_customer_ids[1 + floor(random() * array_length(v_customer_ids, 1))::int];
            INSERT INTO orders(order_id, tenant_id, customer_id, order_number, order_date, order_status)
                VALUES (v_order_id, v_tenant_id, v_customer_id, v_order_number, NOW(), 'pending');
            -- Insert order items
            v_order_item_ids := ARRAY[]::uuid[];
            n_items := p_min_items_per_order + floor(random() *(p_max_items_per_order - p_min_items_per_order + 1))::int;
            FOR k IN 1..n_items LOOP
                v_order_item_id := gen_random_uuid();
                v_order_item_ids := array_append(v_order_item_ids, v_order_item_id);
                INSERT INTO order_items(order_item_id, order_id, tenant_id, product_sku, quantity, price)
                    VALUES (v_order_item_id, v_order_id, v_tenant_id, 'SKU-' ||(100 + floor(random() * 900))::int, 1 + floor(random() * 5)::int, round((10 + random() * 90)::numeric, 2));
            END LOOP;
            -- Create a shipment for this order
            v_shipment_id := gen_random_uuid();
            v_shipment_number := 'SHP-' || i || '-' || j;
            INSERT INTO shipments(shipment_id, tenant_id, shipment_number, shipped_at)
                VALUES (v_shipment_id, v_tenant_id, v_shipment_number, NOW());
            -- Randomly assign items to shipment
            n_ship_items := LEAST(p_min_items_per_shipment + floor(random() *(p_max_items_per_shipment - p_min_items_per_shipment + 1))::int, array_length(v_order_item_ids, 1));
            FOR l IN 1..n_ship_items LOOP
                INSERT INTO shipment_items(shipment_id, order_item_id, tenant_id)
                    VALUES (v_shipment_id, v_order_item_ids[l], v_tenant_id);
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;

CALL cleanup_test_data();

CALL generate_test_data(p_num_tenants := 5, p_customers_per_tenant := 1000, p_orders_per_tenant := 10000, p_min_items_per_order := 1, p_max_items_per_order := 20, p_min_items_per_shipment := 1, p_max_items_per_shipment := 10);

