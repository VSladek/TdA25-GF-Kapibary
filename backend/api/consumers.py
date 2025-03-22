import random
import json
from copy import deepcopy
from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from rest_framework.authtoken.models import Token
from .models import Room, Message
from .serializers import RoomSerializerCreate, RoomSerializerView, UserSerializerView, MessageSerializerView, MessageSerializerCreate


class RoomConsumer(AsyncWebsocketConsumer):
    data = {}
    async def connect(self):
        uuid = self.scope["url_route"]["kwargs"]["uuid"]
        if(uuid is None):
            await self.send(text_data={"type": "error", "message": "Room not found"})
        if(uuid not in self.data):
            self.data[uuid] = {"presentation": [], "now_presenting": None, "end_presenting": None, "vote": {}, "start": False}	
        await self.channel_layer.group_add(f"room_{uuid}", self.channel_name)
        await self.accept()
        await self.send(text_data=json.dumps({"type": "connection", "presenting": self.data[uuid]["now_presenting"]}))

    async def disconnect(self, close_code):
        uuid = self.scope["url_route"]["kwargs"]["uuid"]
        await self.channel_layer.group_discard(f"room_{uuid}", self.channel_name)

    async def receive(self, text_data):
        uuid = self.scope["url_route"]["kwargs"]["uuid"]
        data_receive = json.loads(text_data)
        data_room = self.data[uuid]
        match data_receive.get("type"):
            case "start":
                if(data_room["start"] == True):
                    await self.send(text_data=json.dumps({"type": "error", "message": "Presentation already started"}))
                    return
                if(not await self.check_admin()):
                    await self.send(text_data=json.dumps({"type": "error", "message": "You are not admin"}))
                    return
                if(len(self.data[uuid]["presentation"]) > 0):
                    data_room["start"] = True
                    present = random.choice(self.data[uuid]["presentation"])
                    data_room["now_presenting"] = present
                    data_message = {"next": present}
                    data_room["presentation"].remove(present)
                    data_message["type"] = "next"
                    await self.channel_layer.group_send(
                        f"room_{uuid}",
                        {
                            "type": "room_message",
                            "message": json.dumps(data_message),
                        }
                    )
                else:
                    await self.send(text_data=json.dumps({"type": "error", "message": "No presentation"}))
            case "next":
                if(not await self.check_admin()):
                    await self.send(text_data=json.dumps({"type": "error", "message": "You are not admin"}))
                    return
                if(len(self.data[uuid]["presentation"]) > 0):
                    present = random.choice(self.data[uuid]["presentation"])
                    data_room["now_presenting"] = present
                    data_room["presentation"].remove(present)
                    data_message = {"next": present}
                    data_message["type"] = "next"
                    await self.channel_layer.group_send(
                        f"room_{uuid}",
                        {
                            "type": "room_message",
                            "message": json.dumps(data_message),
                        }
                    )
                else:
                    result = await self.get_result(data_room["vote"])
                    result ["type"] = "result"
                    await self.channel_layer.group_send(
                        f"room_{uuid}",
                        {
                            "type": "room_message",
                            "message": json.dumps(result)
                        }
                    )
            case "present":
                if(data_receive.get("username") in data_room["presentation"]):
                    await self.send(text_data=json.dumps({"type": "error", "message": "Uživatel je jiz prezentujíci"}))
                    return
                data_room["presentation"].append(data_receive.get("username"))
                data_room["vote"][data_receive.get("username")] = {"count1": 0, "count2": 0, "count3": 0, "users": 0}
            case "vote":
                if(data_receive.get("username") == data_room["now_presenting"]):
                    await self.send(text_data=json.dumps({"type": "error", "message": "Uživatel je prave prezentujíci"}))
                    return
                question1 = data_receive.get("1")
                question2 = data_receive.get("2")
                question3 = data_receive.get("3")
                data_room["vote"][data_room["now_presenting"]]["count1"] += question1
                data_room["vote"][data_room["now_presenting"]]["count2"] += question2
                data_room["vote"][data_room["now_presenting"]]["count3"] += question3
                data_room["vote"][data_room["now_presenting"]]["users"] += 1
            case "result_user":
                message = {}
                if(data_room["vote"].get(data_receive.get("username")) == None):
                    await self.send(text_data={"type": "error", "data": "Uživatel nebyl v této místností"})
                if data_room["vote"][data_receive.get("username")]["users"] == 0:
                    message = {1: 0, 2: 0, 3: 0}
                else:
                    question1 = data_room["vote"][data_receive.get("username")]["count1"]/data_room["vote"][data_receive.get("username")]["users"]
                    question2 = data_room["vote"][data_receive.get("username")]["count2"]/data_room["vote"][data_receive.get("username")]["users"]
                    question3 = data_room["vote"][data_receive.get("username")]["count3"]/data_room["vote"][data_receive.get("username")]["users"]
                    message = {1: question1, 2: question2, 3: question3}
                message["type"] = "result_user"
                await self.send(text_data=json.dumps(message))

    async def room_message(self, event):
        message = event["message"]
        await self.send(text_data=message)
    
    async def get_result(self, votes):
        max1 = 0
        max2 = 0
        max3 = 0
        max1_name = ""
        max2_name = ""
        max3_name = ""
        for vote in votes.keys():
            if(votes[vote]["users"] != 0):
                if(votes[vote]["count1"] > max1):
                    max1 = votes[vote]["count1"]/votes[vote]["users"]
                    max1_name = vote
                if(votes[vote]["count2"] > max2):
                    max2 = votes[vote]["count2"]/votes[vote]["users"]
                    max2_name = vote
                if(votes[vote]["count3"] > max3):
                    max3 = votes[vote]["count3"]/votes[vote]["users"]
                    max3_name = vote
        return {1: {"username": max1_name, "body": max1}, 2: {"username": max2_name, "body": max2}, 3: {"username": max3_name, "body": max3}}

    async def get_user_from_token(self):
        headers = dict(deepcopy(self.scope["headers"]))
        cookies = {cookie.split("=")[0]: cookie.split("=")[1]
                    for cookie in headers.get(b"cookie", b"").decode().split("; ") if "=" in cookie}
        auth_token = cookies.get("token", None)

        return auth_token
    
    @sync_to_async
    def get_token(self, token_key):
        try:
            token = Token.objects.get(key=token_key)
            return str(token.user.username)
        except Token.DoesNotExist:
            return None

    async def check_admin(self):
        token = await self.get_user_from_token()
        hello = await self.get_token(token)
        return True if hello == "spravce" else False

class ChatConsumer(AsyncWebsocketConsumer):
    data = {}
    async def connect(self):
        uuid = self.scope["url_route"]["kwargs"]["uuid"]
        await self.channel_layer.group_add(f"chat_{uuid}", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        uuid = self.scope["url_route"]["kwargs"]["uuid"]
        await self.channel_layer.group_discard(f"chat_{uuid}", self.channel_name)

    async def receive(self, text_data):
        uuid = self.scope["url_route"]["kwargs"]["uuid"]
        await self.channel_layer.group_send(
            f"chat_{uuid}",
            {
                "type": "chat_message",
                "message": text_data,
            }
        )

    async def chat_message(self, event):
        message = event["message"]
        await self.send(text_data=message)

