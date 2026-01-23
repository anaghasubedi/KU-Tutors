# Import all views to make them accessible from the views package
from .auth_views import (
    signup,
    verify_email,
    login,
    logout,
    forgot_password,
    reset_password,
)

from .profile_views import (
    get_user_profile,
    update_profile,
    upload_profile_image,
    delete_account,
)

from .tutor_views import (
    list_tutors,
    search_tutors_by_subject,
    get_tutor_profile,
    list_departments,
    list_subjects,
    get_tutor_subjects,
    add_tutor_subjects,
    remove_tutor_subject,
)

from .availability_views import (
    get_tutor_availability,
    get_tutor_availability_by_id,
    add_availability,
    update_availability,
    delete_availability,
)

from .booking_views import (
    demo_sessions,
    booked_classes,
    completed_classes,
    book_demo_session,
    cancel_booking,
    mark_session_complete,
)

from .misc_views import (
    set_online_status,
    add_tutee_subjects,
)

__all__ = [
    # Auth views
    'signup',
    'verify_email',
    'login',
    'logout',
    'forgot_password',
    'reset_password',
    
    # Profile views
    'get_user_profile',
    'update_profile',
    'upload_profile_image',
    'delete_account',
    
    # Tutor views
    'list_tutors',
    'search_tutors_by_subject',
    'get_tutor_profile',
    'list_departments',
    'list_subjects',
    'get_tutor_subjects',
    'add_tutor_subjects',
    'remove_tutor_subject',
    
    # Availability views
    'get_tutor_availability',
    'get_tutor_availability_by_id',
    'add_availability',
    'update_availability',
    'delete_availability',
    
    # Booking views
    'demo_sessions',
    'booked_classes',
    'completed_classes',
    'book_demo_session',
    'cancel_booking',
    'mark_session_complete',
    
    # Misc views
    'set_online_status',
    'add_tutee_subjects',
]