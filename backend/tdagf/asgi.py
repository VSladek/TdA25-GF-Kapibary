"""
ASGI config for tdagf project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.1/howto/deployment/asgi/
"""

import os
from django.urls import path
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from api.consumers import ChatConsumer

websocket_urlpatterns = [
    path("ws/chat", ChatConsumer.as_asgi()),
]

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tdasebsite.settings")

application = ProtocolTypeRouter(
    {
        "http": get_asgi_application(),
        "websocket": URLRouter(websocket_urlpatterns),
    }
)
