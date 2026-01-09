from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate, get_user_model
from django.core.mail import send_mail
from django.contrib.auth.hashers import make_password
from .models import TutorProfile, TuteeProfile, TemporarySignup, AvailabilitySlot
from .serializers import (
    SignupSerializer, LoginSerializer, UserSerializer, 
    VerifyEmailSerializer, TutorProfileSerializer, AvailabilitySlotSerializer
)
import random
import secrets

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

@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Get or update user profile (partial updates supported)
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
    
    elif request.method == 'PATCH':
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
            profile.profile_picture = image  # Use profile_picture field
            profile.save()
            image_url = profile.profile_picture.url if profile.profile_picture else None
        elif user.role == 'Tutee':
            profile = user.tutee_profile
            profile.profile_picture = image  # Use profile_picture field
            profile.save()
            image_url = profile.profile_picture.url if profile.profile_picture else None
        
        return Response({
            'message': 'Image uploaded successfully',
            'image_url': image_url
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_tutors(request):
    """
    List all available tutors with their profiles
    """
    try:
        tutors = TutorProfile.objects.filter(available=True).select_related('user')
        serializer = TutorProfileSerializer(tutors, many=True)
        
        return Response({
            'tutors': serializer.data,
            'count': tutors.count()
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
    
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def manage_availability(request):
    """
    GET: List all availability slots for the tutor
    POST: Create a new availability slot
    """
    user = request.user
    
    # Check if user is a tutor
    if user.role != 'Tutor':
        return Response({
            'error': 'Only tutors can manage availability'
        }, status=status.HTTP_403_FORBIDDEN)
    
    try:
        tutor_profile = user.tutor_profile
    except:
        return Response({
            'error': 'Tutor profile not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    if request.method == 'GET':
        slots = AvailabilitySlot.objects.filter(tutor=tutor_profile)
        serializer = AvailabilitySlotSerializer(slots, many=True)
        return Response({
            'slots': serializer.data
        }, status=status.HTTP_200_OK)
    
    elif request.method == 'POST':
        # Create new availability slot
        day = request.data.get('day')
        time = request.data.get('time')
        
        if not day or not time:
            return Response({
                'error': 'Day and time are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if slot already exists
        if AvailabilitySlot.objects.filter(tutor=tutor_profile, day=day, time=time).exists():
            return Response({
                'error': 'This time slot already exists'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        slot = AvailabilitySlot.objects.create(
            tutor=tutor_profile,
            day=day,
            time=time,
            status='Available'
        )
        
        serializer = AvailabilitySlotSerializer(slot)
        return Response({
            'message': 'Availability slot created',
            'slot': serializer.data
        }, status=status.HTTP_201_CREATED)

@api_view(['PATCH', 'DELETE'])
@permission_classes([IsAuthenticated])
def update_availability(request, slot_id):
    """
    PATCH: Update an availability slot (e.g., change status or time)
    DELETE: Delete an availability slot
    """
    user = request.user
    
    if user.role != 'Tutor':
        return Response({
            'error': 'Only tutors can update availability'
        }, status=status.HTTP_403_FORBIDDEN)
    
    try:
        tutor_profile = user.tutor_profile
        slot = AvailabilitySlot.objects.get(id=slot_id, tutor=tutor_profile)
    except AvailabilitySlot.DoesNotExist:
        return Response({
            'error': 'Availability slot not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    if request.method == 'PATCH':
        # Update slot
        if 'day' in request.data:
            slot.day = request.data['day']
        if 'time' in request.data:
            slot.time = request.data['time']
        if 'status' in request.data:
            slot.status = request.data['status']
        
        slot.save()
        serializer = AvailabilitySlotSerializer(slot)
        
        return Response({
            'message': 'Availability slot updated',
            'slot': serializer.data
        }, status=status.HTTP_200_OK)
    
    elif request.method == 'DELETE':
        slot.delete()
        return Response({
            'message': 'Availability slot deleted'
        }, status=status.HTTP_200_OK)