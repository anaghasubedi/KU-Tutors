from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from datetime import timedelta
from django.utils import timezone
from ..models import TuteeProfile

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
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tutee_public_profile(request, tutee_id):
    """Get public profile of a tutee"""
    try:
        tutee = TuteeProfile.objects.select_related('user').get(id=tutee_id)
        
        # Check if user is online (last seen within 5 minutes)
        is_online = False
        if tutee.user.last_seen:
            is_online = timezone.now() - tutee.user.last_seen <= timedelta(minutes=5)
        
        profile_picture_url = None
        if tutee.profile_picture:
            profile_picture_url = request.build_absolute_uri(tutee.profile_picture.url)
        
        return Response({
            'id': tutee.id,
            'name': f"{tutee.user.first_name} {tutee.user.last_name}".strip() or tutee.user.username,
            'email': tutee.user.email,
            'department': tutee.department,
            'year': tutee.year,
            'semester': tutee.semester,
            'profile_picture_url': profile_picture_url,
            'is_online': is_online,
        })
        
    except TuteeProfile.DoesNotExist:
        return Response(
            {'error': 'Tutee not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        import traceback
        print(f"Error in get_tutee_public_profile: {str(e)}")
        print(traceback.format_exc())
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )