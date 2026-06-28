\set scale 1

INSERT INTO messages (body) VALUES ('hello from db');

INSERT INTO users (email, display_name)
SELECT 'user' || g || '@example.com', 'User ' || g
FROM generate_series(1, 1000 * :scale) AS g;

INSERT INTO categories (name, slug)
SELECT 'Category ' || g, 'category-' || g
FROM generate_series(1, 10) AS g;

INSERT INTO products (sku, name, price_cents, stock)
SELECT 'SKU-' || lpad(g::text, 8, '0'), 'Product ' || g,
       (g * 137 % 9900) + 100, g % 500
FROM generate_series(1, 500 * :scale) AS g;

INSERT INTO product_categories (product_id, category_id)
SELECT p.id, ((p.id + c) % 10) + 1
FROM products p, generate_series(0, 2) AS c
ON CONFLICT DO NOTHING;

INSERT INTO carts (user_id)
SELECT id FROM users WHERE id % 2 = 0;

INSERT INTO cart_items (cart_id, product_id, quantity)
SELECT c.id, ((c.id * 7 + n) % (SELECT count(*) FROM products)) + 1, (n % 3) + 1
FROM carts c, generate_series(0, 2) AS n
ON CONFLICT DO NOTHING;

INSERT INTO orders (user_id, status, total_cents)
SELECT id, CASE WHEN id % 3 = 0 THEN 'paid' ELSE 'pending' END, 0
FROM users WHERE id % 3 <> 1;

INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents)
SELECT o.id, ((o.id * 11 + n) % (SELECT count(*) FROM products)) + 1, (n % 4) + 1,
       (o.id * 53 % 9900) + 100
FROM orders o, generate_series(0, 3) AS n
ON CONFLICT DO NOTHING;

UPDATE orders o
SET total_cents = COALESCE((
  SELECT sum(oi.quantity * oi.unit_price_cents)
  FROM order_items oi WHERE oi.order_id = o.id), 0);

INSERT INTO payments (order_id, amount_cents, method, paid_at)
SELECT id, total_cents, 'card', now()
FROM orders WHERE status = 'paid';
