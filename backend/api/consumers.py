from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from rest_framework.authtoken.models import Token
#from .models import 
#from .serializers import 

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("chat", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("chat", self.channel_name)
    
    async def receive(self, text_data):
        await self.channel_layer.group_send(
            "chat",
            {
                "type": "chat_message",
                "message": text_data,
            }
        )

    async def chat_message(self, event):
        message = event["message"]
        await self.send(text_data=message)