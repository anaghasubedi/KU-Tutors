from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Tutor, Tutee, Session
from django.core.mail import send_mail
from django.contrib.auth.hashers import check_password
from django.contrib.auth.tokens import default_token_generator
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
    
# --- Signup with email verification ---
class TutorSignup(APIView):
    def post(self, request):
        serializer = TutorSignupSerializer(data=request.data)
        if serializer.is_valid():
            tutor = serializer.save()
            return Response({
                "message": "Tutor account created successfully!",
                "email": tutor.email,
                "verification_code": tutor.verification_code  # prints to console
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TuteeSignup(APIView):
    def post(self, request):
        serializer = TuteeSignupSerializer(data=request.data)
        if serializer.is_valid():
            tutee = serializer.save()
            return Response({
                "message": "Tutee account created successfully!",
                "email": tutee.email,
                "verification_code": tutee.verification_code  # prints to console
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# --- Email verification endpoints ---
class TutorVerifyEmail(APIView):
    def post(self, request):
        email = request.data.get("email")
        code = request.data.get("code")

        try:
            tutor = Tutor.objects.get(email=email)
        except Tutor.DoesNotExist:
            return Response({"error": "Tutor not found"}, status=status.HTTP_404_NOT_FOUND)

        if tutor.verification_code == code:
            tutor.is_verified = True
            tutor.verification_code = ""
            tutor.save()
            return Response({"message": "Email verified successfully"})
        return Response({"error": "Invalid verification code"}, status=status.HTTP_400_BAD_REQUEST)

class TuteeVerifyEmail(APIView):
    def post(self, request):
        email = request.data.get("email")
        code = request.data.get("code")

        try:
            tutee = Tutee.objects.get(email=email)
        except Tutee.DoesNotExist:
            return Response({"error": "Tutee not found"}, status=status.HTTP_404_NOT_FOUND)

        if tutee.verification_code == code:
            tutee.is_verified = True
            tutee.verification_code = ""
            tutee.save()
            return Response({"message": "Email verified successfully"})
        return Response({"error": "Invalid verification code"}, status=status.HTTP_400_BAD_REQUEST)
    
class Tutorlogin(APIView):
    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")

        try:
            tutor = Tutor.objects.get(email=email)
        except Tutor.DoesNotExist:
            return Response({"error": "Tutor not found"}, status=status.HTTP_404_NOT_FOUND)

        # Check the password directly here
        if check_password(password, tutor.password):
            if tutor.is_verified:
                return Response({
                    "message": "Login successful",
                    "email": tutor.email,
                    "name": tutor.name
                })
            else:
                return Response({"error": "Email not verified"}, status=status.HTTP_403_FORBIDDEN)
        else:
            return Response({"error": "Invalid password"}, status=status.HTTP_400_BAD_REQUEST)
       
       
       
class Tuteelogin(APIView):
    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")

        try:
            tutor = Tutee.objects.get(email=email)
        except Tutee.DoesNotExist:
            return Response({"error": "Tutor not found"}, status=status.HTTP_404_NOT_FOUND)

        # Check the password directly here
        if check_password(password, tutor.password):
            if tutor.is_verified:
                return Response({
                    "message": "Login successful",
                    "email": tutor.email,
                    "name": tutor.name
                })
            else:
                return Response({"error": "Email not verified"}, status=status.HTTP_403_FORBIDDEN)
        else:
            return Response({"error": "Invalid password"}, status=status.HTTP_400_BAD_REQUEST)
        
class ForgotPassword(APIView):
    def post(self, request):
        email = request.data.get("email")
        if not email:
            return Response({"error": "Email is required"}, status=400)

        # Try to find the user in Tutor or Tutee
        user = None
        user_type = None

        try:
            user = Tutor.objects.get(email=email)
            user_type = "tutor"
        except Tutor.DoesNotExist:
            try:
                user = Tutee.objects.get(email=email)
                user_type = "tutee"
            except Tutee.DoesNotExist:
                return Response({"error": "User not found"}, status=404)

        # Generate a token
        token = default_token_generator.make_token(user)
        reset_url = f"http://your-frontend-app/reset-password/{user_type}/{user.pk}/{token}/"

        # Send email
        send_mail(
            subject="Reset your password",
            message=f"Click the link to reset your password: {reset_url}",
            from_email="no-reply@yourapp.com",
            recipient_list=[user.email],
        )

        return Response({"message": "Password reset link sent"})