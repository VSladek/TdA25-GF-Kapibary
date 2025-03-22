from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Room, Message


class RoomSerializerCreate(serializers.ModelSerializer):
    class Meta:
        model = Room
        fields = ['name', 'code']


class RoomSerializerView(serializers.ModelSerializer):
    class Meta:
        model = Room
        fields = ['code', 'name', 'uuid']


class UserSerializerView(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username']

class UserSerializerCreate(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'password', 'is_superuser']


class MessageSerializerCreate(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['room', 'username', 'content']


class MessageSerializerView(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['username', 'content', 'id']
