from rest_framework import status
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate, get_user_model
from django.core.mail import send_mail
from django.contrib.auth.hashers import make_password
from .models import TutorProfile, TuteeProfile, TemporarySignup, Availability
from .serializers import (
    SignupSerializer, LoginSerializer, UserSerializer, 
    VerifyEmailSerializer, TutorProfileSerializer, AvailabilitySerializer
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
                    'department': tutor_profile.department,
                    'semester': tutor_profile.semester,
                    'year': tutor_profile.year,
                    'subject_code': tutor_profile.subjectcode,
                    'rate': str(tutor_profile.rate) if tutor_profile.rate else None,
                    'account_number': str(tutor_profile.accountNumber) if tutor_profile.accountNumber else None,
                })
            except:
                pass
        elif user.role == 'Tutee':
            try:
                tutee_profile = user.tutee_profile
                profile_data.update({
                    'semester': tutee_profile.semester,
                    'year': tutee_profile.year,
                    'department': tutee_profile.department,
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
                if 'year' in request.data:
                    profile.year = request.year.get('year')
                if 'semester' in request.data:
                    profile.semester = request.data.get('semester')
                if 'subject' in request.data:
                    profile.subject = request.data.get('subject')
                if 'rate' in request.data:
                    profile.rate = request.data.get('rate')
                if 'account_number' in request.data:
                    profile.accountnumber = request.data.get('account_number')
                profile.save()
            except:
                pass
                
        elif user.role == 'Tutee':
            try:
                profile = user.tutee_profile
                if 'year' in request.data:
                    profile.year = request.data.get('year')
                if 'semester' in request.data:
                    profile.semester = request.data.get('semester')
                if 'department' in request.data:
                    profile.department = request.data.get('department')
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
            profile.profile_picture = image
            profile.save()
            image_url = profile.profile_picture.url if profile.profile_picture else None
        elif user.role == 'Tutee':
            profile = user.tutee_profile
            profile.profile_picture = image
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
@permission_classes([IsAuthenticated])
def list_tutors(request):
    """
    List all tutors with filtering support
    Query params: 
    - search: Search in name, subject, department, subject code
    - department: Filter by department (Computer Science/Computer Engineering)
    - subject: Filter by subject name or code
    """
    try:
        # Get all tutor profiles
        tutors = TutorProfile.objects.select_related('user').filter(available=True)
        
        # Get query parameters
        search_query = request.GET.get('search', '').strip().lower()
        department = request.GET.get('department', '').strip()
        subject_filter = request.GET.get('subject', '').strip().lower()
        
        # Apply search filter
        if search_query:
            from django.db.models import Q
            tutors = tutors.filter(
                Q(user__first_name__icontains=search_query) |
                Q(user__last_name__icontains=search_query) |
                Q(subject__icontains=search_query) |
                Q(subjectcode__icontains=search_query) |
                Q(semester__icontains=search_query)
            )
        
        # Apply department filter (assuming semester contains department info)
        if department:
            tutors = tutors.filter(department__icontains=department)
        
        # Apply subject filter (search in both subject and subject code)
        if subject_filter:
            from django.db.models import Q
            tutors = tutors.filter(
                Q(subject__icontains=subject_filter) 
            )
        
        # Serialize the data
        serializer = TutorProfileSerializer(tutors, many=True)
        
        return Response({
            'tutors': serializer.data,
            'count': len(serializer.data)
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_tutors_by_subject(request):
    """
    Search tutors by subject code or subject name
    Query params: query (required)
    """
    query = request.GET.get('query', '').strip()
    
    if not query:
        return Response({
            'error': 'Search query is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        from django.db.models import Q
        tutors = TutorProfile.objects.select_related('user').filter(
            Q(subject__icontains=query) | Q(subjectcode__icontains=query),
            available=True
        )
        
        serializer = TutorProfileSerializer(tutors, many=True)
        
        return Response({
            'tutors': serializer.data,
            'count': len(serializer.data)
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_departments(request):
    """
    Get list of available departments
    """
    departments = [
        {'id': 1, 'name': 'Computer Science'},
        {'id': 2, 'name': 'Computer Engineering'},
    ]
    
    return Response({
        'departments': departments
    }, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tutor_profile(request, tutor_id):
    """
    Get detailed profile of a specific tutor by ID
    """
    try:
        tutor = TutorProfile.objects.select_related('user').get(id=tutor_id)
        serializer = TutorProfileSerializer(tutor)
        
        return Response({
            'tutor': serializer.data
        }, status=status.HTTP_200_OK)
        
    except TutorProfile.DoesNotExist:
        return Response({
            'error': 'Tutor not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_subjects(request):
    """
    Get list of subjects by department
    Query params: department (optional)
    """
    department = request.GET.get('department', '').strip()
    
    computer_science_subjects = {
        'MATH 101': 'Calculus and Linear Algebra',
        'PHYS 101': 'General Physics I',
        'COMP 102': 'Computer Programming',
        'ENGG 111': 'Elements of Engineering I',
        'CHEM 101': 'General Chemistry',
        'EDRG 101': 'Engineering Drawing I',
        'MATH 104': 'Advanced Calculus',
        'PHYS 102': 'General Physics II',
        'COMP 116': 'Object-Oriented Programming',
        'ENGG 112': 'Elements Of Engineering II',
        'ENGT 105': 'Technical Communication',
        'ENVE 101': 'Introduction to Environmental Engineering',
        'EDRG 102': 'Engineering Drawing II',
        'MATH 208': 'Statistics and Probability',
        'MCSC 201': 'Discrete Mathematics/Structure',
        'EEEG 202': 'Digital Logic',
        'EEEG 211': 'Electronics Engineering I',
        'COMP 202': 'Data Structures and Algorithms',
        'MATH 207': 'Differential Equations and Complex Variables',
        'MCSC 202': 'Numerical Methods',
        'COMP 204': 'Communication and Networking',
        'COMP 231': 'Microprocessor and Assembly Language',
        'COMP 232': 'Database Management Systems',
        'COMP 317': 'Computational Operations Research',
        'MGTS 301': 'Engineering Economics',
        'COMP 307': 'Operating Systems',
        'COMP 315': 'Computer Architecture and Organization',
        'COMP 316': 'Theory of Computation',
        'COMP 342': 'Computer Graphics',
        'COMP 343': 'Information System Ethics',
        'COMP 302': 'System Analysis and Design',
        'COMP 409': 'Compiler Design',
        'COMP 314': 'Algorithms and Complexity',
        'COMP 323': 'Graph Theory',
        'COMP 341': 'Human Computer Interaction',
        'MGTS 403': 'Engineering Management',
        'COMP 401': 'Software Engineering',
        'COMP 472': 'Artificial Intelligence',
        'MGTS 402': 'Engineering Entrepreneurship',
        'COMP 486': 'Software Dependability',
    }
    
    computer_engineering_subjects = {
        'MATH 101': 'Calculus and Linear Algebra',
        'PHYS 101': 'General Physics I',
        'COMP 102': 'Computer Programming',
        'ENGG 111': 'Elements of Engineering I',
        'CHEM 101': 'General Chemistry',
        'EDRG 101': 'Engineering Drawing I',
        'MATH 104': 'Advanced Calculus',
        'PHYS 102': 'General Physics II',
        'COMP 116': 'Object-Oriented Programming',
        'ENGG 112': 'Elements Of Engineering II',
        'ENGT 105': 'Technical Communication',
        'ENVE 101': 'Introduction to Environmental Engineering',
        'EDRG 102': 'Engineering Drawing II',
        'MATH 208': 'Statistics and Probability',
        'MCSC 201': 'Discrete Mathematics/Structure',
        'EEEG 202': 'Digital Logic',
        'EEEG 211': 'Electronics Engineering I',
        'COMP 202': 'Data Structures and Algorithms',
        'MATH 207': 'Differential Equations and Complex Variables',
        'MCSC 202': 'Numerical Methods',
        'COMP 204': 'Communication and Networking',
        'COMP 231': 'Microprocessor and Assembly Language',
        'COMP 232': 'Database Management Systems',
        'MGTS 301': 'Engineering Economics',
        'COMP 307': 'Operating Systems',
        'COMP 315': 'Computer Architecture and Organization',
        'COEG 304': 'Instrumentation and Control',
        'COMP 310': 'Laboratory Work',
        'COMP 301': 'Principles of Programming Languages',
        'COMP 304': 'Operations Research',
        'COMP 302': 'System Analysis and Design',
        'COMP 342': 'Computer Graphics',
        'COMP 314': 'Algorithms and Complexity',
        'COMP 306': 'Embedded Systems',
        'COMP 343': 'Information System Ethics',
        'MGTS 403': 'Engineering Management',
        'COMP 401': 'Software Engineering',
        'COMP 472': 'Artificial Intelligence',
        'COMP 409': 'Compiler Design',
        'COMP 407': 'Digital Signal Processing',
        'MGTS 402': 'Engineering Entrepreneurship',
    }
    
    if department == 'Computer Science':
        subjects = [{'code': k, 'name': v} for k, v in computer_science_subjects.items()]
    elif department == 'Computer Engineering':
        subjects = [{'code': k, 'name': v} for k, v in computer_engineering_subjects.items()]
    else:
        # Return all subjects from both departments
        all_subjects = {**computer_science_subjects, **computer_engineering_subjects}
        subjects = [{'code': k, 'name': v} for k, v in all_subjects.items()]
    
    return Response({
        'subjects': subjects,
        'count': len(subjects)
    }, status=status.HTTP_200_OK)

# Availability Management
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tutor_availability(request):
    """
    Get availability slots for current tutor or specific tutor
    Query params: tutor_id (optional), date (optional), from_date (optional)
    """
    try:
        tutor_id = request.GET.get('tutor_id')
        filter_date = request.GET.get('date')
        from_date = request.GET.get('from_date')
        
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
    """
    Update user's online status
    """
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

# Tutor and Tutee Subject Management Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tutor_subjects(request):
    """
    Get all subjects for a tutor
    """
    if request.user.role != 'Tutor':
        return Response({'error': 'Only tutors can access this endpoint'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        tutor = request.user.tutor_profile
        # Return subject, subjectcode, semester as structured data
        subjects_data = {
            'subject': tutor.subject,
            'subject_code': tutor.subjectcode,
            'semester': tutor.semester,
        }
        
        return Response(subjects_data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_tutor_subjects(request):
    """
    Add or update subjects for a tutor
    Body: {"subject": "...", "subject_code": "...", "semester": "..."}
    """
    if request.user.role != 'Tutor':
        return Response({'error': 'Only tutors can access this endpoint'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        tutor = request.user.tutor_profile
        
        # Update fields if provided
        if 'subject' in request.data:
            tutor.subject = request.data['subject']
        if 'subject_code' in request.data:
            tutor.subjectcode = request.data['subject_code']
        if 'semester' in request.data:
            tutor.semester = request.data['semester']
        
        tutor.save()
        
        return Response({
            'message': 'Subjects updated successfully',
            'subject': tutor.subject,
            'subject_code': tutor.subjectcode,
            'semester': tutor.semester,
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remove_tutor_subject(request, subject_id):
    """
    Remove a subject from tutor (placeholder for future multi-subject support)
    """
    if request.user.role != 'Tutor':
        return Response({'error': 'Only tutors can access this endpoint'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    return Response({'message': 'Subject removal not yet implemented'}, 
                   status=status.HTTP_501_NOT_IMPLEMENTED)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_tutee_subjects(request):
    """
    Add or update subjects for a tutee
    Body: {"subject_required": "...", "semester": "..."}
    """
    if request.user.role != 'Tutee':
        return Response({'error': 'Only tutees can access this endpoint'}, 
                       status=status.HTTP_403_FORBIDDEN)
    
    try:
        tutee = request.user.tutee_profile
        
        # Update fields if provided
        if 'subject_required' in request.data:
            tutee.subjectreqd = request.data['subject_required']
        if 'semester' in request.data:
            tutee.semester = request.data['semester']
        
        tutee.save()
        
        return Response({
            'message': 'Subjects updated successfully',
            'subject_required': tutee.subjectreqd,
            'semester': tutee.semester,
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
    
