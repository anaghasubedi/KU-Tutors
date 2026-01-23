from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from datetime import datetime, date

from ..models import TutorProfile, Availability


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
            # Get specific tutor's profile
            try:
                tutor = TutorProfile.objects.get(id=tutor_id)
            except TutorProfile.DoesNotExist:
                return Response({'error': 'Tutor not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            # Get current user's tutor profile
            if request.user.role != 'Tutor':
                return Response({'error': 'Only tutors can view their availability'}, 
                              status=status.HTTP_403_FORBIDDEN)
            try:
                tutor = request.user.tutor_profile
            except TutorProfile.DoesNotExist:
                return Response({'error': 'Tutor profile not found'}, 
                              status=status.HTTP_404_NOT_FOUND)
        
        # Query availabilities
        availabilities = Availability.objects.filter(tutor=tutor)
        
        # Filter by specific date
        if filter_date:
            try:
                filter_date_obj = datetime.strptime(filter_date, '%Y-%m-%d').date()
                availabilities = availabilities.filter(date=filter_date_obj)
            except ValueError:
                return Response({'error': 'Invalid date format. Use YYYY-MM-DD'}, 
                               status=status.HTTP_400_BAD_REQUEST)
        
        # Filter future dates only
        elif from_date:
            try:
                from_date_obj = datetime.strptime(from_date, '%Y-%m-%d').date()
                availabilities = availabilities.filter(date__gte=from_date_obj)
            except ValueError:
                return Response({'error': 'Invalid date format. Use YYYY-MM-DD'}, 
                               status=status.HTTP_400_BAD_REQUEST)
        else:
            # Default: show only future dates
            availabilities = availabilities.filter(date__gte=date.today())
        
        # Order by date and time
        availabilities = availabilities.order_by('date', 'start_time')
        
        # Serialize data
        data = []
        for a in availabilities:
            try:
                data.append({
                    'id': a.id,
                    'date': a.date.strftime('%Y-%m-%d') if a.date else None,
                    'formatted_date': a.formatted_date() if a.date else 'N/A',
                    'day_name': a.day_name() if a.date else 'N/A',
                    'start_time': a.start_time.strftime('%H:%M') if a.start_time else None,
                    'end_time': a.end_time.strftime('%H:%M') if a.end_time else None,
                    'formatted_time': a.formatted_time() if (a.start_time and a.end_time) else 'N/A',
                    'status': a.status,
                })
            except Exception as e:
                print(f"Error formatting availability {a.id}: {e}")
                continue
        
        return Response({'availabilities': data, 'count': len(data)}, status=status.HTTP_200_OK)
        
    except Exception as e:
        import traceback
        print(f"Error in get_tutor_availability: {e}")
        print(traceback.format_exc())
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tutor_availability_by_id(request, tutor_id):
    """Get availability for a specific tutor by their ID"""
    try:
        # Get the tutor profile
        try:
            tutor_profile = TutorProfile.objects.get(id=tutor_id)
        except TutorProfile.DoesNotExist:
            return Response(
                {'error': 'Tutor not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get all availability slots for this tutor
        availability_slots = Availability.objects.filter(
            tutor=tutor_profile
        ).filter(date__gte=date.today()).order_by('date', 'start_time')
        
        # Serialize the availability data
        availability_data = []
        for slot in availability_slots:
            try:
                availability_data.append({
                    'id': slot.id,
                    'date': slot.date.strftime('%Y-%m-%d') if slot.date else None,
                    'formatted_date': slot.formatted_date() if slot.date else 'N/A',
                    'day_name': slot.day_name() if slot.date else 'N/A',
                    'start_time': slot.start_time.strftime('%H:%M') if slot.start_time else None,
                    'end_time': slot.end_time.strftime('%H:%M') if slot.end_time else None,
                    'formatted_time': slot.formatted_time() if (slot.start_time and slot.end_time) else 'N/A',
                    'status': slot.status,
                })
            except Exception as e:
                print(f"Error formatting slot {slot.id}: {e}")
                continue
        
        return Response({
            'availabilities': availability_data,
            'count': len(availability_data)
        })
    except Exception as e:
        import traceback
        print(f"Error in get_tutor_availability_by_id: {e}")
        print(traceback.format_exc())
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


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