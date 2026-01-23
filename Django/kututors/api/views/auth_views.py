from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate, get_user_model
from django.core.mail import send_mail
from django.contrib.auth.hashers import make_password
import random
import secrets

from ..models import TutorProfile, TuteeProfile, TemporarySignup
from ..serializers import SignupSerializer, LoginSerializer, UserSerializer, VerifyEmailSerializer

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    """
    Store signup data temporarily and send verification code
    User account is NOT created until email is verified
    """
    print("SIGNUP ENDPOINT CALLED!")
    serializer = SignupSerializer(data=request.data)
    if serializer.is_valid():
        temp_signup = serializer.save()
        
        # Print verification code to console
        print("=" * 50)
        print(f"SIGNUP VERIFICATION CODE FOR: {temp_signup.email}")
        print(f"CODE: {temp_signup.verification_code}")
        print(f"EXPIRES IN: 15 minutes")
        print("=" * 50)
        
        return Response({
            'email': temp_signup.email,
            'message': 'Verification code sent to your email. Please verify within 15 minutes.'
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_email(request):
    """
    Verify code and create actual user account
    """
    serializer = VerifyEmailSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        code = serializer.validated_data['verification_code']
        
        try:
            temp_signup = TemporarySignup.objects.get(email=email, verification_code=code)
            
            # Check if code expired
            if temp_signup.is_expired():
                temp_signup.delete()
                return Response({
                    'error': 'Verification code expired. Please sign up again.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create actual user account
            user = User.objects.create(
                username=temp_signup.username,
                email=temp_signup.email,
                first_name=temp_signup.first_name,
                last_name=temp_signup.last_name,
                role=temp_signup.role,
                contact=temp_signup.contact,
                is_verified=True,
            )
            # Set the hashed password directly (already hashed with salt in serializer)
            user.password = temp_signup.password
            user.save()
            
            # Create profile based on role
            if user.role == 'Tutor':
                TutorProfile.objects.create(user=user)
            elif user.role == 'Tutee':
                TuteeProfile.objects.create(user=user)
            
            # Delete temporary signup
            temp_signup.delete()
            
            # Generate token
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                'token': token.key,
                'user': UserSerializer(user).data,
                'message': 'Email verified successfully. Account created!'
            }, status=status.HTTP_200_OK)
            
        except TemporarySignup.DoesNotExist:
            return Response({
                'error': 'Invalid verification code or email'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """
    Login user with email and password
    """
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        
        # Find user by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Authenticate with username (since Django uses username by default)
        user = authenticate(username=user.username, password=password)
        
        if user:
            token, created = Token.objects.get_or_create(user=user)
            return Response({
                'token': token.key,
                'user': UserSerializer(user).data,
                'message': 'Login successful'
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def logout(request):
    """
    Logout user by deleting their token
    """
    try:
        request.user.auth_token.delete()
        return Response({
            'message': 'Logout successful'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password(request):
    """
    Send password reset code to email
    """
    print("FORGOT PASSWORD ENDPOINT CALLED!")
    email = request.data.get('email')
    if not email:
        return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Generate 6-digit verification code
    code = str(random.randint(100000, 999999))
    user.verification_code = code
    user.save()
    
    # ALWAYS print to console for development
    print("=" * 50)
    print(f"PASSWORD RESET CODE FOR: {email}")
    print(f"CODE: {code}")
    print("=" * 50)
    
    # Try to send email
    try:
        send_mail(
            subject="Password Reset Code - KU Tutors",
            message=f"Hello {user.first_name},\n\nYour password reset code is: {code}\n\nThank you!",
            from_email=None,
            recipient_list=[user.email],
            fail_silently=False,
        )
        print("Email sent successfully!")
    except Exception as e:
        print(f"Email sending failed: {str(e)}")
    
    return Response({'message': 'Verification code sent to your email'}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    """
    Reset password with verification code
    """
    email = request.data.get('email')
    code = request.data.get('verification_code')
    new_password = request.data.get('new_password')
    
    if not all([email, code, new_password]):
        return Response({'error': 'All fields are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email, verification_code=code)
        
        # Generate cryptographically secure random salt (22 characters)
        salt = secrets.token_urlsafe(16)[:22]
        
        # Hash the new password with salt using make_password
        hashed_password = make_password(new_password, salt=salt)
        
        # Set the hashed password
        user.password = hashed_password
        user.verification_code = None  # Clear the code
        user.save()
        
        return Response({'message': 'Password reset successfully'}, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'error': 'Invalid verification code or email'}, status=status.HTTP_400_BAD_REQUEST)