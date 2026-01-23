from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from datetime import date

from ..models import Availability, Booking


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
        
        if user.role == 'Tutee':
            # Get bookings made by this tutee
            bookings = Booking.objects.filter(
                tutee=user.tutee_profile
            ).select_related(
                'availability__tutor__user',
                'tutee__user'
            ).order_by('-booked_at')
            
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
            # Get bookings for this tutor's availability slots
            bookings = Booking.objects.filter(
                availability__tutor=user.tutor_profile
            ).select_related(
                'availability__tutor__user',
                'tutee__user'
            ).order_by('-booked_at')
            
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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_session_complete(request, booking_id):
    """Mark a session as completed (for tutors)"""
    try:
        if request.user.role != 'Tutor':
            return Response(
                {'error': 'Only tutors can mark sessions as complete'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            booking = Booking.objects.select_related('availability').get(id=booking_id)
        except Booking.DoesNotExist:
            return Response(
                {'error': 'Booking not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Verify this is the tutor's booking
        if booking.availability.tutor.user != request.user:
            return Response(
                {'error': 'You can only mark your own sessions as complete'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Mark as completed
        booking.mark_completed()
        
        return Response({
            'message': 'Session marked as completed',
            'booking_id': booking.id,
            'completed_at': booking.completed_at.strftime('%B %d, %Y at %I:%M %p') if booking.completed_at else None
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )