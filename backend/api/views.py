import uuid
import random
from rest_framework.authtoken.models import Token
from rest_framework.decorators import permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from .models import Room
from .serializers import RoomSerializerCreate, RoomSerializerView, UserSerializerView, UserSerializerCreate


class UserView(APIView):
    def post(self, request):
        data = request.data
        serialazer = UserSerializerCreate(data=data)
        if not serialazer.is_valid():
            return Response({"message": "username and password are required"}, status=400)
        user = User.objects.create_user(**serialazer.data)
        token, created = Token.objects.get_or_create(user=user)
        return Response({"token": token.key}, status=201)

class AllRoomView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        rooms = Room.objects.all()
        serializer = RoomSerializerView(rooms, many=True)
        return Response(serializer.data, status=200)

    def post(self, request):
        data = request.data
        data['code'] = random.randint(100000, 999999)
        serializer = RoomSerializerCreate(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response({"message": "Name is required"}, status=400)

class OneRoomView(APIView):
    @permission_classes([AllowAny])
    def post(self, request):
        data = request.data
        if(data.get("code") == None):
            return Response({"message": "Code is required"}, status=400)
        try:
            room = Room.objects.get(code=data.get("code"))
        except Room.DoesNotExist:
            return Response({"message": "Room not found"}, status=404)
        serializer = RoomSerializerView(room)
        return Response(serializer.data, status=200)
    

class LoginView(APIView):
    @permission_classes([AllowAny])
    def post(self, request):
        data = request.data
        if(data.get("username") == None or data.get("password") == None):
            return Response({"error": "username and password are required"}, status=400)
        user = User.objects.filter(username=data['username']).first()
        if user is None:
            return Response(status=401)
        if not user.check_password(data['password']):
            return Response(status=401)
        token, created = Token.objects.get_or_create(user=user)
        serializer = UserSerializerView(user)
        return Response({'token': token.key, "user": serializer.data}, status=200)


class LogoutView(APIView):
    @permission_classes([IsAuthenticated])
    def post(self, request):
        request.user.auth_token.delete()
        return Response(status=200)