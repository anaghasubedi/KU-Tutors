from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from datetime import date
from django.utils import timezone
from ..models import Availability, Booking, TutorProfile, TuteeProfile

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def demo_sessions(request):
    """Get available demo sessions for tutees"""
    try:
        # Get all available slots that are not booked
        available_slots = Availability.objects.filter(
            status='Available',
            date__gte=date.today()
        ).select_related('tutor__user').order_by('date', 'start_time')
        
        demo_sessions = []
        for slot in available_slots:
            demo_sessions.append({
                'id': slot.id,
                'tutor_id': slot.tutor.id,
                'tutor_name': f"{slot.tutor.user.first_name} {slot.tutor.user.last_name}".strip(),
                'subject': slot.tutor.subject,
                'date': slot.date.strftime('%Y-%m-%d'),
                'formatted_date': slot.formatted_date(),
                'day_name': slot.day_name(),
                'time': slot.formatted_time(),
                'start_time': slot.start_time.strftime('%H:%M'),
                'end_time': slot.end_time.strftime('%H:%M'),
            })
        
        return Response({
            'demo_sessions': demo_sessions,
            'count': len(demo_sessions)
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def booked_classes(request):
    """Get booked classes for the logged-in user (works for both tutors and tutees)"""
    try:
        user = request.user
        
        auto_complete_past_sessions()

        if user.role == 'Tutee':
            # Get bookings made by this tutee - ONLY pending bookings, NOT completed
            bookings = Booking.objects.filter(
                tutee=user.tutee_profile,
                status='pending'  # ← FIX: Only get pending bookings
            ).select_related(
                'availability__tutor__user',
                'tutee__user'
            ).order_by('availability__date', 'availability__start_time')  # Order by upcoming first
            
            booked_classes = []
            for booking in bookings:
                booked_classes.append({
                    'id': booking.id,
                    'tutor_name': f"{booking.tutor_profile.user.first_name} {booking.tutor_profile.user.last_name}".strip(),
                    'subject': booking.subject,
                    'date': booking.availability.date.strftime('%Y-%m-%d'),
                    'time': booking.availability.formatted_time(),
                    'scheduled_at': f"{booking.availability.formatted_date()} at {booking.availability.formatted_time()}",
                    'status': booking.status,
                    'is_demo': booking.is_demo,
                })
            
            return Response({
                'booked_classes': booked_classes,
                'count': len(booked_classes)
            })
            
        elif user.role == 'Tutor':
            # Get bookings for this tutor's availability slots - ONLY pending bookings
            bookings = Booking.objects.filter(
                availability__tutor=user.tutor_profile,
                status='pending'  # ← FIX: Only get pending bookings
            ).select_related(
                'availability__tutor__user',
                'tutee__user'
            ).order_by('availability__date', 'availability__start_time')  # Order by upcoming first
            
            booked_classes = []
            for booking in bookings:
                booked_classes.append({
                    'id': booking.id,
                    'tutee_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                    'student_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                    'subject': booking.subject,
                    'date': booking.availability.date.strftime('%Y-%m-%d'),
                    'time': booking.availability.formatted_time(),
                    'scheduled_at': f"{booking.availability.formatted_date()} at {booking.availability.formatted_time()}",
                    'status': booking.status,
                    'is_demo': booking.is_demo,
                })
            
            return Response({
                'booked_classes': booked_classes,
                'count': len(booked_classes)
            })
        else:
            return Response(
                {'error': 'Invalid user role'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def completed_classes(request):
    """Get completed classes for the logged-in user (works for both tutors and tutees)"""
    try:
        user = request.user
        
        if user.role == 'Tutee':
            # Get completed bookings for this tutee
            bookings = Booking.objects.filter(
                tutee=user.tutee_profile,
                status='completed'
            ).select_related(
                'availability__tutor__user',
                'tutee__user'
            ).order_by('-completed_at', '-updated_at')
            
            completed_classes = []
            for booking in bookings:
                completed_classes.append({
                    'id': booking.id,
                    'tutor_name': f"{booking.tutor_profile.user.first_name} {booking.tutor_profile.user.last_name}".strip(),
                    'subject': booking.subject,
                    'date': booking.availability.date.strftime('%Y-%m-%d'),
                    'time': booking.availability.formatted_time(),
                    'scheduled_at': f"{booking.availability.formatted_date()} at {booking.availability.formatted_time()}",
                    'completed_at': booking.completed_at.strftime('%B %d, %Y') if booking.completed_at else 'N/A',
                    'is_demo': booking.is_demo,
                })
            
            return Response({
                'completed_classes': completed_classes,
                'count': len(completed_classes)
            })
            
        elif user.role == 'Tutor':
            # Get completed bookings for this tutor's availability slots
            bookings = Booking.objects.filter(
                availability__tutor=user.tutor_profile,
                status='completed'
            ).select_related(
                'availability__tutor__user',
                'tutee__user'
            ).order_by('-completed_at', '-updated_at')
            
            completed_classes = []
            for booking in bookings:
                completed_classes.append({
                    'id': booking.id,
                    'tutee_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                    'student_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                    'subject': booking.subject,
                    'date': booking.availability.date.strftime('%Y-%m-%d'),
                    'time': booking.availability.formatted_time(),
                    'scheduled_at': f"{booking.availability.formatted_date()} at {booking.availability.formatted_time()}",
                    'completed_at': booking.completed_at.strftime('%B %d, %Y') if booking.completed_at else 'N/A',
                    'is_demo': booking.is_demo,
                })
            
            return Response({
                'completed_classes': completed_classes,
                'count': len(completed_classes)
            })
        else:
            return Response(
                {'error': 'Invalid user role'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def book_demo_session(request):
    """Book a demo session"""
    try:
        if request.user.role != 'Tutee':
            return Response(
                {'error': 'Only tutees can book demo sessions'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        availability_id = request.data.get('availability_id')
        
        if not availability_id:
            return Response(
                {'error': 'availability_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get the availability slot
        try:
            availability = Availability.objects.get(id=availability_id)
        except Availability.DoesNotExist:
            return Response(
                {'error': 'Availability slot not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if slot is available
        if availability.status != 'Available':
            return Response(
                {'error': 'This time slot is no longer available'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if slot is in the past
        if availability.date < date.today():
            return Response(
                {'error': 'Cannot book slots in the past'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create the booking
        booking = Booking.objects.create(
            availability=availability,
            tutee=request.user.tutee_profile,
            is_demo=True,
            status='pending'
        )
        
        # Update availability status
        availability.status = 'Booked'
        availability.save()
        
        return Response({
            'message': 'Demo session booked successfully',
            'booking_id': booking.id,
            'tutor_name': f"{availability.tutor.user.first_name} {availability.tutor.user.last_name}".strip(),
            'date': availability.date.strftime('%Y-%m-%d'),
            'time': availability.formatted_time(),
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def cancel_booking(request, booking_id):
    """Cancel a booking"""
    try:
        user = request.user
        
        try:
            booking = Booking.objects.select_related('availability').get(id=booking_id)
        except Booking.DoesNotExist:
            return Response(
                {'error': 'Booking not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check permissions
        if user.role == 'Tutee':
            if booking.tutee.user != user:
                return Response(
                    {'error': 'You can only cancel your own bookings'},
                    status=status.HTTP_403_FORBIDDEN
                )
        elif user.role == 'Tutor':
            if booking.availability.tutor.user != user:
                return Response(
                    {'error': 'You can only cancel bookings for your sessions'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Update availability status back to Available
        availability = booking.availability
        availability.status = 'Available'
        availability.save()
        
        # Delete the booking
        booking.delete()
        
        return Response({
            'message': 'Booking cancelled successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_classes(request):
    """Get booked classes for tutors (tutor's view of their upcoming classes)"""
    try:
        if request.user.role != 'Tutor':
            return Response(
                {'error': 'Only tutors can access this endpoint'},
                status=status.HTTP_403_FORBIDDEN
            )
        # Auto-complete past sessions
        auto_complete_past_sessions()

        # Get bookings for this tutor's availability slots
        bookings = Booking.objects.filter(
            availability__tutor=request.user.tutor_profile,
            status='pending'  # Only pending/active bookings, not completed
        ).select_related(
            'availability__tutor__user',
            'tutee__user'
        ).order_by('availability__date', 'availability__start_time')
        
        booked_classes = []
        for booking in bookings:
            booked_classes.append({
                'id': booking.id,
                'tutee_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                'student_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                'tutee_id': booking.tutee.id,
                'subject': booking.subject,
                'date': booking.availability.date.strftime('%Y-%m-%d'),
                'time': booking.availability.formatted_time(),
                'scheduled_at': f"{booking.availability.formatted_date()} at {booking.availability.formatted_time()}",
                'status': booking.status,
                'is_demo': booking.is_demo,
            })
        
        return Response({
            'booked_classes': booked_classes,
            'count': len(booked_classes)
        })
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_tutees(request):
    """Get list of unique tutees who have booked classes with this tutor"""
    try:
        if request.user.role != 'Tutor':
            return Response(
                {'error': 'Only tutors can access this endpoint'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get unique tutee IDs who have bookings with this tutor
        tutee_ids = Booking.objects.filter(
            availability__tutor=request.user.tutor_profile
        ).values_list('tutee_id', flat=True).distinct()
        
        tutees = TuteeProfile.objects.filter(id__in=tutee_ids).select_related('user')
        
        tutees_data = []
        for tutee in tutees:
            # Get the full name
            full_name = f"{tutee.user.first_name} {tutee.user.last_name}".strip()
            if not full_name:
                full_name = tutee.user.username
            
            # Get profile image from tutee profile
            profile_image_url = None
            if tutee.profile_picture:
                profile_image_url = request.build_absolute_uri(tutee.profile_picture.url)
            
            # Check if user is online (last seen within 5 minutes)
            is_online = False
            if tutee.user.last_seen:
                from datetime import timedelta
                from django.utils import timezone
                is_online = timezone.now() - tutee.user.last_seen <= timedelta(minutes=5)
            
            tutees_data.append({
                'id': tutee.id,
                'name': full_name,
                'full_name': full_name,
                'year': tutee.year,
                'semester': tutee.semester,
                'profile_image': profile_image_url,
                'is_online': is_online,
            })
        
        return Response({
            'tutees': tutees_data,
            'count': len(tutees_data)
        })
        
    except Exception as e:
        import traceback
        print(f"Error in my_tutees: {str(e)}")
        print(traceback.format_exc())
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_completed_sessions(request):
    """Get completed sessions for tutors"""
    try:
        if request.user.role != 'Tutor':
            return Response(
                {'error': 'Only tutors can access this endpoint'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Auto-complete past sessions
        auto_complete_past_sessions()
        
        # Get completed bookings for this tutor's availability slots
        bookings = Booking.objects.filter(
            availability__tutor=request.user.tutor_profile,
            status='completed'
        ).select_related(
            'availability__tutor__user',
            'tutee__user'
        ).order_by('-completed_at', '-updated_at')
        
        completed_classes = []
        for booking in bookings:
            completed_classes.append({
                'id': booking.id,
                'tutee_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                'student_name': f"{booking.tutee.user.first_name} {booking.tutee.user.last_name}".strip(),
                'subject': booking.subject,
                'date': booking.availability.date.strftime('%Y-%m-%d'),
                'time': booking.availability.formatted_time(),
                'scheduled_at': f"{booking.availability.formatted_date()} at {booking.availability.formatted_time()}",
                'completed_at': booking.completed_at.strftime('%B %d, %Y') if booking.completed_at else 'N/A',
                'is_demo': booking.is_demo,
            })
        
        return Response({
            'completed_classes': completed_classes,
            'count': len(completed_classes)
        })
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
from django.utils import timezone
from datetime import datetime

def auto_complete_past_sessions():
    """Auto-complete sessions that have passed their scheduled time"""

    now = timezone.now()
    current_date = now.date()
    current_time = now.time()
    
    # Find all pending bookings where the session date has completely passed
    past_bookings = Booking.objects.filter(
        status='pending',
        availability__date__lt=current_date
    )
    
    # Also check for bookings today that have passed their end time
    today_past_bookings = Booking.objects.filter(
        status='pending',
        availability__date=current_date,
        availability__end_time__lt=current_time
    )
    
    # Combine both querysets
    count = 0
    for booking in past_bookings:
        booking.mark_completed()
        count += 1
    
    for booking in today_past_bookings:
        booking.mark_completed()
        count += 1
    
    return count