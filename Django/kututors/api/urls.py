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
]