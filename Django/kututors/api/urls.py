from django.urls import path
from . import views

urlpatterns = [
    # Authentication
    path('signup/', views.signup, name='signup'),
    path('verify-email/', views.verify_email, name='verify_email'),
    path('login/', views.login, name='login'),
    path('logout/', views.logout, name='logout'),
    
    # Profile Management
    path('profile/', views.get_user_profile, name='profile'),
    path('update-profile/', views.update_profile, name='update_profile'),
    path('upload-image/', views.upload_profile_image, name='upload_image'),
    
    # Password Management
    path('forgot-password/', views.forgot_password, name='forgot_password'), 
    path('reset-password/', views.reset_password, name='reset_password'),
    
    # Account Management
    path('delete-account/', views.delete_account, name='delete_account'),
    
    # Tutor Browsing
    path('list-tutors/', views.list_tutors, name='list_tutors'),
    path('search-tutors/', views.search_tutors_by_subject, name='search_tutors'),
    path('tutor/<int:tutor_id>/', views.get_tutor_profile, name='get_tutor_profile'),
    
    # Subject Management
    path('departments/', views.list_departments, name='list_departments'),
    path('subjects/', views.list_subjects, name='list_subjects'),
    
    # Tutor Subjects
    path('tutor/subjects/', views.get_tutor_subjects, name='get_tutor_subjects'),
    path('tutor/subjects/add/', views.add_tutor_subjects, name='add_tutor_subjects'),
    path('tutor/subjects/<int:subject_id>/remove/', views.remove_tutor_subject, name='remove_tutor_subject'),
    
    # Tutee Subjects
    path('tutee/subjects/add/', views.add_tutee_subjects, name='add_tutee_subjects'),
    
    # Availability Management (Date-based)
    path('tutor/availability/', views.get_tutor_availability, name='get_tutor_availability'),
    path('tutor/availability/add/', views.add_availability, name='add_availability'),
    path('tutor/availability/<int:availability_id>/update/', views.update_availability, name='update_availability'),
    path('tutor/availability/<int:availability_id>/delete/', views.delete_availability, name='delete_availability'),
    path('tutor/<int:tutor_id>/availability/', views.get_tutor_availability_by_id, name='get_tutor_availability_by_id'),
    
    # Tutee Booking Endpoints
    path('demo-sessions/', views.demo_sessions, name='demo_sessions'),
    path('booked-classes/', views.booked_classes, name='booked_classes'),
    path('completed-classes/', views.completed_classes, name='completed_classes'),  
    path('book-demo-session/', views.book_demo_session, name='book_demo_session'),
    path('cancel-booking/<int:booking_id>/', views.cancel_booking, name='cancel_booking'),
    path('mark-complete/<int:booking_id>/', views.mark_session_complete, name='mark_session_complete'),  

    #View Tutee 
     path('tutor/my-classes/', views.my_classes, name='my_classes'),
    path('tutor/my-tutees/', views.my_tutees, name='my_tutees'),
    path('tutor/completed-sessions/', views.my_completed_sessions, name='my_completed_sessions'),
]