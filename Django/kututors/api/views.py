from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Tutor, Tutee, Session
from .serializers import (
    TutorSerializer, TuteeSerializer, SessionSerializer,
    TutorSignupSerializer, TuteeSignupSerializer
)

# Tutor views
class TutorListCreate(generics.ListCreateAPIView):
    queryset = Tutor.objects.all()
    serializer_class = TutorSerializer

class TutorRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Tutor.objects.all()
    serializer_class = TutorSerializer
    lookup_field = 'name'

# Tutee views
class TuteeListCreate(generics.ListCreateAPIView):
    queryset = Tutee.objects.all()
    serializer_class = TuteeSerializer


class TuteeRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Tutee.objects.all()
    serializer_class = TuteeSerializer
    lookup_field = 'name'

# Session views
class SessionListCreate(generics.ListCreateAPIView):
    queryset = Session.objects.all()
    serializer_class = SessionSerializer

class SessionRetrieveUpdateDelete(generics.RetrieveUpdateDestroyAPIView):
    queryset = Session.objects.all()
    serializer_class = SessionSerializer

class TutorSignup(APIView):
    def post(self, request):
        serializer = TutorSignupSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Tutor account created successfully!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TuteeSignup(APIView):
    def post(self, request):
        serializer = TuteeSignupSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Tutee account created successfully!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)