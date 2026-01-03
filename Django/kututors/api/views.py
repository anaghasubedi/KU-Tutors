from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate, get_user_model
from django.core.mail import send_mail
from .serializers import SignupSerializer, LoginSerializer, UserSerializer, VerifyEmailSerializer
import random

User = get_user_model()

@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    """
    Register a new user (Tutor or Tutee)
    Expected fields from Flutter: name, email, phone_number, role, password, confirm_password
    """
    serializer = SignupSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        
        # Print verification code to console
        print("=" * 50)
        print(f"SIGNUP VERIFICATION CODE FOR: {user.email}")
        print(f"CODE: {user.verification_code}")
        print("=" * 50)
        
        return Response({
            'user': UserSerializer(user).data,
            'message': 'User created successfully. Please check your email for verification code.'
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_email(request):
    """
    Verify user's email with the verification code
    """
    serializer = VerifyEmailSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        code = serializer.validated_data['verification_code']
        
        try:
            user = User.objects.get(email=email, verification_code=code)
            user.is_verified = True
            user.verification_code = None  # Clear the code after verification
            user.save()
            
            # Generate token after verification
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                'token': token.key,
                'user': UserSerializer(user).data,
                'message': 'Email verified successfully'
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
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
        
        # Check if email is verified
        if not user.is_verified:
            return Response({
                'error': 'Please verify your email first',
                'email': email
            }, status=status.HTTP_403_FORBIDDEN)
        
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
@permission_classes([IsAuthenticated])
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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """
    Get current user's profile
    """
    user = request.user
    return Response({
        'user': UserSerializer(user).data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password(request):
    """
    Send password reset code to email
    """
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
        user.set_password(new_password)
        user.verification_code = None  # Clear the code
        user.save()
        return Response({'message': 'Password reset successfully'}, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'error': 'Invalid verification code or email'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Get or update user profile
    """
    user = request.user
    
    if request.method == 'GET':
        profile_data = {
            'name': f"{user.first_name} {user.last_name}".strip(),
            'email': user.email,
            'phone_number': user.contact,
        }
        
        # Add role-specific data
        if user.role == 'Tutor':
            try:
                tutor_profile = user.tutor_profile
                profile_data.update({
                    'subject': tutor_profile.subject,
                    'semester': tutor_profile.semester,
                    'subject_code': tutor_profile.subjectcode,
                    'rate': str(tutor_profile.accountnumber) if tutor_profile.accountnumber else None,
                })
            except:
                pass
        elif user.role == 'Tutee':
            try:
                tutee_profile = user.tutee_profile
                profile_data.update({
                    'semester': tutee_profile.semester,
                    'subject_required': tutee_profile.subjectreqd,
                })
            except:
                pass
        
        return Response(profile_data, status=status.HTTP_200_OK)
    
    elif request.method == 'PUT':
        # Update user basic info
        name = request.data.get('name')
        if name:
            name_parts = name.split(' ', 1)
            user.first_name = name_parts[0]
            user.last_name = name_parts[1] if len(name_parts) > 1 else ''
        
        if 'phone_number' in request.data:
            user.contact = request.data.get('phone_number')
        
        user.save()
        
        # Update profile based on role
        if user.role == 'Tutor':
            try:
                profile = user.tutor_profile
                if 'subject' in request.data:
                    profile.subject = request.data.get('subject')
                if 'semester' in request.data:
                    profile.semester = request.data.get('semester')
                if 'subject_code' in request.data:
                    profile.subjectcode = request.data.get('subject_code')
                if 'rate' in request.data:
                    profile.accountnumber = request.data.get('rate')
                profile.save()
            except:
                pass
                
        elif user.role == 'Tutee':
            try:
                profile = user.tutee_profile
                if 'semester' in request.data:
                    profile.semester = request.data.get('semester')
                if 'subject_required' in request.data:
                    profile.subjectreqd = request.data.get('subject_required')
                profile.save()
            except:
                pass
        
        return Response({
            'message': 'Profile updated successfully',
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_profile_image(request):
    """
    Upload profile image
    """
    if 'image' not in request.FILES:
        return Response({
            'error': 'No image provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    user = request.user
    image = request.FILES['image']
    
    # Save image based on role
    try:
        if user.role == 'Tutor':
            profile = user.tutor_profile
            profile.bankqr = image
            profile.save()
            image_url = profile.bankqr.url if profile.bankqr else None
        elif user.role == 'Tutee':
            # For tutee, we'll need to add a profile_picture field to the model
            # For now, just return success
            return Response({
                'message': 'Image upload not yet implemented for tutees'
            }, status=status.HTTP_200_OK)
        
        return Response({
            'message': 'Image uploaded successfully',
            'image_url': image_url
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_account(request):
    """
    Delete user account
    """
    user = request.user
    email = user.email
    
    # Delete user (this will cascade delete the profile)
    user.delete()
    
    return Response({
        'message': f'Account for {email} deleted successfully'
    }, status=status.HTTP_200_OK)