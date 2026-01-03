from django.urls import path
from . import views

urlpatterns = [
    path('signup/', views.signup, name='signup'),
    path('verify-email/', views.verify_email, name='verify_email'),
    path('login/', views.login, name='login'),
    path('logout/', views.logout, name='logout'),
    path('profile/', views.get_user_profile, name='profile'),
    path('forgot-password/', views.forgot_password, name='forgot_password'), 
    path('reset-password/', views.reset_password, name='reset_password'),
    path('update-profile/', views.update_profile, name='update_profile'),
    path('upload-image/', views.upload_profile_image, name='upload_image'),
    path('delete-account/', views.delete_account, name='delete_account'),  
]