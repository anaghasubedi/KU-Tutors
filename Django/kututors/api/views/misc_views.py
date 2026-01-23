from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone


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