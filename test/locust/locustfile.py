# Simple load test: browse products, add to cart, checkout
from locust import HttpUser, task, between
import random, uuid

class Shopper(HttpUser):
    wait_time = between(1, 3)

    @task(2)
    def list_products(self):
        self.client.get("/api/products")

    @task(1)
    def add_to_cart_and_checkout(self):
        user = str(uuid.uuid4())
        products = self.client.get("/api/products").json()
        if not products: return
        # Add 2 random items
        for _ in range(2):
            p = random.choice(products)
            self.client.post(f"/api/cart/{user}/items",
                json={"productId": p["id"], "qty": random.randint(1, 3)})
        # Checkout
        self.client.post(f"/api/checkout/{user}", json={})