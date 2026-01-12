from rest_framework import status
from django.utils import timezone
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
from datetime import datetime, date
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

# Add these views to your views.py file

from .models import Availability
from datetime import datetime, date

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tutor_availability(request):
    """
    Get availability slots for current tutor or specific tutor
    Query params: tutor_id (optional), date (optional), from_date (optional)
    """
    try:
        tutor_id = request.GET.get('tutor_id')
        filter_date = request.GET.get('date')  # Single date filter
        from_date = request.GET.get('from_date')  # Future dates filter
        
        if tutor_id:
            tutor = TutorProfile.objects.get(id=tutor_id)
        else:
            if request.user.role != 'Tutor':
                return Response({'error': 'Only tutors can view their availability'}, 
                              status=status.HTTP_403_FORBIDDEN)
            tutor = request.user.tutor_profile
        
        availabilities = Availability.objects.filter(tutor=tutor)
        
        # Filter by specific date
        if filter_date:
            filter_date_obj = datetime.strptime(filter_date, '%Y-%m-%d').date()
            availabilities = availabilities.filter(date=filter_date_obj)
        
        # Filter future dates only
        elif from_date:
            from_date_obj = datetime.strptime(from_date, '%Y-%m-%d').date()
            availabilities = availabilities.filter(date__gte=from_date_obj)
        else:
            # Default: show only future dates
            availabilities = availabilities.filter(date__gte=date.today())
        
        data = [{
            'id': a.id,
            'date': a.date.strftime('%Y-%m-%d'),
            'formatted_date': a.formatted_date(),
            'day_name': a.day_name(),
            'start_time': a.start_time.strftime('%H:%M'),
            'end_time': a.end_time.strftime('%H:%M'),
            'formatted_time': a.formatted_time(),
            'status': a.status,
        } for a in availabilities]
        
        return Response({'availabilities': data, 'count': len(data)}, status=status.HTTP_200_OK)
    except TutorProfile.DoesNotExist:
        return Response({'error': 'Tutor not found'}, status=status.HTTP_404_NOT_FOUND)
    except ValueError:
        return Response({'error': 'Invalid date format. Use YYYY-MM-DD'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_availability(request):
    """
    Add availability slot for tutor on a specific date
    Body: {"date": "2026-01-15", "start_time": "14:00", "end_time": "15:00"}
    """
    if request.user.role != 'Tutor':
        return Response({'error': 'Only tutors can add availability'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        tutor = request.user.tutor_profile
        date_str = request.data.get('date')
        start_time = request.data.get('start_time')
        end_time = request.data.get('end_time')
        
        if not all([date_str, start_time, end_time]):
            return Response({'error': 'Date, start_time, and end_time are required'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Parse date and time strings
        availability_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        start = datetime.strptime(start_time, '%H:%M').time()
        end = datetime.strptime(end_time, '%H:%M').time()
        
        # Check if date is in the past
        if availability_date < date.today():
            return Response({'error': 'Cannot add availability for past dates'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Check if slot already exists
        if Availability.objects.filter(tutor=tutor, date=availability_date, start_time=start).exists():
            return Response({'error': 'This time slot already exists for this date'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Create availability
        availability = Availability.objects.create(
            tutor=tutor,
            date=availability_date,
            start_time=start,
            end_time=end,
            status='Available'
        )
        
        return Response({
            'message': 'Availability added successfully',
            'availability': {
                'id': availability.id,
                'date': availability.date.strftime('%Y-%m-%d'),
                'formatted_date': availability.formatted_date(),
                'day_name': availability.day_name(),
                'start_time': availability.start_time.strftime('%H:%M'),
                'end_time': availability.end_time.strftime('%H:%M'),
                'formatted_time': availability.formatted_time(),
                'status': availability.status,
            }
        }, status=status.HTTP_201_CREATED)
    except ValueError as e:
        return Response({'error': 'Invalid date/time format. Use YYYY-MM-DD for date and HH:MM for time'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_availability(request, availability_id):
    """
    Update availability slot
    Body: {"date": "2026-01-15", "start_time": "14:00", "end_time": "15:00", "status": "Available"}
    """
    if request.user.role != 'Tutor':
        return Response({'error': 'Only tutors can update availability'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        availability = Availability.objects.get(id=availability_id, tutor=request.user.tutor_profile)
        
        # Update fields if provided
        if 'date' in request.data:
            date_str = request.data['date']
            new_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            if new_date < date.today():
                return Response({'error': 'Cannot set availability for past dates'}, 
                              status=status.HTTP_400_BAD_REQUEST)
            availability.date = new_date
        
        if 'start_time' in request.data:
            start_time = request.data['start_time']
            availability.start_time = datetime.strptime(start_time, '%H:%M').time()
        
        if 'end_time' in request.data:
            end_time = request.data['end_time']
            availability.end_time = datetime.strptime(end_time, '%H:%M').time()
        
        if 'status' in request.data:
            availability.status = request.data['status']
        
        availability.save()
        
        return Response({
            'message': 'Availability updated successfully',
            'availability': {
                'id': availability.id,
                'date': availability.date.strftime('%Y-%m-%d'),
                'formatted_date': availability.formatted_date(),
                'day_name': availability.day_name(),
                'start_time': availability.start_time.strftime('%H:%M'),
                'end_time': availability.end_time.strftime('%H:%M'),
                'formatted_time': availability.formatted_time(),
                'status': availability.status,
            }
        }, status=status.HTTP_200_OK)
    except Availability.DoesNotExist:
        return Response({'error': 'Availability slot not found'}, 
                       status=status.HTTP_404_NOT_FOUND)
    except ValueError as e:
        return Response({'error': 'Invalid date/time format. Use YYYY-MM-DD for date and HH:MM for time'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_availability(request, availability_id):
    """
    Delete availability slot
    """
    if request.user.role != 'Tutor':
        return Response({'error': 'Only tutors can delete availability'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        availability = Availability.objects.get(id=availability_id, tutor=request.user.tutor_profile)
        availability.delete()
        
        return Response({'message': 'Availability deleted successfully'}, 
                       status=status.HTTP_200_OK)
    except Availability.DoesNotExist:
        return Response({'error': 'Availability slot not found'}, 
                       status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def set_online_status(request):
    user = request.user
    is_online = request.data.get('is_online')

    if is_online is None:
        return Response({"error": "is_online required"}, status=400)

    user.is_online = is_online
    user.last_seen = timezone.now()
    user.save()

    return Response({
        "message": "Status updated",
        "is_online": user.is_online
    })
