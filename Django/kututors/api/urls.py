from django.urls import path, include
from .views import (
    TutorListCreate, TutorRetrieveUpdateDelete,
    TuteeListCreate, TuteeRetrieveUpdateDelete,
    SessionListCreate, SessionRetrieveUpdateDelete
)

urlpatterns = [
    path('tutors/', TutorListCreate.as_view(), name='tutor-list-create'),
    path('tutors/<int:pk>/', TutorRetrieveUpdateDelete.as_view(), name='tutor-detail'),
    path('tutees/', TuteeListCreate.as_view(), name='tutee-list-create'),
    path('tutees/<int:pk>/', TuteeRetrieveUpdateDelete.as_view(), name='tutee-detail'),
    path('sessions/', SessionListCreate.as_view(), name='session-list-create'),
    path('sessions/<int:pk>/', SessionRetrieveUpdateDelete.as_view(), name='session-detail'),
]