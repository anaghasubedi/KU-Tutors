from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from ..serializers import UserSerializer


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
                    'rate': str(tutor_profile.rate) if tutor_profile.rate else None,
                    'account_number': str(tutor_profile.account_number) if tutor_profile.account_number else None,
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
                    profile.year = request.data.get('year')
                if 'semester' in request.data:
                    profile.semester = request.data.get('semester')
                if 'department' in request.data:
                    profile.department = request.data.get('department')
                if 'rate' in request.data:
                    profile.rate = request.data.get('rate')
                if 'account_number' in request.data:
                    profile.account_number = request.data.get('account_number')
                profile.save()
            except Exception as e:
                print(f"Error updating tutor profile: {e}")
                
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
            except Exception as e:
                print(f"Error updating tutee profile: {e}")
        
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