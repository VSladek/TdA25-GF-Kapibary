from django.urls import path
from . import views

urlpatterns = [
    path('rooms', views.AllRoomView.as_view()),
    path('room', views.OneRoomView.as_view()),
    path('login', views.LoginView.as_view()),
    path('logout', views.LogoutView.as_view()),
    path('users', views.UserView.as_view()),
]
