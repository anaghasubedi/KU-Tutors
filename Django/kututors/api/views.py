from rest_framework import generics
from .models import Tutor, Tutee, Session
from .serializers import TutorSerializer, TuteeSerializer, SessionSerializer

# Tutor views
class TutorListCreate(generics.ListCreateAPIView):
    queryset = Tutor.objects.all()
    serializer_class = TutorSerializer

class TutorRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Tutor.objects.all()
    serializer_class = TutorSerializer

# Tutee views
class TuteeListCreate(generics.ListCreateAPIView):
    queryset = Tutee.objects.all()
    serializer_class = TuteeSerializer

class TuteeRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Tutee.objects.all()
    serializer_class = TuteeSerializer

# Session views
class SessionListCreate(generics.ListCreateAPIView):
    queryset = Session.objects.all()
    serializer_class = SessionSerializer

class SessionRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Session.objects.all()
    serializer_class = SessionSerializer
