from django.db import models
from django.contrib.auth.models import AbstractUser

class CustomUser(AbstractUser):
    ROLE_CHOICES = [
        ('Tutor', 'Tutor'),
        ('Tutee', 'Tutee'),
    ]
    
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    contact = models.CharField(max_length=10, null=True, blank=True)
    is_verified = models.BooleanField(default=True)
    verification_code = models.CharField(max_length=6, blank=True, null=True)
    
    def __str__(self):
        return f"{self.username} ({self.role})"

class TutorProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='tutor_profile')
    subject = models.CharField(max_length=50)
    semester = models.CharField(max_length=20, default="Unknown")
    subjectcode = models.CharField(max_length=10, default="Unknown")
    available = models.BooleanField(default=True)
    accountnumber = models.CharField(max_length=20, default="Not Provided")
    bankqr = models.ImageField(upload_to='tutor_profile/', null=True, blank=True)
    
    def __str__(self):
        return f"{self.user.username} - {self.subject}"

class TuteeProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='tutee_profile')
    semester = models.CharField(max_length=20)
    subjectreqd = models.CharField(max_length=50, default="Unknown")
    
    def __str__(self):
        return f"{self.user.username} - {self.semester}"

class Session(models.Model):
    tutor = models.ForeignKey(TutorProfile, on_delete=models.CASCADE, related_name='sessions')
    tutee = models.ForeignKey(TuteeProfile, on_delete=models.CASCADE, related_name='sessions')
    date = models.DateField()
    time = models.TimeField()
    completed = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.tutor.user.username} with {self.tutee.user.username} on {self.date}"
