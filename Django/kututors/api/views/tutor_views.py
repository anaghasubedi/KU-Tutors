from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q

from ..models import TutorProfile
from ..serializers import TutorProfileSerializer


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
            tutors = tutors.filter(
                Q(user__first_name__icontains=search_query) |
                Q(user__last_name__icontains=search_query) |
                Q(subject__icontains=search_query) |
                Q(subjectcode__icontains=search_query) |
                Q(semester__icontains=search_query)
            )
        
        # Apply department filter
        if department:
            tutors = tutors.filter(department__icontains=department)
        
        # Apply subject filter (search in both subject and subject code)
        if subject_filter:
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